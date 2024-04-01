@IsTest
private class AutomationRuleActivationCtrlTest {

    @TestSetup
    private static void makeData() {
        TestUtilities.getAllMultilicense();
        User user = (User) new User_t()
            .assign(new PermissionSetAssignment_t().copadoUser())
            .assign(new PermissionSetAssignment_t().configureAutomations())
            .persist();
        System.runAs(user) {
            new CopadoLicense().user(user).enableAll().persist();
        }
    }

    @IsTest
    private static void activateRuleWithWrongData() {
        // Setup
        System.runAs(getUser()) {
            Automation_Rule__c rule = (Automation_Rule__c) new AutomationRule()
                .pipeline(new Pipeline())
                .sourceAction(ActionConstants.PROMOTION_DEPLOYMENT)
                .sourceActionStatus(AutomationRuleConstants.SOURCE_ACTION_STATUS_SUCCESSFUL)
                .connector(null)
                .execution(AutomationRuleConstants.EXECUTION_IMMEDIATE)
                .persist();

            Map<String, Schema.SObjectField> fieldMap = Automation_Rule__c.SObjectType.getDescribe().fields.getMap();
            String missingField = fieldMap.get(Settings.ns + 'Automation_Connector__c').getDescribe().getLabel();
            String expectedErrorMessage = String.format(Label.ActivatingAutomationBodyErrorMessage, new List<String> {missingField});

            Exception expectedException;

            // Exercise
            Test.startTest();
            try {
                AutomationRuleActivationCtrl.activateAutomationRule(rule.Id);
            } catch(Exception ex) {
                expectedException = ex;
            }
            Test.stopTest();

            // Verify
            Automation_Rule__c resultRule = [SELECT Active__c FROM Automation_Rule__c WHERE Id = :rule.Id];
            System.assertEquals(false, resultRule.Active__c, 'Rule should not be active');
            System.assertNotEquals(null, expectedException, 'An exception should be thrown');
            System.assertEquals(expectedErrorMessage, expectedException.getMessage(), 'Exception message does not match');
        }
    }

    @IsTest
    private static void activateRuleWithValidData() {
        // Setup
        System.runAs(getUser()) {
            Automation_Rule__c rule = (Automation_Rule__c) new AutomationRule()
                .pipeline(new Pipeline())
                .sourceAction(ActionConstants.PROMOTION_DEPLOYMENT)
                .automatedAction(ActionConstants.PROMOTION)
                .sourceActionStatus(AutomationRuleConstants.SOURCE_ACTION_STATUS_SUCCESSFUL)
                .connector(AutomationRuleConstants.AUTOMATION_CONNECTOR_CUSTOM)
                .execution(AutomationRuleConstants.EXECUTION_IMMEDIATE)
                .customConnector(AutomationConnectorMock.class.getName())
                .persist();

            // Exercise
            Test.startTest();
            AutomationRuleActivationCtrl.activateAutomationRule(rule.Id);
            Test.stopTest();

            // Verify
            Automation_Rule__c resultRule = [SELECT Active__c, Scheduled_Job_Id__c FROM Automation_Rule__c WHERE Id = :rule.Id];
            System.assertEquals(true, resultRule.Active__c, 'Rule should be activated');
        }
    }

    @IsTest
    private static void getDuplicatedAutomationRule() {
        // Setup
        System.runAs(getUser()) {
            Deployment_Flow__c pipeline = (Deployment_Flow__c) new Pipeline().persist();

            Automation_Rule__c rule1 = (Automation_Rule__c) new AutomationRule()
                .pipeline(pipeline.Id)
                .active()
                .sourceAction(ActionConstants.PROMOTION_DEPLOYMENT)
                .automatedAction(ActionConstants.PROMOTION)
                .sourceActionStatus(AutomationRuleConstants.SOURCE_ACTION_STATUS_SUCCESSFUL)
                .connector(ACPromotionDeploymentToPromotion.class.getName())
                .execution(AutomationRuleConstants.EXECUTION_IMMEDIATE)
                .persist();

            Automation_Rule__c rule2 = (Automation_Rule__c) new AutomationRule()
                .pipeline(pipeline.Id)
                .sourceAction(ActionConstants.PROMOTION_DEPLOYMENT)
                .automatedAction(ActionConstants.PROMOTION)
                .sourceActionStatus(AutomationRuleConstants.SOURCE_ACTION_STATUS_SUCCESSFUL)
                .connector(ACPromotionDeploymentToPromotion.class.getName())
                .execution(AutomationRuleConstants.EXECUTION_IMMEDIATE)
                .persist();

            // Exercise
            Test.startTest();
            List<Automation_Rule__c> duplicates = AutomationRuleActivationCtrl.getDuplicatedAutomationRule(rule2.Id);
            Test.stopTest();

            // Verify
            System.assertEquals(1, duplicates.size(), 'Duplicates checker should return one element');
            System.assertEquals(rule1.Id, duplicates[0].Id, 'Automation Rule returned should match');
        }
    }

    private static User getUser() {
        return [SELECT Id FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1];
    }
}