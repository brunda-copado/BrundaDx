@IsTest
private class RunPromoteAndDeployHandlerTest {
    @TestSetup
    private static void setupData() {
        TestUtilities.getAllMultilicense();
        User user = (User) new User_t()
            .assign(new PermissionSetAssignment_t().copadoUser())
            .assign(new PermissionSetAssignment_t().functions())
            .assign(new PermissionSetAssignment_t().jobEngine())
            .assign(new PermissionSetAssignment_t().qualityGatesReadOnly())
            .persist();
        System.runAs(user) {
            new CopadoLicense().user(user).enableAll().persist();
            data();
        }
    }

    @IsTest
    static void validateFail() {
        // Setup
        User user = getRunAsUser();

        System.runAs(user) {
            // Exercise
            List<Environment__c> environments = [SELECT Id, Name, Type__c, Platform__c FROM Environment__c];
            Project__c project = [SELECT Id FROM Project__c LIMIT 1];

            new Promotion().projectId(project.Id).sourceEnvId(environments[0].Id).status('Draft').persist();
            Promotion__c promotion = [
                SELECT Id, Source_Environment__c, Source_Org_Credential__c, Destination_Environment__c, Destination_Org_Credential__c
                FROM Promotion__c
                LIMIT 1
            ];
            System.assertNotEquals(null, promotion.Source_Org_Credential__c, 'Promotion Source Credential is null');
            System.assertNotEquals(null, promotion.Destination_Environment__c, 'Promotion Destination Environment is null');
            System.assertNotEquals(null, promotion.Destination_Org_Credential__c, 'Promotion Destination Credential is null');

            Test.startTest();
            RunPromoteAndDeployJobTemplateHandler.ValidationResponse data = RunPromoteAndDeployJobTemplateHandler.validate(promotion.Id);
            Test.stopTest();

            // Verify
            System.assertEquals(false, data.promotedUserStoriesCreated, 'Promoted User Stories created');
        }
    }

    @IsTest
    static void execute() {
        // Setup
        User user = getRunAsUser();

        System.runAs(user) {
            // Exercise
            List<Environment__c> environments = [SELECT Id, Name, Type__c, Platform__c FROM Environment__c];
            Project__c project = [SELECT Id FROM Project__c LIMIT 1];

            new Promotion().projectId(project.Id).sourceEnvId(environments[0].Id).status('Draft').persist();
            Promotion__c promotion = [
                SELECT Id, Source_Environment__c, Source_Org_Credential__c, Destination_Environment__c, Destination_Org_Credential__c
                FROM Promotion__c
                LIMIT 1
            ];
            JobExecution__c jobExecution = new JobExecutionsSelector().byPromotionId(promotion.Id);
            System.assertEquals(null, jobExecution, 'Job Execution is not created');
            System.assertNotEquals(null, promotion.Source_Org_Credential__c, 'Promotion Source Credential is null');
            System.assertNotEquals(null, promotion.Destination_Environment__c, 'Promotion Destination Environment is null');
            System.assertNotEquals(null, promotion.Destination_Org_Credential__c, 'Promotion Destination Credential is null');

            User_Story__c userStory = [SELECT Id FROM User_Story__c LIMIT 1];
            PromotedUserStoriesDatatableController.addSelectedUserStoriesToPromotion(promotion.Id, new List<Id>{ userStory.Id });

            RunPromoteAndDeployJobTemplateHandler.ValidationResponse data = RunPromoteAndDeployJobTemplateHandler.validate(promotion.Id);
            System.assertEquals(true, data.promotedUserStoriesCreated, 'Promoted User Stories not created');

            Test.startTest();
            RunPromoteAndDeployJobTemplateHandler.execute(promotion.Id, new List<Id>());
            Test.stopTest();

            jobExecution = new JobExecutionsSelector().byPromotionId(promotion.Id);
            System.assertNotEquals(null, jobExecution, 'Job Execution null');

            PromoteActionService.CreateExecutionRequestData contractValues = (PromoteActionService.CreateExecutionRequestData) JSON.deserialize(
                jobExecution.DataJson__c,
                PromoteActionService.CreateExecutionRequestData.class
            );

            Boolean deploymentDryRun = false;

            // Assertions
            System.assertNotEquals(null, contractValues.userStoryIds, 'userStoryIds is null');
            System.assertNotEquals(null, contractValues.userStoryBranches, 'userStoryBranches is null');
            System.assertNotEquals(null, contractValues.promotionId, 'promotionId is null');
            System.assertNotEquals(null, contractValues.promotionBranchName, 'promotionBranchName is null');
            System.assertNotEquals(null, contractValues.destinationBranchName, 'destinationBranchName is null');
            System.assertEquals(deploymentDryRun, contractValues.deploymentDryRun, 'deploymentDryRun true');
            System.assertNotEquals(null, contractValues.fileWithSelectedChanges, 'fileWithSelectedChanges is null');
        }
    }

