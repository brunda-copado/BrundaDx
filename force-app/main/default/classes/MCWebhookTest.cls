@IsTest
private class MCWebhookTest {

    @TestSetup
    private static void makeData() {
        TestUtilities.getAllMultilicense();

        User u = (User) new User_t()
            .assign(new PermissionSetAssignment_t().copadoUser())
            .assign(new PermissionSetAssignment_t().functions())
            .assign(new PermissionSetAssignment_t().jobEngine())
            .assign(new PermissionSetAssignment_t().qualityGatesAdmin())
            .assign(new PermissionSetAssignment_t().executeAutomations())
            .assign(new PermissionSetAssignment_t().configureSnapshots())
            .persist();

        System.runAs(u) {
            new CopadoLicense().user(u).enableAll().persist();
            createData();
        }
    }

    @IsTest
    private static void keyNotCreated() {
        System.runAs( standardUser() ) {

            // Setup

            Exception expectedEx;
            RestContext.request = createRequest( requestBody('SomeAction', 'InvalidKey', '{}') );

            // Exercise

            try {
                MCWebhook.runAction();
            } catch (Exception ex) {
                expectedEx = ex;
            }

            // Verify

            System.assertNotEquals(null, expectedEx, 'Exception should be thrown.');
            System.assertEquals(Label.Invalid_Action_Key, expectedEx.getMessage(), 'Incorrect exception.');
        }
    }


    @IsTest
    private static void incorrectKey() {
        System.runAs( standardUser() ) {

            // Setup

            Exception expectedEx;
            Webhook_Settings__c s = (Webhook_Settings__c) new WebhookSetting().persist();
            RestContext.request = createRequest( requestBody(s.Action__c, 'Key1', '{}') );

            // Exercise

            try {
                MCWebhook.runAction();
            } catch (Exception ex) {
                expectedEx = ex;
            }

            // Verify

            System.assertNotEquals(null, expectedEx, 'Exception should be thrown.');
            System.assertEquals(Label.Invalid_Action_Key, expectedEx.getMessage(), 'Incorrect exception.');
        }
    }

    @IsTest
    private static void expiredKey() {
        System.runAs( standardUser() ) {

            // Setup

            Exception expectedEx;
            Webhook_Settings__c s = (Webhook_Settings__c) new WebhookSetting()
                                                                .startDate( Datetime.now().addDays(-10) )
                                                                .endDate( Datetime.now().addDays(-5) )
                                                                .persist();
            RestContext.request = createRequest( requestBody(s.Action__c, s.Key__c, '{}') );

            // Exercise

            try {
                MCWebhook.runAction();
            } catch (Exception ex) {
                expectedEx = ex;
            }

            // Verify

            System.assertNotEquals(null, expectedEx, 'Exception should be thrown.');
            System.assertEquals(Label.Invalid_Date_Range_Key, expectedEx.getMessage(), 'Incorrect exception.');
        }
    }


    @IsTest
    private static void futureKey() {
        System.runAs( standardUser() ) {

            // Setup

            Exception expectedEx;
            Webhook_Settings__c s = (Webhook_Settings__c) new WebhookSetting()
                                                                .startDate( Datetime.now().addDays(10) )
                                                                .endDate( Datetime.now().addDays(15) )
                                                                .persist();
            RestContext.request = createRequest( requestBody(s.Action__c, s.Key__c, '{}') );

            // Exercise

            try {
                MCWebhook.runAction();
            } catch (Exception ex) {
                expectedEx = ex;
            }

            // Verify

            System.assertNotEquals(null, expectedEx, 'Exception should be thrown.');
            System.assertEquals(Label.Invalid_Date_Range_Key, expectedEx.getMessage(), 'Incorrect exception.');
        }
    }


    @IsTest
    private static void invalidUser() {
        Id webhookUsr = UserInfo.getUserId();

        System.runAs( standardUser() ) {

            // Setup

            Exception expectedEx;
            Webhook_Settings__c s = (Webhook_Settings__c) new WebhookSetting()
                                                                .user(webhookUsr)
                                                                .startDate( Datetime.now().addDays(10) )
                                                                .endDate( Datetime.now().addDays(15) )
                                                                .persist();
            RestContext.request = createRequest( requestBody(s.Action__c, s.Key__c, '{}') );

            // Exercise

            try {
                MCWebhook.runAction();
            } catch (Exception ex) {
                expectedEx = ex;
            }

            // Verify

            System.assertNotEquals(null, expectedEx, 'Exception should be thrown.');
            System.assertEquals(Label.Invalid_Action_Key, expectedEx.getMessage(), 'Incorrect exception.');
        }
    }


