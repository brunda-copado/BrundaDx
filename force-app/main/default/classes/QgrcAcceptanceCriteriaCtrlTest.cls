@isTest
private with sharing class QgrcAcceptanceCriteriaCtrlTest {
    private static final String MOCK_TYPE = 'Mock Testing';
    private static final String EXT_CONFIGURATION_NAME = 'Mock Configuration';
    private static final String UI_SECTION_NAME = 'Mock Section';

    @isTest
    private static void checkForUiSection() {
        System.runAs(getRunAsUser()) {
            // Setup
            createTestData();
            mockUiSection();
            Quality_Gate_Rule_Condition__c qgrc = getQualityGateRuleCondition();

            // Exercise
            Boolean result = QgrcAcceptanceCriteriaCtrl.checkForUiSection(qgrc.Id);

            // Verify
            System.assertEquals(true, result, 'Should return true as we have UI section CMDT');
        }
    }

    @isTest
    private static void uiSectionsNotFound() {
        System.runAs(getRunAsUser()) {
            // Setup
            createTestData();
            Quality_Gate_Rule_Condition__c qgrc = getQualityGateRuleCondition();

            // Exercise
            Boolean result = QgrcAcceptanceCriteriaCtrl.checkForUiSection(qgrc.Id);

            // Verify
            System.assertEquals(false, result, 'Should return false as we do not have UI section CMDT');
        }
    }

    @TestSetup
    private static void setup() {
        TestUtilities.getAllMultilicense();
        User user = (User) new User_t()
            .assign(new PermissionSetAssignment_t().copadoUser())
            .assign(new PermissionSetAssignment_t().jobEngine())
            .assign(new PermissionSetAssignment_t().functions())
            .assign(new PermissionSetAssignment_t().qualityGatesAdmin())
            .persist();
        System.runAs(user) {
            new CopadoLicense().user(user).enableAll().persist();
        }
    }

    private static User getRunAsUser() {
        return [SELECT Id FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1];
    }

    private static ExtensionConfiguration__c createExtensionConfiguration() {
        ExtensionConfiguration__c extensionConfig = new ExtensionConfiguration__c(
            Name = EXT_CONFIGURATION_NAME,
            ExtensionTool__c = 'Manual Tests', // @Note: Has to be one of the packaged values for this picklist field
            ExtensionApplication__c = 'Test',
            Active__c = true
        );

        insert extensionConfig;
        return extensionConfig;
    }

    private static UISection__mdt mockUiSection() {
        TestTool__mdt testTool = new TestToolsSelector().byName('Manual Tests');
        UISection__mdt mockUiSection = new UISection__mdt(MasterLabel = UI_SECTION_NAME, TestTool__c = testTool.Id);

        UiSectionsSelector.mock(new List<UISection__mdt>{ mockUiSection });
        return mockUiSection;
    }

    private static Id getExtensionConfigurationId() {
        return [SELECT Id FROM ExtensionConfiguration__c LIMIT 1].Id;
    }

    private static Quality_Gate_Rule_Condition__c getQualityGateRuleCondition() {
        return [SELECT Id, Filter_Criteria__c, AcceptanceCriteria__c FROM Quality_Gate_Rule_Condition__c LIMIT 1];
    }

    private static Quality_Gate_Rule__c createQualityGateRuleWithCondition() {
        TestToolsSelector.mock(new List<TestTool__mdt>{ new TestTool__mdt(MasterLabel = 'None', TestType__c = 'Mock Type') });

        Quality_Gate_Rule__c rule = (Quality_Gate_Rule__c) new QualityGateRule()
            .action('Promotion')
            .sequence('Before')
            .tool('None') // @Note: Has to be one of the packaged values for the Copado Test Tool picklist
            .active(false)
            .add(
                new QualityGateRuleCondition()
                    .platform('Other')
                    .environment(new Environment().platform('Other'))
                    .extensionConfiguration(getExtensionConfigurationId())
            )
            .persist();

        rule.Status__c = QualityGateConstants.ACTIVE;
        update rule;
        return rule;
    }

    private static void createTestData() {
        createExtensionConfiguration();
        createQualityGateRuleWithCondition();
    }
}