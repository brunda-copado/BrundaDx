public with sharing class SprintVelocityRollUp {
    public Map<Id, User_Story__c> userStoryBySprintIdsForVelocity = new Map<Id, User_Story__c>();
    private static final String IN_PROGRESS = 'In progress';
    private static final String INITIAL_PLANNED_VELOCITY_FIELD = 'InitialPlannedVelocity__c';
    private List<Sprint__c> records;
    private Map<Id, Sprint__c> old;

    // CONSTRUCTOR

    public SprintVelocityRollUp(List<Sprint__c> records) {
        this.records = records;
    }

    public SprintVelocityRollUp(List<Sprint__c> records, Map<Id, Sprint__c> old) {
        this(records);
        this.old = old;
    }

    // PUBLIC

    public void execute() {
        for (Sprint__c sprint : records) {
            getSprintsForInitialPlannedVelocity(old.get(sprint.Id), sprint);
        }
        updateSprintsIntialPlannedVelocity();
    }

    // PRIVATE

    private void getSprintsForInitialPlannedVelocity(Sprint__c oldSprintRecord, Sprint__c newSprintRecord) {
        if (oldSprintRecord == null || newSprintRecord == null || newSprintRecord.Status__c == null) {
            return;
        }

        Boolean isSprintInProgress = oldSprintRecord.Status__c != newSprintRecord.Status__c &&
            newSprintRecord.Status__c == IN_PROGRESS
            ? true
            : false;

        if (isSprintInProgress) {
            if (!userStoryBySprintIdsForVelocity.containsKey(newSprintRecord.Id)) {
                userStoryBySprintIdsForVelocity.put(newSprintRecord.Id, new User_Story__c(Sprint__c = newSprintRecord.Id));
            }
        }
    }

    private void updateSprintsIntialPlannedVelocity() {
        if (hasUserStoriesToProcess(userStoryBySprintIdsForVelocity)) {
            updateSprintsVelocity(userStoryBySprintIdsForVelocity.values());
        }
    }

    private static Boolean hasUserStoriesToProcess(Map<Id, User_Story__c> recordsBySprintId) {
        return !recordsBySprintId.isEmpty() && recordsBySprintId.values() != null && !recordsBySprintId.values().isEmpty();
    }

    private void updateSprintsVelocity(List<User_Story__c> userStories) {
        CopadoRollup.RollUpContext rollupContext = new CopadoRollup.RollUpContext(
            Sprint__c.SobjectType,
            User_Story__c.SobjectType,
            Schema.SObjectType.User_Story__c.fields.Sprint__c
        );

        rollupContext.add(
            new CopadoRollup.RollupSummaryField(
                Schema.SObjectType.Sprint__c.fields.InitialPlannedVelocity__c,
                Schema.SObjectType.User_Story__c.fields.Total_Story_Points__c,
                CopadoRollup.OperationEnum.Sum
            )
        );
        Sobject[] sprints = CopadoRollup.rollUp(rollupContext, userStories);
        if (!sprints.isEmpty()) {
            for (SObject so : sprints) {
                Sprint__c sprint = (Sprint__c) Trigger.newMap.get(so.Id);
                if (so.get(INITIAL_PLANNED_VELOCITY_FIELD) != null) {
                    sprint.InitialPlannedVelocity__c = (Double) so.get(INITIAL_PLANNED_VELOCITY_FIELD);
                }
            }
        }
    }
}