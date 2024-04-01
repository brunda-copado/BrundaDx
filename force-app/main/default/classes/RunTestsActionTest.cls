@IsTest
private class RunTestsActionTest { //NOPMD
    private static final String JOB_TEMPLATE_NAME = 'MockTemplate';
    private static final String EXTENSION_CONFIGURATION_NAME = 'Extension Configuration 1';
    private static final String TEST_TOOL_NAME = 'Manual Tests';
    private static final String MOCK_ACTION_CALLBACK = 'MockRunTestsActionCallback';
    private static final String MOCK_ACCEPTANCE_CRITERIA = '{"criteria1": "mockCriteria1", "criteria2": 1}';

    @TestSetup
    private static void setup() {
        TestUtilities.getAllMultilicense();
        User user = (User) new User_t()
            // @ToDo: To be replaced by AQF Perm sets
            .assign(new PermissionSetAssignment_t().copadoUser())
            .assign(new PermissionSetAssignment_t().jobEngine())
            .assign(new PermissionSetAssignment_t().qualityGatesAdmin())
            .persist();
        System.runAs(user) {
            new CopadoLicense().user(user).enableAll().persist();
            insertData();
        }
    }

    @IsTest
    private static void execute() {
        System.runAs(getRunAsUser()) {
            // Setup
            insertMockTestTool();
            List<Id> contextIds = createContextRecordsForHappyPath();
            RunTestsAction.Request request = createRunTestsActionRequest(contextIds, null, MOCK_ACTION_CALLBACK);
            mockJobResponse();

            // Exercise
            Test.startTest();
            RunTestsAction.execute(new List<RunTestsAction.Request>{ request });
            Test.stopTest();

            // Verify
            List<JobExecution__c> executions = [SELECT DataJson__c, Status__c, Source__c, Pipeline__c, ParentId__c, Job_Step__c FROM JobExecution__c];
            System.assertEquals(
                JobExecutionConstants.STATUS_SUCCESSFUL,
                executions[0].Status__c,
                'Job execution status after stop test should be Successful'
            );
            System.assert(executions[0].ParentId__c != null, 'Job execution parent Id is not null');
            System.assertEquals(null, executions[0].Job_Step__c, 'Non JE doesn\'t have a related job step');
            assertPayload(executions[0], true);
            assertTests(contextIds, executions[0]);
            assertContextParams(contextIds, executions);
        }
    }

    @IsTest
    private static void executeWithoutActionCallback() {
        System.runAs(getRunAsUser()) {
            // Setup
            insertMockTestTool();
            List<Id> contextIds = createContextRecordsForHappyPath();
            RunTestsAction.Request request = createRunTestsActionRequest(contextIds, null, null);
            mockJobResponse();

            // Exercise
            Test.startTest();
            RunTestsAction.execute(new List<RunTestsAction.Request>{ request });
            Test.stopTest();

            // Verify
            List<JobExecution__c> executions = [SELECT DataJson__c, Status__c, Source__c, Pipeline__c, ParentId__c, Job_Step__c FROM JobExecution__c];
            System.assertEquals(
                JobExecutionConstants.STATUS_SUCCESSFUL,
                executions[0].Status__c,
                'Job execution status after stop test should be Successful'
            );
            System.assertEquals(null, executions[0].Job_Step__c, 'Non JE doesn\'t have a related job step');
            System.assert(executions[0].ParentId__c != null, 'Job execution parent Id is not null');
            assertPayload(executions[0], false);
            assertTests(contextIds, executions[0]);
            assertContextParams(contextIds, executions);
        }
    }

    @IsTest
    private static void failWithoutTestToolMetadataType() {
        System.runAs(getRunAsUser()) {
            // Setup
            TestToolsSelector.mock(new List<TestTool__mdt>());

            Test__c mockTest = createTest(getMockExtensionConfiguration());
            RunTestsAction.Request request = createRunTestsActionRequest(new List<Id>{ mockTest.Id }, null, null);

            // Exercise
            Test.startTest();
            RunTestsAction.execute(new List<RunTestsAction.Request>{ request });
            Test.stopTest();

            JobExecution__c execution = [SELECT ErrorMessage__c, Status__c FROM JobExecution__c LIMIT 1];

            // Verify
            System.assertEquals(JobExecutionConstants.STATUS_ERROR, execution.Status__c, 'Job execution status should be Error');
            System.assert(
                execution.errorMessage__c.contains(Label.MissingTestTool),
                'Expected Job Execution with error message: ' + Label.MissingTestTool
            );
        }
    }

