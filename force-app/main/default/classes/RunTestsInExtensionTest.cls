@IsTest
private class RunTestsInExtensionTest {
    private static final String JOB_TEMPLATE_NAME = 'MockTemplate';

    @IsTest
    private static void executeWithMultipleTests() {
        System.runAs(licensedUser()) {
            // Setup
            Exception expectedException = null;
            insertMockTestTool();
            mockJobResponse();

            // Exercise
            try {
                new RunTestsInExtension(getMockTests()).execute();
            } catch (Exception ex) {
                expectedException = ex;
            }

            // Verify
            System.assertNotEquals(null, expectedException, 'Should throw exception if multiple tests are executed in single transaction');
        }
    }

    @IsTest
    private static void execute() {
        System.runAs(licensedUser()) {
            // Setup
            insertMockTestTool();

            Test__c mockTest = getMockTest();

            mockJobResponse();

            // Exercise
            Test.startTest();
            List<JobExecution__c> results = new RunTestsInExtension(new List<Test__c>{ mockTest }).execute();
            Test.stopTest();

            // Verify
            System.assertEquals(1, results.size(), 'Four Job Execution records expected');

            JobExecution__c immediateExecution = results[0];
            JobExecution__c updatedExecution = [SELECT DataJson__c, Status__c FROM JobExecution__c WHERE Id = :immediateExecution.Id];

            assertStatus(immediateExecution, updatedExecution);
            assertPayload(immediateExecution, new List<Id>{ mockTest.id }, null);
        }
    }

    @isTest
    private static void executeAsync() {
        System.runAs(licensedUser()) {
            // Setup
            insertMockTestTool();

            List<Test__c> mockTests = new List<Test__c>{ getMockTest() };

            mockJobResponse();

            // Exercise
            Test.startTest();
            new RunTestsInExtension(mockTests).executeAsync();
            Test.stopTest();

            // Verify
            List<JobExecution__c> results = [SELECT DataJson__c, Status__c FROM JobExecution__c];
            System.assertEquals(1, results.size(), 'Only 1 Job Execution record expected');

            JobExecution__c immediateExecution = results[0];
            JobExecution__c updatedExecution = [SELECT DataJson__c, Status__c FROM JobExecution__c WHERE Id = :immediateExecution.Id];

            assertStatus(immediateExecution, updatedExecution);
            assertPayload(immediateExecution, new List<Id>{ mockTests[0].id }, null);
        }
    }

    @isTest
    private static void executeWithoutExtensionSet() {
        System.runAs(licensedUser()) {
            TestToolsSelector.mock(new List<TestTool__mdt>());

            List<Test__c> mockTests = new List<Test__c>{ getMockTest() };

            // Exercise
            Test.startTest();
            List<JobExecution__c> jobExecutions = new RunTestsInExtension(mockTests).execute();
            Test.stopTest();

            // Verify
            System.assert(jobExecutions.size() > 0, 'Job execution should be available');
            JobExecution__c execution = [SELECT ErrorMessage__c, Status__c FROM JobExecution__c LIMIT 1];
            System.assertEquals('Error', execution.Status__c, 'Job execution status should be Error');
            System.assert(
                jobExecutions[0].errorMessage__c.contains(Label.MissingTestTool),
                'Expected Job Execution with error message: ' + Label.MissingTestTool
            );
        }
    }

    @isTest
    private static void executeWithoutExtensionSetAsync() {
        System.runAs(licensedUser()) {
            // Setup
            TestToolsSelector.mock(new List<TestTool__mdt>());

            List<Test__c> mockTests = new List<Test__c>{ getMockTest() };

            // Exercise

            Test.startTest();
            new RunTestsInExtension(mockTests).executeAsync();
            Test.stopTest();

            JobExecution__c execution = [SELECT ErrorMessage__c, Status__c FROM JobExecution__c LIMIT 1];

            // Verify
            System.assertEquals(execution.errorMessage__c, Label.MissingTestTool, 'Error Message should be: ' + Label.MissingTestTool);
        }
    }

    @isTest
    private static void executeAsAutomation() {
        System.runAs(licensedUser()) {
            // Setup
            insertMockTestTool();

            List<Test__c> mockTests = new List<Test__c>{ getMockTest() };
            Id deploymentJobId = getMockDeploymentJob().Id;

            mockJobResponse();

            // Exercise
            Test.startTest();
            List<JobExecution__c> results = new RunTestsInExtension(mockTests).executeAsAutomation(deploymentJobId);
            Test.stopTest();

            // Verify
            System.assertEquals(1, results.size(), 'Only one Job Execution record expected');

            JobExecution__c immediateExecution = results[0];
            JobExecution__c updatedExecution = [SELECT DataJson__c, Status__c FROM JobExecution__c WHERE Id = :immediateExecution.Id];

            assertStatus(immediateExecution, updatedExecution);
            assertPayload(immediateExecution, idsOnly(mockTests), deploymentJobId);
        }
    }

    @isTest
    private static void executeAsAutomationWithoutExtensionSet() {
        System.runAs(licensedUser()) {
            // Setup
            Exception ex;

            Id deploymentJobId = getMockDeploymentJob().Id;

            // Exercise
            try {
                new RunTestsInExtension(new List<Test__c>{ getMockTest() }).executeAsAutomation(deploymentJobId);
            } catch (Exception e) {
                ex = e;
            }

            // Verify
            Deployment_Job__c job = [SELECT Status__c FROM Deployment_Job__c WHERE Id = :deploymentJobId];
            System.assertEquals('Failed', job.Status__c, 'Deployment Job Status should be failed');
        }
    }