    private static void data() {
        Personal_Settings__c ps = Personal_Settings__c.getInstance();
        if (String.isBlank(ps.API_Key__c)) {
            ps.API_Key__c = DeployAPI.encryptAPIKey('99999999999999999999');
            upsert ps;
        }

        //Environment creation
        for (Integer i = 0; i < 3; i++) {
            new Environment().name('Environment ' + i).type('Production/Developer').platform('Other');
        }
        new Environment().name('Test Environment 3').type('Production/Developer').platform('Other').persist();
        List<Environment__c> environments = [SELECT Id, Name, Type__c, Platform__c FROM Environment__c ORDER BY CreatedDate];

        // Org Credential validation
        List<Org__c> credentials = [
            SELECT Id, Name, Environment__c, Platform__c, Oauth_Signature__c, Validated_Date__c, Disable_Validation__c, SFDC_Org_ID__c
            FROM Org__c
            WHERE Platform__c = 'Other'
        ];
        for (Org__c org : credentials) {
            org.Username__c = UserInfo.getUserName();
            org.SFDC_Org_ID__c = UserInfo.getOrganizationId() + '_' + UserInfo.getUserId();
            org.Oauth_Signature__c = org.Name;
            org.Validated_Date__c = System.now();
            org.Disable_Validation__c = true;
            break;
        }
        update credentials;

        // Function creation
        String namespace = namespacePrefix();
        new Function()
            .name('mulePromotion')
            .apiName('mulePromotion')
            .script('echo hello world $par1')
            .type('Custom')
            .paramaters(
                '[{"name": "SourceDBName", "defaultValue": "{!$Source.Property.DBName}", "required": true},' +
                    '{"name": "DestinationDBProvider", "defaultValue": "{!$Destination.Property.DB-Provider}", "required": true},' +
                    '{"name": "PipelineUsername", "defaultValue": "{!$Pipeline.Property.Username}", "required": true},' +
                    '{"name": "UserEmail", "defaultValue": "{!$User.Property.Email}", "required": true},' +
                    '{"name": "LogLevel", "defaultValue": "ERROR", "required": false}]'
            )
            .options(
                '[{"name": "gitUrl", "value": "xxxxxx", "sensitive": true},' +
                    '{"name": "gitUsername", "value": "", "sensitive": true},' +
                    '{"name": "gitPassword", "value": "", "sensitive": true},' +
                    '{"name": "branchName", "value": "", "sensitive": false}]'
            )
            .callbackType('ApexClass')
            .apexClass(namespace + 'FunctionStepExecutionCallback');

        new Function()
            .name('muleDeployment')
            .apiName('muleDeployment')
            .script('echo hello world $par1')
            .type('Custom')
            .paramaters(
                '[{"name": "SourceDBName", "defaultValue": "{!$Source.Property.DBName}", "required": true},' +
                    '{"name": "DestinationDBProvider", "defaultValue": "{!$Destination.Property.DB-Provider}", "required": true},' +
                    '{"name": "PipelineUsername", "defaultValue": "{!$Pipeline.Property.Username}", "required": true},' +
                    '{"name": "UserEmail", "defaultValue": "{!$User.Property.Email}", "required": true},' +
                    '{"name": "LogLevel", "defaultValue": "ERROR", "required": false}]'
            )
            .options(
                '[{"name": "gitUrl", "value": "xxxxxx", "sensitive": true},' +
                    '{"name": "gitUsername", "value": "", "sensitive": true},' +
                    '{"name": "gitPassword", "value": "", "sensitive": true},' +
                    '{"name": "branchName", "value": "", "sensitive": false}]'
            )
            .callbackType('ApexClass')
            .apexClass(namespace + 'FunctionStepExecutionCallback')
            .persist();

        new JobTemplate()
            .name('JOB_TEMPLATE_PROMOTION')
            .mockAutomation('Promotion')
            .volumeOptions('[{ "name": "volumeEnabled", "value": "false" }]')
            .add(new JobStep().order(1).type('Function').configJson('{"functionName":"mulePromotion","parameters":[]}'));
        new JobTemplate()
            .name('JOB_TEMPLATE_DEPLOYMENT')
            .mockAutomation('PromotionDeployment')
            .volumeOptions('[{ "name": "volumeEnabled", "value": "false" }]')
            .add(new JobStep().order(1).type('Function').configJson('{"functionName":"mulePromotion","parameters":[]}'))
            .persist();

        // Deployment flow creation
        new Pipeline()
            .active(true)
            .mainBranch('master')
            .setPlatform('Other')
            .add(new Connection().sourceId(environments[0].Id).destinationId(environments[2].Id).branch('dev1'))
            .add(new Connection().sourceId(environments[1].Id).destinationId(environments[2].Id).branch('dev2'))
            .add(
                new Project()
                    .add(
                        new UserStory()
                            .status('Approved')
                            .credentialId(credentials[0].Id)
                            .add(new UserStoryMetadata().name('TestClass').type('ApexClass'))
                    )
            )
            .persist();
    }

    private static String namespacePrefix() {
        return Settings.ns.replace('__', '.');
    }

    private static MC_Result__e functionCompletionEvent(Boolean isSuccess, String errorMessage, String data) {
        MC_Result__e result = new MC_Result__e();
        result.IsFinished__c = true;
        result.Result_Data__c = data;
        result.IsSuccess__c = isSuccess;
        result.Error_Message__c = errorMessage;

        return result;
    }

    private static Event__e flowCompletionEvent(Boolean isSuccess, String errorMessage, String data) {
        Event__e result = new Event__e();
        result.Topic_Uri__c = OnJobStepComplete.STEP_ENDPOINT;
        result.Payload__c = Json.serialize(new OnJobStepComplete.EventPayload(isSuccess, errorMessage, data));
        return result;
    }

    private static User getRunAsUser() {
        return [SELECT Id, Email FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1];
    }
}