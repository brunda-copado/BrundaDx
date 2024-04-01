@IsTest
private class ACPromotionToRunQGTest {
    private static final String TEST_TOOL_NAME = 'Manual Tests';
    private static final String MOCK_ACTION_CALLBACK = 'MockRunTestsActionCallback';
    private static final String MOCK_ACCEPTANCE_CRITERIA = '{"criteria1": "mockCriteria1", "criteria2": "mockCriteria2"}';

    @TestSetup
    private static void setupData() {
        TestUtilities.getAllMultilicense();
        User user = (User) new User_t()
            .assign(new PermissionSetAssignment_t().copadoUser())
            .assign(new PermissionSetAssignment_t().functions())
            .assign(new PermissionSetAssignment_t().jobEngine())
            .assign(new PermissionSetAssignment_t().configureAutomations())
            .assign(new PermissionSetAssignment_t().qualityGatesAdmin())
            .persist();
        System.runAs(user) {
            new CopadoLicense().user(user).enableAll().persist();
            createData();
        }
    }

    @IsTest
    private static void connectAndExecuteSuccess() {
        System.runAs(getRunAsUser()) {
            // Setup
            createMockTestTools();
            createQualityGate();

            Deployment_Flow__c pipeline = getPipeline();
            Promotion__c promotion = getPromotion();

            Flow.mockResponse = flowCompletionEvent(true, '', '');

            // Exercise
            Test.startTest();

            ACPromotionToRunQG runQGConnector = new ACPromotionToRunQG();

            AutomationConnectorContext context = new AutomationConnectorContext();
            context.automationEvents = new List<Automation_Event__c>{ automationEvent(pipeline.Id, promotion.Id) };
            context.automationRule = automationRule(pipeline.Id);
            runQGConnector.context = context;

            List<AutomationConnector> connectors = (List<AutomationConnector>) runQGConnector.getConnectors(context);
            for (AutomationConnector connector : connectors) {
                connector.executeAutomation();
            }

            Test.stopTest();

            // Verify
            Test__c test = [SELECT Id, LatestJobExecution__c FROM Test__c WHERE Name = :'t1' LIMIT 1];
            System.assert(test.LatestJobExecution__c != null, 'Test Latest Job Execution must be updated.');

            List<JobExecution__c> executions = [
                SELECT DataJson__c, Status__c, Source__c, Pipeline__c, ParentId__c, Job_Step__c
                FROM JobExecution__c
                WHERE Id = :test.LatestJobExecution__c
            ];
            System.assertEquals(JobExecutionConstants.STATUS_SUCCESSFUL, executions[0].Status__c, 'Job execution status should be Successful');

            //RunTestsExecutionPayload payload = (RunTestsExecutionPayload) JSON.deserialize(executions[0].DataJson__c, RunTestsExecutionPayload.class);
            //System.assertEquals(payload.parentContextId, promotion.Id, 'Parent Context must be promotion.');
            //System.assert(payload.qualityCheck != null, 'Quality Check must be populated in payload.');
        }
    }

    // PRIVATE

    private static void createData() {
        createExtensionConfiguration();

        new JobTemplate().name('MockTemplate').mockAutomation(ActionConstants.RUN_QG).add(new JobStep());
        new JobTemplate().name('Promotion_Template').mockAutomation(ActionConstants.PROMOTION).add(new JobStep()).persist();

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
                    .add(new UserStory().title('US1').credential(dev1Credential).add(new UserStoryMetadata().name('TestClass').type('ApexClass')))
                    .add(new UserStory().title('US2').credential(dev1Credential).add(new UserStoryMetadata().name('TestClass').type('ApexClass')))
                    .add(new UserStory().title('US3').credential(dev1Credential).add(new UserStoryMetadata().name('TestClass').type('ApexClass')))
            )
            .persist();

        User_Story__c userStory = getUserStory('US1');
        Promotion__c promotion = (Promotion__c) new Promotion().projectId([SELECT Id FROM Project__c LIMIT 1].Id).sourceEnvId(dev1.Id).persist();
        insert new Promoted_User_Story__c(User_Story__c = userStory.Id, Promotion__c = promotion.Id);

        ExtensionConfiguration__c extensionConfiguration = getExtensionConfiguration();

        List<Test__c> tests = new List<Test__c>();
        Test__c test1 = new Test__c(
            Name = 't1',
            ExtensionConfiguration__c = extensionConfiguration.Id,
            User_Story__c = userStory.Id,
            ReadyToRun__c = true
        );
        Test__c test2 = new Test__c(
            Name = 't2',
            ExtensionConfiguration__c = extensionConfiguration.Id,
            User_Story__c = userStory.Id,
            ReadyToRun__c = true
        );
        tests.add(test1);
        tests.add(test2);