    @IsTest
    private static void invalidAction() {
        System.runAs( standardUser() ) {

            // Setup

            Exception expectedEx;
            Webhook_Settings__c s = (Webhook_Settings__c) new WebhookSetting().action('InvalidAction').persist();
            RestContext.request = createRequest( requestBody('InvalidAction', s.Key__c, '{}') );

            // Exercise

            try {
                MCWebhook.runAction();
            } catch (Exception ex) {
                expectedEx = ex;
            }

            // Verify

            System.assertNotEquals(null, expectedEx, 'Exception should be thrown.');
            System.assertEquals(Label.Action_Not_Supported, expectedEx.getMessage(), 'Incorrect exception.');
        }
    }


    @IsTest
    private static void emptyPayload() {
        System.runAs( standardUser() ) {

            // Setup

            Exception expectedEx;
            Webhook_Settings__c s = (Webhook_Settings__c) new WebhookSetting().persist();
            RestContext.request = createRequest( requestBody(s.Action__c, s.Key__c, null) );

            // Exercise

            try {
                MCWebhook.runAction();
            } catch (Exception ex) {
                expectedEx = ex;
            }

            // Verify

            System.assertNotEquals(null, expectedEx, 'Exception should be thrown.');
            String errorMsg = String.format(Label.Invalid_Json_Payload_For_Action, new List<String>{ s.Action__c });
            System.assertEquals(errorMsg, expectedEx.getMessage(), 'Incorrect exception.');
        }
    }


    @IsTest
    private static void invalidPayload() {
        System.runAs( standardUser() ) {

            // Setup

            Exception expectedEx;
            Webhook_Settings__c s = (Webhook_Settings__c) new WebhookSetting().persist();
            RestContext.request = createRequest( requestBody(s.Action__c, s.Key__c, '<abc>') );

            // Exercise

            try {
                MCWebhook.runAction();
            } catch (Exception ex) {
                expectedEx = ex;
            }

            // Verify

            System.assertNotEquals(null, expectedEx, 'Exception should be thrown.');
            String errorMsg = String.format(Label.Invalid_Json_Payload_For_Action, new List<String>{ s.Action__c });
            System.assertEquals(errorMsg, expectedEx.getMessage(), 'Incorrect exception.');
        }
    }


    @IsTest
    private static void validAction() {
        System.runAs( standardUser() ) {

            // Setup

            JobExecution__c job = (JobExecution__c) new JobExecution().persist();
            Webhook_Settings__c s = (Webhook_Settings__c) new WebhookSetting().persist();
            RestContext.request = createRequest( requestBody(s.Action__c, s.Key__c, job) );
            RestContext.response = new RestResponse();

            // Exercise

            String response = MCWebhook.runAction();

            // Verify

            JobExecution__c result = (JobExecution__c) JSON.deserialize(response, JobExecution__c.class);
            System.assertEquals(job.Id, result.Id, 'Incorrect Response.');
        }
    }

    @IsTest
    private static void invalidActionOrKey() {
        System.runAs( standardUser() ) {

            // Setup
            Exception expectedEx;
            JobExecution__c job = (JobExecution__c) new JobExecution().persist();
            Webhook_Settings__c s = (Webhook_Settings__c) new WebhookSetting().persist();
            RestContext.request = createRequest( requestBody('Test ACtion', s.Key__c, job) );
            RestContext.response = new RestResponse();

            // Exercise
            try {
                MCWebhook.runAction();
            } catch (Exception ex) {
                expectedEx = ex;
            }

            // Verify

            System.assertNotEquals(null, expectedEx, 'Exception should be thrown.');
            System.assertEquals(Label.Invalid_Action_Key, expectedEx.getMessage(), 'Incorrect exception.');
        }
    }
    
    @IsTest
    private static void validCommitAction() {
        System.runAs( standardUser() ) {

            // Setup
            Id userStoryId = [SELECT Id FROM User_Story__c LIMIT 1].Id;
            CommitAction.Request request = new CommitAction.Request();
            request.userStoryId = userStoryId;
            request.changes = changes(10);
            request.recreateFeatureBranch = true;
            request.jsonInformation = '{"key":"value"}';
             
            Webhook_Settings__c s = (Webhook_Settings__c) new WebhookSetting().action('Commit').persist();
            RestContext.request = createRequest( requestBody(s.Action__c, s.Key__c, request) );
            RestContext.response = new RestResponse();

            Flow.mockResponse = flowCompletionEvent(true, '', '{"commitId": "test_commit_id"}');
            
            // Exercise
            Test.startTest();
            String response = MCWebhook.runAction();
            Test.stopTest();
            
            // Verify

            JobExecution__c jobExecution = [SELECT Status__c, ErrorMessage__c, DataJson__c FROM JobExecution__c LIMIT 1];
            System.assertEquals('Successful', jobExecution.Status__c, 'Job execution status after stop test should be Successful');
            Map<String, Object> dataJson = (Map<String, Object>) JSON.deserializeUntyped(jobExecution.DataJson__c);
            System.assertEquals('{"key":"value"}', dataJson.get('jsonInformation'), 'Job execution Data Json field should be updated');
            List<User_Story_Metadata__c> metadata = [SELECT Id FROM User_Story_Metadata__c];
            System.assertEquals(10, metadata.size(), 'Changes should have been created as User_Story_Metadata__c records');
            List<User_Story_Commit__c> userStoryCommits = [SELECT Id, LastJobExecutionId__c, External_Id__c FROM User_Story_Commit__c];
            System.assertEquals(1, userStoryCommits.size(), 'One User Story Commit record should have been created');
        }
    }

