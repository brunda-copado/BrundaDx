@IsTest
private class AutomationRuleConfigureCtrlTest {

    @TestSetup
    private static void makeData() {
        TestUtilities.getAllMultilicense();
        new User_t().alias('TestUsr1');
        new User_t()
            .alias('TestUsr2')
            .assign(new PermissionSetAssignment_t().configureAutomations())
            .persist();
    }
    
    @IsTest
    private static void getAutomatedActionWithCorrectApexClass() {
        // Setup
        String className = AutomationConnectorMock.class.getName();
        String result;

        // Exercise
        Test.startTest();
        result = AutomationRuleConfigureCtrl.getAutomatedAction(className);
        Test.stopTest();

        // Verify
        System.assertEquals('Mock Action', result, 'Result should match with the value in the connector');
    }

    @IsTest
    private static void getAutomatedActionWithInvalidApexClass() {
        // Setup
        String className = 'Invalid';
        String result;
        Exception resultException;

        // Exercise
        Test.startTest();
        try {
            result = AutomationRuleConfigureCtrl.getAutomatedAction(className);
        } catch(Exception ex) {
            resultException = ex;
        }
        Test.stopTest();

        // Verify
        System.assertEquals(null, result, 'Result should be null');
        System.assertNotEquals(null, resultException, 'An Exception should be thrown');
    }

    @IsTest
    private static void isAutomationRuleEditableWithPermissions() {
        System.runAs(getUserWithPermissions()) {
            // Setup
            Boolean result;

            // Exercise
            Test.startTest();
            result = AutomationRuleConfigureCtrl.isAutomationRuleEditable();
            Test.stopTest();

            // Verify
            System.assertEquals(true, result, 'Result should be true');
        }
    }

    @IsTest
    private static void isAutomationRuleEditableWithoutPermissions() {
        System.runAs(getUserWithoutPermissions()) {
            // Setup
            Boolean result;

            // Exercise
            Test.startTest();
            result = AutomationRuleConfigureCtrl.isAutomationRuleEditable();
            Test.stopTest();

            // Verify
            System.assertEquals(false, result, 'Result should be false');
        }
    }

    @IsTest
    private static void automationRuleIsAccessible() {
        System.runAs(getUserWithPermissions()) {
            // Setup
            Boolean result;

            // Exercise
            Test.startTest();
            result = AutomationRuleConfigureCtrl.isAutomationRuleAccessible();
            Test.stopTest();

            // Verify
            System.assertEquals(true, result, 'Result should be true');
        }
    }

    @IsTest
    private static void automationRuleIsNotAccessible() {
        System.runAs(getUserWithoutPermissions()) {
            // Setup
            Boolean result;

            // Exercise
            Test.startTest();
            result = AutomationRuleConfigureCtrl.isAutomationRuleAccessible();
            Test.stopTest();

            // Verify
            System.assertEquals(false, result, 'Result should be false');
        }
    }

    private static User getUserWithPermissions() {
        return [SELECT Id FROM User WHERE Profile.Name = 'Standard User' AND Alias = 'TestUsr2' ORDER BY CreatedDate DESC LIMIT 1];
    }

    private static User getUserWithoutPermissions() {
        return [SELECT Id FROM User WHERE Profile.Name = 'Standard User' AND Alias = 'TestUsr1' ORDER BY CreatedDate DESC LIMIT 1];
    }
}