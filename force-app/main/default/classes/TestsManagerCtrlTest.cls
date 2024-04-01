@SuppressWarnings('PMD.CyclomaticComplexity')
@isTest
private class TestsManagerCtrlTest {
    private static final String JOB_TEMPLATE_NAME = 'MockTemplate';

    @isTest
    private static void executeForUserStory() {
        System.runAs(licensedUser()) {
            // Setup
            insertMockTestTool();

            User_Story__c mockUserStory = getMockUserStory();

            mockJobResponse();

            // Exercise
            Test.startTest();
            TestsManagerCtrl.runTestsOf(mockUserStory.Id);
            Test.stopTest();

            // Verify
            JobExecution__c execution = [SELECT DataJson__c, Status__c FROM JobExecution__c LIMIT 1];

            System.assertEquals('Successful', execution.Status__c, 'Job execution status after stop test should be Successful');
            assertPayload(execution, idsOnly([SELECT Id FROM Test__c WHERE User_Story__c = :mockUserStory.Id]));
        }
    }

    @isTest
    private static void executeWithoutExtensionSet() {
        System.runAs(licensedUser()) {
            // Setup
            User_Story__c mockUserStory = getMockUserStory();
            TestToolsSelector.mock(new List<TestTool__mdt>());

            Test.startTest();
            TestsManagerCtrl.runTestsOf(mockUserStory.Id);
            Test.stopTest();

            // Verify
            JobExecution__c execution = [SELECT ErrorMessage__c, Status__c FROM JobExecution__c LIMIT 1];
            System.assertEquals('Error', execution.Status__c, 'Job execution status should be Error');
            System.assert(
                execution.errorMessage__c.contains(Label.MissingTestTool),
                'Expected Job Execution with error message: ' + Label.MissingTestTool
            );
        }
    }

    @isTest
    private static void runTestsWhenExtConfigInactive() {
        System.runAs(licensedUser()) {
            // Setup
            User_Story__c mockUserStory = getMockUserStory();
            List<Test__c> tests = getMockTests();

            ExtensionConfiguration__c extConfig = new ExtensionConfiguration__c(Id = tests[0].ExtensionConfiguration__c, Active__c = false);
            update extConfig;

            mockJobResponse();

            // Exercise
            Test.startTest();
            TestsManagerCtrl.runTestsOf(mockUserStory.Id);
            Test.stopTest();

            // Verify
            List<JobExecution__c> executions = [SELECT DataJson__c, Status__c FROM JobExecution__c];

            System.assertEquals(true, executions.isEmpty(), 'Job execution should not be created as Test Extension config is Inactive');
        }
    }

    @isTest
    private static void runTestsWhenTestNotReady() {
        System.runAs(licensedUser()) {
            // Setup
            User_Story__c mockUserStory = getMockUserStory();

            List<Test__c> tests = getMockTests();
            tests[0].ReadyToRun__c = false;
            update tests[0];

            // Exercise
            Test.startTest();
            TestsManagerCtrl.runTestsOf(mockUserStory.Id);
            Test.stopTest();

            // Verify
            List<JobExecution__c> executions = [SELECT DataJson__c, Status__c FROM JobExecution__c];

            System.assertEquals(true, executions.isEmpty(), 'Job execution should not be created as Test are not ready to execute');
        }
    }

    @isTest
    private static void getTestsForUserStory() {
        System.runAs(licensedUser()) {
            // Setup
            insertMockTestTool();
            User_Story__c mockUserStory = getMockUserStory();
            createRelatedResults(mockUserStory.Id);

            // Exercise
            List<TestsManagerCtrl.TestWrapper> tests = TestsManagerCtrl.getTests(mockUserStory.Id);

            // Verify
            System.assertEquals(1, tests.size(), 'there should be 1 test for user story');
            assertGetTestMockResult(tests[0], 'Success', 'User Story Test');
        }
    }

