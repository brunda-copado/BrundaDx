@isTest
private class RunTestsAsAutomationTest {
    private static final String JOB_TEMPLATE_NAME = 'MockTemplate';

    @isTest
    private static void execute() {
        System.runAs(licensedUser()) {
            // Setup
            insertMockTestTool();

            Id mockTestId = getMockTest('Manual Tests').Id;
            Id deploymentJobId = getMockDeploymentJob('Mock Deployment').Id;

            mockJobResponse();

            // Exercise
            Test.startTest();
            System.enqueueJob(new RunTestsAsAutomation(new List<Id>{ mockTestId }, deploymentJobId));
            Test.stopTest();

            // Verify
            JobExecution__c execution = [SELECT DataJson__c, Status__c FROM JobExecution__c LIMIT 1];

            System.assertEquals('Successful', execution.Status__c, 'Job execution status after stop test should be Successful');
            assertPayload(execution, mockTestId, deploymentJobId);
        }
    }

    @isTest
    private static void executeWithoutExtensionSet() {
        System.runAs(licensedUser()) {
            // Setup
            Exception ex;

            Id deploymentJobId = getMockDeploymentJob('Mock Deployment').Id;

            // Exercise
            try {
                Test.startTest();
                System.enqueueJob(new RunTestsAsAutomation(new List<Id>{ getMockTest('Manual Tests').Id }, deploymentJobId));
                Test.stopTest();
            } catch (Exception e) {
                ex = e;
            }

            // Verify
            Deployment_Job__c job = [SELECT Status__c FROM Deployment_Job__c WHERE Id = :deploymentJobId];
            System.assertEquals('Failed', job.Status__c, 'Deployment Job Status should be failed');
        }
    }

    @isTest
    private static void executeForMultipleCrtTests() {
        System.runAs(licensedUser()) {
            // Setup
            insertMockCrtTestTool();

            List<Id> mockTestIds = getCRTMockTestIds('Copado Robotic Testing');
            Id deploymentJobId = getMockDeploymentJob('Mock CRT Deployment').Id;

            mockJobResponse();

            // Exercise
            Test.startTest();
            System.enqueueJob(new RunTestsAsAutomation(mockTestIds, deploymentJobId));
            Test.stopTest();

            // Verify
            JobExecution__c execution = [SELECT DataJson__c, Status__c FROM JobExecution__c LIMIT 1];
            System.assertEquals('Successful', execution.Status__c, 'Job execution status after stop test should be Successful');

            RunTestsExecutionPayload receivedPayload = (RunTestsExecutionPayload) JSON.deserialize(
                execution.dataJson__c,
                RunTestsExecutionPayload.class
            );

            System.assertEquals(deploymentJobId, receivedPayload.environmentId, 'Environment should match');
            System.assertEquals(2, receivedPayload.testIds.size(), 'Size of test ids should be 2');
        }
    }

    private static void assertStatus(JobExecution__c immediateExecution, JobExecution__c latestExecution) {
        System.assertEquals('In Progress', immediateExecution.Status__c, 'Job execution status before stop test should be In Progress');
        System.assertEquals('Successful', latestExecution.Status__c, 'Job execution status after stop test should be Successful');
    }