    @IsTest
    private static void validPromoteAction() {
        System.runAs( standardUser() ) {

            // Setup
            User_Story__c record = [SELECT Id, Environment__c, Project__c FROM User_Story__c LIMIT 1];
            PromoteAction.Request request = new PromoteAction.Request();
            request.userStoryIds = new List<Id>{ record.Id };
            request.sourceEnvironmentId = record.Environment__c;
            request.projectId = record.Project__c;
            request.executePromotion = true;
            request.isBackPromotion = false;
             
            Webhook_Settings__c s = (Webhook_Settings__c) new WebhookSetting().action('Promotion').persist();
            RestContext.request = createRequest( requestBody(s.Action__c, s.Key__c, request) );
            RestContext.response = new RestResponse();

            Flow.mockResponse = flowCompletionEvent(true, '', '{}');
            
            // Exercise
            Test.startTest();
            String response = MCWebhook.runAction();
            Test.stopTest();
            
            // Verify
            PromoteAction.Response result = (PromoteAction.Response) JSON.deserialize(response, PromoteAction.Response.class);
            List<JobExecution__c> jobExecutionResult = [SELECT Id, Promotion__c FROM JobExecution__c WHERE Id = :result.jobExecution.Id];
            System.assertEquals(1, jobExecutionResult.size(), 'There should be a Job Execution created');
            System.assertNotEquals(null, result, 'Result is not null');
            System.assertNotEquals(null, jobExecutionResult[0].Promotion__c, 'There should be a Promotion created');
        }
    }

    @IsTest
    private static void validPromoteDeploymentAction() {
        System.runAs( standardUser() ) {

            // Setup
            Promotion__c promotion = (Promotion__c) new Promotion()
                .projectId([SELECT Id FROM Project__c LIMIT 1].Id)
                .sourceEnvId([SELECT Id FROM Environment__c WHERE Name = 'dev1' LIMIT 1].Id)
                .persist();

            Promoted_User_Story__c promotedUserStory = new Promoted_User_Story__c(
                User_Story__c = [SELECT Id FROM User_Story__c LIMIT 1].Id,
                Promotion__c = promotion.Id
            );
            insert promotedUserStory;

            PromotionDeployAction.Request request = new PromotionDeployAction.Request();
            request.promotionId = promotion.Id;
            request.deploymentDryRun = false;
             
            Webhook_Settings__c s = (Webhook_Settings__c) new WebhookSetting().action('PromotionDeployment').persist();
            RestContext.request = createRequest( requestBody(s.Action__c, s.Key__c, request) );
            RestContext.response = new RestResponse();

            Flow.mockResponse = flowCompletionEvent(true, '', '');
            
            // Exercise
            Test.startTest();
            String response = MCWebhook.runAction();
            Test.stopTest();
            
            // Verify
            PromotionDeployAction.Response result = (PromotionDeployAction.Response) JSON.deserialize(response, PromotionDeployAction.Response.class);
            JobExecution__c jobExecution = [SELECT Status__c FROM JobExecution__c WHERE Id = :result.jobExecution.Id LIMIT 1];
            System.assertEquals('Successful', jobExecution.Status__c, 'Job execution status should be Successful');
            Deployment__c deployment = [SELECT Status__c FROM Deployment__c WHERE Promotion__c = :promotion.Id LIMIT 1];
            System.assertEquals('Completed Successfully', deployment.Status__c, 'Deployment status should be Successful');
        }
    }

