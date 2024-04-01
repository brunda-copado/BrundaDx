@IsTest
private with sharing class AutomationRuleEvaluationScopeCtrlTest {
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
    private static void getData() {
        // Setup
        System.runAs(getUser()) {
            Automation_Rule__c automationRule = getAutomationRule();

            // Exercise
            Test.startTest();
            AutomationRuleEvaluationScopeCtrl.EvaluationScopeData data = AutomationRuleEvaluationScopeCtrl.getData(automationRule.Id);
            Test.stopTest();

            // Verify
            System.assertEquals(3, data.stagesById.size(), '3 stage should be returned');
            System.assertEquals(5, data.environmentsById.size(), '5 environments should be returned');
            System.assertEquals(true, data.userHasPermission, 'User should have permission');
        }
    }

    @IsTest
    private static void automationRuleIsAccessible() {
        // Setup
        System.runAs(getUser()) {
            // Exercise
            Test.startTest();
            Boolean isAccessable = AutomationRuleEvaluationScopeCtrl.isAutomationRuleAccessible();
            Test.stopTest();

            // Verify
            System.assertEquals(true, isAccessable, 'User should have permission');
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
            .add(
                new AutomationRule()
                    .active()
                    .sourceAction(ActionConstants.PROMOTION_DEPLOYMENT)
                    .automatedAction(ActionConstants.PROMOTION)
                    .sourceActionStatus(AutomationRuleConstants.SOURCE_ACTION_STATUS_SUCCESSFUL)
                    .connector(AutomationRuleConstants.AUTOMATION_CONNECTOR_CUSTOM)
                    .execution(AutomationRuleConstants.EXECUTION_IMMEDIATE)
                    .customConnector(AutomationConnectorMock.class.getName())
            )
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

    private static Automation_Rule__c getAutomationRule() {
        return [SELECT Id FROM Automation_Rule__c LIMIT 1];
    }

    private static Stage_Connection__c getStageConnections(String stageName) {
        return [SELECT Id FROM Stage_Connection__c WHERE Stage__r.Name = :stageName];
    }
}