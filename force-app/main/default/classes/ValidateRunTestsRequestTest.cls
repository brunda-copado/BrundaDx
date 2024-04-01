@IsTest
private class ValidateRunTestsRequestTest { //NOPMD
    private static final String JOB_TEMPLATE_NAME = 'MockTemplate';
    private static final String EXTENSION_CONFIGURATION_NAME = 'Mock Extension Configuration';
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
    private static void validRequestQgContext() {
        System.runAs(getRunAsUser()) {
            // Setup
            Test.startTest();
            mockTestTool();
            TestTool__mdt mockTestTool = mockNoneTestToolWithoutReadinessLogic();
            Boolean isQgContext = true;
            List<Id> contextIds = createContextRecordsForHappyPath();
            createQgContextParentData(true);
            Id qgJobStepResultId = getQgJobStepResultWithNoneToolWithReadinessLogic().id;

            JobExecution__c parentJobExecution = getJobExecution();
            parentJobExecution.ParentRecord_Id__c = getSnapshot().Id;
            update parentJobExecution;

            // Exercise
            RunTestsAction.Request request = createRunTestsActionRequest(contextIds, qgJobStepResultId);

            JobExecution__c result = new ValidateRunTestsRequest(request)
                .testTool(mockTestTool)
                .testsWrapper(createTestsWrapper(request, isQgContext))
                .setQgContext(isQgContext)
                .jobTemplateByName(getTemplatesByName(new List<TestTool__mdt>{ mockTestTool }))
                .execute();
            Test.stopTest();

            // Verify
            System.assertEquals(null, result, 'Failed Job Execution is not created. Happy Path Scenario!!!');
        }
    }

    @IsTest
    private static void validRequestNonQgContext() {
        System.runAs(getRunAsUser()) {
            // Setup
            TestTool__mdt mockTestTool = mockTestTool();
            Boolean isQgContext = false;
            List<Id> contextIds = createContextRecordsForHappyPath();
            RunTestsAction.Request request = createRunTestsActionRequest(contextIds, null);
            CategorizeTests.TestsWrapper testsWrapper = createTestsWrapper(request, isQgContext);

            // Exercise
            Test.startTest();
            JobExecution__c result = new ValidateRunTestsRequest(request)
                .testTool(mockTestTool)
                .testsWrapper(testsWrapper)
                .setQgContext(isQgContext)
                .jobTemplateByName(getTemplatesByName(new List<TestTool__mdt>{ mockTestTool }))
                .execute();
            Test.stopTest();

            // Verify
            System.assertEquals(null, result, 'Failed Job Execution is not created. Happy Path Scenario!!!');
        }
    }

    @IsTest
    private static void invalidRequestWithoutTestToolNonQgContext() {
        System.runAs(getRunAsUser()) {
            // Setup
            TestToolsSelector.mock(new List<TestTool__mdt>());
            Test__c mockTest = createMockTest(getMockExtensionConfiguration());
            Boolean isQgContext = false;
            RunTestsAction.Request request = createRunTestsActionRequest(new List<Id>{ mockTest.Id }, null);
            CategorizeTests.TestsWrapper testsWrapper = createTestsWrapper(request, isQgContext);
            TestTool__mdt mockTestTool = mockTestTool();

            // Exercise
            Test.startTest();
            JobExecution__c result = new ValidateRunTestsRequest(request)
                .testTool(null)
                .testsWrapper(testsWrapper)
                .setQgContext(isQgContext)
                .jobTemplateByName(getTemplatesByName(new List<TestTool__mdt>{ mockTestTool }))
                .execute();
            Test.stopTest();

            // Verify
            System.assertEquals('Error', result.Status__c, 'Job execution status should be Error');
            System.assert(
                result.errorMessage__c.contains(Label.MissingTestTool),
                'Expected Job Execution with error message: ' + Label.MissingTestTool
            );
        }
    }