    @IsTest
    private static void autoCreateTests() {
        System.runAs(getRunAsUser()) {
            // Setup
            insertBothMockTestTool();
            Result__c consolidatedResult = getQgJobStepResultWithNoneAsTool();
            RunTestsAction.Request request = createRunTestsActionRequestWithMockNoneTool(consolidatedResult.Id);
            mockJobResponse();

            // Exercise
            Test.startTest();
            RunTestsAction.Response response = RunTestsAction.execute(new List<RunTestsAction.Request>{ request })[0];
            Test.stopTest();

            JobExecution__c execution = [
                SELECT ErrorMessage__c, Status__c, dataJson__c
                FROM JobExecution__c
                WHERE Id = :response.jobExecution.Id
                LIMIT 1
            ];
            Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(execution.dataJson__c);

            // Verify
            System.assertEquals(JobExecutionConstants.STATUS_SUCCESSFUL, execution.Status__c, 'Job execution status should be Successful');
            assertConsolidatedResult(payload, ResultConstants.STATUS_SUCCESS, consolidatedResult.Id);
            System.assertEquals(
                1,
                [SELECT COUNT() FROM Test__c WHERE Promotion__c = :getPromotion().Id],
                'One test should be autocreated and linked to the promotion'
            );
            assertSubJobPayload(execution, consolidatedResult.Id);
        }
    }

    @IsTest
    private static void verifyResultWithAllTestSuccess() {
        System.runAs(getRunAsUser()) {
            // Setup
            insertMockTestTool();
            List<Id> contextIds = createContextRecordsForHappyPath();
            RunTestsAction.Request request = createRunTestsActionRequest(contextIds, null, MOCK_ACTION_CALLBACK);
            mockJobResponse();

            // Exercise
            Test.startTest();
            RunTestsAction.execute(new List<RunTestsAction.Request>{ request });
            updateResults([SELECT id, name FROM Result__c WHERE status__c = :ResultConstants.STATUS_IN_PROGRESS]);
            Test.stopTest();

            // Verify
            List<JobExecution__c> executions = [
                SELECT DataJson__c, Status__c, Source__c, Pipeline__c, ParentId__c, Job_Step__c, ErrorMessage__c
                FROM JobExecution__c
            ];

            System.assertEquals(
                JobExecutionConstants.STATUS_SUCCESSFUL,
                executions[0].Status__c,
                'Job execution status after stop test should be Successful'
            );
            System.assertEquals(null, executions[0].Job_Step__c, 'Job Step is null');
            System.assert(executions[0].ParentId__c != null, 'Job execution parent Id is not null');
            assertPayload(executions[0], true);
            assertContextParams(contextIds, executions);

            createMockNotifications();
            new RunTestServiceImpl().execute(executions[0], JobExecutionConstants.STATUS_SUCCESSFUL);
            System.assertEquals(1, Limits.getEmailInvocations(), 'One email should be sent');
        }
    }

    @IsTest
    private static void verifyConsolidatedResultQualityGateContext() {
        System.runAs(getRunAsUser()) {
            // Setup
            insertMockTestTool();
            List<Id> contextIds = createContextRecordsForHappyPath();
            RunTestsAction.Request request = createRunTestsActionRequest(contextIds, getQgJobStepResult().Id, MOCK_ACTION_CALLBACK);
            mockJobResponse();

            // Exercise
            Test.startTest();
            RunTestsAction.Response response = RunTestsAction.execute(new List<RunTestsAction.Request>{ request })[0];
            Test.stopTest();

            JobExecution__c execution = [
                SELECT Source__c, Destination__c, Status__c, DataJson__c, Pipeline__c, Job_Step__c, ErrorMessage__c
                FROM JobExecution__c
                WHERE Id = :response.jobExecution.Id
                LIMIT 1
            ];
            Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(execution.dataJson__c);
            Id resultId = (Id) payload.get('resultId');
            Result__c result = [
                SELECT
                    Id,
                    JobStep__c,
                    JobStep__r.Source_Id__c,
                    JobStep__r.Destination_Id__c,
                    JobStep__r.Pipeline_Id__c,
                    JobStep__r.JobExecution__r.DataJson__c,
                    JobStep__r.JobExecution__r.ParentId__c
                FROM Result__c
                WHERE Id = :resultId
            ];

            // Verify
            System.assertEquals(JobExecutionConstants.STATUS_SUCCESSFUL, execution.Status__c, 'Job execution status should be Successful');
            System.assertEquals(result.JobStep__r.Source_Id__c, execution.Source__c, 'Source value should be present on Job Execution');
            System.assertEquals(result.JobStep__c, execution.Job_Step__c, 'For QG sub JE, Job step is populated');
            System.assertEquals(
                result.JobStep__r.Destination_Id__c,
                execution.Destination__c,
                'Destination value should be present on Job Execution'
            );
            System.assertEquals(result.JobStep__r.Pipeline_Id__c, execution.Pipeline__c, 'Pipeline value should be present on Job Execution');
            assertConsolidatedResult(payload, ResultConstants.STATUS_SUCCESS, (Id) payload.get('resultId'));
            assertSizeOfResults(0);
            assertCallback();
            assertSubJobPayload(execution, result.Id);

            createMockNotifications();
            updateResults(new List<Result__c>{ result });
            new RunTestServiceImpl().execute(execution, JobExecutionConstants.STATUS_SUCCESSFUL);
            System.assertEquals(1, Limits.getEmailInvocations(), 'One email should be sent');
        }
    }