    @isTest
    private static void getTestsForFeature() {
        System.runAs(licensedUser()) {
            // Setup
            insertMockTestTool();
            Application_Feature__c mockFeature = getMockFeature();
            createRelatedResults(mockFeature.Id);

            // Exercise
            List<TestsManagerCtrl.TestWrapper> tests = TestsManagerCtrl.getTests(mockFeature.Id);

            // Verify
            System.assertEquals(1, tests.size(), 'there should be 1 test for Feature');
            assertGetTestMockResult(tests[0], 'Success', 'Feature Test');
        }
    }

    @isTest
    private static void getTestsForApplication() {
        System.runAs(licensedUser()) {
            // Setup
            insertMockTestTool();
            Application__c mockApplication = getMockApplication();
            createRelatedResults(mockApplication.Id);

            // Exercise
            List<TestsManagerCtrl.TestWrapper> tests = TestsManagerCtrl.getTests(mockApplication.Id);

            // Verify
            System.assertEquals(1, tests.size(), 'there should be 1 test for application');
            assertGetTestMockResult(tests[0], 'Success', 'Application Test');
        }
    }

    @isTest
    private static void getTestsWhenTestAreNotReady() {
        System.runAs(licensedUser()) {
            // Setup
            insertMockTestTool();
            User_Story__c mockUserStory = getMockUserStory();

            List<Test__c> mockTests = getMockTests();
            mockTests[0].ReadyToRun__c = false;
            update mockTests[0];

            createRelatedResults(mockUserStory.Id);

            // Exercise
            List<TestsManagerCtrl.TestWrapper> tests = TestsManagerCtrl.getTests(mockUserStory.Id);

            // Verify
            System.assertEquals(1, tests.size(), 'There should be 1 test for user story');
            System.assertEquals('Not Executable', tests[0].status, 'Test Status should be Not Executable');
            List<Result__c> results = [SELECT Id, Name FROM Result__c WHERE Test__c = :tests[0].Id];
            System.assertEquals(true, results.isEmpty(), 'Result should not be generated when test is not ready to execute');
        }
    }

    @isTest
    private static void getTestsWhenExtenConfigIsInActive() {
        System.runAs(licensedUser()) {
            // Setup
            insertMockTestTool();
            User_Story__c mockUserStory = getMockUserStory();
            List<Test__c> mockTests = getMockTests();

            ExtensionConfiguration__c extConfig = new ExtensionConfiguration__c(Id = mockTests[0].ExtensionConfiguration__c, Active__c = false);
            update extConfig;

            createRelatedResults(mockUserStory.Id);

            // Exercise
            List<TestsManagerCtrl.TestWrapper> tests = TestsManagerCtrl.getTests(mockUserStory.Id);

            // Verify
            System.assertEquals(1, tests.size(), 'There should be 1 test for user story');
            System.assertEquals('Not Executable', tests[0].status, 'Test Status should be Not Executable');
            List<Result__c> results = [SELECT Id, Name FROM Result__c WHERE Test__c = :tests[0].Id];
            System.assertEquals(true, results.isEmpty(), 'Result should not be generated when Extension config is in active');
        }
    }

    @isTest
    private static void getTestsWithResultsAfterExtenConfigIsInActive() {
        System.runAs(licensedUser()) {
            // Setup
            insertMockTestTool();
            User_Story__c mockUserStory = getMockUserStory();
            List<Test__c> mockTests = getMockTests();

            createRelatedResults(mockUserStory.Id);

            ExtensionConfiguration__c extConfig = new ExtensionConfiguration__c(Id = mockTests[0].ExtensionConfiguration__c, Active__c = false);
            update extConfig;

            // Exercise
            List<TestsManagerCtrl.TestWrapper> tests = TestsManagerCtrl.getTests(mockUserStory.Id);

            // Verify
            System.assertEquals(1, tests.size(), 'There should be 1 test for user story');
            assertGetTestMockResult(tests[0], 'Not Executable', 'User Story Test');
        }
    }