    @IsTest
    private static void validCreatePackageAction() {
        System.runAs( standardUser() ) {

            // Setup
            Artifact__c packageRecord = (Artifact__c) new Package_t()
                .pipelineId([SELECT Id FROM Deployment_Flow__c LIMIT 1].Id)
                .packageType('First-Generation Package')
                .persist();
            
            PackageCreateAction.Request request = new PackageCreateAction.Request(packageRecord.Id, '{"key": "value"}');
            
            Webhook_Settings__c s = (Webhook_Settings__c) new WebhookSetting().action('CreatePackage').persist();
            RestContext.request = createRequest( requestBody(s.Action__c, s.Key__c, request) );
            RestContext.response = new RestResponse();

            Flow.mockResponse = flowCompletionEvent(true, '', '{}');
            
            // Exercise
            Test.startTest();
            String response = MCWebhook.runAction();
            Test.stopTest();
            
            // Verify
            PackageCreateAction.Response result = (PackageCreateAction.Response) JSON.deserialize(response, PackageCreateAction.Response.class);
            
            System.assertNotEquals(null, result, 'Result is not null');
            System.assertEquals('Successful', result.job.Status__c, 'Job execution should be started.');
            List<JobExecution__c> jobs = [SELECT Status__c, DataJson__c FROM JobExecution__c];
            System.assertEquals(1, jobs.size(), 'Job execution should be started.');
            List<Automation_Event__c> events = [SELECT Id, Action_Name__c FROM Automation_Event__c];
            System.assertEquals(1, events.size(), 'An Automation Event should be created');
            System.assertEquals(ActionConstants.CREATE_PACKAGE, events[0].Action_Name__c, 'Action Name should match');
        }
    }

    @SuppressWarnings('PMD.AvoidHardcodingId')
    @IsTest
    private static void validCreatePackageVersionAction() {
        System.runAs(standardUser()) {

            // Setup
            Artifact__c packageRecord = (Artifact__c) new Package_t()
                .pipelineId([SELECT Id FROM Deployment_Flow__c LIMIT 1].Id)
                .packageType('First-Generation Package')
                .persist();

            Artifact_Version__c mockResultRecord = new Artifact_Version__c();
            mockResultRecord.Artifact__c = packageRecord.Id;
            mockResultRecord.Package_Version_Id__c = '05i7Q000000blPMQAY';
            mockResultRecord.Subscriber_Version_Id__c = '04t7Q00000090xtQAA';
            mockResultRecord.Is_released__c = false;
            mockResultRecord.Branch__c = 'main';
            mockResultRecord.Version_Name__c = 'My Version';
            mockResultRecord.Tag__c = null;
            mockResultRecord.Version_Description__c = null;
            mockResultRecord.Version_number__c = '1.0.0.0';
            mockResultRecord.Data_JSON__c = '{\"uninstallscript\":\"\",\"postinstallscript\":\"\",\"postinstallurl\":\"\",\"releasenotesurl\":\"\",\"skipvalidation\":true,\"codecoverage\":false,\"installationkeybypass\":true,\"tag\":\"\",\"overrideProjectJsonPath\":null,\"overridePath\":null,\"apiversion\":\"45.0\"}';
            mockResultRecord.Name = packageRecord.Name + ' - 1.0.0.0';
            
            PackageVersionCreateAction.Request request = new PackageVersionCreateAction.Request(packageRecord.Id, '{"key": "value"}');
            
            Webhook_Settings__c s = (Webhook_Settings__c) new WebhookSetting().action('CreatePackageVersion').persist();
            RestContext.request = createRequest(requestBody(s.Action__c, s.Key__c, request));
            RestContext.response = new RestResponse();

            Flow.mockResponse = flowCompletionEvent(true, '', JSON.serialize(mockResultRecord));
            
            // Exercise
            Test.startTest();
            String response = MCWebhook.runAction();
            Test.stopTest();
            
            // Verify
            PackageVersionCreateAction.Response result = (PackageVersionCreateAction.Response) JSON.deserialize(response, PackageVersionCreateAction.Response.class);
            System.assertNotEquals(null, result, 'Result is not null');
            System.assertEquals('Successful', result.job.Status__c, 'Job execution status should be Successful');
            List<JobExecution__c> jobExecutionResult = [SELECT Id, Status__c FROM JobExecution__c WHERE Id = :result.job.Id];
            System.assertEquals(1, jobExecutionResult.size(), 'There should be a Job Execution created');
            List<Automation_Event__c> events = [SELECT Id, Action_Name__c FROM Automation_Event__c];
            System.assertEquals(1, events.size(), 'An Automation Event should be created');
            System.assertEquals(ActionConstants.CREATE_PACKAGE_VERSION, events[0].Action_Name__c, 'Action Name should match');
            Artifact_Version__c version = [SELECT Package_Version_Id__c, Is_released__c, Version_Name__c, Version_number__c, Name, Artifact__r.Artifact_Version__c FROM Artifact_Version__c LIMIT 1];
            System.assertEquals(mockResultRecord.Package_Version_Id__c, version.Package_Version_Id__c, 'Package_Version_Id__c are not the same');
            System.assertEquals(mockResultRecord.Is_released__c, version.Is_released__c, 'Is_released__c are not the same');
            System.assertEquals(mockResultRecord.Version_Name__c, version.Version_Name__c, 'Version_Name__c are not the same');
            System.assertEquals(mockResultRecord.Version_number__c, version.Version_number__c, 'Version_number__c are not the same');
            System.assertEquals(mockResultRecord.Name, version.Name, 'Name are not the same');
            System.assertEquals(version.Id, version.Artifact__r.Artifact_Version__c, 'Latest package version is not updated');
        }
    }

