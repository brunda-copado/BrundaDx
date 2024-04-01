@isTest
public with sharing class GenerateScaRuleSetCtrlTest {

    @TestSetup
    private static void makeData() {
        User standardUser = setupUser();
        System.runAs(standardUser) {
            Static_Code_Analysis_Settings__c scas = TestMethodUtilities.createScaSetting('Test PMD');
            insert scas;

            List<Static_Code_Analysis_Rule__c> scaRules = new List<Static_Code_Analysis_Rule__c>();
            for(Integer i=0;i<3;i++){
                Static_Code_Analysis_Rule__c scar = new Static_Code_Analysis_Rule__c();
                scar.Rule_Name__c = 'Test';
                scar.Priority__c = '3';
                scar.Message__c = 'Test Description';
                scar.Rule_Reference__c = 'test';
                scar.Static_Code_Analysis_Settings__c = scas.Id;
                scaRules.add(scar);
            }
            insert scaRules;
        }
    }

    @isTest
    private static void validategetRules(){
        System.runAs(getStandardUser()) {
            // Setup
            Static_Code_Analysis_Settings__c scaSetting = [Select Id from Static_Code_Analysis_Settings__c limit 1];

            // Exercise
            Test.startTest();
            List<Static_Code_Analysis_Rule__c> rules = GenerateScaRuleSetCtrl.getRulesFrom(scaSetting.Id);
            Test.stopTest();

            // Verify
            System.assertEquals(3, rules.size(), 'expected 3 but found '+rules.size());
        }
    }
   
    private static User setupUser() {
        ITestDefaults userCreation = new CopadoSetupTestDefaults.UserDefaults().createRunAsUsers().executeDML();
        User standardUser = userCreation.getRunAsUsers().get('Standard')[0];

        return standardUser;
    }
    
    private static User getStandardUser() {
        User standardUser = [
            SELECT Id
            FROM User
            WHERE ProfileId IN (SELECT Id FROM Profile WHERE Name = 'Standard User')
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        return standardUser;
    }
}