    @IsTest
    private static void invalidRequestWithoutValidTestsQgContextPromotion() {
        System.runAs(getRunAsUser()) {
            // Setup
            TestToolsSelector.mock(new List<TestTool__mdt>());
            Test__c mockTest = createMockTest(getMockExtensionConfiguration());
            Boolean isQgContext = true;
            createQgContextParentData(false);
            Test.startTest();
            Id qgJobStepResultId = getQgJobStepResultWithNoneToolWithReadinessLogic().id;
            JobExecution__c parentJobExecution = getJobExecution();
            parentJobExecution.Promotion__c = getPromotion().Id;
            update parentJobExecution;
            RunTestsAction.Request request = createRunTestsActionRequest(new List<Id>{ mockTest.Id }, qgJobStepResultId);
            CategorizeTests.TestsWrapper testsWrapper = createTestsWrapper(request, isQgContext);
            TestTool__mdt mockTestTool = mockNoneTestToolWithReadinessLogic();
            mockTestTool();

            // Exercise
            JobExecution__c result = new ValidateRunTestsRequest(request)
                .testTool(mockTestTool)
                .testsWrapper(testsWrapper)
                .setQgContext(isQgContext)
                .jobTemplateByName(getTemplatesByName(new List<TestTool__mdt>{ mockTestTool }))
                .execute();
            Test.stopTest();

            // Verify
            System.assertEquals(null, result, 'Failed Job Execution is not created. Happy Path Scenario!!!');
            System.assertEquals(true, testsWrapper.validTests.size() > 0, 'Valid Test is auto-created');
        }
    }

    @IsTest
    private static void invalidRequestWithoutValidTestsQgContextUsCommit() {
        System.runAs(getRunAsUser()) {
            // Setup
            TestToolsSelector.mock(new List<TestTool__mdt>());
            Test__c mockTest = createMockTest(getMockExtensionConfiguration());
            Boolean isQgContext = true;
            createQgContextParentData(true);
            Test.startTest();
            Id qgJobStepResultId = getQgJobStepResultWithNoneToolWithoutReadinessLogic().id;
            JobExecution__c parentJobExecution = getJobExecution();
            parentJobExecution.UserStoryCommit__c = getUserStoryCommit().Id;
            update parentJobExecution;
            RunTestsAction.Request request = createRunTestsActionRequest(new List<Id>{ mockTest.Id }, qgJobStepResultId);
            CategorizeTests.TestsWrapper testsWrapper = createTestsWrapper(request, isQgContext);
            TestTool__mdt mockTestTool = mockNoneTestToolWithoutReadinessLogic();
            mockTestTool();

            // Exercise

            JobExecution__c result = new ValidateRunTestsRequest(request)
                .testTool(mockTestTool)
                .testsWrapper(testsWrapper)
                .setQgContext(isQgContext)
                .jobTemplateByName(getTemplatesByName(new List<TestTool__mdt>{ mockTestTool }))
                .execute();
            Test.stopTest();

            // Verify
            System.assertEquals(null, result, 'Failed Job Execution is not created. Happy Path Scenario!!!');
            System.assertEquals(true, testsWrapper.validTests.size() > 0, 'Valid Test is auto-created');
        }
    }

    @IsTest
    private static void invalidRequestWithInvalidTemplateId() {
        System.runAs(getRunAsUser()) {
            // Setup
            TestTool__mdt mockTestTool = mockTestTool();
            List<Id> contextIds = createContextRecordsForHappyPath();
            createQgContextParentData(false);
            Id qgJobStepResultId = getQgJobStepResultWithNoneToolWithReadinessLogic().id;
            JobExecution__c parentJobExecution = getJobExecution();
            parentJobExecution.Deployment__c = getDeployment().Id;
            update parentJobExecution;
            RunTestsAction.Request request = createRunTestsActionRequest(contextIds, qgJobStepResultId);
            Boolean isQgContext = true;

            // Exercise
            Test.startTest();
            JobExecution__c result = new ValidateRunTestsRequest(request)
                .testTool(mockTestTool)
                .testsWrapper(createTestsWrapper(request, isQgContext))
                .setQgContext(isQgContext)
                .jobTemplateByName(getTemplatesByName(new List<TestTool__mdt>{}))
                .execute();
            Test.stopTest();

            Result__c consolidatedResult = getConsolidatedResult();

            // Verify
            System.assertEquals('Failed', consolidatedResult.Status__c, 'Consolidated Result is updated with status as Failed.');
            System.assertEquals('Error', result.Status__c, 'Job execution status should be Error');
        }
    }

