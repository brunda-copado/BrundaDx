@isTest
private with sharing class TestDefinitionCtrlTest {
    private static final String TEST_TOOL_NAME = 'Manual Tests'; // @Note: Has to be one of the packaged values for the picklists
    private static final String TEST_TYPE_NAME = 'Functional Test';
    private static final String EXT_CONFIGURATION_NAME = 'Mock Configuration';
    private static final String UI_SECTION_NAME = 'Mock Section';
    private static final String MOCK_TEST = 'Mock Test';

    @isTest
    private static void checkForUiSections() {
        System.runAs(licensedUser()) {
            //Setup
            mockUiSection();
            ExtensionConfiguration__c extensionConfiguration = initExtensionConfiguration();
            insert extensionConfiguration;
            Test__c test = createTest(extensionConfiguration.Id);
            insert test;

            // Exercise
            List<Boolean> results = TestDefinitionCtrl.checkForUiSections(test.Id);

            // Verify
            System.assertEquals(2, results.size(), 'List should have two rows');
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
        return new ExtensionConfiguration__c(
            Name = EXT_CONFIGURATION_NAME,
            ExtensionApplication__c = 'Test',
            ExtensionTool__c = TEST_TOOL_NAME,
            Active__c = true
        );
    }

    private static Test__c createTest(Id extensionConfigId) {
        return new Test__c(Name = MOCK_TEST, ExtensionConfiguration__c = extensionConfigId);
    }

    private static UISection__mdt mockUiSection() {
        TestTool__mdt testTool = new TestToolsSelector().byName(TEST_TOOL_NAME);
        UISection__mdt mockUiSection = new UISection__mdt(MasterLabel = UI_SECTION_NAME, TestTool__c = testTool.Id);

        UiSectionsSelector.mock(new List<UISection__mdt>{ mockUiSection });
        return mockUiSection;
    }
}