@isTest
public with sharing class ComplianceRulePermissionsValidatorTest {
    @TestSetup
    private static void setupData() {
        insertData();
    }

    @isTest
    private static void executeHappyPath() {
        System.runAs(getTestUser()) {
            // Exercise
            String error = new ComplianceRulePermissionsValidator().execute().toString();

            // Verify
            System.assert(String.isBlank(error), 'There should not be any error in the permission validation');
        }
    }

    @isTest
    private static void failsWhenApiKeyIsMissing() {
        System.runAs(getTestUser()) {
            // Setup
            Personal_Settings__c personalSettings = Personal_Settings__c.getInstance();
            personalSettings.API_Key__c = null;
            upsert personalSettings;

            // Exercise
            String error = new ComplianceRulePermissionsValidator().execute().toString();

            // Verify
            System.assertEquals(Label.CCH_MISSING_API_KEY, error, 'Validation should fail due to the missing API Key');
        }
    }

    @isTest
    private static void failsWhenCCHFeatureIsDisabled() {
        System.runAs(getTestUser()) {
            // Setup
            TestUtilities.enableLicenses(1, 1, 1, 1, 0);

            // Exercise
            String error = new ComplianceRulePermissionsValidator().execute().toString();

            // Verify
            System.assertEquals(Label.FEATURE_NOT_SUPPORTED, error, 'Validation should fail because CCH Feature is disabled');
        }
    }

    @isTest
    private static void failsWhenCCHLicenseIsDisabled() {
        User testUser = getTestUser();
        System.runAs(testUser) {
            // Setup
            TestUtilities.assignLicense(String.valueOf(testUser.Username), true, true, true, true, false);

            // Exercise
            String error = new ComplianceRulePermissionsValidator().execute().toString();

            // Verify
            System.assertEquals(Label.CCH_LICENSE_NOT_ENABLED, error, 'Validation should fail because CCH License is disabled');
        }
    }

    private static void insertData() {
        User adminUser = setupUser();
        System.runAs(adminUser) {
            TestUtilities.assignLicense(String.valueOf(adminUser.Username), true, true, true, true, true);

            Personal_Settings__c personalSettings = Personal_Settings__c.getInstance();
            personalSettings.API_Key__c = 'Test Api Key';
            upsert personalSettings;
        }
    }

    private static User setupUser() {
        ITestDefaults userCreation = new CopadoSetupTestDefaults.UserDefaults().createRunAsUsers().executeDML();
        User adminUser = userCreation.getRunAsUsers().get('Admin')[0];

        return adminUser;
    }

    private static User getTestUser() {
        User testUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test@test.org' LIMIT 1].get(0);
        TestUtilities.assignLicense(String.valueOf(testUser.Username), true, true, true, true, true);

        return testUser;
    }
}