@SuppressWarnings('PMD.CyclomaticComplexity')
@IsTest
private class ActionsTest {
    private final static String NULL_POINTER_EXCEPTION = 'Attempt to de-reference a null object';
    private final static String NO_ROWS_EXCEPTION = 'List has no rows for assignment to SObject';

    @TestSetup
    private static void setupData() {
        TestUtilities.getAllMultilicense();
        User user = (User) new User_t()
            .assign(new PermissionSetAssignment_t().copadoUser())
            .assign(new PermissionSetAssignment_t().functions())
            .assign(new PermissionSetAssignment_t().jobEngine())
            .assign(new PermissionSetAssignment_t().qualityGatesAdmin())
            .assign(new PermissionSetAssignment_t().configureAutomations())
            .assign(new PermissionSetAssignment_t().executeAutomations())
            .persist();
        System.runAs(user) {
            new CopadoLicense().user(user).enableAll().persist();
            createData();
        }
    }

    /******** COMMIT ********/

    @IsTest
    private static void commitServiceExecute() {
        System.runAs(getUser()) {
            // Setup
            Id userStoryId = getUserStoryId();
            Actions.CommitRequest request = new Actions.CommitRequest();
            request.userStoryId = userStoryId;
            request.changes = changes(10);
            request.recreateFeatureBranch = true;
            request.otherInformation = '{"key":"value"}';

            Flow.mockResponse = flowCompletionEvent(true, '', '{"commitId": "test_commit_id"}');

            // Exercise
            Test.startTest();
            Actions.CommitService.execute(request);
            Test.stopTest();

            // Verify
            JobExecution__c jobExecution = [SELECT Status__c, ErrorMessage__c, DataJson__c FROM JobExecution__c LIMIT 1];
            System.assertEquals('Successful', jobExecution.Status__c, 'Job execution status after stop test should be Successful');
            Map<String, Object> dataJson = (Map<String, Object>) JSON.deserializeUntyped(jobExecution.DataJson__c);
            System.assertEquals('{"key":"value"}', dataJson.get('jsonInformation'), 'Job execution Data Json field should be updated');
            List<User_Story_Metadata__c> metadata = [SELECT Id FROM User_Story_Metadata__c WHERE User_Story__c = :userStoryId];
            System.assertEquals(10, metadata.size(), 'Changes should have been created as User_Story_Metadata__c records');
            List<ContentVersion> files = [SELECT Id FROM ContentVersion WHERE PathOnClient = 'Copado Commit changes.json'];
            System.assertEquals(1, files.size(), 'Copado Commit changes.json file should have been upserted');
            List<Git_Org_Commit__c> gitCommits = [SELECT Status__c, Commit_Id__c FROM Git_Org_Commit__c];
            System.assertEquals(1, gitCommits.size(), 'One Git Org Commit record should have been created');
            List<User_Story_Commit__c> userStoryCommits = [SELECT LastJobExecutionId__c, External_Id__c FROM User_Story_Commit__c];
            System.assertEquals(1, userStoryCommits.size(), 'One User Story Commit record should have been created');
        }
    }

    @IsTest
    private static void commitServiceExecuteException() {
        System.runAs(getUser()) {
            Exception expectedException;
            Actions.CommitResult expectedResult;

            // Exercise
            Test.startTest();
            try {
                expectedResult = Actions.CommitService.execute(null);
            } catch (Exception ex) {
                expectedException = ex;
            }
            Test.stopTest();

            // Verify
            System.assertEquals(null, expectedResult, 'Response should be null');
            System.assertNotEquals(null, expectedException, 'An exception should be thrown');
            System.assertEquals(NULL_POINTER_EXCEPTION, expectedException.getMessage(), 'Exception message should match');
        }
    }

    @IsTest
    private static void commitServiceStatus() {
        System.runAs(getUser()) {
            // Setup
            JobExecution__c jobExecution = (JobExecution__c) new JobExecution().persist();

            // Exercise
            Test.startTest();
            Actions.StatusResult expectedResult = Actions.CommitService.status(jobExecution.Id);
            Test.stopTest();

            // Verify
            System.assertNotEquals(null, expectedResult, 'Result is not null');
            System.assertNotEquals(null, expectedResult.jobStatus, 'There should be a Status returned');
        }
    }

