@SuppressWarnings('PMD.ExcessiveParameterList')
@IsTest
public with sharing class TestDataFactory { // NOPMD : Supressing rule to avoid large refactor.
    // When we create a list of SObjects, we need to have a unique field for the insert if there isn't an autonumber field.
    // Usually we use the Name field, but some objects don't have a name field.
    private static Map<Schema.SObjectType, Schema.SObjectField> nameFieldMap = new Map<Schema.SObjectType, Schema.SObjectField>{
        Contact.SObjectType => Contact.LastName,
        Case.SObjectType => Case.CaseNumber, //this is the autonumber field
        User.SObjectType => User.LastName,
        PermissionSetAssignment.SObjectType => PermissionSetAssignment.Id
    };

    public static List<User> createUsers() {
        List<User> users = new List<User>();

        String orgTimezoneKey = getOrgTimeZoneKey();
        orgTimezoneKey = orgTimezoneKey != null ? orgTimezoneKey : 'America/Los_Angeles';

        User sysUs = new User();
        sysUs.ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id;
        sysUs.LastName = 'LastName';
        sysUs.Email = 'test1@test1.com';
        sysUs.Username = 'psysUser000@amamama.com' + System.currentTimeMillis();
        sysUs.CompanyName = 'TEST';
        sysUs.Title = 'title';
        sysUs.Alias = 'alias';
        sysUs.TimeZoneSidKey = orgTimezoneKey;
        sysUs.EmailEncodingKey = 'UTF-8';
        sysUs.LanguageLocaleKey = 'en_US';
        sysUs.LocaleSidKey = 'en_US';
        sysUs.UserPermissionsInteractionUser = true;
        users.add(sysUs);

        User stdUs = new User();
        stdUs.ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User'].Id;
        stdUs.LastName = 'LastName';
        stdUs.Email = 'test2@test2.com';
        stdUs.Username = 'pstdUser002@amamama.com' + System.currentTimeMillis();
        stdUs.CompanyName = 'TEST';
        stdUs.Title = 'title2';
        stdUs.Alias = 'alias2';
        stdUs.TimeZoneSidKey = orgTimezoneKey;
        stdUs.EmailEncodingKey = 'UTF-8';
        stdUs.LanguageLocaleKey = 'en_US';
        stdUs.LocaleSidKey = 'en_US';
        stdUs.UserPermissionsInteractionUser = true;
        users.add(stdUs);

        insert users;

        return users;
    }

    public static List<Environment__c> createEnvironments(Integer count) {
        List<Environment__c> environments = new List<Environment__c>();
        for (Integer i = 0; i < count; i++) {
            Environment__c environment = new Environment__c();
            environment.Name = 'Environment ' + i;
            environment.Index_Back_Promotion_metadata__c = true;
            environment.Type__c = 'Production/Developer';
            environment.Platform__c = 'Salesforce';

            environments.add(environment);
        }

        insert environments;

        return environments;
    }

    public static Environment__c createEnvironments(String environmentName, String environmentType) {
        Environment__c environment = new Environment__c();
        environment.Name = environmentName;
        environment.Index_Back_Promotion_metadata__c = true;
        environment.Type__c = environmentType;

        return environment;
    }

    public static Environmental_Variable__c createEnvironmentVariable(String name, String value, String scope, String envId) {
        Environmental_Variable__c environmentVariable = new Environmental_Variable__c();
        environmentVariable.Name = name;
        environmentVariable.Value__c = value;
        environmentVariable.Scope__c = scope;
        environmentVariable.Environment__c = envId;

        return environmentVariable;
    }

    public static List<Org__c> createOrgCredentials(Integer count, String userName, List<Environment__c> environments) {
        List<Org__c> credentials = new List<Org__c>();
        for (Integer i = 0; i < count; i++) {
            Org__c org = new Org__c();
            org.Name = 'Test Org ' + i;
            org.Org_Type__c = 'Production/Developer';
            org.Username__c = userName + i;
            org.Environment__c = environments[i].Id;
            org.Oauth_Signature__c = 'signature';
            org.Validated_Date__c = System.now();

            credentials.add(org);
        }

        insert credentials;

        return credentials;
    }

    public static List<Org__c> createOrgCredentials(Integer count, String userName) {
        List<Org__c> credentials = new List<Org__c>();
        for (Integer i = 0; i < count; i++) {
            Org__c org = new Org__c();
            org.Name = 'Test Org ' + i;
            org.Org_Type__c = 'Production/Developer';
            org.Username__c = userName + i;
            org.Oauth_Signature__c = 'signature';
            org.Validated_Date__c = System.now();

            credentials.add(org);
        }

        insert credentials;

        return credentials;
    }

    public static Org__c createOrgCredentials(String userName, String environmentId, String orgType) {
        Org__c org = new Org__c();
        org.Name = 'Test Org ' + environmentId;
        org.Org_Type__c = orgType;
        org.Username__c = userName + environmentId;
        org.Environment__c = environmentId;
        org.Oauth_Signature__c = 'signature';
        org.Validated_Date__c = System.now();

        return org;
    }

    public static Org__c createOrgCredentials(String orgName, String orgType) {
        Org__c org = new Org__c();
        org.Name = orgName;
        org.Org_Type__c = orgType;

        return org;
    }

    public static Data_Template__c createDataTemplate(String name, String mainObject, String filterLogic, String orgId) {
        // NOPMD : Supressing rule to avoid large refactor.
        Data_Template__c dataTemplate = new Data_Template__c();
        dataTemplate.Name = name;
        dataTemplate.Description__c = 'This is to test read-only access for Jesus';
        dataTemplate.Main_Object__c = mainObject;
        dataTemplate.Attachment_Options__c = 'Insert attachments';
        dataTemplate.Continue_on_Error__c = 'Continue deployment until blocker issue';
        dataTemplate.Filter_Logic__c = filterLogic;
        dataTemplate.Active__c = true;
        dataTemplate.Template_Source_Org__c = orgId;

        return dataTemplate;
    }

    public static Data_Template__c createDataTemplate( // NOPMD : Supressing rule to avoid large refactor.
        String name,
        String sourceOrg,
        String mainObject,
        Data_Template__c childDataTemplate,
        Data_Template__c parentDataTemplate,
        List<DataFilter> dataFilters,
        String filterLogic,
        Map<String, Boolean> selectedFields
    ) {
        Data_Template__c dataTemplate = new Data_Template__c(
            Name = name,
            Template_Source_Org__c = sourceOrg,
            Main_Object__c = mainObject,
            Filter_Logic__c = filterLogic
        );
        insert dataTemplate;

        DataTemplateDetail templateDetail = new DataTemplateDetail();
        templateDetail.parentObjectsReferenceList = new List<DataTemplateDetail.RelationTemplateDetails>();
        templateDetail.childrenObjectsReferenceList = new List<DataTemplateDetail.RelationTemplateDetails>();
        if (childDataTemplate != null) {
            DataTemplateDetail.RelationTemplateDetails childDetails = new DataTemplateDetail.RelationTemplateDetails();
            childDetails.templateId = childDataTemplate.Id;
            templateDetail.childrenObjectsReferenceList.add(childDetails);
        }
        if (parentDataTemplate != null) {
            DataTemplateDetail.RelationTemplateDetails parentDetails = new DataTemplateDetail.RelationTemplateDetails();
            parentDetails.templateId = parentDataTemplate.Id;
            templateDetail.parentObjectsReferenceList.add(parentDetails);
        }
        templateDetail.selectableFieldsMap = new Map<String, DataTemplateDetail.CopadoSelectedField>();
        if (selectedFields != null) {
            for (String fieldName : selectedFields.keySet()) {
                DataTemplateDetail.CopadoSelectedField field = new DataTemplateDetail.CopadoSelectedField();
                field.name = fieldName;
                field.isSelected = selectedFields.get(fieldName);
                templateDetail.selectableFieldsMap.put(field.name, field);
            }
        }
        if (dataFilters != null) {
            templateDetail.queryFilterList = new List<QueryEditor.CriteriaWrapper>();
            for (DataFilter filter : dataFilters) {
                templateDetail.queryFilterList.add(filter.toQueryCriteria());
            }
        }
        templateDetail.dataTemplate.templateFilterLogic = filterLogic;

        Attachment attachment = new Attachment(
            ParentId = dataTemplate.Id,
            Name = DataTemplateDetail.ATTACHMENT_NAME,
            Body = Blob.valueOf(JSON.serialize(templateDetail))
        );
        insert attachment;

        return dataTemplate;
    }

    public static Deployment__c createDeployment(String name, String recordTypeId, String fromOrgId) {
        Deployment__c deployment = new Deployment__c();
        deployment.Name = name;
        deployment.Active__c = true;
        deployment.From_Org__c = fromOrgId;
        deployment.RecordTypeId = recordTypeId;

        return deployment;
    }

    public static Deployment__c createDeployment(String name, String apiName, String recordTypeId, String fromOrgId) {
        // NOPMD : Supressing rule to avoid large refactor.
        Deployment__c deployment = new Deployment__c();
        deployment.Name = name;
        deployment.ApiName__c = apiName;
        deployment.Active__c = true;
        deployment.From_Org__c = fromOrgId;
        deployment.RecordTypeId = recordTypeId;

        return deployment;
    }

    public static Attachment createAttachment(String name, String parentId, String attBody) {
        Attachment att = new Attachment();
        att.Name = name;
        att.ParentId = parentId;
        att.Body = Blob.valueOf(attBody);
        return att;
    }

    public static Destination_Org__c createDestinationOrg(String deploymentId, String toOrg) {
        Destination_Org__c destination = new Destination_Org__c();
        destination.Deployment__c = deploymentId;
        destination.To_Org__c = toOrg;

        return destination;
    }

    public static Git_Repository__c createGitRepository() {
        Git_Repository__c repo = new Git_Repository__c();
        repo.Name = 'test repo';

        return repo;
    }

    public static Git_Commit__c createGitCommit(String commitId, Date commitDate, String repositoryId) {
        Git_Commit__c gitCommit = new Git_Commit__c();
        gitCommit.Commit_Id__c = commitId;
        gitCommit.Commit_Date__c = commitDate;
        gitCommit.Git_Repository__c = repositoryId;

        return gitCommit;
    }

    public static Git_Backup__c createGitBackup(String name, String orgId, String repositoryId) {
        Git_Backup__c gitBackup = new Git_Backup__c();
        gitBackup.Name = name;
        gitBackup.Git_Repository__c = repositoryId;
        gitBackup.Org__c = orgId;

        return gitBackup;
    }

    public static Git_Org_Commit__c createGitOrgCommit(String commitId, Date commitDate, String snapshotId, String orgId, String status) {
        // NOPMD : Supressing rule to avoid large refactor.
        Git_Org_Commit__c gitOrgCommit = new Git_Org_Commit__c();
        gitOrgCommit.Commit_Id__c = commitId;
        gitOrgCommit.Commit_Date__c = commitDate;
        gitOrgCommit.Git_Backup__c = snapshotId;
        gitOrgCommit.Org__c = orgId;
        gitOrgCommit.Status__c = status;

        return gitOrgCommit;
    }

    public static Copado_Notification__c createCopadoNotification( // NOPMD : Supressing rule to avoid large refactor.
        String type,
        String status,
        Boolean isSuccess,
        Boolean isFinished,
        String name,
        String parentId
    ) {
        Copado_Notification__c copadoNotification = new Copado_Notification__c();
        copadoNotification.Type__c = type;
        copadoNotification.status__c = status;
        copadoNotification.isSuccess__c = isSuccess;
        copadoNotification.isFinished__c = isFinished;
        copadoNotification.Name = name;
        copadoNotification.ParentId__c = parentId;

        return copadoNotification;
    }

    public static Step__c createStep( // NOPMD : Supressing rule to avoid large refactor.
        String deploymentId,
        String name,
        String type,
        String status,
        Integer order,
        String commitName,
        String dataJson
    ) {
        Step__c step = new Step__c();
        step.Deployment__c = deploymentId;
        step.Name = name;
        step.Type__c = type;
        step.Status__c = status;
        step.Order__c = order;
        step.Commit_Name__c = commitName;
        step.dataJson__c = dataJson;

        return step;
    }

    public static Connection_Behavior__c createConnectionBehavior(
        String promotionBehavior,
        String backPromotionBehavior,
        String statusAfterDeployment
    ) {
        Connection_Behavior__c connectionBehavior = new Connection_Behavior__c();
        connectionBehavior.Name = 'Test Connection Behavior';
        connectionBehavior.Promotion_Behavior__c = promotionBehavior;
        connectionBehavior.Max_Scheduled_Promotion_Batch_Size__c = 1;
        connectionBehavior.Back_Promotion_Behavior__c = backPromotionBehavior;
        connectionBehavior.Max_Scheduled_Back_Promotion_Batch_Size__c = 1;
        connectionBehavior.Story_Status_After_Deployment__c = statusAfterDeployment;

        return connectionBehavior;
    }

    public static Quality_Gate__c createQualityGate( // NOPMD : Supressing rule to avoid large refactor.
        String complianceRuleGroupId,
        String metadataGroupId,
        String connectionBehaviorId,
        String seleniumTestGroupId,
        String staticCodeAnalysisSettingId,
        String type,
        String testLevel,
        Integer scoreThreshold
    ) {
        Quality_Gate__c qualityGate = new Quality_Gate__c();
        qualityGate.Name = 'Test Quality Gate';
        qualityGate.Compliance_Rule_Group__c = complianceRuleGroupId;
        qualityGate.Metadata_Group__c = metadataGroupId;
        qualityGate.Connection_Behavior__c = connectionBehaviorId;
        qualityGate.Selenium_Test_Group__c = seleniumTestGroupId;
        qualityGate.Static_Code_Analysis_Settings__c = staticCodeAnalysisSettingId;
        qualityGate.Type__c = type;
        qualityGate.Test_Level__c = testLevel;
        qualityGate.Score_Threshold__c = scoreThreshold;

        return qualityGate;
    }

    public static Deployment_Task__c createDeploymentTask(String name, Integer order, String type, String status, String userStoryId) {
        // NOPMD : Supressing rule to avoid large refactor.
        Deployment_Task__c deploymentTask = new Deployment_Task__c();
        deploymentTask.Name = name;
        deploymentTask.Order__c = order;
        deploymentTask.Type__c = type;
        deploymentTask.Status__c = status;
        deploymentTask.User_Story__c = userStoryId;

        return deploymentTask;
    }

    public static Deployment_Flow__c createDeploymentFlow(String name, Boolean isActive, String gitRepositoryId, Boolean enableDX) {
        // NOPMD : Supressing rule to avoid large refactor.
        Deployment_Flow__c deploymentFlow = new Deployment_Flow__c();
        deploymentFlow.Name = name;
        deploymentFlow.Active__c = isActive;
        deploymentFlow.Git_Repository__c = gitRepositoryId;
        deploymentFlow.Enable_Copado_DX__c = enableDX;

        return deploymentFlow;
    }

    public static Deployment_Flow_Step__c createDeploymentFlowStep( // NOPMD : Supressing rule to avoid large refactor.
        String sourceEnvironmentId,
        String destinationEnvironmentId,
        String deploymentFlowId,
        String scratchOrgDestination
    ) {
        Deployment_Flow_Step__c deploymentFlowStep = new Deployment_Flow_Step__c();
        deploymentFlowStep.Source_Environment__c = sourceEnvironmentId;
        deploymentFlowStep.Destination_Environment__c = destinationEnvironmentId;
        deploymentFlowStep.Deployment_Flow__c = deploymentFlowId;
        deploymentFlowStep.Enable_as_Scratch_Org_Destination__c = scratchOrgDestination;

        return deploymentFlowStep;
    }

    public static Project__c createProject(String name, String deploymentFlowId, Boolean indexMetadata) {
        Project__c project = new Project__c();
        project.Name = name;
        project.Deployment_Flow__c = deploymentFlowId;
        project.Index_Metadata__c = indexMetadata;

        return project;
    }

    public static Promotion__c createPromotion( // NOPMD : Supressing rule to avoid large refactor.
        String projectId,
        String sourceOrgId,
        String sourceEnvId,
        String destinationOrgId,
        String destinationEnvId,
        String status
    ) {
        Promotion__c promotion = new Promotion__c();
        promotion.Project__c = projectId;
        promotion.Source_Org_Credential__c = sourceOrgId;
        promotion.Source_Environment__c = sourceEnvId;
        promotion.Destination_Org_Credential__c = destinationOrgId;
        promotion.Destination_Environment__c = destinationEnvId;
        promotion.Status__c = status;

        return promotion;
    }
    public static Release__c createRelease(String name, String projectId) {
        Release__c release = new Release__c();
        release.Name = name;
        release.Project__c = projectId;

        return release;
    }

    public static User_Story__c createUserStory( // NOPMD : Supressing rule to avoid large refactor.
        String userStoryTitle,
        String status,
        String sprintId,
        String projectId,
        String environmentId,
        String orgId
    ) {
        User_Story__c userStory = new User_Story__c();
        userStory.User_Story_Title__c = userStoryTitle;
        userStory.Status__c = status;
        userStory.Sprint__c = sprintId;
        userStory.Project__c = projectId;
        userStory.Environment__c = environmentId;
        userStory.Org_Credential__c = orgId;

        return userStory;
    }

    public static Test_Script__c createTestScript(String testScriptName, String userStoryId) {
        Test_Script__c testScript = new Test_Script__c();
        testScript.Test_Title__c = testScriptName;
        testScript.User_Story__c = userStoryId;
        return testScript;
    }

    public static Test_Script_Step__c createTestScriptStep( // NOPMD : Supressing rule to avoid large refactor.
        Integer order,
        String stepTitle,
        String actionDescription,
        String expectedResult,
        String testScriptId
    ) {
        Test_Script_Step__c testScriptStep = new Test_Script_Step__c();
        testScriptStep.Step_Title__c = stepTitle;
        testScriptStep.Order__c = order;
        testScriptStep.Action_Description__c = actionDescription;
        testScriptStep.Expected_Result__c = expectedResult;
        testScriptStep.Test_Script__c = testScriptId;

        return testScriptStep;
    }

    public static Test_Run__c createTestRun(String testScriptId, String testerId, String environmentId) {
        Test_Run__c testRun = new Test_Run__c();
        testRun.Test_Script__c = testScriptId;
        testRun.Tester__c = testerId;
        testRun.Environment__c = environmentId;

        return testRun;
    }

    public static Continuous_Integration__c createContinuousIntegration(String name, Boolean isActive, String status) {
        Continuous_Integration__c continuousIntegration = new Continuous_Integration__c();
        continuousIntegration.Name = name;
        continuousIntegration.Active__c = isActive;
        continuousIntegration.Status__c = status;

        return continuousIntegration;
    }

    public static Build_Task__c createBuildTask(Continuous_Integration__c continuousIntegration, Integer duration, String status) {
        Build_Task__c buildTask = new Build_Task__c();
        buildTask.Continuous_Integration__c = continuousIntegration.Id;
        buildTask.Duration__c = duration;
        buildTask.Status__c = status;

        return buildTask;
    }

    public static Compliance_Rule__c createComplianceRule(String name) {
        return new Compliance_Rule__c(Name = name, Action__c = 'Document Only', Severity__c = 'Medium');
    }

    public static Compliance_Rule_Criteria__c newCriteria(String node, String field, String operator, String value, Decimal order) {
        // NOPMD : Supressing rule to avoid large refactor.
        return newCriteria(null, node, field, operator, value, order);
    }

    public static Compliance_Rule_Criteria__c newCriteria(Id ruleId, String node, String field, String operator, String value, Decimal order) {
        // NOPMD : Supressing rule to avoid large refactor.
        Compliance_Rule_Criteria__c result = new Compliance_Rule_Criteria__c();
        result.Compliance_Rule__c = ruleId;
        result.Node__c = node;
        result.Operator__c = operator;
        result.Field__c = field;
        result.Value__c = value;
        result.Order__c = order;
        return result;
    }

    public static SObject createSObject(SObject sObj, Map<Schema.SObjectField, Object> fieldDefaults) {
        addFieldDefaults(sObj, fieldDefaults);
        return sObj;
    }

    public static List<SObject> createSObjectList(SObject sObj, Integer numberOfObjects) {
        return createSObjectList(sObj, numberOfObjects, null, null);
    }

    public static List<SObject> createSObjectList( // NOPMD : Supressing rule to avoid large refactor.
        SObject sObj,
        Integer numberOfObjects,
        Map<Schema.SObjectField, Object> fieldDefaults,
        Map<Schema.SObjectType, Set<Schema.SObjectField>> incrementalFields
    ) {
        List<SObject> sObjs = new List<SObject>{};
        SObject newObj;
        newObj = createSObject(sObj, fieldDefaults);

        // Get the name field for the object
        String nameField = String.valueOf(nameFieldMap.get(sObj.getSObjectType()));
        if (nameField == null) {
            nameField = 'Name';
        }
        Boolean nameIsAutoNumber = sObj.getSObjectType().getDescribe().fields.getMap().get(nameField).getDescribe().isAutoNumber();

        // Clone the object the number of times requested. Increment the name field so each record is unique
        for (Integer i = 0; i < numberOfObjects; i++) {
            SObject clonedSObj = newObj.clone(false, true);
            if (!nameIsAutoNumber && nameField != 'Id') {
                clonedSObj.put(nameField, (String) clonedSObj.get(nameField) + ' ' + i);
            }
            if (incrementalFields.containsKey(sObj.getSObjectType())) {
                for (Schema.SObjectField field : incrementalFields.get(sObj.getSObjectType())) {
                    clonedSObj.put(field, (String) clonedSObj.get(field) + ' ' + i);
                }
            }
            sObjs.add(clonedSObj);
        }
        return sObjs;
    }

    private static String getOrgTimeZoneKey() {
        String result;

        List<Organization> organizations = [SELECT TimeZoneSidKey FROM Organization LIMIT 1];
        if (!organizations.isEmpty()) {
            result = organizations.get(0).TimeZoneSidKey;
        }

        return result;
    }

    private static void addFieldDefaults(SObject sObj, Map<Schema.SObjectField, Object> defaults) {
        // Loop through the map of fields and if they weren't specifically assigned, fill them.
        Map<String, Object> populatedFields = sObj.getPopulatedFieldsAsMap();
        for (Schema.SObjectField field : defaults.keySet()) {
            if (!populatedFields.containsKey(String.valueOf(field))) {
                sObj.put(field, defaults.get(field));
            }
        }
    }

    public class TestDataFactoryException extends Exception {
    }

    public static List<User_Story__c> createUserStories( // NOPMD : Supressing rule to avoid large refactor.
        Integer count,
        String title,
        String status,
        String sprintId,
        String projectId,
        String environmentId,
        String orgId,
        String recTypeDevName
    ) {
        List<User_Story__c> result = new List<User_Story__c>();
        for (Integer i = 0; i < count; i++) {
            User_Story__c userStory = new User_Story__c();
            userStory.User_Story_Title__c = title + i;
            userStory.Status__c = status;
            userStory.Sprint__c = sprintId;
            userStory.Project__c = projectId;
            userStory.Environment__c = environmentId;
            userStory.Org_Credential__c = orgId;
            userStory.RecordTypeId = Schema.SObjectType.User_Story__c.getRecordTypeInfosByDeveloperName().get(recTypeDevName).getRecordTypeId();
            result.add(userStory);
        }
        return result;
    }
    public static List<Artifact__c> createPackages(Integer count, String name, String recTypeDevName) {
        List<Artifact__c> result = new List<Artifact__c>();
        for (Integer i = 0; i < count; i++) {
            Artifact__c artifact = new Artifact__c(
                Name = name + i,
                RecordTypeId = Schema.SObjectType.Artifact__c.getRecordTypeInfosByDeveloperName().get(recTypeDevName).getRecordTypeId()
            );
            result.add(artifact);
        }
        return result;
    }
    public static List<Artifact_Version__c> createPackageVersions(Integer count, String name, String artifact) {
        List<Artifact_Version__c> result = new List<Artifact_Version__c>();
        for (Integer i = 0; i < count; i++) {
            Artifact_Version__c version = new Artifact_Version__c(Name = name + i, Artifact__c = artifact);
            result.add(version);
        }
        return result;
    }

    public static List<Bundled_Story__c> createBundledStories(Id pkgVersion, List<User_Story__c> stories) {
        List<Bundled_Story__c> result = new List<Bundled_Story__c>();
        for (User_Story__c story : stories) {
            Bundled_Story__c bundledStory = new Bundled_Story__c(User_Story__c = story.Id, Package_Version__c = pkgVersion);
            result.add(bundledStory);
        }
        return result;
    }

    public static JobTemplate__c createJobTemplate(String name, String apiName, Integer version, String volumeOptions) {
        // NOPMD : Supressing rule to avoid large refactor.
        JobTemplate__c template = new JobTemplate__c();
        template.Name = name;
        template.ApiName__c = apiName;
        template.Version__c = version;
        template.VolumeOptions__c = volumeOptions;
        return template;
    }

    public static JobStep__c createJobStep(String name, Id jobTemplateId, String type, Integer order, String configJson) {
        // NOPMD : Supressing rule to avoid large refactor.
        JobStep__c step = new JobStep__c();
        step.Name = name;
        step.Type__c = type;
        step.Order__c = order;
        step.ConfigJson__c = configJson;
        step.JobTemplate__c = jobTemplateId;
        return step;
    }

    public static JobExecution__c createJobExecution(Id jobTemplateId, String status) {
        JobExecution__c execution = new JobExecution__c(Template__c = jobTemplateId, Status__c = status);
        return execution;
    }

    public static Result__c createResult(Id jobStepId, String type, String status, Id functionId) {
        // NOPMD : Supressing rule to avoid large refactor.
        Result__c result = new Result__c(JobStep__c = jobStepId, Job_Type__c = type, Status__c = status, Function__c = functionId);
        return result;
    }
}