    // PRIVATE

    private static void mockJobResponse() {
        Flow.mockResponse = flowCompletionEvent();
    }

    private static void assertPayload(JobExecution__c execution, Boolean withCallback) {
        RunTestsExecutionPayload expectedPayload = getExpectedPayload(10, 0);

        RunTestsExecutionPayload receivedPayload = getReceivedPayload(execution);

        if (withCallback) {
            System.assertEquals(expectedPayload.actionCallback, receivedPayload.actionCallback, 'Action callback should match');
        }

        System.assertEquals(null, receivedPayload.environmentId, 'Environment should match');
        System.assertEquals(10, receivedPayload.testIds.size(), 'Size of test ids should be 10');
        System.assertEquals(expectedPayload.testIds.size(), receivedPayload.testIds.size(), 'Size of test ids should match');

        if (receivedPayload.resultId == null) {
            System.assertEquals(10, expectedPayload.resultIds.size(), 'Size of valid test ids should be equal to number of results');
        } else {
            System.assertEquals(true, String.isNotBlank(receivedPayload.resultId), 'Consolidated Result record should be created');
        }

        System.assertEquals(
            expectedPayload.acceptanceCriteria,
            receivedPayload.acceptanceCriteria,
            'Acceptance criteria should be: ' + MOCK_ACCEPTANCE_CRITERIA
        );

        for (Id testId : expectedPayload.testIds) {
            System.assert(receivedPayload.testIds.contains(testId), 'Received payload should contain the test id: ' + testId);
        }

        System.assertEquals(true, String.isNotBlank(receivedPayload.extensionConfigurationId), 'Extension Configuration Id should be available.');
    }

    private static void assertTests(List<Id> parentIds, JobExecution__c execution) {
        for (Test__c test : new TestsSelector().byParents(new Set<Id>(parentIds))) {
            System.assertEquals(execution.Id, test.LatestJobExecution__c, 'Test should populate with latest execution Id');
        }
    }

    private static void assertContextParams(List<Id> parentIds, List<JobExecution__c> executions) {
        Map<Id, JobExecution__c> executionsByParentId = new Map<Id, JobExecution__c>();
        for (JobExecution__c execution : executions) {
            executionsByParentId.put(execution.ParentId__c, execution);
        }

        for (Test__c test : new TestsSelector().byParents(new Set<Id>(parentIds))) {
            if (test.User_Story__c != null && executionsByParentId.containsKey(test.Id)) {
                System.assertEquals(
                    test.User_Story__r.Environment__c,
                    executionsByParentId.get(test.Id).Source__c,
                    'Job execution source is the source of related US'
                );
                System.assertEquals(
                    test.User_Story__r.Project__r.Deployment_Flow__c,
                    executionsByParentId.get(test.Id).Pipeline__c,
                    'Job execution pipeline is the pipeline of related US'
                );
            }
        }
    }

    private static void assertSubJobPayload(JobExecution__c execution, Id resultId) {
        Map<String, Object> expectedPayload = createSubJobExpectedPayload(resultId);
        Map<String, Object> receivedPayload = (Map<String, Object>) JSON.deserializeUntyped(execution.dataJson__c);

        System.assertEquals(expectedPayload.get('promotionId'), receivedPayload.get('promotionId'), 'Promotion Id should match');
        System.assertEquals(expectedPayload.get('promotionBranchName'), receivedPayload.get('promotionBranchName'), 'Promotion Id should match');
        System.assertEquals(expectedPayload.get('isBackPromotion'), receivedPayload.get('isBackPromotion'), 'Promotion Id should match');
        System.assertEquals(expectedPayload.get('executePromotion'), receivedPayload.get('executePromotion'), 'Promotion Id should match');
        System.assertEquals(expectedPayload.get('destinationBranchName'), receivedPayload.get('destinationBranchName'), 'Promotion Id should match');
    }