    @IsTest
    private static void invalidRequestWithoutTestsNonQgContext() {
        System.runAs(getRunAsUser()) {
            // Setup
            TestTool__mdt mockTestTool = mockTestTool();
            RunTestsAction.Request request = createRunTestsActionRequest(new List<Id>(), null);
            Boolean isQgContext = false;
            CategorizeTests.TestsWrapper testsWrapper = createTestsWrapper(request, isQgContext);

            // Exercise
            Test.startTest();
            JobExecution__c result = new ValidateRunTestsRequest(request)
                .testTool(mockTestTool)
                .testsWrapper(testsWrapper)
                .setQgContext(isQgContext)
                .jobTemplateByName(getTemplatesByName(new List<TestTool__mdt>{ mockTestTool }))
                .execute();
            Test.stopTest();

            // Verify
            System.assertEquals('Error', result.Status__c, 'Job execution status should be Error');
            System.assert(result.errorMessage__c.contains(Label.NoTestsFound), 'Expected Job Execution with error message: ' + Label.NoTestsFound);
        }
    }

    // PRIVATE

    private static TestTool__mdt mockTestTool() {
        TestTool__mdt mockTestTool = new TestTool__mdt(
            MasterLabel = TEST_TOOL_NAME,
            JobTemplate__c = JOB_TEMPLATE_NAME,
            TestType__c = 'Mock Type',
            Automate_Test_Readiness__c = false,
            Test_Readiness_Logic__c = ''
        );
        if (TestToolsSelector.mock == null) {
            TestToolsSelector.mock = new List<TestTool__mdt>();
        }
        TestToolsSelector.mock.add(mockTestTool);
        return mockTestTool;
    }

    private static TestTool__mdt mockNoneTestToolWithReadinessLogic() {
        TestTool__mdt mockTestTool = new TestTool__mdt(
            MasterLabel = 'None',
            JobTemplate__c = JOB_TEMPLATE_NAME,
            TestType__c = 'Mock Type',
            Automate_Test_Readiness__c = true,
            Test_Readiness_Logic__c = 'MockTestReadinessLogic'
        );
        if (TestToolsSelector.mock == null) {
            TestToolsSelector.mock = new List<TestTool__mdt>();
        }
        TestToolsSelector.mock.add(mockTestTool);
        return mockTestTool;
    }

    private static TestTool__mdt mockNoneTestToolWithoutReadinessLogic() {
        TestTool__mdt mockTestTool = new TestTool__mdt(
            MasterLabel = 'None',
            JobTemplate__c = JOB_TEMPLATE_NAME,
            TestType__c = 'Mock Type',
            Automate_Test_Readiness__c = true,
            Test_Readiness_Logic__c = ''
        );
        if (TestToolsSelector.mock == null) {
            TestToolsSelector.mock = new List<TestTool__mdt>();
        }
        TestToolsSelector.mock.add(mockTestTool);
        return mockTestTool;
    }

    private static void insertData() {
        createExtensionConfiguration();

        JobTemplate__c jobTemplate = (JobTemplate__c) new JobTemplate().add(new JobStep()).persist();
        jobTemplate.ApiName__c = JOB_TEMPLATE_NAME;
        update jobTemplate;
    }

