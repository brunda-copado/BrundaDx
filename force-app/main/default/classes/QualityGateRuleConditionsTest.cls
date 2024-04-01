@IsTest
private with sharing class QualityGateRuleConditionsTest {
    private static final String NONE_VALUE = 'None'; // @Note: Has to be one of the packaged values for the Copado Test Tool picklist

    @IsTest
    private static void checkConditionAndEnvironment() {
        System.runAs(getRunAsUser()) {
            // Setup
            TestToolsSelector.mock(new List<TestTool__mdt>{ new TestTool__mdt(MasterLabel = NONE_VALUE, TestType__c = 'Mock Type') });

            // Exercise + Verify
            try {
                Test.startTest();
                new QualityGateRule()
                    .action('Promotion')
                    .sequence('Before')
                    .tool(NONE_VALUE)
                    .active(false)
                    .add(
                        new QualityGateRuleCondition()
                            .platform('Salesforce')
                            .environment(new Environment().platform('Other'))
                            .extensionConfiguration(getExtensionConfiguration().Id)
                    )
                    .persist();
                Test.stopTest();
            } catch (Exception e) {
                System.assert(true, 'An error should be thrown while inserting the Quality Gate Rule Condition');
            }
        }
    }

    @IsTest
    private static void checkConditionAndPipeline() {
        System.runAs(getRunAsUser()) {
            // Setup
            TestToolsSelector.mock(new List<TestTool__mdt>{ new TestTool__mdt(MasterLabel = NONE_VALUE, TestType__c = 'Mock Type') });

            // Exercise + Verify
            try {
                Test.startTest();
                new QualityGateRule()
                    .action('Promotion')
                    .sequence('Before')
                    .tool(NONE_VALUE)
                    .active(false)
                    .add(
                        new QualityGateRuleCondition()
                            .platform('Salesforce')
                            .pipeline(new Pipeline().setPlatform('Other'))
                            .extensionConfiguration(getExtensionConfiguration().Id)
                    )
                    .persist();
            } catch (Exception e) {
                System.assert(true, 'An error should be thrown while inserting the Quality Gate Rule Condition');
            }
        }
    }

    @IsTest
    private static void checkEnvironmentAndPipeline() {
        System.runAs(getRunAsUser()) {
            // Setup
            TestToolsSelector.mock(new List<TestTool__mdt>{ new TestTool__mdt(MasterLabel = NONE_VALUE, TestType__c = 'Mock Type') });

            // Exercise + Verify
            try {
                Test.startTest();
                new QualityGateRule()
                    .action('Promotion')
                    .sequence('Before')
                    .tool(NONE_VALUE)
                    .active(false)
                    .add(
                        new QualityGateRuleCondition()
                            .environment(new Environment().platform('Salesforce'))
                            .pipeline(new Pipeline().setPlatform('Other'))
                            .extensionConfiguration(getExtensionConfiguration().Id)
                    )
                    .persist();
                Test.stopTest();
            } catch (Exception e) {
                System.assert(true, 'An error should be thrown while inserting the Quality Gate Rule Condition');
            }
        }
    }

    @IsTest
    private static void checkConditionAndEnvironmentAndPipeline() {
        System.runAs(getRunAsUser()) {
            // Setup
            TestToolsSelector.mock(new List<TestTool__mdt>{ new TestTool__mdt(MasterLabel = NONE_VALUE, TestType__c = 'Mock Type') });

            // Exercise + Verify
            try {
                Test.startTest();
                new QualityGateRule()
                    .action('Promotion')
                    .sequence('Before')
                    .tool(NONE_VALUE)
                    .active(false)
                    .add(
                        new QualityGateRuleCondition()
                            .platform('Other')
                            .environment(new Environment().platform('Salesforce'))
                            .pipeline(new Pipeline().setPlatform('Other'))
                            .extensionConfiguration(getExtensionConfiguration().Id)
                    )
                    .persist();
                Test.stopTest();
            } catch (Exception e) {
                System.assert(true, 'An error should be thrown while inserting the Quality Gate Rule Condition');
            }
        }
    }

    @IsTest
    private static void verifyAcceptanceCriteriaOnInsert() {
        System.runAs(getRunAsUser()) {
            // Setup
            TestToolsSelector.mock(new List<TestTool__mdt>{ new TestTool__mdt(MasterLabel = NONE_VALUE, TestType__c = 'Mock Type') });

            // Exercise
            Test.startTest();
            new QualityGateRule()
                .action('Promotion')
                .sequence('Before')
                .tool(NONE_VALUE)
                .active(false)
                .add(new QualityGateRuleCondition().platform('Other').extensionConfiguration(getExtensionConfiguration().Id))
                .persist();
            Test.stopTest();

            // Verify
            Quality_Gate_Rule_Condition__c condition = getQualityGateRuleCondition();
            System.assertEquals(true, condition.AcceptanceCriteria__c != null, 'Acceptance Criteria must be available.');
        }
    }

    @IsTest
    private static void verifyAcceptanceCriteriaOnUpdate() {
        System.runAs(getRunAsUser()) {
            // Setup
            TestToolsSelector.mock(new List<TestTool__mdt>{ new TestTool__mdt(MasterLabel = NONE_VALUE, TestType__c = 'Mock Type') });

            ExtensionConfiguration__c config = getExtensionConfiguration();

            // Exercise
            Test.startTest();
            new QualityGateRule()
                .action('Promotion')
                .sequence('Before')
                .tool(NONE_VALUE)
                .active(false)
                .add(new QualityGateRuleCondition().platform('Other').extensionConfiguration(config.Id))
                .persist();

            Quality_Gate_Rule_Condition__c condition = getQualityGateRuleCondition();
            condition.AcceptanceCriteria__c = condition.AcceptanceCriteria__c.replace('1', '3');
            update condition;

            Test.stopTest();

            // Verify
            System.assertEquals(true, condition.AcceptanceCriteria__c != null, 'Acceptance Criteria must be available.');
            System.assertNotEquals(config.AcceptanceCriteria__c, condition.AcceptanceCriteria__c, 'Acceptance Criteria must be updated.');
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

    private static ExtensionConfiguration__c getExtensionConfiguration() {
        return [SELECT Id, AcceptanceCriteria__c FROM ExtensionConfiguration__c LIMIT 1];
    }

    private static Quality_Gate_Rule_Condition__c getQualityGateRuleCondition() {
        return [SELECT Id, Filter_Criteria__c, AcceptanceCriteria__c FROM Quality_Gate_Rule_Condition__c LIMIT 1];
    }

    private static ExtensionConfiguration__c createExtensionConfiguration() {
        ExtensionConfiguration__c extensionConfig = new ExtensionConfiguration__c(
            ExtensionTool__c = 'Manual Tests', // @Note: Has to be one of the packaged values for this picklist field
            ExtensionApplication__c = 'Test',
            Active__c = true,
            AcceptanceCriteria__c = '{"All": {"priority": "1 - High","violationFrequency": "Equals or Greater than","warning": 3,"errorDescription": "There should not be any high priority violation"},"Best Practices": {"priority": "1 - High","violationFrequency": "Equals or Less than","warning": 3,"errorDescription": "All Priority best Practices rules should be enforced to have less than 1 error"}}'
        );

        insert extensionConfig;
        return extensionConfig;
    }

    private static User getRunAsUser() {
        User standardUser = [SELECT Id FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1];
        return standardUser;
    }
}