    private static Map<String, Object> createSubJobExpectedPayload(Id resultId) {
        return new Map<String, Object>{
            'promotionId' => 'a12XXXXXXXXXX',
            'promotionBranchName' => 'promotion/P02576',
            'isBackPromotion' => false,
            'executePromotion' => true,
            'executeDeployment' => true,
            'destinationBranchName' => 'main',
            'deploymentDryRun' => false,
            'acceptanceCriteria' => '{}',
            'resultId' => resultId
        };
    }

    private static RunTestsExecutionPayload getExpectedPayload(Integer validTests, Integer ignoredTests) {
        return new RunTestsExecutionPayload()
            .tests(getTestIds(validTests, 'ASC'))
            .ignoredTests(getTestIds(ignoredTests, 'DESC'))
            .callback(MOCK_ACTION_CALLBACK)
            .acceptanceCriteria(MOCK_ACCEPTANCE_CRITERIA)
            .results(getResults(getTestIds(validTests, 'ASC')));
    }

    private static RunTestsExecutionPayload getReceivedPayload(JobExecution__c execution) {
        return (RunTestsExecutionPayload) JSON.deserialize(execution.dataJson__c, RunTestsExecutionPayload.class);
    }

    private static void assertCallback() {
        Result__c result = [SELECT Description__c FROM Result__c WHERE Job_Type__c = :'Mock Run Tests Result' LIMIT 1];
        System.assertEquals(
            'Mock Run Tests Description',
            result.Description__c,
            'Mock Run Test Action callback should have updated a result description'
        );
    }

    private static void assertConsolidatedResult(Map<String, Object> payload, String expectedStatus, Id resultId) {
        resultId = resultId != null ? resultId : (Id) payload.get('resultId');
        Result__c result = new ResultsSelector().byId(resultId);

        System.assertEquals(expectedStatus, result.Status__c, 'Consolidated Result status should be ' + expectedStatus);

        List<Object> ignoredTestIds = (List<Object>) payload.get('ignoredTestIds');
        if (payload != null) {
            for (Object id : ignoredTestIds) {
                System.assertEquals(true, result.Result_Data__c.contains((Id) id), 'Result_Data__c should contain ID: ' + id);
            }
        } else {
            System.assertEquals(
                true,
                result.Result_Data__c.containsIgnoreCase(Label.NoTestsFound),
                'Result_Data__c should contain ' + Label.NoTestsFound
            );
        }
    }

    private static User getRunAsUser() {
        return [SELECT Id FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1];
    }

    private static Result__c getQgJobStepResultWithNoneAsTool() {
        List<Environment__c> envList = TestDataFactory.createEnvironments(2);
        JobTemplate__c template = new JobTemplate__c(Name = 'Test Template', Version__c = 1);
        insert template;

        createParentData();

        JobExecution__c parentJobExecution = new JobExecution__c();
        parentJobExecution.Template__c = template.Id;
        parentJobExecution.Source__c = envList[0].Id;
        parentJobExecution.Destination__c = envList[1].Id;
        parentJobExecution.Promotion__c = getPromotion().Id;
        parentJobExecution.ParentRecord_Id__c = parentJobExecution.Promotion__c;
        parentJobExecution.DataJson__c = '{\"promotionId\":\"a12XXXXXXXXXX\",\"promotionBranchName\":\"promotion/P02576\",\"isBackPromotion\":false,\"executePromotion\":true,\"executeDeployment\":true,\"destinationBranchName\":\"main\",\"deploymentDryRun\":false}"';
        insert parentJobExecution;

        Quality_Gate_Rule__c rule = (Quality_Gate_Rule__c) new QualityGateRule()
            .action('Promotion')
            .sequence('After')
            .tool('None')
            .active(false)
            .add(
                new QualityGateRuleCondition()
                    .platform('Other')
                    .environment(new Environment().platform('Other'))
                    .extensionConfiguration(getMockExtensionConfiguration().id)
            )
            .persist();

        rule.Status__c = QualityGateConstants.ACTIVE;
        update rule;

        JobStep__c jobStep = new JobStep__c(
            Type__c = 'Test',
            CustomType__c = 'Test',
            Name = 'Quality Gate Test Step',
            ExecutionSequence__c = 'before',
            JobTemplate__c = template.Id,
            JobExecution__c = parentJobExecution.Id,
            Quality_Gate_Rule__c = rule.Id
        );
        insert jobStep;

        Result__c result = new Result__c(Job_Type__c = TEST_TOOL_NAME, JobStep__c = jobStep.id);
        insert result;
        return result;
    }