    @IsTest
    private static void validPublishPackageVersionAction() {
        System.runAs(standardUser()) {

            // Setup
            Git_Repository__c repository = new Git_Repository__c(Name='Test Repo');
            insert repository;
            
            new Package_t()
                .packageArtifactRecordType()
                .name('Test package')
                .pipelineId([SELECT Id FROM Deployment_Flow__c LIMIT 1].Id)
                .repositoryId(repository.Id)
                .add(new PackageVersion().versionName('v0.1.0').versionNumber('0.1.0.1'))
                .persist();
            
            PackageVersionPublishAction.Request request = new PackageVersionPublishAction.Request([SELECT Id FROM Artifact_Version__c LIMIT 1].Id);
            
            Webhook_Settings__c s = (Webhook_Settings__c) new WebhookSetting().action('PublishPackageVersion').persist();
            RestContext.request = createRequest(requestBody(s.Action__c, s.Key__c, request));
            RestContext.response = new RestResponse();

            Flow.mockResponse = flowCompletionEvent(true, '', '');
            
            // Exercise
            Test.startTest();
            String response = MCWebhook.runAction();
            Test.stopTest();
            
            // Verify
            PackageVersionPublishAction.Response result = (PackageVersionPublishAction.Response) JSON.deserialize(response, PackageVersionPublishAction.Response.class);
            JobExecution__c jobExecution = [SELECT Status__c FROM JobExecution__c WHERE Id = :result.job.Id LIMIT 1];
            System.assertEquals('Successful', jobExecution.Status__c, 'Job execution status should be Successful');
            Artifact_Version__c packageVersion = [SELECT Is_released__c FROM Artifact_Version__c WHERE Id = :request.packageVersionId LIMIT 1];
            System.assertEquals(true, packageVersion.Is_released__c, 'Package version should be released');
        }
    }

    @isTest
    private static void validImportPackageAction() {
        System.runAs(standardUser()) {

            // Setup
            Git_Repository__c repository = new Git_Repository__c(Name='Test Repo');
            insert repository;
            
            PackageImportAction.Request request = new PackageImportAction.Request(null, [SELECT Id FROM Deployment_Flow__c LIMIT 1].Id, null);

            Artifact__c packageRecord = new Artifact__c(
                Name = 'Test',
                RecordTypeId = Schema.SObjectType.Artifact__c.getRecordTypeInfosByDeveloperName().get('Package_Artifact').getRecordTypeId(),
                Package_Type__c = 'Unlocked',
                Artifact_Repository__c = repository.Id
            );

            PackageImportAction.ResultPayload payload = new PackageImportAction.ResultPayload();
            payload.packageRecord = packageRecord;
            payload.packageVersions = new List<Artifact_Version__c>{ new Artifact_Version__c(Name = 'version1') };
            
            Webhook_Settings__c s = (Webhook_Settings__c) new WebhookSetting().action('ImportPackage').persist();
            RestContext.request = createRequest(requestBody(s.Action__c, s.Key__c, request));
            RestContext.response = new RestResponse();
            
            Flow.mockResponse = flowCompletionEvent(true, '', JSON.serialize(payload));
            
            // Exercise
            Test.startTest();
            String response = MCWebhook.runAction();
            Test.stopTest();
            
            // Verify
            PackageImportAction.Response result = (PackageImportAction.Response) JSON.deserialize(response, PackageImportAction.Response.class);
            System.assertNotEquals(null, result, 'Result is not null');
            System.assertEquals('Successful', result.job.Status__c, 'Job execution status should be Successful');

            System.assertEquals(1, [SELECT COUNT() FROM Artifact__c], 'One Artifact__c record should have been created');
            System.assertEquals(1, [SELECT COUNT() FROM Artifact_Version__c], 'One Artifact_Version__c record should have been created');

            List<Automation_Event__c> events = [SELECT Id, Action_Name__c FROM Automation_Event__c];
            System.assertEquals(1, events.size(), 'An Automation Event should be created');
            System.assertEquals(ActionConstants.IMPORT_PACKAGE, events[0].Action_Name__c, 'Action Name should match');
        }
    }