    private static void createQgContextParentData(Boolean createUserStoryCommit) {
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

        if (createUserStoryCommit) {
            Git_Backup__c snapshot = createGitBackup('Commit Metadata', sourceOrgId, repoId);
            Git_Org_Commit__c orgCommit = createGitOrgCommit(snapshot.Id, sourceOrgId);

            User_Story__c us = createUserStory(projectId, sourceOrgId, sourceEnvId);
            createUserStoryCommit(us, orgCommit);
        }
    }

    private static List<Id> createContextRecordsForHappyPath() {
        Application__c application1 = new Application__c();
        insert application1;

        Application_Feature__c feature1 = new Application_Feature__c();
        Application_Feature__c feature2 = new Application_Feature__c(Application__c = application1.Id);
        Application_Feature__c feature3 = new Application_Feature__c(Application__c = application1.Id);
        insert new List<Application_Feature__c>{ feature1, feature2, feature3 };

        User_Story__c userStory1 = new User_Story__c();
        User_Story__c userStory2 = new User_Story__c(US_Feature__c = feature1.Id);
        User_Story__c userStory3 = new User_Story__c(US_Feature__c = feature1.Id);
        User_Story__c userStory4 = new User_Story__c(US_Feature__c = feature2.Id);
        User_Story__c userStory5 = new User_Story__c(US_Feature__c = feature3.Id);
        insert new List<User_Story__c>{ userStory1, userStory2, userStory3, userStory4, userStory5 };

        ExtensionConfiguration__c extensionConfiguration = getMockExtensionConfiguration();

        Test__c test1 = new Test__c(Configuration__c = 't1', ExtensionConfiguration__c = extensionConfiguration.Id, ReadyToRun__c = true);
        Test__c test2 = new Test__c(Configuration__c = 't2', ExtensionConfiguration__c = extensionConfiguration.Id, ReadyToRun__c = true);
        Test__c test3 = new Test__c(
            Configuration__c = 't3',
            ExtensionConfiguration__c = extensionConfiguration.Id,
            User_Story__c = userStory1.Id,
            ReadyToRun__c = true
        );
        Test__c test4 = new Test__c(
            Configuration__c = 't4',
            ExtensionConfiguration__c = extensionConfiguration.Id,
            User_Story__c = userStory1.Id,
            ReadyToRun__c = true
        );
        Test__c test5 = new Test__c(Configuration__c = 't5', ExtensionConfiguration__c = extensionConfiguration.Id, User_Story__c = userStory2.Id);
        Test__c test6 = new Test__c(Configuration__c = 't6', ExtensionConfiguration__c = extensionConfiguration.Id, User_Story__c = userStory3.Id);
        Test__c test7 = new Test__c(Configuration__c = 't7', ExtensionConfiguration__c = extensionConfiguration.Id, User_Story__c = userStory4.Id);
        Test__c test8 = new Test__c(Configuration__c = 't8', ExtensionConfiguration__c = extensionConfiguration.Id, User_Story__c = userStory4.Id);
        Test__c test9 = new Test__c(Configuration__c = 't9', ExtensionConfiguration__c = extensionConfiguration.Id, User_Story__c = userStory5.Id);
        Test__c test10 = new Test__c(Configuration__c = 't10', ExtensionConfiguration__c = extensionConfiguration.Id, User_Story__c = userStory5.Id);

        List<Test__c> tests = new List<Test__c>{ test1, test2, test3, test4, test5, test6, test7, test8, test9, test10 };
        insert tests;

        return new List<Id>{ test1.Id, test2.Id, userStory1.Id, feature1.Id, application1.Id };
    }

    private static void createExtensionConfiguration() {
        insert new ExtensionConfiguration__c(
            Name = EXTENSION_CONFIGURATION_NAME,
            ExtensionApplication__c = 'Test',
            ExtensionTool__c = TEST_TOOL_NAME,
            Active__c = true
        );
    }

    public static Test__c createMockTest(ExtensionConfiguration__c extensionConfig) {
        Test__c test = new Test__c(Name = 'Mock Test', ExtensionConfiguration__c = extensionConfig.Id, ReadyToRun__c = true);
        insert test;
        return test;
    }