    private static Result__c getQgJobStepResult() {
        List<Environment__c> envList = TestDataFactory.createEnvironments(2);
        JobTemplate__c template = new JobTemplate__c(Name = 'Test Template', Version__c = 1);
        insert template;

        createOrg('Dev1', 'Production', '000000000000000001', 'SFDC_TOKEN', 'USERNAME', System.now(), envList[0].Id);
        createOrg('Dev2', 'Production', '000000000000000002', 'SFDC_TOKEN1', 'USERNAME1', System.now(), envList[1].Id);

        Id repoId = createGitRepository().Id;
        Id pipelineId = createDeploymentFlow('My Pipeline', true, repoId).Id;
        createDeploymentFlowStep(envList[0].Id, envList[1].Id, pipelineId);

        Id projectId = createProject('My Project', pipelineId);
        Id promotionId = createPromotion(projectId, envList[0].Id, envList[1].Id);
        createDeployment(promotionId);

        JobExecution__c parentJobExecution = new JobExecution__c();
        parentJobExecution.Template__c = template.Id;
        parentJobExecution.Source__c = envList[0].Id;
        parentJobExecution.Destination__c = envList[1].Id;
        parentJobExecution.Promotion__c = promotionId;
        parentJobExecution.ParentRecord_Id__c = promotionId;
        parentJobExecution.Pipeline__c = pipelineId;
        parentJobExecution.DataJson__c = '{\"promotionId\":\"a12XXXXXXXXXX\",\"promotionBranchName\":\"promotion/P02576\",\"isBackPromotion\":false,\"executePromotion\":true,\"executeDeployment\":true,\"destinationBranchName\":\"main\",\"deploymentDryRun\":false}"';
        insert parentJobExecution;

        JobStep__c jobStep = new JobStep__c(
            Type__c = 'Test',
            CustomType__c = 'Test',
            Name = 'Quality Gate Test Step',
            ExecutionSequence__c = 'before',
            JobTemplate__c = template.Id,
            JobExecution__c = parentJobExecution.Id
        );
        insert jobStep;

        Result__c result = new Result__c(Job_Type__c = TEST_TOOL_NAME, JobStep__c = jobStep.id);
        insert result;
        return result;
    }

    private static List<Id> getTestIds(Integer noOfTests, String order) {
        String query = 'SELECT Id FROM Test__c ORDER BY Reference__c ' + order + ' LIMIT ' + noOfTests;
        List<Test__c> tests = Database.query(query);
        return idsOnly(tests);
    }

    private static List<Id> idsOnly(List<SObject> records) {
        return new List<Id>(new Map<Id, SObject>(records).keySet());
    }

    private static void insertData() {
        createExtensionConfiguration();

        JobTemplate__c jobTemplate = (JobTemplate__c) new JobTemplate().add(new JobStep()).persist();
        jobTemplate.ApiName__c = JOB_TEMPLATE_NAME;
        update jobTemplate;
    }

    private static void createParentData() {
        Id sourceEnvId = createEnvironment('Dev1', '000000000000000001');
        Id sourceOrgId = createOrg('Dev1', 'Production', '000000000000000001', 'SFDC_TOKEN', 'USERNAME', System.now(), sourceEnvId).Id;

        Id destinationEnvId = createEnvironment('Dev2', '000000000000000002');
        createOrg('Dev2', 'Production', '000000000000000002', 'SFDC_TOKEN1', 'USERNAME1', System.now(), destinationEnvId);

        Id repoId = createGitRepository().Id;
        Id pipelineId = createDeploymentFlow('My Pipeline', true, repoId).Id;
        createDeploymentFlowStep(sourceEnvId, destinationEnvId, pipelineId);

        Id projectId = createProject('My Project', pipelineId);
        Id promotionId = createPromotion(projectId, sourceEnvId, destinationEnvId);

        createDeployment(promotionId);

        Git_Backup__c snapshot = createGitBackup('Commit Metadata', sourceOrgId, repoId);
        Git_Org_Commit__c orgCommit = createGitOrgCommit(snapshot.Id, sourceOrgId);

        User_Story__c us = createUserStory(projectId, sourceOrgId, sourceEnvId);
        createUserStoryCommit(us, orgCommit);
    }

