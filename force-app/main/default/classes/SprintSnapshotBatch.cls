@SuppressWarnings('PMD.AvoidGlobalModifier, PMD.AvoidDebugStatements, PMD.DebugsShouldUseLoggingLevel, PMD.UnusedLocalVariable')
global with sharing class SprintSnapshotBatch implements Database.Batchable<SObject>, Database.Stateful, Schedulable {
    private static final String CLASS_NAME = 'SprintSnapshotBatch';
    private static final String SPRINT_SNAPSHOT_WAS_COMPLETED = 'Sprint Snapshot Was Completed';
    private static final String SPRINT_SNAPSHOT_WAS_NOT_COMPLETED = 'Sprint Snapshot Was Not Completed';

    private Map<String, String> sprintSnapshotMapping;
    private static final String QUERY_TEMPLATE = 'SELECT {0}, {1} FROM {2} WHERE {3}';
    private static final String SPRINT_OBJECT = Schema.SObjectType.Sprint__c.getName();
    private static final String WHERE_CLAUSE = getWhereClause();
    private static final Set<String> SPRINT_FIELDS = new Set<String>{
        Schema.SObjectType.Sprint__c.fields.Id.getName(),
        Schema.SObjectType.Sprint__c.fields.Name.getName(),
        Schema.SObjectType.Sprint__c.fields.Start_Date__c.getName(),
        Schema.SObjectType.Sprint__c.fields.End_Date__c.getName()
    };

    private static final String BURNDOWN_OBJECT = Schema.SObjectType.Burndown_Item__c.getName();
    private static final Set<String> BURNDOWN_FIELDS = new Set<String>{
        Schema.SObjectType.Burndown_Item__c.fields.Id.getName(),
        Schema.SObjectType.Burndown_Item__c.fields.Sprint__c.getName(),
        Schema.SObjectType.Burndown_Item__c.fields.Snapshot_Date__c.getName()
    };

    global Database.QueryLocator start(Database.BatchableContext bc) {
        Date currentDate = System.today();
        populateSprintToSnapshotMappings();

        Database.QueryLocator queryLocator;
        try {
            queryLocator = Database.getQueryLocator(getSprintQuery());
        } catch (Exception ex) {
            exceptionWithDetails(ex, CLASS_NAME);
        }
        return queryLocator;
    }

    global void execute(Database.BatchableContext bc, List<Sprint__c> scope) {
        List<Burndown_Item__c> sprintSnapshots = new List<Burndown_Item__c>();
        List<Burndown_Item__c> sprintSnapshotsToUpdate = new List<Burndown_Item__c>();
        Map<String, Burndown_Item__c> existingSnapshotBySprint = getSnapshotRecordBySprintId(scope);
        for (Sprint__c sprint : scope) {
            if (needNewSnapshot(existingSnapshotBySprint, sprint)) {
                sprintSnapshots.add(createSprintSnapshotRecord(sprint));
            } else {
                sprintSnapshotsToUpdate.add(new Burndown_Item__c(Id = existingSnapshotBySprint.get(sprint.Id).Id, Snapshot_Date__c = System.Today()));
            }
        }

        if (!sprintSnapshots.isEmpty() && Schema.SObjectType.Burndown_Item__c.isCreateable()) {
            Utilities.Secure_DML(sprintSnapshots, Utilities.DML_Action.UPS, schema.SObjectType.Burndown_Item__c);
        }

        if (!sprintSnapshotsToUpdate.isEmpty() && Schema.SObjectType.Burndown_Item__c.isUpdateable()) {
            Utilities.Secure_DML(sprintSnapshotsToUpdate, Utilities.DML_Action.UPS, schema.SObjectType.Burndown_Item__c);
        }
    }

    global void finish(Database.BatchableContext bc) {
        sendEmail(SPRINT_SNAPSHOT_WAS_COMPLETED, SPRINT_SNAPSHOT_WAS_COMPLETED);
    }

    // PRIVATE

    private static String getWhereClause() {
        String whereClauseTemplate = '{0} <= : currentDate AND {1} >= : currentDate';
        return String.format(
            whereClauseTemplate,
            new List<String>{ Schema.SObjectType.Sprint__c.fields.Start_Date__c.getName(), Schema.SObjectType.Sprint__c.fields.End_Date__c.getName() }
        );
    }

    private String getSprintQuery() {
        return String.format(
            QUERY_TEMPLATE,
            new List<String>{
                String.join(new List<String>(SPRINT_FIELDS), ','),
                String.join(new List<String>(sprintSnapshotMapping.keyset()), ','),
                SPRINT_OBJECT,
                WHERE_CLAUSE
            }
        );
    }

    private List<Copado_Setting__mdt> getCopadoSetting() {
        return [
            SELECT Id, Text_Field__c, Enabled__c
            FROM Copado_Setting__mdt
            WHERE DeveloperName = :SprintSnapshotConstants.SPRINT_TO_SNAPSHOT_FIELD_MAPPING
            LIMIT 1
        ];
    }

    private void populateSprintToSnapshotMappings() {
        sprintSnapshotMapping = new Map<String, String>();
        try {
            for (Copado_Setting__mdt copadoSetting : getCopadoSetting()) {
                sprintSnapshotMapping.put(SprintSnapshotConstants.SPRINT_PLANNED_VELOCITY, SprintSnapshotConstants.SNAPSHOT_PLANNED_VELOCITY);
                sprintSnapshotMapping.put(SprintSnapshotConstants.SPRINT_ACTUAL_VELOCITY, SprintSnapshotConstants.SNAPSHOT_ACTUAL_VELOCITY);

                if (copadoSetting.Enabled__c && String.isNotBlank(copadoSetting.Text_Field__c)) {
                    String jsonText = copadoSetting.Text_Field__c;
                    Map<String, Object> fieldMap = (Map<String, Object>) JSON.deserializeUntyped(jsonText);
                    for (String sprintFieldName : fieldMap.keyset()) {
                        sprintSnapshotMapping.put(sprintFieldName, (String) fieldMap.get(sprintFieldName));
                    }
                }
            }
        } catch (Exception ex) {
            exceptionWithDetails(ex, CLASS_NAME);
        }
    }

    private Burndown_Item__c createSprintSnapshotRecord(Sprint__c sprint) {
        Burndown_Item__c sprintSnapshot = new Burndown_Item__c();
        for (String sprintFieldName : sprintSnapshotMapping.keyset()) {
            sprintSnapshot.put(sprintSnapshotMapping.get(sprintFieldName), sprint.get(sprintFieldName));
        }
        sprintSnapshot.Snapshot_Date__c = System.today();
        sprintSnapshot.Sprint__c = sprint.Id;
        return sprintSnapshot;
    }

    private Map<String, Burndown_Item__c> getSnapshotRecordBySprintId(List<Sprint__c> sprints) {
        Map<String, Burndown_Item__c> existingSnapshotBySprint = new Map<String, Burndown_Item__c>();
        for (Burndown_Item__c sprintSnapshot : (List<Burndown_Item__c>) Database.query(getSnapshotQuery())) {
            if (!existingSnapshotBySprint.containsKey(sprintSnapshot.Sprint__c)) {
                existingSnapshotBySprint.put(sprintSnapshot.Sprint__c, sprintSnapshot);
            }
        }
        return existingSnapshotBySprint;
    }

    private String getSnapshotQuery() {
        String whereClause = 'Snapshot_Date__c != NULL AND Sprint__c IN :sprints';
        String query = String.format(
            QUERY_TEMPLATE,
            new List<String>{
                String.join(new List<String>(sprintSnapshotMapping.values()), ','),
                String.join(new List<String>(BURNDOWN_FIELDS), ','),
                BURNDOWN_OBJECT,
                whereClause
            }
        );
        query += ' ORDER BY Snapshot_Date__c DESC';
        return query;
    }

    private Boolean needNewSnapshot(Map<String, Burndown_Item__c> existingSnapshotBySprint, Sprint__c sprint) {
        Boolean result = !existingSnapshotBySprint.containsKey(Sprint.Id);
        if (!result) {
            Burndown_Item__c existingSnapshot = existingSnapshotBySprint.get(Sprint.Id);
            for (String sprintFieldName : sprintSnapshotMapping.keyset()) {
                if (!result && sprint.get(sprintFieldName) != existingSnapshot.get(sprintSnapshotMapping.get(sprintFieldName))) {
                    result = true;
                    break;
                }
            }
        }
        return result;
    }

    private void sendEmail(String textBody, String subject) {
        String[] toAddresses = new List<String>{ UserInfo.getUserEmail() };
        try {
            sendEmail(textBody, subject, toAddresses);
        } catch (Exception ex) {
            exceptionWithDetails(ex, CLASS_NAME);
        }
    }

    private static void sendEmail(String textBody, String subject, String[] toAddresses) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String senderName = UserInfo.getOrganizationName();
        mail.setToAddresses(toAddresses);
        mail.setSubject(subject);
        mail.setPlainTextBody(textBody);
        if (senderName != null) {
            mail.setSenderDisplayName(senderName);
        }
        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
    }

    private void exceptionWithDetails(System.Exception ex, String className) {
        System.debug('****************************************\n Exception Message : ' + ex.getMessage());
        System.debug('****************************************\n Class Name : ' + className + ' Line Number : ' + ex.getLineNumber());
        System.debug('****************************************');

        String errorMessage = '\n Exception Message : ' + ex.getMessage();
        errorMessage += '\n Class Name : ' + className + ' Line Number : ' + ex.getLineNumber();

        sendEmail(SPRINT_SNAPSHOT_WAS_NOT_COMPLETED + errorMessage, SPRINT_SNAPSHOT_WAS_NOT_COMPLETED);
    }

    // EXECUTE THE BATCH
    public static void run(Integer batchSize) {
        SprintSnapshotBatch batch = new SprintSnapshotBatch();
        Database.executebatch(batch, batchSize);
    }

    public static void run() {
        run(200);
    }

    // SCHEDULE
    global static String schedule(String jobName, String cronExpression) {
        SprintSnapshotBatch job = new SprintSnapshotBatch();
        return System.schedule(jobName, cronExpression, job);
    }

    global void execute(SchedulableContext ctx) {
        run();
    }
}