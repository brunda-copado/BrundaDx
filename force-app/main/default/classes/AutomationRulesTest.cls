@IsTest
private class AutomationRulesTest {

    @TestSetup
    private static void setup() {
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
    private static void deleteActiveRule() {
        System.runAs(user()) {
            // Setup
            Automation_Rule__c automationRule = (Automation_Rule__c) new AutomationRule()
                .pipeline(new Pipeline())
                .active()
                .persist();

            Exception error;

            // Exercise
            Test.startTest();
            try {
                delete automationRule;
            } catch(Exception ex) {
                error = ex;
            }
            Test.stopTest();
            
            // Verify
            System.assertNotEquals(null, error, 'There should be an exception thrown');
            System.assertEquals(StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION, error.getDmlType(0), 'Exception type does not match.');
            System.assert(error.getMessage().contains(Label.ActiveAutomatioRuleCannotBeDeleted), 'Error message does not match: ' + error.getMessage());
        }
    }

    @IsTest
    private static void deleteInactiveRule() {
        System.runAs(user()) {
            // Setup
            Automation_Rule__c automationRule = (Automation_Rule__c) new AutomationRule()
                .pipeline(new Pipeline())
                .persist();

            // Exercise
            Test.startTest();
            delete automationRule;
            Test.stopTest();
            
            // Verify
            Integer numberOfAutomationRules = [SELECT COUNT() FROM Automation_Rule__c];
            System.assertEquals(0, numberOfAutomationRules, 'The rule should be deleted.');
        }
    }

    private static User user() {
        return [SELECT Id FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1];
    }
}