    private static List<Id> createContextRecordsForHappyPath() {
        Application__c application1 = new Application__c();
        insert application1;

        Application_Feature__c feature1 = new Application_Feature__c();
        insert feature1;

        Id sourceEnvId = createEnvironment('Dev1', '000000000000000001');
        Id pipelineId = createDeploymentFlow('My Pipeline', true, createGitRepository().Id).Id;
        Id projectId = createProject('My Project', pipelineId);

        User_Story__c userStory1 = createUserStory(projectId, null, sourceEnvId);

        ExtensionConfiguration__c extensionConfiguration = getMockExtensionConfiguration();

        Test__c test1 = new Test__c(
            Name = 't1',
            Configuration__c = 't1',
            ExtensionConfiguration__c = extensionConfiguration.Id,
            ReadyToRun__c = true
        );
        Test__c test2 = new Test__c(
            Name = 't2',
            Configuration__c = 't2',
            ExtensionConfiguration__c = extensionConfiguration.Id,
            ReadyToRun__c = true
        );
        Test__c test3 = new Test__c(
            Name = 't3',
            Configuration__c = 't3',
            ExtensionConfiguration__c = extensionConfiguration.Id,
            User_Story__c = userStory1.Id,
            ReadyToRun__c = true
        );
        Test__c test4 = new Test__c(
            Name = 't4',
            Configuration__c = 't4',
            ExtensionConfiguration__c = extensionConfiguration.Id,
            User_Story__c = userStory1.Id,
            ReadyToRun__c = true
        );
        Test__c test5 = new Test__c(
            Name = 't5',
            Configuration__c = 't5',
            ExtensionConfiguration__c = extensionConfiguration.Id,
            Feature__c = feature1.Id,
            ReadyToRun__c = true
        );
        Test__c test6 = new Test__c(
            Name = 't6',
            Configuration__c = 't6',
            ExtensionConfiguration__c = extensionConfiguration.Id,
            Feature__c = feature1.Id,
            ReadyToRun__c = true
        );
        Test__c test7 = new Test__c(
            Name = 't7',
            Configuration__c = 't7',
            ExtensionConfiguration__c = extensionConfiguration.Id,
            Application__c = application1.Id,
            ReadyToRun__c = true
        );
        Test__c test8 = new Test__c(
            Name = 't8',
            Configuration__c = 't8',
            ExtensionConfiguration__c = extensionConfiguration.Id,
            Application__c = application1.Id,
            ReadyToRun__c = true
        );
        Test__c test9 = new Test__c(
            Name = 't9',
            Configuration__c = 't9',
            ExtensionConfiguration__c = extensionConfiguration.Id,
            Application__c = application1.Id,
            ReadyToRun__c = true
        );
        Test__c test10 = new Test__c(
            Name = 't10',
            Configuration__c = 't10',
            ExtensionConfiguration__c = extensionConfiguration.Id,
            Application__c = application1.Id,
            ReadyToRun__c = true
        );

        List<Test__c> tests = new List<Test__c>{ test1, test2, test3, test4, test5, test6, test7, test8, test9, test10 };
        insert tests;

        return new List<Id>{ test1.Id, test2.Id, userStory1.Id, feature1.Id, application1.Id };
    }

    private static void assertSizeOfResults(Integer validTests) {
        System.assertEquals(
            validTests,
            [SELECT COUNT() FROM Result__c WHERE Test__c != NULL AND Job_Type__c = :TEST_TOOL_NAME],
            'Number of valid tests should be equal to number of results'
        );
    }

    private static Map<Id, Test__c> getTests(List<Id> tests) {
        return new Map<Id, Test__c>([SELECT ExtensionConfiguration__r.ExtensionTool__c FROM Test__c WHERE Id IN :tests]);
    }

    private static List<Id> getResults(List<Id> tests) {
        return new List<Id>(new Map<Id, Result__c>([SELECT status__c FROM Result__c WHERE Test__c IN :tests]).keySet());
    }

    private static void updateResults(List<Result__c> results) {
        for (Result__c result : results) {
            result.Status__c = 'Success';
            result.Progress_Status__c = 'Success';
        }
        update results;
    }

    private static TestTool__mdt insertMockTestTool() {
        TestTool__mdt mockTestTool = new TestTool__mdt(MasterLabel = TEST_TOOL_NAME, JobTemplate__c = JOB_TEMPLATE_NAME, TestType__c = 'Mock Type');
        TestToolsSelector.mock(new List<TestTool__mdt>{ mockTestTool });
        return mockTestTool;
    }