    @isTest
    private static void validRunTestsAction() {
        System.runAs(standardUser()) {

            // Setup
            ExtensionConfiguration__c extensionConfiguration = new ExtensionConfiguration__c(
                Name = 'Extension Configuration 1',
                ExtensionApplication__c = 'Test',
                ExtensionTool__c = 'Manual Tests',
                Active__c = true
            );
            insert extensionConfiguration;
            
            new JobTemplate().name('RunTest_Template').add(new JobStep()).persist();
            TestToolsSelector.mock(
                new List<TestTool__mdt>{
                    new TestTool__mdt(MasterLabel = 'Manual Tests', JobTemplate__c = 'RunTest_Template_1', TestType__c = 'Mock Type')
                }
            );
            
            Test__c testRecord = new Test__c(Configuration__c = 'test1',
            ExtensionConfiguration__c = extensionConfiguration.Id,
            User_Story__c = [SELECT Id, Environment__c, Project__c FROM User_Story__c LIMIT 1].Id,
            ReadyToRun__c = true);
            insert testRecord;

            RunTestsAction.Request request = new RunTestsAction.Request();
            request.tool = 'Manual Tests';
            request.contextIds = new List<Id>{ testRecord.Id };
            request.extensionConfigurationId = extensionConfiguration.Id;
            
            
            Webhook_Settings__c s = (Webhook_Settings__c) new WebhookSetting().action('RunTests').persist();
            RestContext.request = createRequest(requestBody(s.Action__c, s.Key__c, request));
            RestContext.response = new RestResponse();
            
            Flow.mockResponse = flowCompletionEvent(true, '', '{}');
            
            // Exercise
            Test.startTest();
            String response = MCWebhook.runAction();
            Test.stopTest();
            
            // Verify
            RunTestsAction.Response result = (RunTestsAction.Response) JSON.deserialize(response, RunTestsAction.Response.class);
            JobExecution__c jobExecution = [SELECT Status__c FROM JobExecution__c WHERE Id = :result.jobExecution.Id LIMIT 1];
            System.assertEquals('Successful', jobExecution.Status__c, 'Job execution status should be Successful');
            for (Test__c test : [SELECT Id, LatestJobExecution__c FROM Test__c]) {
                System.assertEquals(jobExecution.Id, test.LatestJobExecution__c, 'Test should populate with latest execution Id');
            }
        }
    }

    @isTest
    private static void validCheckStatusActionWithResult() {
        System.runAs(standardUser()) {

            // Setup
            Result__c r = (Result__c) new Result()
                .jobType('Test')
                .status('Error')
                .errMsg('Failed')
                .progress('None')
                .persist();

            CheckStatusAction.Request request = new CheckStatusAction.Request(null, r.Id);         
            
            Webhook_Settings__c s = (Webhook_Settings__c) new WebhookSetting().action('CheckStatusAction').persist();
            RestContext.request = createRequest(requestBody(s.Action__c, s.Key__c, request));
            RestContext.response = new RestResponse();
            
            // Exercise
            Test.startTest();
            String response = MCWebhook.runAction();
            Test.stopTest();
            
            // Verify
            CheckStatusAction.Response result = (CheckStatusAction.Response) JSON.deserialize(response, CheckStatusAction.Response.class);
            System.assertEquals(r.Status__c, result.status, 'Incorrect Status');
            System.assertEquals(r.Error_Message__c, result.errorMessage, 'Incorrect Message.');
            System.assertEquals(r.Progress_Status__c, result.progressStatus, 'Incorrect Message.');
            System.assertEquals(r.Id, result.resultId, 'Incorrect Message.');
        }
    }

    @isTest
    private static void validCheckStatusActionWithJobExecution() {
        System.runAs(standardUser()) {

            // Setup
            JobExecution__c je = (JobExecution__c) new JobExecution()
                .status('Starting')
                .errorMsg('No errors yet')
                .persist();

            CheckStatusAction.Request request = new CheckStatusAction.Request(je.Id, null);         
            
            Webhook_Settings__c s = (Webhook_Settings__c) new WebhookSetting().action('CheckStatusAction').persist();
            RestContext.request = createRequest(requestBody(s.Action__c, s.Key__c, request));
            RestContext.response = new RestResponse();
            
            // Exercise
            Test.startTest();
            String response = MCWebhook.runAction();
            Test.stopTest();
            
            // Verify
            CheckStatusAction.Response result = (CheckStatusAction.Response) JSON.deserialize(response, CheckStatusAction.Response.class);
            System.assertEquals(je.Status__c, result.status, 'Incorrect Status');
            System.assertEquals(je.ErrorMessage__c, result.errorMessage, 'Incorrect Message.');
            System.assertEquals(null, result.progressStatus, 'Incorrect Message.');
            System.assertEquals(null, result.resultId, 'Incorrect Result Id.');
        }
    }

