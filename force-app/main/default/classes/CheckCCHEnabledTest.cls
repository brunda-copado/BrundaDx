@isTest
private class CheckCCHEnabledTest {
    @TestSetup
    private static void setupData() {
        insertData();
    }

    @isTest
    private static void executeHappyPath() {
        System.runAs(getTestUser()) {
            // Exercise
            Boolean isEnabled = Feature.isCCHEnabled();

            // Verify
            Assert.isTrue(isEnabled, 'CCH feature is enabled and the user has license too');
        }
    }

    @isTest
    private static void whenCCHFeatureIsDisabled() {
        System.runAs(getTestUser()) {
            // Setup
            String exceptionMessage;
            TestUtilities.enableLicenses(1, 1, 1, 1, 0);

            // Exercise
            try {
                Feature.isCCHEnabled();
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }

            // Verify
            Assert.areEqual(Label.FEATURE_NOT_SUPPORTED + ': ' + Label.Compliance_Hub, exceptionMessage, 'CCH feature is disabled.');
        }
    }

    @isTest
    private static void whenCCHLicenseIsDisabled() {
        User testUser = getTestUser();
        System.runAs(testUser) {
            // Setup
            String exceptionMessage;
            TestUtilities.assignLicense(String.valueOf(testUser.Username), true, true, true, true, false);

            // Exercise
            try {
                Feature.isCCHEnabled();
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }

            // Verify
            Assert.areEqual(Label.CCH_LICENSE_NOT_ENABLED, exceptionMessage, 'CCH feature is disabled.');
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