    @IsTest
    private static void commitServiceStatusException() {
        System.runAs(getUser()) {
            Exception expectedException;
            Actions.StatusResult expectedResult;

            // Exercise
            Test.startTest();
            try {
                expectedResult = Actions.CommitService.status(null);
            } catch (Exception ex) {
                expectedException = ex;
            }
            Test.stopTest();

            // Verify
            System.assertEquals(null, expectedResult, 'Response should be null');
            System.assertNotEquals(null, expectedException, 'An exception should be thrown');
            System.assertEquals(NO_ROWS_EXCEPTION, expectedException.getMessage(), 'Exception message should match');
        }
    }

    private static Id getUserStoryId() {
        return [SELECT Id FROM User_Story__c LIMIT 1].Id;
    }

    private static List<Actions.CommitChange> changes(Integer count) {
        List<Actions.CommitChange> result = new List<Actions.CommitChange>();

        for (Integer i = 0; i < count; i++) {
            Actions.CommitChange change = new Actions.CommitChange();
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

    /******** COMMIT ********/

    /******** PROMOTION ********/

    @IsTest
    private static void promotionServiceExecute() {
        System.runAs(getUser()) {
            // Setup
            User_Story__c userStory = getUserStory();

            Actions.PromotionRequest request = new Actions.PromotionRequest();
            request.userStoryIds = new List<Id>{ userStory.Id };
            request.sourceEnvironmentId = userStory.Environment__c;
            request.projectId = userStory.Project__c;
            request.executePromotion = true;
            request.isBackPromotion = false;

            Flow.mockResponse = flowCompletionEvent(true, '', '{}');

            // Exercise
            Test.startTest();
            Actions.PromotionResult expectedResult = Actions.PromotionService.execute(request);
            Test.stopTest();

            // Verify
            System.assertNotEquals(null, expectedResult, 'Result is not null');
            List<JobExecution__c> jobExecutionResult = [SELECT Id, Promotion__c FROM JobExecution__c WHERE Id = :expectedResult.jobExecution.Id];
            System.assertEquals(1, jobExecutionResult.size(), 'There should be a Job Execution created');
            System.assertNotEquals(null, jobExecutionResult[0].Promotion__c, 'There should be a Promotion created');
        }
    }

    @IsTest
    private static void promotionServiceExecuteException() {
        System.runAs(getUser()) {
            Exception expectedException;
            Actions.PromotionResult expectedResult;

            // Exercise
            Test.startTest();
            try {
                expectedResult = Actions.PromotionService.execute(null);
            } catch (Exception ex) {
                expectedException = ex;
            }
            Test.stopTest();

            // Verify
            System.assertEquals(null, expectedResult, 'Response should be null');
            System.assertNotEquals(null, expectedException, 'An exception should be thrown');
            System.assertEquals(NULL_POINTER_EXCEPTION, expectedException.getMessage(), 'Exception message should match');
        }
    }

    @IsTest
    private static void promotionServiceStatus() {
        System.runAs(getUser()) {
            // Setup
            JobExecution__c jobExecution = (JobExecution__c) new JobExecution().persist();

            // Exercise
            Test.startTest();
            Actions.StatusResult expectedResult = Actions.PromotionService.status(jobExecution.Id);
            Test.stopTest();

            // Verify
            System.assertNotEquals(null, expectedResult, 'Result is not null');
            System.assertNotEquals(null, expectedResult.jobStatus, 'There should be a Status returned');
        }
    }

    @IsTest
    private static void promotionServiceStatusException() {
        System.runAs(getUser()) {
            Exception expectedException;
            Actions.StatusResult expectedResult;

            // Exercise
            Test.startTest();
            try {
                expectedResult = Actions.PromotionService.status(null);
            } catch (Exception ex) {
                expectedException = ex;
            }
            Test.stopTest();

            // Verify
            System.assertEquals(null, expectedResult, 'Response should be null');
            System.assertNotEquals(null, expectedException, 'An exception should be thrown');
            System.assertEquals(NO_ROWS_EXCEPTION, expectedException.getMessage(), 'Exception message should match');
        }
    }

    /******** PROMOTION ********/

    /******** PROMOTION DEPLOYMENT ********/

    @IsTest
    private static void promotionDeploymentExecute() {
        System.runAs(getUser()) {
            // Setup
            Promotion__c promotion = createPromotion();
            Flow.mockResponse = flowCompletionEvent(true, '', '');

            Actions.PromotionDeploymentRequest request = new Actions.PromotionDeploymentRequest();
            request.promotionId = promotion.Id;
            request.deploymentDryRun = false;

            // Exercise
            Test.startTest();
            Actions.PromotionDeploymentResult response = Actions.PromotionDeploymentService.execute(request);
            Test.stopTest();

            // Verify
            JobExecution__c jobExecution = [SELECT Status__c FROM JobExecution__c WHERE Id = :response.jobExecution.Id LIMIT 1];
            System.assertEquals('Successful', jobExecution.Status__c, 'Job execution status should be Successful');
            Deployment__c deployment = [SELECT Status__c FROM Deployment__c WHERE Promotion__c = :promotion.Id LIMIT 1];
            System.assertEquals('Completed Successfully', deployment.Status__c, 'Deployment status should be Successful');
        }
    }

    @IsTest
    private static void promotionDeploymentExecuteException() {
        System.runAs(getUser()) {
            // Exercise
            Exception expectedException;
            Actions.PromotionDeploymentResult expectedResult;

            Actions.PromotionDeploymentRequest request = new Actions.PromotionDeploymentRequest();
            request.promotionId = null;
            request.deploymentDryRun = true;

            Test.startTest();
            try {
                expectedResult = Actions.PromotionDeploymentService.execute(request);
            } catch (Exception ex) {
                expectedException = ex;
            }
            Test.stopTest();

            // Verify
            System.assertEquals(null, expectedResult, 'Response should be null');
            System.assertNotEquals(null, expectedException, 'An exception should be thrown');
            System.assert(expectedException.getMessage().contains('Id not specified in an update call'), 'Exception message should match');
        }
    }

    @IsTest
    private static void promotionDeploymentStatus() {
        System.runAs(getUser()) {
            // Setup
            JobExecution__c jobExecution = (JobExecution__c) new JobExecution().persist();

            // Exercise
            Test.startTest();
            Actions.StatusResult expectedResult = Actions.PromotionDeploymentService.status(jobExecution.Id);
            Test.stopTest();

            // Verify
            System.assertNotEquals(null, expectedResult, 'Result is not null');
            System.assertNotEquals(null, expectedResult.jobStatus, 'There should be a Status returned');
        }
    }

    @IsTest
    private static void promotionDeploymentStatusException() {
        System.runAs(getUser()) {
            Exception expectedException;
            Actions.StatusResult expectedResult;

            // Exercise
            Test.startTest();
            try {
                expectedResult = Actions.PromotionDeploymentService.status(null);
            } catch (Exception ex) {
                expectedException = ex;
            }
            Test.stopTest();

            // Verify
            System.assertEquals(null, expectedResult, 'Response should be null');
            System.assertNotEquals(null, expectedException, 'An exception should be thrown');
            System.assertEquals(NO_ROWS_EXCEPTION, expectedException.getMessage(), 'Exception message should match');
        }
    }

    private static Promotion__c createPromotion() {
        Promotion__c firstPromotion = (Promotion__c) new Promotion()
            .projectId([SELECT Id FROM Project__c LIMIT 1].Id)
            .sourceEnvId([SELECT Id FROM Environment__c WHERE Name = 'dev1' LIMIT 1].Id)
            .persist();

        Promoted_User_Story__c promotedUserStory = new Promoted_User_Story__c(User_Story__c = getUserStory().Id, Promotion__c = firstPromotion.Id);
        insert promotedUserStory;
        return firstPromotion;
    }

    /******** PROMOTION DEPLOYMENT ********/

    /******** PACKAGE CREATE ********/

    @IsTest
    private static void packageCreateServiceExecute() {
        System.runAs(getUser()) {
            // Setup
            Artifact__c packageRecord = (Artifact__c) new Package_t().pipelineId(getPipelineId()).packageType('First-Generation Package').persist();

            Actions.PackageCreateRequest request = new Actions.PackageCreateRequest();
            request.packageId = packageRecord.Id;
            request.otherInformation = '{"key": "value"}';

            Flow.mockResponse = flowCompletionEvent(true, '', '{}');

            // Exercise
            Test.startTest();
            Actions.PackageCreateResult result = Actions.PackageCreateService.execute(request);
            Test.stopTest();

            // Verify
            System.assertNotEquals(null, result, 'Result is not null');
            List<JobExecution__c> jobs = [SELECT DataJson__c FROM JobExecution__c];
            System.assertEquals(1, jobs.size(), 'Job execution should be started.');
            String expectedJSON = JSON.serialize(request).replace('otherInformation', 'jsonInformation');
            System.assertEquals(expectedJSON, jobs[0].DataJson__c, 'Payload should be passed to job execution.');

            List<Automation_Event__c> events = [SELECT Id, Action_Name__c FROM Automation_Event__c];
            System.assertEquals(1, events.size(), 'An Automation Event should be created');
            System.assertEquals(ActionConstants.CREATE_PACKAGE, events[0].Action_Name__c, 'Action Name should match');
        }
    }

    @IsTest
    private static void packageCreateServiceExecuteException() {
        System.runAs(getUser()) {
            Exception expectedException;
            Actions.PackageCreateResult expectedResult;

            // Exercise
            Test.startTest();
            try {
                expectedResult = Actions.PackageCreateService.execute(null);
            } catch (Exception ex) {
                expectedException = ex;
            }
            Test.stopTest();

            // Verify
            System.assertEquals(null, expectedResult, 'Response should be null');
            System.assertNotEquals(null, expectedException, 'An exception should be thrown');
            System.assertEquals(NULL_POINTER_EXCEPTION, expectedException.getMessage(), 'Exception message should match');
        }
    }

    @IsTest
    private static void packageCreateServiceStatus() {
        System.runAs(getUser()) {
            // Setup
            JobExecution__c jobExecution = (JobExecution__c) new JobExecution().persist();

            // Exercise
            Test.startTest();
            Actions.StatusResult expectedResult = Actions.PackageCreateService.status(jobExecution.Id);
            Test.stopTest();

            // Verify
            System.assertNotEquals(null, expectedResult, 'Result is not null');
            System.assertNotEquals(null, expectedResult.jobStatus, 'There should be a Status returned');
        }
    }

    @IsTest
    private static void packageCreateServiceStatusException() {
        System.runAs(getUser()) {
            Exception expectedException;
            Actions.StatusResult expectedResult;

            // Exercise
            Test.startTest();
            try {
                expectedResult = Actions.PackageCreateService.status(null);
            } catch (Exception ex) {
                expectedException = ex;
            }
            Test.stopTest();

            // Verify
            System.assertEquals(null, expectedResult, 'Response should be null');
            System.assertNotEquals(null, expectedException, 'An exception should be thrown');
            System.assertEquals(NO_ROWS_EXCEPTION, expectedException.getMessage(), 'Exception message should match');
        }
    }

    /******** PACKAGE CREATE ********/

    /******** PACKAGE VERSION CREATE ********/

    @IsTest
    private static void packageVersionCreateServiceExecute() {
        System.runAs(getUser()) {
            // Setup
            Artifact__c packageRecord = (Artifact__c) new Package_t().pipelineId(getPipelineId()).packageType('First-Generation Package').persist();

            Actions.PackageVersionCreateRequest request = new Actions.PackageVersionCreateRequest();
            request.packageId = packageRecord.Id;
            request.otherInformation = '{"key": "value"}';

            Flow.mockResponse = flowCompletionEvent(true, '', '{}');

            // Exercise
            Test.startTest();
            Actions.PackageVersionCreateResult expectedResult = Actions.PackageVersionCreateService.execute(request);
            Test.stopTest();

            // Verify
            System.assertNotEquals(null, expectedResult, 'Result is not null');
            List<JobExecution__c> jobExecutionResult = [SELECT Id, Promotion__c FROM JobExecution__c WHERE Id = :expectedResult.jobExecution.Id];
            System.assertEquals(1, jobExecutionResult.size(), 'There should be a Job Execution created');
        }
    }

    @IsTest
    private static void packageVersionCreateServiceExecuteException() {
        System.runAs(getUser()) {
            Exception expectedException;
            Actions.PackageVersionCreateResult expectedResult;

            // Exercise
            Test.startTest();
            try {
                expectedResult = Actions.PackageVersionCreateService.execute(null);
            } catch (Exception ex) {
                expectedException = ex;
            }
            Test.stopTest();

            // Verify
            System.assertEquals(null, expectedResult, 'Response should be null');
            System.assertNotEquals(null, expectedException, 'An exception should be thrown');
            System.assertEquals(NULL_POINTER_EXCEPTION, expectedException.getMessage(), 'Exception message should match');
        }
    }

    @IsTest
    private static void packageVersionCreateServiceStatus() {
        System.runAs(getUser()) {
            // Setup
            JobExecution__c jobExecution = (JobExecution__c) new JobExecution().persist();

            // Exercise
            Test.startTest();
            Actions.StatusResult expectedResult = Actions.PackageVersionCreateService.status(jobExecution.Id);
            Test.stopTest();

            // Verify
            System.assertNotEquals(null, expectedResult, 'Result is not null');
            System.assertNotEquals(null, expectedResult.jobStatus, 'There should be a Status returned');
        }
    }

    @IsTest
    private static void packageVersionCreateServiceStatusException() {
        System.runAs(getUser()) {
            Exception expectedException;
            Actions.StatusResult expectedResult;

            // Exercise
            Test.startTest();
            try {
                expectedResult = Actions.PackageVersionCreateService.status(null);
            } catch (Exception ex) {
                expectedException = ex;
            }
            Test.stopTest();

            // Verify
            System.assertEquals(null, expectedResult, 'Response should be null');
            System.assertNotEquals(null, expectedException, 'An exception should be thrown');
            System.assertEquals(NO_ROWS_EXCEPTION, expectedException.getMessage(), 'Exception message should match');
        }
    }

    /******** PACKAGE VERSION CREATE ********/

    /******** PACKAGE DISTRIBUTE ********/

    @IsTest
    private static void packageDistributeExecute() {
        System.runAs(getUser()) {
            // Setup
            createPackageDistributeData();

            Flow.mockResponse = flowCompletionEvent(true, '', '');

            Actions.PackageDistributeRequest request = new Actions.PackageDistributeRequest();
            request.packageVersionId = getPackageVersion().Id;

            // Exercise
            Test.startTest();
            Actions.PackageDistributeRequestResult response = Actions.PackageDistributeService.execute(request);
            Test.stopTest();

            // Verify
            JobExecution__c jobExecution = [SELECT Status__c FROM JobExecution__c WHERE Id = :response.jobExecution.Id LIMIT 1];
            System.assertEquals('Successful', jobExecution.Status__c, 'Job execution status should be Successful');
            Artifact_Version__c packageVersion = [SELECT Is_released__c FROM Artifact_Version__c WHERE Id = :request.packageVersionId LIMIT 1];
            System.assertEquals(true, packageVersion.Is_released__c, 'Package version should be released');
        }
    }

    @IsTest
    private static void packageDistributeExecuteException() {
        System.runAs(getUser()) {
            // Exercise
            Exception expectedException;
            Actions.PackageDistributeRequestResult expectedResult;

            Actions.PackageDistributeRequest request = new Actions.PackageDistributeRequest();
            request.packageVersionId = null;

            Test.startTest();
            try {
                expectedResult = Actions.PackageDistributeService.execute(request);
            } catch (Exception ex) {
                expectedException = ex;
            }
            Test.stopTest();

            // Verify
            System.assertEquals(null, expectedResult, 'Response should be null');
            System.assertNotEquals(null, expectedException, 'An exception should be thrown');
            System.assertEquals(Label.InvalidPackageVersionId, expectedException.getMessage(), 'Exception message should match');
        }
    }

    @IsTest
    private static void packageDistributeStatus() {
        System.runAs(getUser()) {
            // Setup
            JobExecution__c jobExecution = (JobExecution__c) new JobExecution().persist();

            // Exercise
            Test.startTest();
            Actions.StatusResult expectedResult = Actions.PackageDistributeService.status(jobExecution.Id);
            Test.stopTest();

            // Verify
            System.assertNotEquals(null, expectedResult, 'Result is not null');
            System.assertNotEquals(null, expectedResult.jobStatus, 'There should be a Status returned');
        }
    }

    @IsTest
    private static void packageDistributeStatusException() {
        System.runAs(getUser()) {
            Exception expectedException;
            Actions.StatusResult expectedResult;

            // Exercise
            Test.startTest();
            try {
                expectedResult = Actions.PackageDistributeService.status(null);
            } catch (Exception ex) {
                expectedException = ex;
            }
            Test.stopTest();

            // Verify
            System.assertEquals(null, expectedResult, 'Response should be null');
            System.assertNotEquals(null, expectedException, 'An exception should be thrown');
            System.assertEquals(NO_ROWS_EXCEPTION, expectedException.getMessage(), 'Exception message should match');
        }
    }

    private static void createPackageDistributeData() {
        new Package_t()
            .packageArtifactRecordType()
            .name('Test package')
            .pipelineId(getPipelineId())
            .repositoryId(getRepository().Id)
            .add(new PackageVersion().versionName('v0.1.0').versionNumber('0.1.0.1'))
            .persist();
    }

    private static Artifact_Version__c getPackageVersion() {
        return [SELECT Id FROM Artifact_Version__c LIMIT 1];
    }

    private static Git_Repository__c getRepository() {
        return [SELECT Id FROM Git_Repository__c LIMIT 1];
    }

    /******** PACKAGE DISTRIBUTE ********/

    /******** RUN TEST ********/

    @IsTest
    private static void runTestExecute() {
        System.runAs(getUser()) {
            // Setup
            createRunTestData();

            Flow.mockResponse = flowCompletionEvent(true, '', '');

            Actions.RunTestRequest request = new Actions.RunTestRequest();
            request.tool = 'Manual Tests';
            request.contextIds = getTestIds();
            request.extensionConfigurationId = getExtensionConfiguration().Id;

            // Exercise
            Test.startTest();
            Actions.RunTestResult response = Actions.RunTestService.execute(request);
            Test.stopTest();

            // Verify
            JobExecution__c jobExecution = [SELECT Status__c FROM JobExecution__c WHERE Id = :response.jobExecution.Id LIMIT 1];
            System.assertEquals('Successful', jobExecution.Status__c, 'Job execution status should be Successful');
            for (Test__c test : new TestsSelector().byParents(new Set<Id>(getTestIds()))) {
                System.assertEquals(jobExecution.Id, test.LatestJobExecution__c, 'Test should populate with latest execution Id');
            }
        }
    }

    @IsTest
    private static void runTestExecuteException() {
        System.runAs(getUser()) {
            // Exercise
            Exception expectedException;
            Actions.RunTestResult expectedResult;

            Actions.RunTestRequest request = new Actions.RunTestRequest();
            request.tool = 'Manual Test';
            request.contextIds = null;
            request.extensionConfigurationId = null;

            Test.startTest();
            try {
                expectedResult = Actions.RunTestService.execute(request);
            } catch (Exception ex) {
                expectedException = ex;
            }
            Test.stopTest();

            // Verify
            System.assertEquals(null, expectedResult, 'Response should be null');
            System.assertNotEquals(null, expectedException, 'An exception should be thrown');
            System.assertEquals(NULL_POINTER_EXCEPTION, expectedException.getMessage(), 'Exception message should match');
        }
    }

    @IsTest
    private static void runTestStatus() {
        System.runAs(getUser()) {
            // Setup
            JobExecution__c jobExecution = (JobExecution__c) new JobExecution().persist();

            // Exercise
            Test.startTest();
            Actions.StatusResult expectedResult = Actions.RunTestService.status(jobExecution.Id);
            Test.stopTest();

            // Verify
            System.assertNotEquals(null, expectedResult, 'Result is not null');
            System.assertNotEquals(null, expectedResult.jobStatus, 'There should be a Status returned');
        }
    }

    @IsTest
    private static void runTestStatusException() {
        System.runAs(getUser()) {
            Exception expectedException;
            Actions.StatusResult expectedResult;

            // Exercise
            Test.startTest();
            try {
                expectedResult = Actions.RunTestService.status(null);
            } catch (Exception ex) {
                expectedException = ex;
            }
            Test.stopTest();

            // Verify
            System.assertEquals(null, expectedResult, 'Response should be null');
            System.assertNotEquals(null, expectedException, 'An exception should be thrown');
            System.assertEquals(NO_ROWS_EXCEPTION, expectedException.getMessage(), 'Exception message should match');
        }
    }

    private static void createRunTestData() {
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
        insert new Test__c(
            Configuration__c = 'test1',
            ExtensionConfiguration__c = extensionConfiguration.Id,
            User_Story__c = getUserStory().Id,
            ReadyToRun__c = true
        );
    }

    private static ExtensionConfiguration__c getExtensionConfiguration() {
        return [SELECT Id FROM ExtensionConfiguration__c LIMIT 1];
    }

    private static List<Id> getTestIds() {
        return new List<Id>(new Map<Id, Test__c>([SELECT Id FROM Test__c LIMIT 1]).keySet());
    }

    /******** RUN TEST ********/

    /******** GIT SNAPSHOT ********/
    @IsTest
    private static void gitSnapshotStatus() {
        System.runAs(getUser()) {
            // Setup
            JobExecution__c jobExecution = (JobExecution__c) new JobExecution().persist();

            // Exercise
            Test.startTest();
            Actions.StatusResult expectedResult = Actions.GitSnapshotService.status(jobExecution.Id);
            Test.stopTest();

            // Verify
            System.assertNotEquals(null, expectedResult, 'Result is not null');
            System.assertNotEquals(null, expectedResult.jobStatus, 'There should be a Status returned');
        }
    }

    @IsTest
    private static void gitSnapshotStatusException() {
        System.runAs(getUser()) {
            Exception expectedException;
            Actions.StatusResult expectedResult;

            // Exercise
            Test.startTest();
            try {
                expectedResult = Actions.GitSnapshotService.status(null);
            } catch (Exception ex) {
                expectedException = ex;
            }
            Test.stopTest();

            // Verify
            System.assertEquals(null, expectedResult, 'Response should be null');
            System.assertNotEquals(null, expectedException, 'An exception should be thrown');
            System.assertEquals(NO_ROWS_EXCEPTION, expectedException.getMessage(), 'Exception message should match');
        }
    }

    /******** GIT SNAPSHOT ********/

    /******** USER STORY BUNDLE ********/

    @IsTest
    private static void userStoryBundleServiceCreate() {
        System.runAs(getUserWithoutUSBPermission()) {
            // Setup
            List<Id> userStoryIds = new List<Id>();
            for (User_Story__c userStory : getUserStories()) {
                userStoryIds.add(userStory.Id);
            }

            Artifact_Version__c packageVersion = new Artifact_Version__c();
            packageVersion.Name = 'Poc';

            Actions.CreateUserStoryBundleRequest request = new Actions.CreateUserStoryBundleRequest();
            request.packageVersion = packageVersion;
            request.userStoryIds = userStoryIds;

            Exception expectedException;

            // Exercise
            Test.startTest();
            try {
                Actions.UserStoryBundleService.create(request);
            } catch (Exception ex) {
                expectedException = ex;
            }
            Test.stopTest();

            // Verify
            System.assertNotEquals(null, expectedException, 'An exception should be thrown since custom Permission is required to create USB.');
        }
    }

    @IsTest
    private static void userStoryBundleStatusException() {
        System.runAs(getUser()) {
            Exception expectedException;
            Actions.StatusResult expectedResult;

            // Exercise
            Test.startTest();
            try {
                expectedResult = Actions.SubmitUserStoryService.status(null);
            } catch (Exception ex) {
                expectedException = ex;
            }
            Test.stopTest();

            // Verify
            System.assertEquals(null, expectedResult, 'Response should be null');
            System.assertNotEquals(null, expectedException, 'An exception should be thrown');
            System.assertEquals(NO_ROWS_EXCEPTION, expectedException.getMessage(), 'Exception message should match');
        }
    }

    @IsTest
    private static void userStoryBundleStatus() {
        System.runAs(getUser()) {
            // Setup
            JobExecution__c jobExecution = (JobExecution__c) new JobExecution().persist();

            // Exercise
            Test.startTest();
            Actions.StatusResult expectedResult = Actions.UserStoryBundleService.status(jobExecution.Id);
            Test.stopTest();

            // Verify
            System.assertNotEquals(null, expectedResult, 'Result is not null');
            System.assertNotEquals(null, expectedResult.jobStatus, 'There should be a Status returned');
        }
    }

    /******** USER STORY BUNDLES ********/

    /******** SUBMIT USER STORY ********/

    @IsTest
    private static void submitUserStoryServiceMatch() {
        System.runAs(getUser()) {
            // Setup
            Actions.MatchAutomationRuleRequest request = new Actions.MatchAutomationRuleRequest();
            request.userStoryId = getUserStory().Id;

            // Exercise
            Test.startTest();
            Actions.MatchAutomationRuleResult result = Actions.SubmitUserStoryService.match(request);
            Test.stopTest();

            // Verify
            System.assertEquals(true, result.automationRule == null, 'Automation Rule should not be returned');
        }
    }

    @IsTest
    private static void submitUserStoryServiceSubmit() {
        System.runAs(getUser()) {
            // Setup
            Actions.SubmitUserStoryRequest request = new Actions.SubmitUserStoryRequest();
            request.userStoryId = getUserStory().Id;

            // Exercise
            Test.startTest();
            Actions.SubmitUserStoryResult result = Actions.SubmitUserStoryService.submit(request);
            Test.stopTest();

            // Verify
            System.assertEquals(true, result.automationEvent == null, 'Event should not be created with source Action');
        }
    }

    @IsTest
    private static void submitUserStoryStatus() {
        System.runAs(getUser()) {
            // Setup
            JobExecution__c jobExecution = (JobExecution__c) new JobExecution().persist();

            // Exercise
            Test.startTest();
            Actions.StatusResult expectedResult = Actions.SubmitUserStoryService.status(jobExecution.Id);
            Test.stopTest();

            // Verify
            System.assertNotEquals(null, expectedResult, 'Result is not null');
            System.assertNotEquals(null, expectedResult.jobStatus, 'There should be a Status returned');
        }
    }

    @IsTest
    private static void submitUserStoryStatusException() {
        System.runAs(getUser()) {
            Exception expectedException;
            Actions.StatusResult expectedResult;

            // Exercise
            Test.startTest();
            try {
                expectedResult = Actions.SubmitUserStoryService.status(null);
            } catch (Exception ex) {
                expectedException = ex;
            }
            Test.stopTest();

            // Verify
            System.assertEquals(null, expectedResult, 'Response should be null');
            System.assertNotEquals(null, expectedException, 'An exception should be thrown');
            System.assertEquals(NO_ROWS_EXCEPTION, expectedException.getMessage(), 'Exception message should match');
        }
    }

    /******** SUBMIT USER STORY ********/

    private static User getUser() {
        return [SELECT Id, Email FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1];
    }

    private static void createData() {
        new JobTemplate().name('Commit_Template').mockAutomation('Commit').add(new JobStep());
        new JobTemplate().name('Promotion_Template').mockAutomation('Promotion').add(new JobStep());
        new JobTemplate().name('PromotionDeployment_Template').mockAutomation('PromotionDeployment').add(new JobStep());
        new JobTemplate().name('Package_Create_Template').mockAutomation('CreatePackage').add(new JobStep());
        new JobTemplate().name('Package_Version_Create').mockAutomation('CreatePackageVersion').add(new JobStep());
        new JobTemplate().name('Package_Distribute').mockAutomation('PublishPackageVersion').add(new JobStep()).persist();

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
            .add(
                new Project()
                    .add(new UserStory().credential(dev1Credential).add(new UserStoryMetadata().name('TestClass').type('ApexClass')))
                    .add(new UserStory().credential(dev1Credential).add(new UserStoryMetadata().name('TestClass 1').type('ApexClass')))
            )
            .persist();
    }

    private static User_Story__c getUserStory() {
        return [SELECT Id, Environment__c, Project__c FROM User_Story__c LIMIT 1];
    }

    private static List<User_Story__c> getUserStories() {
        return [SELECT Id FROM User_Story__c LIMIT 2];
    }

    private static Id getPipelineId() {
        return [SELECT Id FROM Deployment_Flow__c LIMIT 1].Id;
    }

    private static Event__e flowCompletionEvent(Boolean isSuccess, String errorMessage, String data) {
        Event__e result = new Event__e();
        result.Topic_Uri__c = OnJobStepComplete.STEP_ENDPOINT;
        result.Payload__c = Json.serialize(new OnJobStepComplete.EventPayload(isSuccess, errorMessage, data));

        return result;
    }

    private static MC_Result__e functionCompletionEvent(Boolean isSuccess, String errorMessage, String data) {
        MC_Result__e result = new MC_Result__e();
        result.IsFinished__c = true;
        result.Result_Data__c = data;
        result.IsSuccess__c = isSuccess;
        result.Error_Message__c = errorMessage;
        return result;
    }

    private static User getUserWithoutUSBPermission() {
        User user = (User) new User_t().persist();
        deletePermissionIfExists(user.Id);
        return user;
    }

    private static void deletePermissionIfExists(String userId) {
        delete [
            SELECT Id
            FROM SetupEntityAccess
            WHERE
                SetupEntityId IN (
                    SELECT Id
                    FROM CustomPermission
                    WHERE DeveloperName = :CustomPermissionConstants.USER_STORY_BUNDLE_CUSTOM_PERMISSION
                )
                AND ParentId IN (SELECT PermissionSetId FROM PermissionSetAssignment WHERE AssigneeId = :userId)
        ];
    }
}