    @isTest
    private static void validRunJobTemplateAction() {

        //Setup
        System.runAs(standardUser()) {
            String firstNamePattern = UserInfo.getFirstName() + '*';

            new JobTemplate()
                .name('Sample')
                .version(1)
                .volumeOptions('[{}]')
                .add(new JobStep().order(1).name('step1').type('Flow').configJson('{"flowName" : "MockedFlow"}'))
                .add(new JobStep().order(2).name('manual').type('Manual').skipCondition('{$User.Name.matches("' + firstNamePattern + '")}'))
                .add(new JobStep().order(3).name('Execute').type('Flow').configJson('{"flowName" : "MockedFlow"}').skipCondition('{$User.Name.matches("test' + firstNamePattern + '")}'))
                .persist();
            
            Git_Commit__c gitCommit = new Git_Commit__c();
            insert gitCommit;

            CreateExecution.request request = new CreateExecution.request();
            request.templateName = 'Sample_1';
            request.parentId = gitCommit.Id;
            request.runAfterInstantiation = true;

            Webhook_Settings__c s = (Webhook_Settings__c) new WebhookSetting().action('RunJobTemplate').persist();
            RestContext.request = createRequest(requestBody(s.Action__c, s.Key__c, request));
            RestContext.response = new RestResponse();

            Flow.mockResponse = flowCompletionEvent(true, '', 'Success data');

            // Exercise
            Test.startTest();
            String response = MCWebhook.runAction();
            Test.stopTest();

            // Verify
            List<JobStep__c> jobSteps = [SELECT Id, IsSkipped__c, Result__c, Status__c FROM JobStep__c WHERE JobExecution__c != NULL ORDER BY Order__c];
            System.assertEquals(3, jobSteps.size(), 'Wrong number of steps');

            System.assertEquals(false, jobSteps[0].IsSkipped__c, '1st job step is not skipped during the execution.');
            System.assertEquals(true, jobSteps[1].IsSkipped__c, '2nd job step is skipped during the execution.');
            System.assertEquals(false, jobSteps[2].IsSkipped__c, '3rd job step is not skipped during the execution.');

            System.assertNotEquals(null, jobSteps[0].Result__c, '1st job step has an associated result.');
            System.assertEquals(null, jobSteps[1].Result__c, '2nd job step does not have an associated result.');
            System.assertNotEquals(null, jobSteps[2].Result__c, '3rd job step has an associated result.');

            System.assertEquals('Success', jobSteps[0].Status__c, '1st job step\'s status is Success');
            System.assertEquals('Skipped', jobSteps[1].Status__c, '2nd job step\'s status is Skipped');
            System.assertEquals('Success', jobSteps[2].Status__c, '3rd job step\'s status is Skipped');
        }
    }

    @isTest
    private static void testTakeSnapshot(){
        System.runAs(standardUser()){
            
            new JobTemplate().name('Snapshot Template').mockAutomation(ActionConstants.TAKE_SNAPSHOT).add(new JobStep()).persist();

            Environment dev = new Environment().name('dev').type('Sandbox').platform('Other').add(new Credential());
            Environment prod = new Environment().name('prod').type('Sandbox').platform('Other').add(new Credential());

            Deployment_Flow__c pipeline = (Deployment_Flow__c) new Pipeline()
                .active(true)
                .mainBranch('main')
                .setPlatform('Other')
                .add(new Connection(dev, prod).branch('dev'))
                .persist();

            Org__c credential = [SELECT Id FROM Org__c WHERE Environment__r.Name = 'dev' LIMIT 1];

            Git_Repository__c repository = [SELECT Id FROM Git_Repository__c LIMIT 1];
            
            String snapExternalId = 'snap1';

            Actions.ConfigureGitSnapshotRequest configRequest = new Actions.ConfigureGitSnapshotRequest();
            configRequest.credentialId = credential.Id;
            configRequest.branch = 'main';
            configRequest.externalId = snapExternalId;
            configRequest.repositoryId = repository.Id;
            configRequest.pipelineId = pipeline.Id;
            Actions.ConfigureGitSnapshotResult configResult = Actions.GitSnapshotService.configure(configRequest);


            Actions.TakeGitSnapshotRequest takeRequest = new Actions.TakeGitSnapshotRequest();
            takeRequest.snapshotId = snapExternalId;
            takeRequest.message = 'hello';

            Webhook_Settings__c s = (Webhook_Settings__c) new WebhookSetting().action('TakeSnapshot').persist();
            Flow.mockResponse = flowCompletionEvent(true, '', '{"commitId": "test_commit_id"}');
            RestContext.request = createRequest(requestBody(s.Action__c, s.Key__c, takeRequest));

            Test.startTest();
                String response = MCWebhook.runAction();
            Test.stopTest();

            JobExecution__c jobExecution = [SELECT Status__c, ErrorMessage__c, DataJson__c FROM JobExecution__c LIMIT 1];
            System.assertEquals(
                JobExecutionConstants.STATUS_SUCCESSFUL,
                jobExecution.Status__c,
                'Job execution status after stop test should be Successful'
            );
            List<Git_Org_Commit__c> gitCommits = [SELECT Status__c, Commit_Id__c FROM Git_Org_Commit__c WHERE Git_Backup__r.External_Id__c = :snapExternalId];
            System.assertEquals(1, gitCommits.size(), 'One Git Org Commit record should have been created');

            // Verify callback
            Git_Backup__c gitSnapshot = [SELECT Last_Backup__c FROM Git_Backup__c WHERE External_Id__c = :snapExternalId LIMIT 1];
            System.assertNotEquals(
                null,
                gitSnapshot.Last_Backup__c,
                'Git Snapshot should have been updated with last backup date in callback execution'
            );
            System.assertEquals(CommitConstants.STATUS_COMPLETE, gitCommits[0].Status__c, 'Git Snapshot Commit status should have been updated');
            System.assertEquals('test_commit_id', gitCommits[0].Commit_Id__c, 'Git Snapshot Commit status should have been updated');

            List<Automation_Event__c> events = [SELECT Id, Action_Name__c, Environment_Id__c FROM Automation_Event__c];
            System.assertEquals(1, events.size(), 'An Automation Event should be created');
            System.assertEquals(ActionConstants.TAKE_SNAPSHOT, events[0].Action_Name__c, 'Action Name should match');
            Environment__c environment = [SELECT Id FROM Environment__c WHERE Name = 'dev'];
            System.assertEquals(environment.Id, events[0].Environment_Id__c, 'Environment should match');
        }
    }