    private static void insertBothMockTestTool() {
        TestToolsSelector.mock(
            new List<TestTool__mdt>{
                new TestTool__mdt(
                    MasterLabel = 'None',
                    JobTemplate__c = JOB_TEMPLATE_NAME,
                    TestType__c = 'Mock Type',
                    Automate_Test_Readiness__c = true,
                    Test_Readiness_Logic__c = ''
                ),
                new TestTool__mdt(
                    MasterLabel = TEST_TOOL_NAME,
                    JobTemplate__c = JOB_TEMPLATE_NAME,
                    TestType__c = 'Mock Type',
                    Automate_Test_Readiness__c = true,
                    Test_Readiness_Logic__c = ''
                )
            }
        );
    }

    private static void createExtensionConfiguration() {
        insert new ExtensionConfiguration__c(
            Name = EXTENSION_CONFIGURATION_NAME,
            ExtensionApplication__c = 'Test',
            ExtensionTool__c = TEST_TOOL_NAME,
            Active__c = true
        );
    }

    public static Test__c createTest(ExtensionConfiguration__c extensionConfig) {
        Test__c test = new Test__c(Name = 'Mock Test', ExtensionConfiguration__c = extensionConfig.Id, ReadyToRun__c = true);

        insert test;
        return test;
    }

    private static ExtensionConfiguration__c getMockExtensionConfiguration() {
        return [SELECT Id FROM ExtensionConfiguration__c LIMIT 1];
    }

    private static Event__e flowCompletionEvent() {
        Event__e result = new Event__e();
        result.Topic_Uri__c = OnJobStepComplete.STEP_ENDPOINT;
        result.Payload__c = Json.serialize(new OnJobStepComplete.EventPayload(true, '', 'Success data 1'));

        return result;
    }

    private static RunTestsAction.Request createRunTestsActionRequest(List<Id> contextIds, Id consolidatedResultId, String actionCallback) {
        return new RunTestsAction.Request()
            .tool(TEST_TOOL_NAME)
            .context(contextIds)
            .actionCallback(actionCallback)
            .acceptanceCriteria(MOCK_ACCEPTANCE_CRITERIA)
            .extensionConfigurationId(getMockExtensionConfiguration().id)
            .result(consolidatedResultId);
    }

    private static RunTestsAction.Request createRunTestsActionRequestWithMockNoneTool(Id consolidatedResultId) {
        return new RunTestsAction.Request()
            .tool('None')
            .context(new List<Id>())
            .actionCallback(null)
            .acceptanceCriteria(MOCK_ACCEPTANCE_CRITERIA)
            .extensionConfigurationId(getMockExtensionConfiguration().id)
            .result(consolidatedResultId);
    }

    public static Id createEnvironment(String name, String orgId) {
        Environment__c env = new Environment__c();
        env.Name = name;
        env.org_id__c = orgId;
        insert env;
        return env.Id;
    }

    @SuppressWarnings('PMD.ExcessiveParameterList')
    private static Org__c createOrg(String name, String orgType, String sfdcorgid, String token, String un, DateTime vd, Id envId) {
        //NOPMD
        Org__c org = new Org__c();
        org.name = name;
        org.Org_Type__c = orgType;
        org.SFDC_Org_ID__c = sfdcorgid;
        org.Token__c = token;
        org.Username__c = un;
        org.Validated_Date__c = vd;
        org.Environment__c = envId;
        insert org;
        return org;
    }

    public static Git_Repository__c createGitRepository() {
        Git_Repository__c repo = new Git_Repository__c();
        repo.Name = 'test repo';
        insert repo;
        return repo;
    }

    public static Deployment_Flow__c createDeploymentFlow(String name, Boolean isActive, Id gitRepositoryId) {
        // NOPMD : Supressing rule to avoid large refactor.
        Deployment_Flow__c deploymentFlow = new Deployment_Flow__c();
        deploymentFlow.Name = name;
        deploymentFlow.Active__c = isActive;
        deploymentFlow.Git_Repository__c = gitRepositoryId;
        deploymentFlow.Main_Branch__c = 'main';
        insert deploymentFlow;
        return deploymentFlow;
    }

    public static Deployment_Flow_Step__c createDeploymentFlowStep(Id sourceEnvironmentId, Id destinationEnvironmentId, Id deploymentFlowId) {
        // NOPMD : Supressing rule to avoid large refactor.
        Deployment_Flow_Step__c deploymentFlowStep = new Deployment_Flow_Step__c();
        deploymentFlowStep.Source_Environment__c = sourceEnvironmentId;
        deploymentFlowStep.Destination_Environment__c = destinationEnvironmentId;
        deploymentFlowStep.Deployment_Flow__c = deploymentFlowId;
        deploymentFlowStep.Branch__c = 'dev1';

        insert deploymentFlowStep;
        return deploymentFlowStep;
    }

