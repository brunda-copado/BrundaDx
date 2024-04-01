@IsTest
private class RestrictQgrDuplicateTest {
    private static final String NONE_VALUE = 'None'; // @Note: Has to be one of the packaged values for the Copado Test Tool picklist

    @IsTest
    private static void verifyActiveQgrDuplicateErrorOnInsert() {
        System.runAs(getRunAsUser()) {
            // Setup
            TestToolsSelector.mock(new List<TestTool__mdt>{ new TestTool__mdt(MasterLabel = NONE_VALUE, TestType__c = 'Mock Type') });

            String errorMessage;
            Quality_Gate_Rule__c rule = (Quality_Gate_Rule__c) new QualityGateRule()
                .action('Promotion')
                .sequence('Before')
                .tool(NONE_VALUE)
                .active(false)
                .name('Rule1')
                .persist();
            rule.Status__c = QualityGateConstants.ACTIVE;
            update rule;

            // Exercise
            try {
                Quality_Gate_Rule__c rule1 = (Quality_Gate_Rule__c) new QualityGateRule()
                    .action('Promotion')
                    .sequence('Before')
                    .tool(NONE_VALUE)
                    .active(false)
                    .name('Rule2')
                    .persist();
                rule1.Status__c = QualityGateConstants.ACTIVE;
                update rule1;
            } catch (Exception error) {
                errorMessage = error.getMessage();
            }

            // Verify
            System.assert(
                errorMessage.contains(Label.Duplicate_Quality_Gate_Rule_Error),
                'Users should not be able to create duplicate quality gate rule.'
            );
        }
    }

    @IsTest
    private static void verifyInactiveQgrDuplicateOnInsert() {
        System.runAs(getRunAsUser()) {
            // Setup
            TestToolsSelector.mock(new List<TestTool__mdt>{ new TestTool__mdt(MasterLabel = NONE_VALUE, TestType__c = 'Mock Type') });

            String errorMessage;
            Quality_Gate_Rule__c rule = (Quality_Gate_Rule__c) new QualityGateRule()
                .action('Promotion')
                .sequence('Before')
                .tool(NONE_VALUE)
                .active(false)
                .name('Rule1')
                .persist();

            rule.Status__c = QualityGateConstants.ACTIVE;
            update rule;

            // Exercise
            try {
                new QualityGateRule().action('Promotion').sequence('Before').tool(NONE_VALUE).active(false).name('Rule2').persist();
            } catch (Exception error) {
                errorMessage = error.getMessage();
            }

            // Verify
            System.assert(errorMessage == null, 'Users should be able to create duplicate inactive quality gate rule.');
        }

    }

    @IsTest
    private static void verifyActiveQgrDuplicateErrorOnUpdate() {
        System.runAs(getRunAsUser()) {
            // Setup
            TestToolsSelector.mock(new List<TestTool__mdt>{ new TestTool__mdt(MasterLabel = NONE_VALUE, TestType__c = 'Mock Type') });

            String errorMessage;
            Quality_Gate_Rule__c rule = (Quality_Gate_Rule__c) new QualityGateRule()
                .action('Promotion')
                .sequence('Before')
                .tool(NONE_VALUE)
                .active(false)
                .name('Rule1')
                .persist();
            rule.Status__c = QualityGateConstants.ACTIVE;
            update rule;
            new QualityGateRule().action('Promotion').sequence('Before').tool(NONE_VALUE).active(false).name('Rule2').persist();

            // Exercise
            try {
                List<Quality_Gate_Rule__c> qualityGateRules = [SELECT Id, Status__c FROM Quality_Gate_Rule__c WHERE Name = 'Rule2'];
                qualityGateRules[0].Status__c = 'Active';
                update qualityGateRules;
            } catch (Exception error) {
                errorMessage = error.getMessage();
            }

            // Verify
            System.assert(
                errorMessage.contains(Label.Duplicate_Quality_Gate_Rule_Error),
                'Users should not be able to update duplicate quality gate rule.'
            );
        }

    }

    @TestSetup
    private static void setup() {
        TestUtilities.getAllMultilicense();
        User user = (User) new User_t()
            .assign(new PermissionSetAssignment_t().copadoUser())
            .assign(new PermissionSetAssignment_t().qualityGatesAdmin())
            .persist();
        System.runAs(user) {
            new CopadoLicense().user(user).enableAll().persist();
            createExtensionConfiguration();
        }
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