@IsTest
private class BackPromotionAutomationScopeCtrlTest {
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
        }
    }

    @IsTest
    private static void getData() {
        // Setup
        System.runAs(getUser()) {
            createData(getConfig('a000AAA'));
            Automation_Rule__c automationRule = getAutomationRule();

            // Exercise
            Test.startTest();
            BackPromotionAutomationScopeCtrl.EvaluationScopeData data = BackPromotionAutomationScopeCtrl.getData(automationRule.Id);
            Test.stopTest();

            // Verify
            Assert.areEqual('a000AAA', data.currentExcludedEnvironmentsForBp, 'The config json matches');
            Assert.areEqual(4, data.environmentsById.size(), '4 environments should be returned');
            Assert.areEqual(true, data.userHasPermission, 'User should have permission');
        }
    }

    @IsTest
    private static void getDataWithBlankConfig() {
        // Setup
        System.runAs(getUser()) {
            createData('');
            Automation_Rule__c automationRule = getAutomationRule();

            // Exercise
            Test.startTest();
            BackPromotionAutomationScopeCtrl.EvaluationScopeData data = BackPromotionAutomationScopeCtrl.getData(automationRule.Id);
            Test.stopTest();

            // Verify
            Assert.areEqual(null, data.currentExcludedEnvironmentsForBp, 'There isnt any environment excluded');
            Assert.areEqual(4, data.environmentsById.size(), '4 environments should be returned');
            Assert.areEqual(true, data.userHasPermission, 'User should have permission');
        }
    }

    @IsTest
    private static void automationRuleIsAccessible() {
        // Setup
        System.runAs(getUser()) {
            // Exercise
            Test.startTest();
            Boolean isAccessible = BackPromotionAutomationScopeCtrl.isAutomationRuleAccessible();
            Test.stopTest();

            // Verify
            Assert.areEqual(true, isAccessible, 'User should have permission');
        }
    }

    private static void createData(String configJson) {
        Environment dev1 = new Environment().name('dev1').type('Sandbox').platform('Other').add(new Credential());
        Environment dev2 = new Environment().name('dev2').type('Sandbox').platform('Other').add(new Credential());
        Environment integration = new Environment().name('int').type('Sandbox').platform('Other').add(new Credential());
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
                new AutomationRule()
                    .active()
                    .sourceAction(ActionConstants.PROMOTION_DEPLOYMENT)
                    .automatedAction(ActionConstants.PROMOTION)
                    .sourceActionStatus(AutomationRuleConstants.SOURCE_ACTION_STATUS_SUCCESSFUL)
                    .connector(AutomationRuleConstants.AUTOMATION_CONNECTOR_CUSTOM)
                    .execution(AutomationRuleConstants.EXECUTION_IMMEDIATE)
                    .customConnector(AutomationConnectorMock.class.getName())
                    .configJson(configJson)
            )
            .persist();
    }

    private static User getUser() {
        return [SELECT Id FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1];
    }

    private static Automation_Rule__c getAutomationRule() {
        return [SELECT Id FROM Automation_Rule__c LIMIT 1];
    }

    private static String getConfig(String inputString) {
        BackPromotionAutomationScopeCtrlTest.JsonData jsonData = new BackPromotionAutomationScopeCtrlTest.JsonData();
        jsonData.excludedEnvironmentsForBackPromotion = new List<String>{ inputString };

        return JSON.serialize(jsonData);
    }

    private class JsonData {
        private List<String> excludedEnvironmentsForBackPromotion;
    }
}