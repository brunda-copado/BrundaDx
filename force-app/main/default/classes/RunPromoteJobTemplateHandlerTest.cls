@IsTest
private class RunPromoteJobTemplateHandlerTest {
    @TestSetup
    private static void setupData() {
        TestUtilities.getAllMultilicense();
        User user = (User) new User_t()
            .assign(new PermissionSetAssignment_t().copadoUser())
            .assign(new PermissionSetAssignment_t().functions())
            .assign(new PermissionSetAssignment_t().jobEngine())
            .assign(new PermissionSetAssignment_t().qualityGatesReadOnly())
            .assign(new PermissionSetAssignment_t().executeAutomations())
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
            RunPromoteJobTemplateHandler.ValidationResponse validationResponse = RunPromoteJobTemplateHandler.validate(promotion.Id);
            Test.stopTest();

            // Verify
            System.assertEquals(false, validationResponse.promotedUserStoriesCreated, 'Promoted User Stories created');
            System.assertEquals(false, validationResponse.jobInProgress, 'Job should not be in progress');
            System.assertEquals(false, validationResponse.hasMetadata, 'User Story should not contain metadata');
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

            Test.startTest();
            RunPromoteJobTemplateHandler.ValidationResponse validationResponse = RunPromoteJobTemplateHandler.validate(promotion.Id);
            RunPromoteJobTemplateHandler.execute(promotion.Id, false);
            Test.getEventBus().deliver();
            Test.stopTest();

            System.assertEquals(true, validationResponse.promotedUserStoriesCreated, 'Promoted User Stories not created');
            System.assertEquals(false, validationResponse.jobInProgress, 'Job should not be in progress');
            System.assertEquals(true, validationResponse.hasMetadata, 'User Story should contain metadata');

            jobExecution = new JobExecutionsSelector().byPromotionId(promotion.Id);

            PromoteActionService.CreateExecutionRequestData contractValues = (PromoteActionService.CreateExecutionRequestData) JSON.deserialize(
                jobExecution.DataJson__c,
                PromoteActionService.CreateExecutionRequestData.class
            );

            Boolean isBackPromotion = false;
            Boolean executePromotion = true;
            Boolean executeDeployment = false;
            Boolean deploymentDryRun = false;

            // Assertions
            System.assertNotEquals(null, contractValues.userStoryIds, 'userStoryIds is null');
            System.assertNotEquals(null, contractValues.userStoryBranches, 'userStoryBranches is null');
            System.assertNotEquals(null, contractValues.promotionId, 'promotionId is null');
            System.assertNotEquals(null, contractValues.sourceCredentialId, 'sourceCredentialId is null');
            System.assertNotEquals(null, contractValues.destinationCredentialId, 'destinationCredentialId is null');
            System.assertNotEquals(null, contractValues.promotionBranchName, 'promotionBranchName is null');
            System.assertNotEquals(null, contractValues.destinationBranchName, 'destinationBranchName is null');
            System.assertEquals(isBackPromotion, contractValues.isBackPromotion, 'isBackPromotion true');
            System.assertEquals(executePromotion, contractValues.executePromotion, 'executePromotion false');
            System.assertEquals(executeDeployment, contractValues.executeDeployment, 'executeDeployment true');
            System.assertEquals(deploymentDryRun, contractValues.deploymentDryRun, 'deploymentDryRun true');
            System.assertNotEquals(null, contractValues.fileWithSelectedChanges, 'fileWithSelectedChanges is null');
        }
    }

    @IsTest
    static void conflict() {
        // Setup
        FunctionEngine.mockResponse = functionCompletionEvent(true, '', '');
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock('{}', null));

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

            Test.startTest();
            NotificationsSelector.mockNotifications = new List<MC_Notification__mdt>{
                new MC_Notification__mdt(
                    DeveloperName = 'Promotion_Conflict',
                    Active__c = true,
                    Subject__c = 'Promotion failed with conflicts - {PromotionName} - {SourceEnv} => {TargetEnv}',
                    Template__c = 'Hi {UserName},<br/><br/>The Promotion <b><a href="{PromotionLink}">{PromotionName}</a></b> from source environment {SourceEnv} to target environment {TargetEnv} finished with conflicts.'
                )
            };

            RunPromoteJobTemplateHandler.ValidationResponse validationResponse = RunPromoteJobTemplateHandler.validate(promotion.Id);
            RunPromoteJobTemplateHandler.execute(promotion.Id, false);
            Test.getEventBus().deliver();
            System.assertEquals(1, Limits.getEmailInvocations(), 'One email should be sent');
            Test.stopTest();

            System.assertEquals(true, validationResponse.promotedUserStoriesCreated, 'Promoted User Stories not created');
            System.assertEquals(false, validationResponse.jobInProgress, 'Job should not be in progress');
            System.assertEquals(true, validationResponse.hasMetadata, 'User Story should contain metadata');

            jobExecution = new JobExecutionsSelector().byPromotionId(promotion.Id);
            Result__c latestResult = new ResultsSelector().byJobExecutionId(jobExecution.Id);
            latestResult.Result_Data__c = '{"status": "conflicts"}';
            update latestResult;

            PromotionServiceImpl callback = new PromotionServiceImpl();
            callback.execute(jobExecution, 'Error');

            promotion = [SELECT Id, Status__c, Merge_Conflict__c FROM Promotion__c WHERE Id = :promotion.Id];

            System.assertEquals('Merge Conflict', promotion.Status__c, 'Promotion status is not Merge Conflict');
            System.assertEquals(true, promotion.Merge_Conflict__c, 'Promotion Merge_Conflict__c is not checked');
            System.assertEquals(1, Limits.getEmailInvocations(), 'One email should be sent');
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

    private static User getRunAsUser() {
        return [SELECT Id, Email FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1];
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
}