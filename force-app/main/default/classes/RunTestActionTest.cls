@isTest
private class RunTestActionTest {
    private static final String JOB_TEMPLATE_NAME = 'MockTemplate';
    private static final String MOCK_ACTION_CALLBACK = 'MockRunTestsActionCallback';

    @isTest
    private static void execute() {
        System.runAs(licensedUser()) {
            // Setup
            insertMockTestTool();

            Test__c mockTest = getMockTest();

            RunTestAction.Request request = new RunTestAction.Request();
            request.testId = mockTest.Id;
            List<RunTestAction.Request> requests = new List<RunTestAction.Request>{ request };

            mockJobResponse(true);

            // Exercise
            Test.startTest();
            List<RunTestAction.Result> result = RunTestAction.execute(requests);
            Test.stopTest();

            // Verify
            System.assertEquals(1, result.size(), 'Only one Job Execution record expected');

            JobExecution__c execution = [SELECT DataJson__c, Status__c FROM JobExecution__c WHERE Id = :result[0].executionId];
            System.assertEquals('Successful', execution.Status__c, 'Job execution status after stop test should be Successful');
            assertPayload(execution, mockTest.Id);
        }
    }

    @isTest
    private static void executeForJobExecutionFailure() {
        System.runAs(licensedUser()) {
            // Setup
            insertMockTestTool();

            Test__c mockTest = getMockTest();

            RunTestAction.Request request = new RunTestAction.Request();
            request.testId = mockTest.Id;
            List<RunTestAction.Request> requests = new List<RunTestAction.Request>{ request };

            mockJobResponse(false);

            // Exercise
            Test.startTest();
            List<RunTestAction.Result> result = RunTestAction.execute(requests);
            Test.stopTest();

            // Verify
            System.assertEquals(1, result.size(), 'Only one Job Execution record expected');

            JobExecution__c execution = [SELECT DataJson__c, Status__c FROM JobExecution__c WHERE Id = :result[0].executionId];
            System.assertEquals('Error', execution.Status__c, 'Job execution status after stop test should be Successful');
            assertPayload(execution, mockTest.Id);
        }
    }

    @isTest
    private static void executeWithoutExtensionSet() {
        System.runAs(licensedUser()) {
            // Setup
            Test__c mockTest = getMockTest();
            TestToolsSelector.mock(new List<TestTool__mdt>());

            RunTestAction.Request request = new RunTestAction.Request();
            request.testId = mockTest.Id;

            List<RunTestAction.Request> requests = new List<RunTestAction.Request>{ request };

            // Exercise
            Test.startTest();
            List<RunTestAction.Result> result = RunTestAction.execute(requests);
            Test.stopTest();

            // Verify
            System.assertEquals(1, result.size(), 'Only one Job Execution record expected');

            JobExecution__c execution = [SELECT ErrorMessage__c, Status__c FROM JobExecution__c WHERE Id = :result[0].executionId];
            System.assertEquals('Error', execution.Status__c, 'Job execution status should be Error because of missing test tool.');
            System.assertEquals(execution.errorMessage__c, Label.MissingTestTool, 'Error should be: ' + Label.MissingTestTool);
        }
    }

    private static void assertPayload(JobExecution__c execution, Id expectedTestId) {
        RunTestsExecutionPayload receivedPayload = (RunTestsExecutionPayload) JSON.deserialize(execution.dataJson__c, RunTestsExecutionPayload.class);

        System.assertEquals(null, receivedPayload.environmentId, 'Environment should match');
        System.assertEquals(1, receivedPayload.testIds.size(), 'Size of test ids should be 1');
        System.assertEquals(expectedTestId, receivedPayload.testIds[0], 'Received payload should contain the test id: ' + expectedTestId);

        if (!receivedPayload.resultIds.isEmpty()) {
            List<Result__c> results = new ResultsSelector().byIds(new Set<Id>(receivedPayload.resultIds));
            System.assertEquals(1, results.size(), 'Size of test result should be equal to 1');
            if (execution.Status__c == 'Error') {
                System.assertEquals('Failed', results[0].Status__c, 'Test result should be failed.');
            }
        }
    }

    @TestSetup
    private static void setupData() {
        insertData();
    }

    private static void insertData() {
        User licensedUser = createLicensedUser();

        System.runAs(licensedUser) {
            TestUtilities.assignLicense(String.valueOf(licensedUser.Username), true, true, true, true, true);

            TestTool__mdt testTool = insertMockTestTool();

            ExtensionConfiguration__c extensionConfig = new ExtensionConfiguration__c(
                ExtensionTool__c = testTool.MasterLabel,
                ExtensionApplication__c = 'Test',
                Active__c = true
            );
            insert extensionConfig;

            insert new Test__c(Name = 'Mock Test', ExtensionConfiguration__c = extensionConfig.Id, ReadyToRun__c = true);

            JobTemplate__c jobTemplate = (JobTemplate__c) new JobTemplate().add(new JobStep()).persist();
            jobTemplate.ApiName__c = JOB_TEMPLATE_NAME;
            update jobTemplate;
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

    private static TestTool__mdt insertMockTestTool() {
        TestTool__mdt mockTestTool = new TestTool__mdt(MasterLabel = 'Manual Tests', JobTemplate__c = JOB_TEMPLATE_NAME, TestType__c = 'Mock Type');

        TestToolsSelector.mock(new List<TestTool__mdt>{ mockTestTool });
        return mockTestTool;
    }

    private static Test__c getMockTest() {
        return [SELECT Name FROM Test__c LIMIT 1];
    }

    private static void mockJobResponse(Boolean isSuccess) {
        Flow.mockResponse = flowCompletionEvent(isSuccess);
    }

    private static Event__e flowCompletionEvent(Boolean isSuccess) {
        Event__e result = new Event__e();
        result.Topic_Uri__c = OnJobStepComplete.STEP_ENDPOINT;
        result.Payload__c = Json.serialize(new OnJobStepComplete.EventPayload(isSuccess, '', 'data 1'));

        return result;
    }
}