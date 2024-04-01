@IsTest
private class CalculateQGConditionWeightTest {
    private static final String NONE_VALUE = 'None'; // @Note: Has to be one of the packaged values for the Copado Test Tool picklist

    @IsTest
    private static void calculateQualityGateRuleConditionWeight() {
        System.runAs(getRunAsUser()) {
            // Setup
            createQualityGateRule()
                .add(
                    new QualityGateRuleCondition()
                        .platform('Other')
                        .environment(new Environment().platform('Other'))
                        .extensionConfiguration(getExtensionConfigurationId())
                        .filterCriteria(
                            '({$Changes.Type.equals("ApexClass")} || {$Changes.Directory.equals("ApexTrigger")}) && {$Changes.Name.notContains("Opportunity")}'
                        )
                )
                .persist();

            activateQualityGateRules();

            Quality_Gate_Rule_Condition__c condition = getQualityGateRuleConditions()[0];

            // Exercise
            Integer weight = new CalculateQGConditionWeight(condition).execute();

            // Verify

            // Scope Weight: 'Platform' => 5 + 'Environment' => 20
            // Criteria Weight: Min ('Type' => 10 * 'equals' => 10, 'Directory' => 20 * 'equals' => 10) + 'Name' => 30 * 'notContains' => 4
            System.assertEquals(245, weight, 'Weight should be 240 (Scope weight: 22 + Filter Criteria weight: 220)');
        }
    }

    @IsTest
    private static void calculateWeightMultipleQualityGateRuleCondition() {
        System.runAs(getRunAsUser()) {
            // Setup
            Id extensionConfigurationId = getExtensionConfigurationId();

            createQualityGateRule()
                .add(
                    new QualityGateRuleCondition()
                        .platform('Other')
                        .environment(new Environment().platform('Other'))
                        .extensionConfiguration(extensionConfigurationId)
                        .filterCriteria(
                            '({$Changes.Type.equals("ApexClass")} || {$Changes.Directory.equals("ApexTrigger")}) && {$Changes.Name.notContains("Opportunity")}'
                        )
                )
                .add(
                    new QualityGateRuleCondition()
                        .platform('Salesforce')
                        .pipeline(new Pipeline().setPlatform('Salesforce'))
                        .extensionConfiguration(extensionConfigurationId)
                        .filterCriteria('{$Changes.Type.equals("ApexClass")} && {$Changes.Directory.equals("ApexTrigger")}')
                )
                .persist();

            activateQualityGateRules();

            List<Integer> weights = new List<Integer>();

            // Exercise
            for (Quality_Gate_Rule_Condition__c condition : getQualityGateRuleConditions()) {
                Integer weight = new CalculateQGConditionWeight(condition).execute();
                weights.add(weight);
            }

            // Verify

            // Scope Weight: 'Platform' => 5 + 'Environment' => 20
            // Criteria Weight: Min ('Type' => 10 * 'equals' => 10, 'Directory' => 20 * 'equals' => 10) + 'Name' => 30 * 'notContains' => 4
            System.assertEquals(245, weights[0], 'Weight should be 240 (Scope weight: 25 + Filter Criteria weight: 220)');

            // Scope Weight: 'Platform' => 5 + 'Pipeline' => 10
            // Criteria Weight: 'Type' => 10 * 'equals' => 10 + 'Directory' => 20 * 'equals' => 10
            System.assertEquals(315, weights[1], 'Weight should be 315 (Scope weight: 15 + Filter Criteria weight: 200)');

            System.assertEquals(true, weights[1] > weights[0], 'Second condition should with higher weight');
        }
    }

    @IsTest
    private static void calculateWeightWithoutFilterCriteria() {
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

            Quality_Gate_Rule_Condition__c condition = getQualityGateRuleConditions()[0];

            // Exercise
            Integer weight = new CalculateQGConditionWeight(condition).execute();

            // Verify
            // 'Platform' => 5 + 'Environment' => 20
            System.assertEquals(25, weight, 'Weight should be 20 (Scope weight: 25 + Filter Criteria weight: 0)');
        }
    }

    // HELPER

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

    private static List<Quality_Gate_Rule_Condition__c> getQualityGateRuleConditions() {
        return [SELECT Id, Environment__c, Stage__c, Pipeline__c, Platform__c, Filter_Criteria__c FROM Quality_Gate_Rule_Condition__c ORDER BY Name];
    }

    private static void activateQualityGateRules() {
        Quality_Gate_Rule__c rule = [SELECT Id, Status__c FROM Quality_Gate_Rule__c LIMIT 1];
        rule.Status__c = QualityGateConstants.ACTIVE;
        update rule;
    }
}