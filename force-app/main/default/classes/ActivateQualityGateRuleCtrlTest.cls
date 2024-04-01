@IsTest
private with sharing class ActivateQualityGateRuleCtrlTest {
    private static final String NONE_VALUE = 'None'; // @Note: Has to be one of the packaged values for the Copado Test Tool picklist

    @IsTest
    private static void activateQualityGateRule() {
        System.runAs(getRunAsUser()) {
            // Setup
            TestToolsSelector.mock(new List<TestTool__mdt>{ new TestTool__mdt(MasterLabel = NONE_VALUE, TestType__c = 'Mock Type') });

            Quality_Gate_Rule__c rule = (Quality_Gate_Rule__c) new QualityGateRule()
                .action('Promotion')
                .sequence('Before')
                .tool(NONE_VALUE)
                .active(false)
                .add(
                    new QualityGateRuleCondition()
                        .platform('Other')
                        .environment(new Environment().platform('Other'))
                        .extensionConfiguration(getExtensionConfigurationId())
                )
                .persist();

            // Exercise
            Test.startTest();
            ActivateQualityGateRuleCtrl.ActivationResult result = ActivateQualityGateRuleCtrl.activate(rule.Id);
            Test.stopTest();

            // Verify
            Quality_Gate_Rule__c updatedRule = [SELECT Status__c FROM Quality_Gate_Rule__c WHERE Id = :rule.Id LIMIT 1][0];
            System.assert(result.activated, 'Quality Gate Rule should be activated');
            System.assert(String.isBlank(result.message), 'There should be no error message');
            System.assertEquals('Active', updatedRule.Status__c, 'Quality Gate Rule status should be Active');
        }
    }

    @IsTest
    private static void activateQualityGateRuleWithoutConditions() {
        System.runAs(getRunAsUser()) {
            // Setup
            TestToolsSelector.mock(new List<TestTool__mdt>{ new TestTool__mdt(MasterLabel = NONE_VALUE, TestType__c = 'Mock Type') });

            Quality_Gate_Rule__c rule = (Quality_Gate_Rule__c) new QualityGateRule()
                .action('Promotion')
                .sequence('Before')
                .tool(NONE_VALUE)
                .active(false)
                .persist();

            // Exercise
            Test.startTest();
            ActivateQualityGateRuleCtrl.ActivationResult result = ActivateQualityGateRuleCtrl.activate(rule.Id);
            Test.stopTest();

            // Verify
            Quality_Gate_Rule__c updatedRule = [SELECT Status__c FROM Quality_Gate_Rule__c WHERE Id = :rule.Id LIMIT 1][0];
            System.assert(!result.activated, 'Quality Gate Rule should not be activated');
            System.assert(String.isNotBlank(result.message), 'There should be an error message');
            System.assertEquals('Inactive', updatedRule.Status__c, 'Quality Gate Rule status should be Inactive');
        }
    }

    @TestSetup
    private static void setup() {
        TestUtilities.getAllMultilicense();
        User runAsUser = createTestUserWithPermissionSets();
        System.runAs(runAsUser) {
            TestUtilities.assignLicense(String.valueOf(runAsUser.Username), true, true, true, true, true, true);
            createExtensionConfiguration();
        }
    }

    private static User createTestUserWithPermissionSets() {
        User result = TestDataFactory.createUsers()[1];

        // To be able to create Quality Gate Rules: we need Configure_AQF permissions.
        List<PermissionSet> permissionSets = [
            SELECT Id
            FROM PermissionSet
            WHERE Name IN ('Copado_User', 'Copado_Functions', 'Copado_Job_Engine', 'Configure_AQF')
        ];
        List<PermissionSetAssignment> assignments = new List<PermissionSetAssignment>();
        for (PermissionSet permissionSet : permissionSets) {
            assignments.add(new PermissionSetAssignment(AssigneeId = result.Id, PermissionSetId = permissionSet.Id));
        }
        insert assignments;

        return result;
    }

    private static User getRunAsUser() {
        return [SELECT Id FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1];
    }

    private static Id getExtensionConfigurationId() {
        return [SELECT Id FROM ExtensionConfiguration__c LIMIT 1].id;
    }

    private static ExtensionConfiguration__c createExtensionConfiguration() {
        ExtensionConfiguration__c extensionConfig = new ExtensionConfiguration__c(
            ExtensionTool__c = 'Manual Tests', // @Note: Has to be one of the packaged values for this picklist field
            ExtensionApplication__c = 'Test',
            Active__c = true
        );

        insert extensionConfig;
        return extensionConfig;
    }
}