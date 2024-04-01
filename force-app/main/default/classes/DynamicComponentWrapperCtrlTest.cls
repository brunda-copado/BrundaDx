@IsTest
private class DynamicComponentWrapperCtrlTest {
    @TestSetup
    private static void setupData() {
        TestUtilities.getAllMultilicense();
        User user = (User) new User_t()
            .assign(new PermissionSetAssignment_t().copadoUser())
            .assign(new PermissionSetAssignment_t().functions())
            .assign(new PermissionSetAssignment_t().jobEngine())
            .assign(new PermissionSetAssignment_t().qualityGatesAdmin())
            .assign(new PermissionSetAssignment_t().configureAutomations())
            .persist();
        System.runAs(user) {
            new CopadoLicense().user(user).enableAll().persist();
        }
    }

    @IsTest
    private static void executeWithIncorrectRecordId() {
        System.runAs(getRunAsUser()) {
            // Setup
            Exception ex;

            // Exercise
            Test.startTest();
            try {
                DynamicComponentWrapperCtrl.getComponentName('test');
            } catch (Exception e) {
                ex = e;
            }
            Test.stopTest();

            // Verify
            Assert.isNotNull(ex, 'There is an exception');
            Assert.areEqual('Script-thrown exception', ex.getMessage(), 'Exception messages match');
        }
    }

    @IsTest
    private static void execute() {
        System.runAs(getRunAsUser()) {
            // Setup
            Automation_Rule__c automationRule = (Automation_Rule__c) new AutomationRule()
                .pipeline(new Pipeline())
                .active()
                .sourceAction(ActionConstants.PROMOTION_DEPLOYMENT)
                .automatedAction(ActionConstants.PROMOTION)
                .sourceActionStatus(AutomationRuleConstants.SOURCE_ACTION_STATUS_SUCCESSFUL)
                .connector(AutomationRuleConstants.AUTOMATION_CONNECTOR_CUSTOM)
                .execution(AutomationRuleConstants.EXECUTION_IMMEDIATE)
                .customConnector(AutomationConnectorMock.class.getName())
                .persist();

            // Exercise
            Test.startTest();
            String componentName = DynamicComponentWrapperCtrl.getComponentName(automationRule.Id);
            Test.stopTest();

            // Verify
            Assert.areEqual('c:mockScopeConfigurator', componentName, 'The component name matches');
        }
    }

    private static User getRunAsUser() {
        return [SELECT Id FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1];
    }
}