    private static void assertPayload(JobExecution__c execution, Id expectedTestId, Id environmentId) {
        RunTestsExecutionPayload receivedPayload = (RunTestsExecutionPayload) JSON.deserialize(execution.dataJson__c, RunTestsExecutionPayload.class);

        System.assertEquals(environmentId, receivedPayload.environmentId, 'Environment should match');
        System.assertEquals(1, receivedPayload.testIds.size(), 'Size of test ids should be 1');
        System.assertEquals(expectedTestId, receivedPayload.testIds[0], 'Received payload should contain the test id: ' + expectedTestId);
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
        TestTool__mdt testTool = insertMockTestTool();
        TestTool__mdt crtTestTool = insertMockCrtTestTool();

        ExtensionConfiguration__c extConfig = new ExtensionConfiguration__c(
            ExtensionTool__c = testTool.MasterLabel,
            ExtensionApplication__c = 'Test',
            Active__c = true
        );
        insert extConfig;

        ExtensionConfiguration__c crtExtConfig = new ExtensionConfiguration__c(
            ExtensionTool__c = crtTestTool.MasterLabel,
            ExtensionApplication__c = 'Test',
            Active__c = true
        );
        insert crtExtConfig;

        Test__c mockTest = new Test__c(Name = 'Mock Test', ExtensionConfiguration__c = extConfig.Id, ReadyToRun__c = true);
        insert mockTest;

        List<Test__c> crtTests = new List<Test__c>();
        for (Integer index = 0; index < 2; index++) {
            crtTests.add(new Test__c(Name = 'Mock CRT Test' + index, ExtensionConfiguration__c = crtExtConfig.Id, ReadyToRun__c = true));
        }
        insert crtTests;

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

        Deployment__c crtDeployment = new Deployment__c(Name = 'Mock CRT Deployment', From_Org__c = org1.Id, Status__c = 'In progress');
        insert crtDeployment;

        Destination_Org__c destinationOrg = new Destination_Org__c(Deployment__c = deployment.Id, Status__c = 'In progress', To_Org__c = org2.Id);
        insert destinationOrg;

        Step__c step = new Step__c(
            Name = 'Mock Step',
            dataJson__c = JSON.serialize(new AttachmentTriggerHelper.TestWrapper(mockTest.Id)),
            Deployment__c = deployment.Id,
            Order__c = 1,
            Status__c = 'In progress',
            Type__c = 'Test'
        );
        insert step;

        Step__c crtStep = new Step__c(
            Name = 'Mock CRT Step',
            dataJson__c = JSON.serialize(getTestIdsJson(crtTests)),
            Deployment__c = crtDeployment.Id,
            Order__c = 1,
            Status__c = 'In progress',
            Type__c = 'Test'
        );
        insert crtStep;

        Deployment_Job__c deploymentJob = new Deployment_Job__c(
            Deployed__c = 1,
            Destination_Org__c = destinationOrg.Id,
            Status__c = 'In progress',
            Step__c = step.Id
        );
        insert deploymentJob;

        Deployment_Job__c crtDeploymentJob = new Deployment_Job__c(
            Deployed__c = 1,
            Destination_Org__c = destinationOrg.Id,
            Status__c = 'In progress',
            Step__c = crtStep.Id
        );
        insert crtDeploymentJob;

        JobTemplate__c jobTemplate = (JobTemplate__c) new JobTemplate().add(new JobStep()).persist();
        jobTemplate.ApiName__c = JOB_TEMPLATE_NAME;
        update jobTemplate;
    }

    private static Test__c getMockTest(String tool) {
        return [SELECT Name FROM Test__c WHERE ExtensionConfiguration__r.ExtensionTool__c = :tool LIMIT 1];
    }

    private static List<Id> getCRTMockTestIds(String tool) {
        List<Id> testIds = new List<Id>();
        for (Test__c test : [SELECT Id FROM Test__c WHERE ExtensionConfiguration__r.ExtensionTool__c = :tool]) {
            testIds.add(test.Id);
        }
        return testIds;
    }

    private static Deployment_Job__c getMockDeploymentJob(String name) {
        return [SELECT Id FROM Deployment_Job__c WHERE Step__r.Deployment__r.Name = :name LIMIT 1];
    }

    private static TestTool__mdt insertMockTestTool() {
        TestTool__mdt mockTestTool = new TestTool__mdt(MasterLabel = 'Manual Tests', JobTemplate__c = JOB_TEMPLATE_NAME, TestType__c = 'Mock Type');

        TestToolsSelector.mock(new List<TestTool__mdt>{ mockTestTool });
        return mockTestTool;
    }

    private static TestTool__mdt insertMockCrtTestTool() {
        TestTool__mdt mockTestTool = new TestTool__mdt(
            MasterLabel = 'Copado Robotic Testing',
            JobTemplate__c = JOB_TEMPLATE_NAME,
            TestType__c = 'Functional Test'
        );

        TestToolsSelector.mock(new List<TestTool__mdt>{ mockTestTool });
        return mockTestTool;
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

    private static String getTestIdsJson(List<Test__c> tests) {
        return '{"testIds":["' + tests[0].Id + '","' + tests[1].Id + '"],"testNames":["' + tests[0].Name + '"]}';
    }
}