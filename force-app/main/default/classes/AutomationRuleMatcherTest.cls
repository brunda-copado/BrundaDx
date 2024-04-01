@IsTest
private with sharing class AutomationRuleMatcherTest {
    @TestSetup
    private static void makeData() {
        TestUtilities.getAllMultilicense();
        User user = (User) new User_t()
            .assign(new PermissionSetAssignment_t().copadoUser())
            .assign(new PermissionSetAssignment_t().configureAutomations())
            .assign(new PermissionSetAssignment_t().executeAutomations())
            .persist();
        System.runAs(user) {
            new CopadoLicense().user(user).enableAll().persist();
            createData();
        }
    }

    @IsTest
    private static void simpleMatch() {
        // Setup
        System.runAs(getUser()) {
            Deployment_Flow__c pipeline = getPipeline();

            Automation_Rule__c rule = (Automation_Rule__c) new AutomationRule()
                .pipeline(pipeline.Id)
                .active()
                .sourceAction(ActionConstants.PROMOTION_DEPLOYMENT)
                .automatedAction(ActionConstants.PROMOTION)
                .sourceActionStatus(AutomationRuleConstants.SOURCE_ACTION_STATUS_SUCCESSFUL)
                .connector(AutomationRuleConstants.AUTOMATION_CONNECTOR_CUSTOM)
                .execution(AutomationRuleConstants.EXECUTION_IMMEDIATE)
                .customConnector(AutomationConnectorMock.class.getName())
                .persist();

            Automation_Event__c event = (Automation_Event__c) new AutomationEvent()
                .pipelineId(pipeline.Id)
                .actionName(ActionConstants.PROMOTION_DEPLOYMENT)
                .actionStatus(AutomationRuleConstants.SOURCE_ACTION_STATUS_SUCCESSFUL)
                .actionResult('Test Result')
                .persist();

            // Exercise
            Test.startTest();
            Map<Id, List<Automation_Event__c>> automationEventsByRule = new AutomationRuleMatcher(new List<Automation_Event__c>{ event }).execute();
            Test.stopTest();

            // Verify
            List<Automation_Event__c> events = automationEventsByRule.get(rule.Id);
            System.assertNotEquals(null, events, 'Rule should match with some event');
            System.assert(events.contains(event), 'The event should be the same');
        }
    }

    @IsTest
    private static void matchingEnvironment() {
        // Setup
        System.runAs(getUser()) {
            Deployment_Flow__c pipeline = getPipeline();
            Environment__c environment = getEnvironment();

            new AutomationRule()
                .pipeline(pipeline.Id)
                .active()
                .sourceAction(ActionConstants.PROMOTION_DEPLOYMENT)
                .automatedAction(ActionConstants.PROMOTION)
                .sourceActionStatus(AutomationRuleConstants.SOURCE_ACTION_STATUS_SUCCESSFUL)
                .connector(AutomationRuleConstants.AUTOMATION_CONNECTOR_CUSTOM)
                .execution(AutomationRuleConstants.EXECUTION_IMMEDIATE)
                .customConnector(AutomationConnectorMock.class.getName())
                .persist();

            Automation_Rule__c rule = (Automation_Rule__c) new AutomationRule()
                .pipeline(pipeline.Id)
                .active()
                .sourceAction(ActionConstants.PROMOTION_DEPLOYMENT)
                .automatedAction(ActionConstants.PROMOTION)
                .sourceActionStatus(AutomationRuleConstants.SOURCE_ACTION_STATUS_SUCCESSFUL)
                .connector(AutomationRuleConstants.AUTOMATION_CONNECTOR_CUSTOM)
                .execution(AutomationRuleConstants.EXECUTION_IMMEDIATE)
                .customConnector(AutomationConnectorMock.class.getName())
                .environment(environment.Id)
                .persist();

            Automation_Event__c event = (Automation_Event__c) new AutomationEvent()
                .pipelineId(pipeline.Id)
                .actionName(ActionConstants.PROMOTION_DEPLOYMENT)
                .actionStatus(AutomationRuleConstants.SOURCE_ACTION_STATUS_SUCCESSFUL)
                .environmentId(environment.Id)
                .actionResult('Test Result')
                .persist();

            // Exercise
            Test.startTest();
            Map<Id, List<Automation_Event__c>> automationEventsByRule = new AutomationRuleMatcher(new List<Automation_Event__c>{ event }).execute();
            Test.stopTest();

            // Verify
            List<Automation_Event__c> events = automationEventsByRule.get(rule.Id);
            System.assertNotEquals(null, events, 'Rule should match with some event');
            System.assert(events.contains(event), 'The event should be the same');
        }
    }

    @IsTest
    private static void matchingStage() {
        // Setup
        System.runAs(getUser()) {
            Deployment_Flow__c pipeline = getPipeline();
            Stage__c stage = getStage();

            new AutomationRule()
                .pipeline(pipeline.Id)
                .active()
                .sourceAction(ActionConstants.PROMOTION_DEPLOYMENT)
                .automatedAction(ActionConstants.PROMOTION)
                .sourceActionStatus(AutomationRuleConstants.SOURCE_ACTION_STATUS_SUCCESSFUL)
                .connector(AutomationRuleConstants.AUTOMATION_CONNECTOR_CUSTOM)
                .execution(AutomationRuleConstants.EXECUTION_IMMEDIATE)
                .customConnector(AutomationConnectorMock.class.getName())
                .persist();

            Automation_Rule__c rule = (Automation_Rule__c) new AutomationRule()
                .pipeline(pipeline.Id)
                .active()
                .sourceAction(ActionConstants.PROMOTION_DEPLOYMENT)
                .automatedAction(ActionConstants.PROMOTION)
                .sourceActionStatus(AutomationRuleConstants.SOURCE_ACTION_STATUS_SUCCESSFUL)
                .connector(AutomationRuleConstants.AUTOMATION_CONNECTOR_CUSTOM)
                .execution(AutomationRuleConstants.EXECUTION_IMMEDIATE)
                .customConnector(AutomationConnectorMock.class.getName())
                .stage(stage.Id)
                .persist();

            Automation_Event__c event = (Automation_Event__c) new AutomationEvent()
                .pipelineId(pipeline.Id)
                .actionName(ActionConstants.PROMOTION_DEPLOYMENT)
                .actionStatus(AutomationRuleConstants.SOURCE_ACTION_STATUS_SUCCESSFUL)
                .stageId(stage.Id)
                .actionResult('Test Result')
                .persist();

            // Exercise
            Test.startTest();
            Map<Id, List<Automation_Event__c>> automationEventsByRule = new AutomationRuleMatcher(new List<Automation_Event__c>{ event }).execute();
            Test.stopTest();

            // Verify
            List<Automation_Event__c> events = automationEventsByRule.get(rule.Id);
            System.assertNotEquals(null, events, 'Rule should match with some event');
            System.assert(events.contains(event), 'The event should be the same');
        }
    }

    @IsTest
    private static void matchingStageWithExcludedEnvironments() {
        // Setup
        System.runAs(getUser()) {
            Deployment_Flow__c pipeline = getPipeline();
            Environment__c dev1Environment = getEnvironment('dev1');
            Environment__c dev2Environment = getEnvironment('dev2');
            Stage__c stage = getStage('Dev');

            new AutomationRule()
                .pipeline(pipeline.Id)
                .active()
                .sourceAction(ActionConstants.PROMOTION_DEPLOYMENT)
                .automatedAction(ActionConstants.PROMOTION)
                .sourceActionStatus(AutomationRuleConstants.SOURCE_ACTION_STATUS_SUCCESSFUL)
                .connector(AutomationRuleConstants.AUTOMATION_CONNECTOR_CUSTOM)
                .execution(AutomationRuleConstants.EXECUTION_IMMEDIATE)
                .customConnector(AutomationConnectorMock.class.getName())
                .persist();

            Automation_Rule__c rule = (Automation_Rule__c) new AutomationRule()
                .pipeline(pipeline.Id)
                .active()
                .sourceAction(ActionConstants.PROMOTION_DEPLOYMENT)
                .automatedAction(ActionConstants.PROMOTION)
                .sourceActionStatus(AutomationRuleConstants.SOURCE_ACTION_STATUS_SUCCESSFUL)
                .connector(AutomationRuleConstants.AUTOMATION_CONNECTOR_CUSTOM)
                .execution(AutomationRuleConstants.EXECUTION_IMMEDIATE)
                .customConnector(AutomationConnectorMock.class.getName())
                .stage(stage.Id)
                .excludedEnvironments(dev2Environment.Id)
                .persist();

            Automation_Event__c event = (Automation_Event__c) new AutomationEvent()
                .pipelineId(pipeline.Id)
                .actionName(ActionConstants.PROMOTION_DEPLOYMENT)
                .actionStatus(AutomationRuleConstants.SOURCE_ACTION_STATUS_SUCCESSFUL)
                .stageId(stage.Id)
                .environmentId(dev1Environment.Id)
                .actionResult('Test Result')
                .persist();

            // Exercise
            Test.startTest();
            Map<Id, List<Automation_Event__c>> automationEventsByRule = new AutomationRuleMatcher(new List<Automation_Event__c>{ event }).execute();
            Test.stopTest();

            // Verify
            List<Automation_Event__c> events = automationEventsByRule.get(rule.Id);
            System.assertNotEquals(null, events, 'Rule should match with some event');
            System.assert(events.contains(event), 'The event should be the same');
        }
    }

    private static void createData() {
        Stage devStage = new Stage().name('Dev').metaStage('Build');
        Stage testStage = new Stage().name('Test').metaStage('Test');
        Stage productionStage = new Stage().name('Production').metaStage('Production');

        Environment dev1 = new Environment().name('dev1').type('Sandbox').platform('Other').add(new Credential());
        Environment dev2 = new Environment().name('dev2').type('Sandbox').platform('Other').add(new Credential());
        Environment integration = new Environment().name('int').type('Sandbox').platform('Other').add(new Credential());
        Environment uat = new Environment().name('uat').type('Sandbox').platform('Other').add(new Credential());
        Environment prod = new Environment().name('prod').type('Sandbox').platform('Other').add(new Credential());

        StageConnection devStageConnection = new StageConnection().stage(devStage);
        StageConnection testStageConnection = new StageConnection().stage(testStage);
        StageConnection productionStageConnection = new StageConnection().stage(productionStage);

        new Pipeline()
            .active(true)
            .mainBranch('main')
            .setPlatform('Other')
            .add(new Connection(dev1, integration).branch('dev1').stageConnection(devStageConnection))
            .add(new Connection(dev2, integration).branch('dev2').stageConnection(devStageConnection))
            .add(new Connection(integration, uat).branch('int').stageConnection(devStageConnection))
            .add(new Connection(uat, prod).branch('uat').stageConnection(testStageConnection))
            .add(devStageConnection)
            .add(testStageConnection)
            .add(productionStageConnection)
            .persist();

        Stage_Connection__c devStageConnectionRecord = getStageConnections('Dev');
        Stage_Connection__c testStageConnectionRecord = getStageConnections('Test');
        Stage_Connection__c prodStageConnectionRecord = getStageConnections('Production');
        devStageConnectionRecord.Next_Stage_Connection__c = testStageConnectionRecord.Id;
        testStageConnectionRecord.Next_Stage_Connection__c = prodStageConnectionRecord.Id;
        update new List<Stage_Connection__c>{ devStageConnectionRecord, testStageConnectionRecord };
    }

    private static User getUser() {
        return [SELECT Id FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1];
    }

    private static Deployment_Flow__c getPipeline() {
        return [SELECT Id FROM Deployment_Flow__c LIMIT 1];
    }

    private static Environment__c getEnvironment() {
        return [SELECT Id FROM Environment__c LIMIT 1];
    }

    private static Environment__c getEnvironment(String name) {
        return [SELECT Id FROM Environment__c WHERE Name = :name LIMIT 1];
    }

    private static Stage__c getStage() {
        return [SELECT Id FROM Stage__c LIMIT 1];
    }

    private static Stage__c getStage(String name) {
        return [SELECT Id FROM Stage__c WHERE Name = :name LIMIT 1];
    }

    private static Stage_Connection__c getStageConnections(String stageName) {
        return [SELECT Id FROM Stage_Connection__c WHERE Stage__r.Name = :stageName];
    }
}