@IsTest
private class FunctionCreditHelperTest {

    @TestSetup
    private static void setup(){
        TestUtilities.getAllMultilicense();

        User u = (User) new User_t()
            .assign( new PermissionSetAssignment_t().copadoUser() )
            .assign( new PermissionSetAssignment_t().functions() )
            .persist();

        System.runAs(u) {
            new CopadoLicense().user(u).enableAll().persist();
        }
    }


    @IsTest
    private static void updateCreditUsageWithoutMonthlyUsage() {

        // Setup & Exercise

        System.runAs( standardUser() ) {
            Test.startTest();
            DataBase.executeBatch(new FunctionCreditHelper());
            Test.stopTest();
        }

        // Verify

        List<CustomFunctionUsage__c> results = [SELECT Credits__c, Year_Month__c FROM CustomFunctionUsage__c];
        System.assertEquals(0, results.size(), 'No custom setting record should be created');
    }


    @IsTest
    private static void updateCreditUsageWithExistingMonthlyUsage() {

        // Setup

        Integer usedCredits = 2;
        Integer addCredits = 3;

        FeatureManagement.setPackageIntegerValue('CustomFunctionCreditUsage', usedCredits);
        // Note: To avoid MIXED_DML_OPERATION
        System.runAs( standardUser() ) {
            insert new CustomFunctionUsage__c(Name = String.valueOf(Date.today()), Year_Month__c = Date.today(), Credits__c = usedCredits);
            insert new Result__c(CreditSyncStatus__c = 'Pending', Custom_Function_Used_Credits__c = addCredits, Job_Type__c = 'echo_json');
        }

        // Exercise

        System.runAs( standardUser() ) {
            Test.startTest();
            DataBase.executeBatch(new FunctionCreditHelper());
            Test.stopTest();
        }

        // Verify

        List<CustomFunctionUsage__c> results = [SELECT Credits__c, Year_Month__c FROM CustomFunctionUsage__c];
        System.assertEquals(1, results.size(), 'Only one custom setting record should be created');
        System.assertEquals(Date.today().year(), results[0].Year_Month__c.year(), 'Credit Year does not match');
        System.assertEquals(Date.today().month(), results[0].Year_Month__c.month(), 'Credit Month does not match');
        System.assertEquals(addCredits + usedCredits, results[0].Credits__c, 'Credit Usage does not match');
        System.assertEquals(addCredits + usedCredits, FeatureManagement.checkPackageIntegerValue('CustomFunctionCreditUsage'), 'Credit Usage does not match');
    }

    // HELPER


    private static User standardUser() {
        return [SELECT Id FROM User WHERE Profile.Name = 'Standard User' AND UserName LIKE '%@test%.org' ORDER BY CreatedDate DESC LIMIT 1];
    }
}