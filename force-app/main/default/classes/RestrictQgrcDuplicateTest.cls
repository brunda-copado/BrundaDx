@IsTest
private class RestrictQgrcDuplicateTest {
    private static final String MANUAL_TESTS_VALUE = 'Manual Tests'; // @Note: Has to be one of the packaged values for the picklists

    @IsTest
    private static void verifyActiveQgrcSimilarityError() {
        System.runAs(getRunAsUser()) {
            // Setup
            String errorMessage;
            Id extensionConfigurationId = getExtensionConfigurationId();

            Quality_Gate_Rule__c rule = (Quality_Gate_Rule__c) createQualityGateRule()
                .add(
                    new QualityGateRuleCondition()
                        .platform('Other')
                        .environment(new Environment().platform('Other'))
                        .extensionConfiguration(extensionConfigurationId)
                )
                .persist();

            rule.Status__c = QualityGateConstants.ACTIVE;
            update rule;

            List<Quality_Gate_Rule__c> qualityGateRules = [SELECT Id FROM Quality_Gate_Rule__c];

            // Exercise
            try {
                new QualityGateRuleCondition()
                    .qualityGateRuleId(qualityGateRules[0].Id)
                    .platform('Other')
                    .environment(new Environment().platform('Other'))
                    .extensionConfiguration(extensionConfigurationId)
                    .persist();
            } catch (Exception exceptionRecord) {
                errorMessage = exceptionRecord.getMessage();
            }

            // Verify
            System.assert(
                errorMessage.contains(Label.Similar_Quality_Gate_Rule_Condition_Error),
                'Users should not be able to create similar quality gate rule condition.'
            );
        }
    }

    @IsTest
    private static void verifyActiveQgrcDuplicateError() {
        System.runAs(getRunAsUser()) {
            // Setup
            String errorMessage;
            Id extensionConfigurationId = getExtensionConfigurationId();

            Quality_Gate_Rule__c rule = (Quality_Gate_Rule__c) createQualityGateRule()
                .add(
                    new QualityGateRuleCondition()
                        .platform('Other')
                        .environment(new Environment().platform('Other'))
                        .extensionConfiguration(extensionConfigurationId)
                )
                .persist();

            rule.Status__c = QualityGateConstants.ACTIVE;
            update rule;

            List<Quality_Gate_Rule__c> qualityGateRules = [SELECT Id FROM Quality_Gate_Rule__c];
            List<Environment__c> environments = [SELECT Id FROM Environment__c];

            // Exercise
            try {
                new QualityGateRuleCondition()
                    .qualityGateRuleId(qualityGateRules[0].Id)
                    .platform('Other')
                    .environmentId(environments[0].Id)
                    .extensionConfiguration(extensionConfigurationId)
                    .persist();
            } catch (Exception exceptionRecord) {
                errorMessage = exceptionRecord.getMessage();
            }

            // Verify
            System.assert(
                errorMessage.contains(Label.Duplicate_Quality_Gate_Rule_Condition),
                'Users should not be able to create duplicate quality gate rule condition.'
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

    private static QualityGateRule createQualityGateRule() {
        TestToolsSelector.mock(new List<TestTool__mdt>{ new TestTool__mdt(MasterLabel = 'None', TestType__c = 'Mock Type') });

        return new QualityGateRule()
            .actions(new List<String>{ 'Promotion', 'PromotionDeployment' })
            .sequence('Before')
            .tool('None') // @Note: Has to be one of the packaged values for the Copado Test Tool picklist
            .active(false)
            .name('Rule1');
    }
}