    // HELPER

    private static RestRequest createRequest(Blob reqBody) {
        RestRequest result = new RestRequest();
        result.httpMethod = 'POST';
        result.requestBody = reqBody;

        return result;
    }


    private static Blob requestBody(String action, String key, Object payload) {
        Map<String, Object> body = new Map<String, Object> {
            'action' => action,
            'key' => key,
            'payload' => payload
        };
        return Blob.valueOf( JSON.serialize(body) );
    }

    private static User standardUser() {
        return [SELECT Id FROM User WHERE Profile.Name = 'Standard User' AND UserName LIKE '%@test%.org' ORDER BY CreatedDate DESC LIMIT 1];
    }
    
    private static List<CommitAction.Change> changes(Integer count) {
        List<CommitAction.Change> result = new List<CommitAction.Change>();

        for (Integer i = 0; i < count; i++) {
            CommitAction.Change change = new CommitAction.Change();
            change.a = 'add';
            change.n = 'TestClass_' + i;
            change.t = 'ApexClass';
            change.m = 'force-app/main/default';
            change.c = 'category';
            change.j = '{"vk": "6368cb8e-776c-4ad6-9906-444d460715d7"}';
            result.add(change);
        }

        return result;
    }
    
    private static void createData() {
        new JobTemplate().name('Commit_Template').mockAutomation('Commit').add(new JobStep());
        new JobTemplate().name('Promotion_Template').mockAutomation('Promotion').add(new JobStep());
        new JobTemplate().name('PromotionDeployment_Template').mockAutomation('PromotionDeployment').add(new JobStep());
        new JobTemplate().name('Package_Create_Template').mockAutomation('CreatePackage').add(new JobStep());
        new JobTemplate().name('Package_Version_Create').mockAutomation('CreatePackageVersion').add(new JobStep());
        new JobTemplate().name('Package_Publish').mockAutomation('PublishPackageVersion').add(new JobStep()).persist();
        new JobTemplate().name('Package_Import').mockAutomation('ImportPackage').add(new JobStep()).persist();

        Credential dev1Credential = new Credential();
        Environment dev1 = new Environment().name('dev1').type('Sandbox').platform('Other').add(dev1Credential);
        Environment dev2 = new Environment().name('dev2').type('Sandbox').platform('Other').add(new Credential());
        Credential intCredential = new Credential();
        Environment integration = new Environment().name('int').type('Sandbox').platform('Other').add(intCredential);
        Environment uat = new Environment().name('uat').type('Sandbox').platform('Other').add(new Credential());
        Environment prod = new Environment().name('prod').type('Sandbox').platform('Other').add(new Credential());

        new Pipeline()
            .active(true)
            .mainBranch('main')
            .setPlatform('Other')
            .add(new Connection(dev1, integration).branch('dev1'))
            .add(new Connection(dev2, integration).branch('dev2'))
            .add(new Connection(integration, uat).branch('int'))
            .add(new Connection(uat, prod).branch('uat'))
            .add(new Project().add(new UserStory().credential(dev1Credential).add(new UserStoryMetadata().name('TestClass').type('ApexClass'))))
            .persist();
    }

    private static Event__e flowCompletionEvent(Boolean isSuccess, String errorMessage, String data) {
        Event__e result = new Event__e();
        result.Topic_Uri__c = OnJobStepComplete.STEP_ENDPOINT;
        result.Payload__c = Json.serialize(new OnJobStepComplete.EventPayload(isSuccess, errorMessage, data));

        return result;
    }
}