        insert tests;
    }

    private static void createMockTestTools() {
        String jobTemplateApiName = 'MockTemplate_1';
        TestToolsSelector.mock(
            new List<TestTool__mdt>{
                new TestTool__mdt(
                    MasterLabel = 'None',
                    JobTemplate__c = jobTemplateApiName,
                    TestType__c = 'Mock Type',
                    Automate_Test_Readiness__c = true,
                    Test_Readiness_Logic__c = ''
                ),
                new TestTool__mdt(
                    MasterLabel = TEST_TOOL_NAME,
                    JobTemplate__c = jobTemplateApiName,
                    TestType__c = 'Mock Type',
                    Automate_Test_Readiness__c = true,
                    Test_Readiness_Logic__c = ''
                )
            }
        );
    }

    private static void createExtensionConfiguration() {
        insert new ExtensionConfiguration__c(
            Name = 'EC 1',
            ExtensionApplication__c = 'Test',
            ExtensionTool__c = TEST_TOOL_NAME,
            AcceptanceCriteria__c = MOCK_ACCEPTANCE_CRITERIA,
            Active__c = true
        );
    }

    private static void createQualityGate() {
        Quality_Gate_Rule__c rule = (Quality_Gate_Rule__c) new QualityGateRule()
            .action(ActionConstants.PROMOTION)
            .sequence(QualityGateConstants.AFTER)
            .tool('None')
            .active(false)
            .add(
                new QualityGateRuleCondition()
                    .platform('Other')
                    .extensionConfiguration(getExtensionConfiguration().Id)
            )
            .persist();

        rule.Status__c = QualityGateConstants.ACTIVE;
        update rule;
    }

    private static ExtensionConfiguration__c getExtensionConfiguration() {
        return [SELECT Id FROM ExtensionConfiguration__c LIMIT 1];
    }

    private static Promotion__c getPromotion() {
        return [SELECT Id FROM Promotion__c LIMIT 1];
    }

    private static User_Story__c getUserStory(String userStoryTitle) {
        return [SELECT Id FROM User_Story__c WHERE User_Story_Title__c = :userStoryTitle LIMIT 1];
    }

    private static Environment__c getEnvironment(String name) {
        return [SELECT Id FROM Environment__c WHERE Name = :name LIMIT 1];
    }

    private static User getRunAsUser() {
        return [SELECT Id FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1];
    }

    private static Deployment_Flow__c getPipeline() {
        return [SELECT Id FROM Deployment_Flow__c LIMIT 1];
    }

    private static Quality_Gate_Rule_Condition__c getQualityGateRuleCondition() {
        return [SELECT Id FROM Quality_Gate_Rule_Condition__c LIMIT 1];
    }

    private static Event__e flowCompletionEvent(Boolean isSuccess, String errorMessage, String data) {
        Event__e result = new Event__e();
        result.Topic_Uri__c = OnJobStepComplete.STEP_ENDPOINT;
        result.Payload__c = Json.serialize(new OnJobStepComplete.EventPayload(isSuccess, errorMessage, data));

        return result;
    }

    private static Automation_Rule__c automationRule(Id pipelineId) {
        Automation_Rule__c automationRule = (Automation_Rule__c) new AutomationRule()
            .pipeline(pipelineId)
            .qualityGateRuleCondition(getQualityGateRuleCondition().Id)
            .sourceAction(ActionConstants.PROMOTION)
            .automatedAction(ActionConstants.RUN_QG)
            .sourceActionStatus(AutomationRuleConstants.SOURCE_ACTION_STATUS_SUCCESSFUL)
            .execution(AutomationRuleConstants.EXECUTION_IMMEDIATE)
            .automatedActionCallback(MOCK_ACTION_CALLBACK)
            .active()
            .persist();
        return automationRule;
    }

    private static Automation_Event__c automationEvent(Id pipelineId, Id promotionId) {
        Actions.PromotionResult result = new Actions.PromotionResult();
        result.jobExecution = (JobExecution__c) new JobExecution().dataJson('{ "promotionId" : "' + promotionId + '"}').persist();
        result.jobExecution.Promotion__c = promotionId;

        return (Automation_Event__c) new AutomationEvent()
            .pipelineId(pipelineId)
            .actionName(ActionConstants.RUN_QG)
            .actionStatus(AutomationRuleConstants.SOURCE_ACTION_STATUS_SUCCESSFUL)
            .actionResult(JSON.serialize(result))
            .persist();
    }
}