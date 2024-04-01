@IsTest
private class CalculateQGCScopeWeightTest {
    private static final String NONE_VALUE = 'None'; // @Note: Has to be one of the packaged values for the Copado Test Tool picklist

    @IsTest
    private static void calculateScopeWeight() {
        System.runAs(getRunAsUser()) {
            // Setup
            createQualityGateRule()
                .add(
                    new QualityGateRuleCondition()
                        .platform('Salesforce')
                        .pipeline(new Pipeline().setPlatform('Salesforce'))
                        .extensionConfiguration(getExtensionConfigurationId())
                )
                .persist();

            activateQualityGateRules();

            Quality_Gate_Rule_Condition__c condition = getQualityGateRuleCondition();

            // Exercise
            Integer scopeWeight = new CalculateQGCScopeWeight(condition).execute();

            // Verify

            // 'Platform' => 5 + 'Pipeline' => 10
            System.assertEquals(15, scopeWeight, 'Scope weight should be 15 (Platform: 5 + Pipeline: 10)');
        }
    }

    @IsTest
    private static void calculateScopeWeightWithEnvironment() {
        System.runAs(getRunAsUser()) {
            // Setup
            createQualityGateRule()
                .add(
                    new QualityGateRuleCondition()
                        .platform('Other')
                        .environment(new Environment().platform('Other'))
                        .extensionConfiguration(getExtensionConfigurationId())
                )
                .persist();

            activateQualityGateRules();

            Quality_Gate_Rule_Condition__c condition = getQualityGateRuleCondition();

            // Exercise
            Integer scopeWeight = new CalculateQGCScopeWeight(condition).execute();

            // Verify

            // 'Platform' => 5 + 'Environment' => 20
            System.assertEquals(25, scopeWeight, 'Scope weight should be 20 (Platform: 5 + Environment: 20)');
        }
    }

    @IsTest
    private static void calculateScopeWeightWithStage() {
        System.runAs(getRunAsUser()) {
            // Setup
            createQualityGateRule()
                .add(
                    new QualityGateRuleCondition()
                        .platform('Other')
                        .stage(new Stage().name('Dev').metaStage('Build'))
                        .extensionConfiguration(getExtensionConfigurationId())
                )
                .persist();

            activateQualityGateRules();

            Quality_Gate_Rule_Condition__c condition = getQualityGateRuleCondition();

            // Exercise
            Integer scopeWeight = new CalculateQGCScopeWeight(condition).execute();

            // Verify

            // 'Platform' => 5 + 'Stage' => 15
            System.assertEquals(20, scopeWeight, 'Scope weight should be 20 (Platform: 5 + Stage: 15)');
        }
    }

    //HELPER

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
        TestToolsSelector.mock(new List<TestTool__mdt>{ new TestTool__mdt(MasterLabel = NONE_VALUE, TestType__c = 'Mock Type') });

        return new QualityGateRule()
            .actions(new List<String>{ 'Promotion', 'PromotionDeployment' })
            .sequence('Before')
            .tool(NONE_VALUE)
            .active(false)
            .name('Rule1');
    }

    private static Quality_Gate_Rule_Condition__c getQualityGateRuleCondition() {
        return [SELECT Id, Environment__c, Stage__c, Pipeline__c, Platform__c, Filter_Criteria__c FROM Quality_Gate_Rule_Condition__c LIMIT 1];
    }

    private static void activateQualityGateRules() {
        Quality_Gate_Rule__c rule = [SELECT Id, Status__c FROM Quality_Gate_Rule__c LIMIT 1];
        rule.Status__c = QualityGateConstants.ACTIVE;
        update rule;
    }
}