    private static void assertStatus(JobExecution__c immediateExecution, JobExecution__c latestExecution) {
        System.assertEquals('Successful', latestExecution.Status__c, 'Job execution status after stop test should be Successful');
    }

    private static void assertPayload(JobExecution__c execution, List<Id> expectedTestIds, Id environmentId) {
        RunTestsExecutionPayload expectedPayload = new RunTestsExecutionPayload().tests(expectedTestIds);
        RunTestsExecutionPayload receivedPayload = (RunTestsExecutionPayload) JSON.deserialize(execution.dataJson__c, RunTestsExecutionPayload.class);

        System.assertEquals(environmentId, receivedPayload.environmentId, 'Environment should match');
        System.assertEquals(expectedTestIds.size(), receivedPayload.testIds.size(), 'Size of test ids should match');
        System.assertEquals(expectedPayload.testIds.size(), receivedPayload.testIds.size(), 'Size of test ids should match');

        for (Id testId : expectedPayload.testIds) {
            System.assert(receivedPayload.testIds.contains(testId), 'Received payload should contain the test id: ' + testId);
        }
    }

    private static void assertMockResult(Result__c mockResult) {
        System.assertEquals('Mock Type', mockResult.Job_Type__c, 'Result Job Type should be Mock Type');
        System.assertEquals('Success', mockResult.Progress_Status__c, 'Result Progress Status should be Success');
        System.assertEquals('Success', mockResult.Status__c, 'Result Status should be Success');
    }

    @TestSetup
    private static void insertData() {
        User licensedUser = createLicensedUser();

        System.runAs(licensedUser) {
            TestUtilities.assignLicense(String.valueOf(licensedUser.Username), true, true, true, true, true);
            createMockData();
        }
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
        TestTool__mdt testTool = insertMockTestTool();

        ExtensionConfiguration__c extConfig = createExtensionConfiguration(testTool);

        Test__c test1 = createTest('Mock Test 1', extConfig, '{}');
        Test__c test2 = createTest('Mock Test 2', extConfig, '{}');
        Test__c test3 = createTest('Mock Test 3', extConfig, '{}');
        Test__c test4 = createTest('Mock Test 4', extConfig, '{}');
        insert new List<Test__c>{ test1, test2, test3, test4 };

        Environment__c env1 = new Environment__c(Name = 'Mock Dev 1', Type__c = 'Sandbox');
        insert env1;

        Org__c org1 = new Org__c(
            Name = 'Mock Dev 1',
            Org_Type__c = 'Sandbox',
            Validated_Date__c = Datetime.now(),
            Environment__c = env1.Id,
            SFDC_Org_ID__c = 'SFDC_Dev1OrgId'
        );
        insert org1;

        Environment__c env2 = new Environment__c(Name = 'Mock Dev 2', Type__c = 'Sandbox');
        insert env2;

        Org__c org2 = new Org__c(
            Name = 'Mock Dev 1',
            Org_Type__c = 'Sandbox',
            Validated_Date__c = Datetime.now(),
            Environment__c = env2.Id,
            SFDC_Org_ID__c = 'SFDC_Dev2OrgId'
        );
        insert org2;

        Deployment__c deployment = new Deployment__c(Name = 'Mock Deployment', From_Org__c = org1.Id, Status__c = 'In progress');
        insert deployment;

        Destination_Org__c destinationOrg = new Destination_Org__c(Deployment__c = deployment.Id, Status__c = 'In progress', To_Org__c = org2.Id);
        insert destinationOrg;

        Step__c step = new Step__c(
            Name = 'Mock Step',
            dataJson__c = JSON.serialize(new AttachmentTriggerHelper.TestWrapper(test1.Id)),
            Deployment__c = deployment.Id,
            Order__c = 1,
            Status__c = 'In progress',
            Type__c = 'Test'
        );
        insert step;

        Deployment_Job__c deploymentJob = new Deployment_Job__c(
            Deployed__c = 1,
            Destination_Org__c = destinationOrg.Id,
            Status__c = 'In progress',
            Step__c = step.Id
        );
        insert deploymentJob;

        JobTemplate__c jobTemplate = (JobTemplate__c) new JobTemplate().add(new JobStep()).persist();
        jobTemplate.ApiName__c = JOB_TEMPLATE_NAME;
        update jobTemplate;
    }

    private static List<Test__c> getMockTests() {
        return [SELECT Name, ExtensionConfiguration__r.ExtensionTool__c, AcceptanceCriteria__c FROM Test__c];
    }

    private static Test__c getMockTest() {
        return [SELECT Name, ExtensionConfiguration__r.ExtensionTool__c, AcceptanceCriteria__c FROM Test__c LIMIT 1];
    }

    private static Deployment_Job__c getMockDeploymentJob() {
        return [SELECT Id FROM Deployment_Job__c LIMIT 1];
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

    private static Test__c createTest(String testName, ExtensionConfiguration__c extensionConfig, String acceptanceCriteria) {
        Test__c test = new Test__c(
            Name = testName,
            ExtensionConfiguration__c = extensionConfig.Id,
            AcceptanceCriteria__c = acceptanceCriteria,
            ReadyToRun__c = true
        );

        return test;
    }

    private static List<Id> idsOnly(List<SObject> records) {
        return new List<Id>(new Map<Id, SObject>(records).keySet());
    }
}