@IsTest
private with sharing class UniversalFeatureToggleTest {
    private static UniversalFeatureToggle.Feature feature1 = UniversalFeatureToggle.Feature.APEX_TESTS_WITH_V2;
    private static UniversalFeatureToggle.Feature feature2 = UniversalFeatureToggle.Feature.UNUSED_2;
    private static UniversalFeatureToggle.Feature feature3 = UniversalFeatureToggle.Feature.UNUSED_3;
    private static UniversalFeatureToggle.Feature feature4 = UniversalFeatureToggle.Feature.UNUSED_4;
    private static UniversalFeatureToggle.Feature feature5 = UniversalFeatureToggle.Feature.UNUSED_5;

    @IsTest
    private static void isDisabled() {
        System.runAs(getTestUser()) {
            // Setup & Exercise
            // Note: 19 in binary is 10011
            UniversalFeatureToggle.mockValue = 19;
            UniversalFeatureToggle toggle = new UniversalFeatureToggle();

            // Verify
            System.assert(toggle.isDisabled(feature3), 'Feature 3 should show as disabled, as the third 0 in 10011 indicates (reading right-left)');
            System.assert(toggle.isDisabled(feature4), 'Feature 4 should show as disabled, as the fourth 0 in 10011 indicates (reading right-left)');
        }
    }

    @IsTest
    private static void isEnabled() {
        System.runAs(getTestUser()) {
            // Setup & Exercise
            // Note: 19 in binary is 10011
            UniversalFeatureToggle.mockValue = 19;
            UniversalFeatureToggle toggle = new UniversalFeatureToggle();

            // Verify
            System.assert(toggle.isEnabled(feature1), 'Feature 1 should show as enabled, as the first 1 in 10011 indicates (reading right-left)');
            System.assert(toggle.isEnabled(feature2), 'Feature 2 should show as enabled, as the third 1 in 10011 indicates (reading right-left)');
            System.assert(toggle.isEnabled(feature5), 'Feature 5 should show as enabled, as the fifth 1 in 10011 indicates (reading right-left)');
        }
    }

    @TestSetup
    private static void setupUser() {
        new CopadoSetupTestDefaults.UserDefaults().createRunAsUsers().executeDML();
    }

    private static User getTestUser() {
        return [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test@test.org' LIMIT 1].get(0);
    }
}