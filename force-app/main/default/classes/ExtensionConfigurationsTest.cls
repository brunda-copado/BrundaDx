@isTest
private with sharing class ExtensionConfigurationsTest {
    private static final String TEST_TOOL_NAME = 'Manual Tests';
    private static final String TEST_TYPE_NAME = 'Functional Test';
    private static final String EXT_CONFIGURATION_NAME = 'Mock Configuration';

    @isTest
    private static void insertExtensionConfigurations() {
        System.runAs(licensedUser()) {
            // Setup
            ExtensionConfiguration__c extensionConfiguration = initExtensionConfiguration();

            // Exercise
            insert extensionConfiguration;

            // Verify
            System.assertEquals(
                TEST_TYPE_NAME,
                [SELECT TestType__c FROM ExtensionConfiguration__c WHERE Name = :EXT_CONFIGURATION_NAME].get(0).TestType__c,
                'The test type should be the same.'
            );
        }
    }

    @isTest
    private static void updateExtensionConfigurations() {
        System.runAs(licensedUser()) {
            // Setup
            ExtensionConfiguration__c extensionConfiguration = initExtensionConfiguration();
            insert extensionConfiguration;

            extensionConfiguration.TestType__c = 'Another';

            // Exercise
            update extensionConfiguration;

            // Verify
            System.assertEquals(
                TEST_TYPE_NAME,
                [SELECT TestType__c FROM ExtensionConfiguration__c WHERE Name = :EXT_CONFIGURATION_NAME].get(0).TestType__c,
                'The test type should be updated.'
            );
        }
    }

    @isTest
    private static void deleteExtensionConfigurations() {
        System.runAs(licensedUser()) {
            // Setup
            Exception expectedException = null;

            ExtensionConfiguration__c extensionConfiguration = initExtensionConfiguration();
            extensionConfiguration.Active__c = true;
            insert extensionConfiguration;

            // Exercise
            try {
                delete extensionConfiguration;
            } catch (Exception ex) {
                expectedException = ex;
            }

            // Verify
            System.assertNotEquals(null, expectedException, 'There is an exception here.');
            System.assert(expectedException.getMessage().contains(Label.RestrictExtensionConfigDeletion), 'Error message.');
        }
    }

    // PRIVATE

    @TestSetup
    private static void insertData() {
        createTestUserWithPermissionSets();
    }

    private static User createTestUserWithPermissionSets() {
        User result = TestDataFactory.createUsers()[0];

        List<PermissionSet> permissionSets = [SELECT Id FROM PermissionSet WHERE Name IN ('Copado_User', 'Copado_Functions', 'Copado_Job_Engine')];
        List<PermissionSetAssignment> assignments = new List<PermissionSetAssignment>();
        for (PermissionSet permissionSet : permissionSets) {
            assignments.add(new PermissionSetAssignment(AssigneeId = result.Id, PermissionSetId = permissionSet.Id));
        }
        insert assignments;

        return result;
    }

    private static User licensedUser() {
        return [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
    }

    private static ExtensionConfiguration__c initExtensionConfiguration() {
        return new ExtensionConfiguration__c(Name = EXT_CONFIGURATION_NAME, ExtensionApplication__c = 'Test', ExtensionTool__c = TEST_TOOL_NAME);
    }
}