    private static void createDeployment(Id promotionId) {
        Deployment__c dep = new Deployment__c();
        dep.Name = 'dep1';
        dep.Promotion__c = promotionId;
        insert dep;
    }

    public static Git_Backup__c createGitBackup(String name, String orgId, String repositoryId) {
        Git_Backup__c gitBackup = new Git_Backup__c();
        gitBackup.Name = name;
        gitBackup.Git_Repository__c = repositoryId;
        gitBackup.Org__c = orgId;
        insert gitBackup;

        return gitBackup;
    }

    private static Git_Org_Commit__c createGitOrgCommit(Id snapshotId, Id orgId) {
        // NOPMD : Supressing rule to avoid large refactor.
        Git_Org_Commit__c gitOrgCommit = new Git_Org_Commit__c();
        gitOrgCommit.Commit_Id__c = 'Bundle Metadata';
        gitOrgCommit.Commit_Date__c = Date.today();
        gitOrgCommit.Git_Backup__c = snapshotId;
        gitOrgCommit.Org__c = orgId;
        gitOrgCommit.Status__c = 'Complete';
        gitOrgCommit.Git_Operation__c = 'Commit Files';
        insert gitOrgCommit;

        return gitOrgCommit;
    }

    public static Id createPromotion(Id projectId, Id sourceEnvId, Id destinationEnvId) {
        Promotion__c promotion = new Promotion__c();
        promotion.Project__c = projectId;
        promotion.Source_Environment__c = sourceEnvId;
        Org__c org = [SELECT Id FROM Org__c WHERE name = 'Dev1' LIMIT 1];
        promotion.Source_Org_Credential__c = org.Id;
        Org__c org1 = [SELECT Id FROM Org__c WHERE name = 'Dev2' LIMIT 1];
        promotion.Destination_Environment__c = destinationEnvId;
        promotion.Destination_Org_Credential__c = org1.Id;

        insert promotion;
        return promotion.Id;
    }

    public static Id createProject(String name, Id deploymentFlowId) {
        Project__c project = new Project__c();
        project.Name = name;
        project.Deployment_Flow__c = deploymentFlowId;
        insert project;
        return project.Id;
    }

    private static User_Story__c createUserStory(Id projectId, Id credentialId, Id envId) {
        User_Story__c us = new User_Story__c();
        us.Project__c = projectId;
        us.Environment__c = envId;
        us.Org_Credential__c = credentialId;

        insert us;
        return us;
    }

    private static void createUserStoryCommit(User_Story__c us, Git_Org_Commit__c orgCommit) {
        User_Story_Commit__c usc = new User_Story_Commit__c(User_Story__c = us.Id, Snapshot_Commit__c = orgCommit.Id);
        insert usc;
    }

    private static void createMockNotifications() {
        NotificationsSelector.mockNotifications = new List<MC_Notification__mdt>{
            new MC_Notification__mdt(
                DeveloperName = 'Test_Success',
                Active__c = true,
                Subject__c = '{TestName} - Success',
                Template__c = 'Hi {UserName},<br/><br/>The test <b> <a href=”{TestNameLink}”>{TestName}</a></b> ended with a Success status. Please refer to the result <b><a href=”{TestResultLink}”>{TestResultName}</a></b> for further details.'
            ),
            new MC_Notification__mdt(
                DeveloperName = 'Quality_Gate_Success',
                Active__c = true,
                Subject__c = '{QualityGateRuleName} - Success',
                Template__c = 'Hi {UserName},<br/><br/>The Quality Gate <b> <a href=”{QualityGateRuleJobStepLink}”> {QualityGateRuleName}</a></b> for this <b> <a href=”{ParentContextLink}”>{ParentContextName}</a></b> ended with a Success status. Please refer to the result <b><a href=”{ConsolidatedResultLink}”>{ConsolidatedResultName}</a></b> for further details.'
            )
        };
    }

    private static Promotion__c getPromotion() {
        return [SELECT Id FROM Promotion__c LIMIT 1];
    }

    private static Deployment_Flow__c getPipeline() {
        return [SELECT Id FROM Deployment_Flow__c LIMIT 1];
    }

    private static Deployment__c getDeployment() {
        return [SELECT Id, Promotion__c FROM Deployment__c LIMIT 1];
    }

    private static User_Story_Commit__c getUserStoryCommit() {
        return [SELECT Id FROM User_Story_Commit__c LIMIT 1];
    }

    private static Git_Backup__c getSnapshot() {
        return [SELECT Id FROM Git_Backup__c LIMIT 1];
    }
}