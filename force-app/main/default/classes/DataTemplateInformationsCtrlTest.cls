@isTest
private class DataTemplateInformationsCtrlTest {
    @TestSetup
    private static void setup() {
        User standardUser = setupUser();
        System.runAs(standardUser) {
            setupLicense();
            createTestData();
        }
    }

    @isTest
    private static void getRelatedObjectCount() {
        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            // Setup
            Data_Template__c dataTemplate = [SELECT Id, Name FROM Data_Template__c WHERE Name = 'Test'];

            // Exercise
            Integer relatedObjectCount = DataTemplateInformationsCtrl.getRelatedObjectCount(dataTemplate.Id);

            // Verify
            System.assertEquals(2, relatedObjectCount, 'Data template does not have the correct number of related object as expected');
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

    private static void createTestData() {
        List<Environment__c> environments = TestDataFactory.createEnvironments(1);
        List<Org__c> orgs = TestDataFactory.createOrgCredentials(1, UserInfo.getUserName(), environments);
        for (Org__c org : orgs) {
            org.SFDC_Org_ID__c = UserInfo.getOrganizationId() + '_' + UserInfo.getUserId();
        }
        update orgs;

        Data_Template__c dataTemplateContact = TestDataFactory.createDataTemplate(
            'Test Contact',
            orgs.get(0).Id,
            'Contact',
            null,
            null,
            null,
            null,
            null
        );

        Data_Template__c parentAccountTemplate = TestDataFactory.createDataTemplate(
            'Test Account',
            orgs.get(0).Id,
            'Account',
            null,
            null,
            null,
            null,
            null
        );

        Data_Template__c accountTemplate = TestDataFactory.createDataTemplate(
            'Test',
            orgs.get(0).Id,
            'Account',
            dataTemplateContact,
            parentAccountTemplate,
            null,
            null,
            null
        );
    }
}