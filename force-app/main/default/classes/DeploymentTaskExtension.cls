@SuppressWarnings('PMD')
public with sharing class DeploymentTaskExtension {
    private static final String DUMMY_ID = '000000000000000';

    public Id orgId { get; set; }
    public Id currentId;
    public String DEFAULT_SERVER_URL = 'https://na.api.copado.com';

    private final ApexPages.StandardController std;

    public Deployment_Task__c task { get; set; }
    public String dataJson { get; set; }
    public String describe_url { get; set; }
    public String sobjects_url { get; set; }
    public String testquery_url { get; set; }
    public String metadata_url { get; set; }
    public String custom_settings_url { get; set; }
    public Settings settings { get; set; }
    public User_Story__c ustry { get; set; }

    // CONSTRUCTOR

    public DeploymentTaskExtension(ApexPages.StandardController stdController) {
        this.std = stdController;
        settings = new Settings();

        /**
         * Adding all fields to the standard controller scope to avoid field exceptions
         */
        if (!Test.isRunningTest()) {
            stdController.addFields(Utilities.getAllFields('Deployment_Task__c').get(Label.FIELDS).split(','));
        }
        this.task = (Deployment_Task__c) stdController.getRecord();
        if (this.task.Type__c == null) {
            dataJson = '{"Perform_in_Source_Org":' + this.task.Perform_in_Source_Org__c;
            dataJson += ',"Perform_in_Destination_Orgs":' + this.task.Perform_in_Destination_Orgs__c;
            dataJson += ',"Task_Description":"';
            if (this.task.Task_Description__c != null) {
                dataJson += this.task.Task_Description__c.escapeJava();
            }
            dataJson += '"}';
            this.task.Type__c = 'Manual Task';
        } else {
            dataJson = task.dataJson__c;
        }
        populateUserStoryRelation();
    }

    // PUBLIC

    public PageReference deleteAction() {
        Utilities.Secure_DML(task, Utilities.DML_Action.DEL, schema.SObjectType.Deployment_Task__c);
        String newPageUrl = '/' + task.User_Story__c;
        PageReference newPage = new PageReference(newPageUrl);
        newPage.setRedirect(true);
        return newPage;
    }

    public PageReference saveAction() {
        Boolean keepDataTemplateJSON = false;
        Deployment_Task__c taskToSave = (Deployment_Task__c) std.getRecord();
        currentId = taskToSave.Id;
        if (null != currentId && !Utilities.HasEditAccess(currentId)) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.FATAL, Label.InSuffPriv));
            return null;
        }

        String data = ApexPages.currentPage().getParameters().get('detail');
        Boolean dataIdsPopulated = checkDataIdsPopulated(data, taskToSave.Type__c);
        if (
            String.isBlank(taskToSave.Name) ||
            String.isBlank(taskToSave.Type__c) ||
            taskToSave.User_Story__c == null ||
            String.isBlank(taskToSave.Perform_Manual_Task__c) ||
            !dataIdsPopulated
        ) {
            ApexPages.addMessage(new ApexPages.message(ApexPages.Severity.ERROR, Label.FILL_REQUIRED_FIELDS));
            return null;
        }
        Boolean isDataTemplate = null != data && taskToSave.Type__c != null && taskToSave.Type__c == 'Data Template';
        Boolean isManualTask = null != data && taskToSave.Type__c != null && taskToSave.Type__c == 'Manual Task';
        if (isManualTask) {
            Map<String, Object> valuesByParameters = (Map<String, Object>) JSON.deserializeUntyped(data);
            taskToSave.Apply_to__c = (String) valuesByParameters.get('Apply_to');
            taskToSave.Disable_Task_for_Back_Promotions__c = (Boolean) valuesByParameters.get('Disable_Task_for_Back_Promotions');
        }

        if (isDataTemplate) {
            DataTemplateJSON previousData = null != taskToSave.dataJson__c
                ? (DataTemplateJSON) JSON.deserialize(taskToSave.dataJson__c, DataTemplateJSON.class)
                : null;
            DataTemplateJSON newData = null != data ? (DataTemplateJSON) JSON.deserialize(data, DataTemplateJSON.class) : null;
            if (null != previousData && null != newData) {
                keepDataTemplateJSON = (previousData.dataTemplateId == newData.dataTemplateId);
            }
            if (null != previousData) {
                taskToSave.Data_Template__c = Test.isRunningTest() ? null : previousData.dataTemplateId;
            }
            if (null != newData) {
                taskToSave.Data_Template__c = Test.isRunningTest() ? null : newData.dataTemplateId;
            }
        }

        Boolean updateDataJsonField =
            data != null &&
            taskToSave.Type__c != null &&
            taskToSave.Type__c != 'Delete MetaData' &&
            taskToSave.Type__c != 'Apex';
        if (!keepDataTemplateJSON) {
            taskToSave.dataJson__c = updateDataJsonField ? data : null;
        }

        if (
            ApexPages.currentPage().getParameters().get('clone') != null &&
            Integer.valueOf(ApexPages.currentPage().getParameters().get('clone')) == 1
        ) {
            taskToSave.id = null;
        }
        Utilities.Secure_DML(taskToSave, Utilities.DML_Action.UPS, schema.Sobjecttype.Deployment_Task__c);

        if (
            data != null &&
            taskToSave.Type__c != null &&
            (taskToSave.Type__c == 'Apex' ||
            taskToSave.Type__c == 'Delete MetaData' ||
            taskToSave.Type__c == 'Custom Settings')
        ) {
            List<Attachment> attList = new List<Attachment>(
                [
                    SELECT Id
                    FROM Attachment
                    WHERE ParentId = :taskToSave.Id AND (Name = 'Apex' OR Name = 'Delete MetaData' OR Name = 'Custom Settings')
                ]
            );
            if (!attList.isEmpty()) {
                Utilities.Secure_DML(attList, Utilities.DML_Action.DEL, schema.Sobjecttype.Attachment);
            }
            Attachment att = new Attachment();
            att.Name = taskToSave.Type__c;
            att.Body = Blob.valueOf(data);
            att.ParentId = taskToSave.Id;
            Utilities.Secure_DML(att, Utilities.DML_Action.INS, schema.Sobjecttype.Attachment);
        }
        String newPageUrl = '/' + taskToSave.id;
        PageReference newPage = new PageReference(newPageUrl);
        newPage.setRedirect(true);
        return newPage;
    }

    public PageReference populateUserStoryRelation() {
        try {
            Deployment_Task__c currentVersion = (Deployment_Task__c) std.getRecord();
            String ustryName = ApexPages.currentPage().getParameters().get('ustryName');
            Settings__c s = Settings__c.getOrgDefaults(); // Copado settings (custom setting)
            String serverUrl = String.isNotBlank(s.Server_URL__c) ? s.Server_URL__c : DEFAULT_SERVER_URL; // Copado server url to shape callout urls
            /**
             * Query the record itself to get org credentials from related user story.
             * Org credentials Id is in use to generate below end point urls
             */
            ustry = [
                SELECT Id, Org_Credential__c
                FROM User_Story__c
                WHERE Id = :currentVersion.User_Story__c OR Name = :ustryName
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];

            if (ustry != null && ustry.Org_Credential__c != null) {
                String urlParameters = '?nosid=1';
                String herokuServer = serverUrl;
                String urlBase = herokuServer + '/json/v1/';
                orgId = ustry.Org_Credential__c;
                sobjects_url = urlBase + 'listSObjects/' + EncodingUtil.urlEncode(ustry.Org_Credential__c, 'UTF-8') + urlParameters; // to retrieve sobjects by using copado API
                testquery_url = urlBase + 'test-query/' + EncodingUtil.urlEncode(ustry.Org_Credential__c, 'UTF-8') + urlParameters; // to test defined query at data step
                describe_url = urlBase + 'describe/' + EncodingUtil.urlEncode(ustry.Org_Credential__c, 'UTF-8') + '/{sobject}' + urlParameters; // to get sObject description
                custom_settings_url =
                    urlBase +
                    'customSetting/' +
                    EncodingUtil.urlEncode(ustry.Org_Credential__c, 'UTF-8') +
                    '/{sobject}' +
                    urlParameters; // to get custom settings
                metadata_url =
                    urlBase +
                    'metadata/' +
                    EncodingUtil.urlEncode(ustry.Org_Credential__c, 'UTF-8') +
                    urlParameters +
                    EncodingUtil.urlEncode('&dates=format', 'UTF-8'); //to get metadata
            }
            return null;
        } catch (Exception e) {
            return null;
        }
    }

    @RemoteAction
    public static User_Story__c getUserStory(String userStoryName) {
        try {
            return [SELECT Id, Org_Credential__c FROM User_Story__c WHERE Name = :userStoryName WITH SECURITY_ENFORCED LIMIT 1];
        } catch (Exception e) {
            return null;
        }
    }

    // PRIVATE

    private Boolean checkDataIdsPopulated(String data, String taskType) {
        Boolean isValid = true;
        try {
            if (data != null && taskType == 'Data Template') {
                DataStepData dataInformations = (DataStepData) JSON.deserialize(data, DataStepData.class);
                if (
                    dataInformations.source == null &&
                    (String.isBlank(dataInformations.dataTemplateId) || dataInformations.dataTemplateId == DUMMY_ID)
                ) {
                    isValid = false;
                } else if (
                    dataInformations.source != null &&
                    dataInformations.source.type == DataDeployRequest.Source.DATASET &&
                    (String.isBlank(dataInformations.source.id) || dataInformations.source.id == DUMMY_ID)
                ) {
                    isValid = false;
                }
            }
        } catch (Exception e) {
            isValid = false;
        }
        return isValid;
    }

    public class DataTemplateJSON {
        public String dataTemplateId;
        public String dataTemplateName;
    }
}