    @isTest
    private static void runTest() {
        System.runAs(licensedUser()) {
            // Setup
            insertMockTestTool();

            Test__c mockTest = getMockTests().get(0);

            mockJobResponse();

            // Exercise
            Test.startTest();
            TestsManagerCtrl.runTest(mockTest.Id);
            Test.stopTest();

            // Verify
            JobExecution__c execution = [SELECT DataJson__c, Status__c FROM JobExecution__c LIMIT 1];

            System.assertEquals('Successful', execution.Status__c, 'Job execution status after stop test should be Successful');
            assertPayload(execution, idsOnly([SELECT Id FROM Test__c WHERE Id = :mockTest.Id]));
        }
    }

    @isTest
    private static void runTestWithoutExtensionSet() {
        System.runAs(licensedUser()) {
            // Setup
            Test__c mockTest = getMockTests().get(0);
            TestToolsSelector.mock(new List<TestTool__mdt>());

            // Exercise
            TestsManagerCtrl.runTest(mockTest.Id);

            // Verify
            JobExecution__c execution = [SELECT ErrorMessage__c, Status__c FROM JobExecution__c LIMIT 1];
            System.assertEquals('Error', execution.Status__c, 'Job execution status should be Error');
            System.assert(
                execution.errorMessage__c.contains(Label.MissingTestTool),
                'Expected Job Execution with error message: ' + Label.MissingTestTool
            );
        }
    }

    private static void assertPayload(JobExecution__c execution, List<Id> expectedTestIds) {
        RunTestsExecutionPayload expectedPayload = new RunTestsExecutionPayload().tests(expectedTestIds);
        RunTestsExecutionPayload receivedPayload = (RunTestsExecutionPayload) JSON.deserialize(execution.dataJson__c, RunTestsExecutionPayload.class);

        System.assertEquals(null, receivedPayload.environmentId, 'Environment should match');
        System.assertEquals(expectedTestIds.size(), receivedPayload.testIds.size(), 'Size of test ids should match');
        System.assertEquals(expectedPayload.testIds.size(), receivedPayload.testIds.size(), 'Size of test ids should match');

        for (Id testId : expectedPayload.testIds) {
            System.assert(receivedPayload.testIds.contains(testId), 'Received payload should contain the test id: ' + testId);
        }
    }

    private static void assertGetTestMockResult(TestsManagerCtrl.TestWrapper test, String expectedStatus, String expectedName) {
        Result__c result = [SELECT Id, Name FROM Result__c WHERE Test__c = :test.Id LIMIT 1];

        System.assertEquals(expectedName, test.name, 'Test Name should be Mock Test 1');
        System.assertEquals('Mock Type', test.testType, 'Test Type should be Mock Type');
        System.assertEquals('Manual Tests', test.testTool, 'Test Tool should be None');
        System.assertEquals(expectedStatus, test.status, 'Expected ' + expectedStatus + ' but found ' + test.status);

        System.assertEquals(result.Name, test.result, 'Result Status should be ' + result.Name);
        System.assertEquals('/' + result.id, test.resultUrl, 'Result Status should be ' + test.resultUrl);
        System.assertEquals(
            true,
            test.runDate.contains(System.now().format('dd/MM/yyyy')),
            'Result Run date should be ' + System.now().format('dd/MM/yyyy')
        );
    }

    @TestSetup
    private static void setupData() {
        insertData();
    }

    private static void insertData() {
        User licensedUser = createLicensedUser();

        System.runAs(licensedUser) {
            TestUtilities.assignLicense(String.valueOf(licensedUser.Username), true, true, true, true, true);
            createMockData();
        }
    }

    private static User createLicensedUser() {
        User result = TestDataFactory.createUsers()[0];

        List<PermissionSet> permissionSets = [SELECT Id FROM PermissionSet WHERE Name IN ('Copado_User', 'Copado_Functions', 'Copado_Job_Engine')];
        List<PermissionSetAssignment> assignments = new List<PermissionSetAssignment>();
        for (PermissionSet permissionSet : permissionSets) {
            assignments.add(new PermissionSetAssignment(AssigneeId = result.Id, PermissionSetId = permissionSet.Id));
        }
        insert assignments;

        return result;
    }

