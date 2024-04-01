@isTest
private with sharing class ExtensionConfigurationAutoActivationTest {
    private static final String TEST_TOOL_NAME = 'Manual Tests'; // @Note: Has to be one of the packaged values for the picklists
    private static final String TEST_TYPE_NAME = 'Functional Test';
    private static final String EXT_CONFIGURATION_NAME = 'Mock Configuration';
    private static final String UI_SECTION_NAME = 'Mock Section';
    private static final String TEST_TOOL_TEMPLATE = 'MockTemplate';

    @isTest
    private static void activateECNoneExtensionTool() {
        System.runAs(licensedUser()) {
            //Setup
            ExtensionConfiguration__c extensionConfiguration = initExtensionConfiguration();
            insert extensionConfiguration;

            // Exercise
            Test.startTest();
            ExtensionConfigurationAutoActivationCtrl.requiresActivationLogic(extensionConfiguration.Id);
            Test.stopTest();

            // Verify
            extensionConfiguration = [SELECT Active__c FROM ExtensionConfiguration__c WHERE Id = :extensionConfiguration.Id LIMIT 1];
            System.assertEquals(true, extensionConfiguration.Active__c, 'Extension Configuration should be activated successfully');
        }
    }

    @isTest
    private static void activateECValidExtensionTool() {
        System.runAs(licensedUser()) {
            //Setup
            mockUiSection();
            ExtensionConfiguration__c extensionConfiguration = initExtensionConfiguration();
            insert extensionConfiguration;

            // Exercise
            Test.startTest();
            ExtensionConfigurationAutoActivationCtrl.requiresActivationLogic(extensionConfiguration.Id);
            Test.stopTest();

            // Verify
            extensionConfiguration = [SELECT Active__c FROM ExtensionConfiguration__c WHERE Id = :extensionConfiguration.Id LIMIT 1];
            System.assertEquals(false, extensionConfiguration.Active__c, 'Extension Configuration should not be activated');
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

    private static UISection__mdt mockUiSection() {
        TestTool__mdt testTool = new TestToolsSelector().byName(TEST_TOOL_NAME);
        UISection__mdt mockUiSection = new UISection__mdt(MasterLabel = UI_SECTION_NAME, TestTool__c = testTool.Id);

        UiSectionsSelector.mock(new List<UISection__mdt>{ mockUiSection });
        return mockUiSection;
    }
}