    private static RunTestsAction.Request createRunTestsActionRequest(List<Id> contextIds, Id consolidatedResultId) {
        return new RunTestsAction.Request()
            .tool(TEST_TOOL_NAME)
            .context(contextIds)
            .actionCallback(MOCK_ACTION_CALLBACK)
            .acceptanceCriteria(MOCK_ACCEPTANCE_CRITERIA)
            .extensionConfigurationId(getMockExtensionConfiguration().id)
            .result(consolidatedResultId);
    }

    private static CategorizeTests.TestsWrapper createTestsWrapper(RunTestsAction.Request request, Boolean isQgContext) {
        CategorizeTests.TestsWrapper testsWrapper = new CategorizeTests(request, isQgContext, testToolByLabel()).execute();
        return testsWrapper;
    }

    private static ExtensionConfiguration__c getMockExtensionConfiguration() {
        return [SELECT Id FROM ExtensionConfiguration__c LIMIT 1];
    }

    private static User getRunAsUser() {
        return [SELECT Id FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1];
    }

    private static Result__c getConsolidatedResult() {
        return [SELECT Status__c, Result_Data__c, Error_Message__c FROM Result__c LIMIT 1];
    }

    private static Result__c getQgJobStepResultWithNoneToolWithReadinessLogic() {
        JobTemplate__c template = new JobTemplate__c(Name = 'Test Template', Version__c = 1);
        insert template;

        JobExecution__c execution = new JobExecution__c(Template__c = template.Id);
        insert execution;

        mockTestTool();
        mockNoneTestToolWithReadinessLogic();

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
            JobExecution__c = execution.Id,
            Quality_Gate_Rule__c = rule.Id
        );
        insert jobStep;

        Result__c result = new Result__c(Job_Type__c = TEST_TOOL_NAME, JobStep__c = jobStep.id);
        insert result;

        return result;
    }

    private static Result__c getQgJobStepResultWithNoneToolWithoutReadinessLogic() {
        JobTemplate__c template = new JobTemplate__c(Name = 'Test Template', Version__c = 1);
        insert template;

        JobExecution__c execution = new JobExecution__c(Template__c = template.Id);
        insert execution;

        mockTestTool();
        mockNoneTestToolWithoutReadinessLogic();

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
            JobExecution__c = execution.Id,
            Quality_Gate_Rule__c = rule.Id
        );
        insert jobStep;

        Result__c result = new Result__c(Job_Type__c = TEST_TOOL_NAME, JobStep__c = jobStep.id);
        insert result;

        return result;
    }

    private static Map<String, TestTool__mdt> testToolByLabel() {
        Map<String, TestTool__mdt> testToolByLabel = new Map<String, TestTool__mdt>();

        List<TestTool__mdt> testTools = new TestToolsSelector().getAll();
        for (TestTool__mdt testTool : testTools) {
            testToolByLabel.put(testTool.MasterLabel, testTool);
        }
        return testToolByLabel;
    }

    private static Map<String, JobTemplate__c> getTemplatesByName(List<TestTool__mdt> testTools) {
        Map<String, JobTemplate__c> result = new Map<String, JobTemplate__c>();
        Set<String> templateNames = new Set<String>();
        for (TestTool__mdt testTool : testTools) {
            templateNames.add(testTool.JobTemplate__c);
        }

        for (JobTemplate__c template : new JobTemplatesSelector().byApiName(templateNames)) {
            result.put(template.ApiName__c, template);
        }

        return result;
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

    private static JobExecution__c getJobExecution() {
        return [SELECT Id, Promotion__c, Deployment__c, UserStoryCommit__c, Context__c, ParentRecord_Id__c FROM JobExecution__c LIMIT 1];
    }

    private static Promotion__c getPromotion() {
        return [SELECT Id FROM Promotion__c LIMIT 1];
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