@isTest
private class VerifyCallbacksTest {
    static {
        User user = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(user) {
            assignPermissions(user.Id);
        }
    }

    @TestSetup
    private static void makeData() {
        TestUtilities.assignLicense(UserInfo.getUserName(), true, true, true, true, true);
    }

    @isTest
    private static void apexCallbackSuccessOnInsert() {
        // Setup

        Function__c function = function();
        function.Callback_Type__c = 'ApexClass';
        function.ApexClass__c = namespacePrefix() + 'MCCallbackHandlerTestClass';

        // Exercise

        Test.startTest();
        insert function;
        Test.stopTest();

        // Verify

        System.assert(![SELECT Id FROM Function__c WHERE Id = :function.Id].isEmpty(), 'Could not create function.');
    }

    @isTest
    private static void flowCallbackSuccessOnInsert() {
        // Setup

        Function__c function = function();
        function.Callback_Type__c = 'Flow';
        function.ApexClass__c = namespacePrefix() + 'MCCallbackHandlerTestFlow';

        // Exercise

        Test.startTest();
        insert function;
        Test.stopTest();

        // Verify

        System.assert(![SELECT Id FROM Function__c WHERE Id = :function.Id].isEmpty(), 'Could not create function.');
    }

    @isTest
    private static void apexCallbackErrorOnInsert() {
        // Setup

        Function__c function = function();
        function.Callback_Type__c = 'ApexClass';
        function.ApexClass__c = 'fakenamespace.MCCallbackHandlerTestClass';

        // Exercise

        DmlException error;
        Test.startTest();
        try {
            insert function;
        } catch (DmlException ex) {
            error = ex;
        }
        Test.stopTest();

        // Verify

        System.assertEquals(
            error.getDmlMessage(0),
            String.format(Label.Callback_not_Found, new List<String>{ function.Callback_Type__c, function.ApexClass__c }),
            'Validation should throw an error for non-existing apex callbacks.'
        );
    }

    @isTest
    private static void apexCallbackErrorOnUpdate() {
        // Setup

        Function__c function = function();
        function.Callback_Type__c = 'ApexClass';
        insert function;

        // Exercise

        DmlException error;
        Test.startTest();
        try {
            function.ApexClass__c = 'fakenamespace.MCCallbackHandlerTestClass';
            update function;
        } catch (DmlException ex) {
            error = ex;
        }
        Test.stopTest();

        // Verify

        System.assertEquals(
            error.getDmlMessage(0),
            String.format(Label.Callback_not_Found, new List<String>{ function.Callback_Type__c, function.ApexClass__c }),
            'Validation should throw an error for non-existing apex callbacks.'
        );
    }

    @isTest
    private static void flowCallbackErrorOnInsert() {
        // Setup

        Function__c function = function();
        function.Callback_Type__c = 'Flow';
        function.FlowHandler__c = 'fakenamespace.MCCallbackHandlerTestFlow';

        // Exercise

        DmlException error;
        Test.startTest();
        try {
            insert function;
        } catch (DmlException ex) {
            error = ex;
        }
        Test.stopTest();

        // Verify

        System.assertEquals(
            error.getDmlMessage(0),
            String.format(Label.Callback_not_Found, new List<String>{ function.Callback_Type__c, function.FlowHandler__c }),
            'Validation should throw an error for non-existing flow callbacks.'
        );
    }

    @isTest
    private static void flowCallbackErrorOnUpdate() {
        // Setup

        Function__c function = function();
        function.Callback_Type__c = 'Flow';
        insert function;

        // Exercise

        DmlException error;
        Test.startTest();
        try {
            function.FlowHandler__c = 'fakenamespace.MCCallbackHandlerTestFlow';
            update function;
        } catch (DmlException ex) {
            error = ex;
        }
        Test.stopTest();

        // Verify

        System.assertEquals(
            error.getDmlMessage(0),
            String.format(Label.Callback_not_Found, new List<String>{ function.Callback_Type__c, function.FlowHandler__c }),
            'Validation should throw an error for non-existing flow callbacks.'
        );
    }

    // Helpers

    private static void assignPermissions(Id userId) {
        List<PermissionSetAssignment> assignments = new List<PermissionSetAssignment>();

        for (PermissionSet permissionSet : [
            SELECT Id
            FROM PermissionSet
            WHERE
                Name IN ('Copado_User', 'Copado_Functions')
                AND Id NOT IN (SELECT PermissionSetId FROM PermissionSetAssignment WHERE AssigneeId = :userId)
        ]) {
            assignments.add(new PermissionSetAssignment(AssigneeId = userId, PermissionSetId = permissionSet.Id));
        }

        insert assignments;
    }

    private static Function__c function() {
        return new Function__c(
            Name = 'muleDeploy',
            API_Name__c = 'muleDeploy',
            Script__c = 'echo hello',
            Type__c = 'Custom',
            Image_Name__c = 'us.gcr.io/copado/copado-function-core'
        );
    }

    private static String namespacePrefix() {
        return Settings.ns.replace('__', '.');
    }
}