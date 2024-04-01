@isTest
private with sharing class RecordMatchingFormulaCtrlTest {
    @TestSetup
    private static void setup() {
        User standardUser = setupUser();
        System.runAs(standardUser) {
            setupLicense();
            createTestData();
        }
    }

    @isTest
    private static void getRecordMatchingFormula() {
        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            //Setup
            Record_Matching_Formula__c recordMatchingFormula = getFormula();
            //Execute
            Record_Matching_Formula__c formula = RecordMatchingFormulaCtrl.getRecordMatchingFormula(
                recordMatchingFormula.Id
            );

            //Verify
            System.assertEquals('Test Name', formula.Name, 'Test Name must be the name of record matching formula');
        }
    }
	
    @isTest
    private static void checkObjectAlreadyInUse() {
        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            //Setup
            String mainObject = 'Test Object';
            //Execute
            Boolean objectInUSe = RecordMatchingFormulaCtrl.checkObjectAlreadyInUse(
                mainObject
            );

            //Verify
            System.assert(objectInUSe, 'The object present in record matching formula should be Test Object');
        }
    }

    @isTest
    private static void handleExceptions() {
        System.runAs(getStandardUser()) {
            //Execute + Verify
            Test.startTest();

            Exception handledException;
            try {
                RecordMatchingFormulaCtrl.getRecordMatchingFormula(null);
            } catch (Exception e) {
                handledException = e;
            }
            System.assert(handledException != null, 'Formula Id should be mandatory');
            
            Test.stopTest();
        }
    }

    private static User setupUser() {
        ITestDefaults userCreation = new CopadoSetupTestDefaults.UserDefaults().createRunAsUsers().executeDML();
        User standardUser = userCreation.getRunAsUsers().get('Standard')[0];
        return standardUser;
    }

    private static void setupLicense() {
        TestUtilities.enableLicenses(2, 2, 2, 2, 2, 2, 2);
        TestUtilities.assignLicense(String.valueOf(UserInfo.getUserName()), true, true, true, true, true, true);
    }

    private static void createTestData() {
        List<Environment__c> environments = TestDataFactory.createEnvironments(1);
        List<Org__c> orgs = TestDataFactory.createOrgCredentials(1, UserInfo.getUserName(), environments);

        for (Org__c org : orgs) {
            org.SFDC_Org_ID__c = UserInfo.getOrganizationId() + '_' + UserInfo.getUserId();
        }
        update orgs;

        Record_Matching_Formula__c formula = new Record_Matching_Formula__c(
            Name = 'Test Name',
            Configuration_Source_Org__c = orgs.get(0).Id,
            Object__c = 'Test Object'
        );
        insert formula;
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

    private static Org__c getOrg() {
        Org__c org = [SELECT Id, Name FROM Org__c LIMIT 1];
        return org;
    }

    private static Record_Matching_Formula__c getFormula() {
        Record_Matching_Formula__c recordMatchingFormula = [
                SELECT Id, Name, Configuration_Source_Org__c, Object__c, Hash_Formula__c, Field_1__c, Field_2__c, Field_3__c
                FROM Record_Matching_Formula__c
                LIMIT 1
            ];
        return recordMatchingFormula;
    }

}