    private static User licensedUser() {
        return [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
    }

    private static void createMockData() {
        Application__c app = new Application__c();
        insert app;

        Application_Feature__c feature = new Application_Feature__c();
        feature.Application__c = app.Id;
        insert feature;

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
            .add(new Project().add(new UserStory().credential(dev1Credential).featureId(feature.Id)))
            .persist();

        TestTool__mdt testTool = insertMockTestTool();
        ExtensionConfiguration__c extConfig = createExtensionConfiguration(testTool);

        Test__c userStoryTest = new Test__c(
            Name = 'User Story Test',
            ExtensionConfiguration__c = extConfig.Id,
            ReadyToRun__c = true,
            User_Story__c = getMockUserStory().Id
        );
        Test__c featureTest = new Test__c(
            Name = 'Feature Test',
            ExtensionConfiguration__c = extConfig.Id,
            ReadyToRun__c = true,
            Feature__c = feature.Id
        );
        Test__c applicationTest = new Test__c(
            Name = 'Application Test',
            ExtensionConfiguration__c = extConfig.Id,
            ReadyToRun__c = true,
            Application__c = app.Id
        );
        insert new List<Test__c>{ userStoryTest, featureTest, applicationTest };

        JobTemplate__c jobTemplate = (JobTemplate__c) new JobTemplate().add(new JobStep()).persist();
        jobTemplate.ApiName__c = JOB_TEMPLATE_NAME;
        update jobTemplate;
    }

    private static Promotion__c createPromotion() {
        Promotion__c promotion = (Promotion__c) new Promotion().projectId(getMockProject().Id).sourceEnvId(getMockEnvironment('dev1').Id).persist();

        Promoted_User_Story__c promotedUserStory = new Promoted_User_Story__c(User_Story__c = getMockUserStory().Id, Promotion__c = promotion.Id);
        insert promotedUserStory;
        return promotion;
    }

    private static void createRelatedResults(Id parentId) {
        List<Result__c> results = new List<Result__c>();
        List<Test__c> tests = new TestsSelector().byParentAndAutomaticallyExecutableTests(parentId);

        for (Test__c test : tests) {
            results.add(testMethodUtilities.createResult(test.Id));
        }

        insert results;
    }

    private static Project__c getMockProject() {
        return [SELECT Id FROM Project__c LIMIT 1];
    }

    private static Environment__c getMockEnvironment(String envName) {
        return [SELECT Id FROM Environment__c WHERE Name = :envName LIMIT 1];
    }

    private static User_Story__c getMockUserStory() {
        return [SELECT Id FROM User_Story__c LIMIT 1];
    }

    private static Application_Feature__c getMockFeature() {
        return [SELECT Id FROM Application_Feature__c LIMIT 1];
    }

    private static Application__c getMockApplication() {
        return [SELECT Id FROM Application__c LIMIT 1];
    }

    private static List<Test__c> getMockTests() {
        return [SELECT Name, ExtensionConfiguration__c FROM Test__c];
    }

    private static TestTool__mdt insertMockTestTool() {
        TestTool__mdt mockTestTool = new TestTool__mdt(MasterLabel = 'Manual Tests', JobTemplate__c = JOB_TEMPLATE_NAME, TestType__c = 'Mock Type');

        TestToolsSelector.mock(new List<TestTool__mdt>{ mockTestTool });
        return mockTestTool;
    }

    private static ExtensionConfiguration__c createExtensionConfiguration(TestTool__mdt testTool) {
        ExtensionConfiguration__c extensionConfig = new ExtensionConfiguration__c(
            ExtensionTool__c = testTool.MasterLabel,
            ExtensionApplication__c = 'Test',
            Active__c = true
        );

        insert extensionConfig;
        return extensionConfig;
    }

    private static void mockJobResponse() {
        Flow.mockResponse = flowCompletionEvent();
    }

    private static Event__e flowCompletionEvent() {
        Event__e result = new Event__e();
        result.Topic_Uri__c = OnJobStepComplete.STEP_ENDPOINT;
        result.Payload__c = Json.serialize(new OnJobStepComplete.EventPayload(true, '', 'Success data 1'));

        return result;
    }

    private static List<Id> idsOnly(List<SObject> records) {
        return new List<Id>(new Map<Id, SObject>(records).keySet());
    }
}