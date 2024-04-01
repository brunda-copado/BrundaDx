@IsTest
private class CreateDefaultOrgTest {
    
    @IsTest
    private static void createSfEnvironment() {

        // Setup & Exercise
        Environment__c e = new Environment__c();
        e.Name = 'env';
        insert e;


        // Verify
        System.assertEquals(0, [SELECT count() FROM Org__c]);
    }


    @IsTest
    private static void createOtherEnvironment() {

        // Setup & Exercise
        Environment__c e = new Environment__c();
        e.Name = 'env';
        e.Platform__c = 'Other';
        insert e;


        // Verify
        System.assertEquals(1, [SELECT count() FROM Org__c]);
    }
}