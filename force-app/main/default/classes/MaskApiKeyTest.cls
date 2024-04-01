@IsTest
private with sharing class MaskApiKeyTest {
    @TestSetup
    private static void setup() {
        User standardUser = setupUser();
        System.runAs(standardUser) {
            setupLicense();
        }
    }

    @IsTest
    private static void doNotMaskApiKey() {
        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            // Setup
            Personal_Settings__c settings = createPersonalSettings(false);
            upsert settings;

            // Exercise
            Test.startTest();
            String maskedApiKey = new MaskApiKey(settings.API_Key__c).execute();
            Test.stopTest();

            // Verify
            System.assertEquals(settings.API_Key__c, maskedApiKey, 'API Key should be the same');
        }
    }

    @IsTest
    private static void maskApiKeyUsingStars() {
        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            // Setup
            Personal_Settings__c settings = createPersonalSettings(true);
            upsert settings;

            // Exercise
            Test.startTest();
            String maskedApiKey = new MaskApiKey(settings.API_Key__c).execute();
            Test.stopTest();

            // Verify
            System.assertEquals('*'.repeat(settings.API_Key__c.length()), maskedApiKey, 'API Key should be masked');
        }
    }

    @IsTest
    private static void maskApiKeyUsingPlaceholder() {
        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            // Setup
            Personal_Settings__c settings = createPersonalSettings(true);
            upsert settings;

            // Exercise
            Test.startTest();
            String maskedApiKey = new MaskApiKey(settings.API_Key__c).usingPlaceholder().execute();
            Test.stopTest();

            // Verify
            System.assertEquals(Label.ApiKeyPlaceholder, maskedApiKey, 'API Key should be replaced by placeholder');
        }
    }

    @IsTest
    private static void maskNull() {
        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            // Setup
            Personal_Settings__c settings = createPersonalSettings(true);
            settings.API_Key__c = null;
            upsert settings;

            // Exercise
            Test.startTest();
            String maskedApiKey = new MaskApiKey(settings.API_Key__c).execute();
            Test.stopTest();

            // Verify
            System.assertEquals(null, maskedApiKey, 'API Key should be empty');
        }
    }

    @IsTest
    private static void maskEmpty() {
        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            // Setup
            Personal_Settings__c settings = createPersonalSettings(true);
            settings.API_Key__c = '';
            upsert settings;

            // Exercise
            Test.startTest();
            String maskedApiKey = new MaskApiKey(settings.API_Key__c).execute();
            Test.stopTest();

            // Verify
            System.assertEquals('', maskedApiKey, 'API Key should be empty');
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

    private static Personal_Settings__c createPersonalSettings(Boolean maskApiKey) {
        Personal_Settings__c settings = new Personal_Settings__c();
        settings.API_Key__c = 'Test API Key';
        settings.MaskApiKey__c = maskApiKey;
        return settings;
    }
}