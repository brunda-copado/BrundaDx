@IsTest
private class QualityServiceImplTest {
    private static final String NONE_VALUE = 'None'; // @Note: Has to be one of the packaged values for the Copado Test Tool picklist

    @IsTest
    private static void matchingRules() {
        System.runAs(getRunAsUser()) {
            // Setup
            TestToolsSelector.mock(new List<TestTool__mdt>{ new TestTool__mdt(MasterLabel = NONE_VALUE, TestType__c = 'Mock Type') });

            Id extensionConfigurationId = getExtensionConfigurationId();

            Quality_Gate_Rule__c rule = (Quality_Gate_Rule__c) new QualityGateRule()
                .actions(new List<String>{ 'Promotion', 'PromotionDeployment' })
                .sequence('Before')
                .tool(NONE_VALUE)
                .active(false)
                .add(
                    new QualityGateRuleCondition()
                        .platform('Other')
                        .environment(new Environment().platform('Other'))
                        .extensionConfiguration(extensionConfigurationId)
                )
                .persist();
            rule.Status__c = QualityGateConstants.ACTIVE;
            update rule;

            Id environmentId = [SELECT Id FROM Environment__c LIMIT 1].Id;

            Quality.MatchingRulesRequest request = new Quality.MatchingRulesRequest();
            request.action = 'Promotion';
            request.platform = 'Other';
            request.environment = environmentId;

            // Exercise
            Test.startTest();
            Quality.MatchingRulesResult result = Quality.matchingRules(request);
            Test.stopTest();

            // Verify
            System.assertEquals(1, result.qualityGates.size(), 'Should have matched 1 quality gate rule');
        }
    }

    @IsTest
    private static void executeWith1BeforeQualityGateRule() {
        System.runAs(getRunAsUser()) {
            // Setup
            TestToolsSelector.mock(new List<TestTool__mdt>{ new TestTool__mdt(MasterLabel = NONE_VALUE, TestType__c = 'Mock Type') });

            Id extensionConfigurationId = getExtensionConfigurationId();

            Quality_Gate_Rule__c rule = (Quality_Gate_Rule__c) new QualityGateRule()
                .actions(new List<String>{ 'Promotion', 'PromotionDeployment' })
                .sequence('Before')
                .tool(NONE_VALUE)
                .active(false)
                .add(
                    new QualityGateRuleCondition()
                        .platform('Other')
                        .environment(new Environment().platform('Other'))
                        .extensionConfiguration(extensionConfigurationId)
                )
                .persist();
            rule.Status__c = QualityGateConstants.ACTIVE;
            update rule;

            Id environmentId = [SELECT Id FROM Environment__c LIMIT 1].Id;

            Quality.StepsRequest request = new Quality.StepsRequest();
            request.action = 'Promotion';
            request.platform = 'Other';
            request.environment = environmentId;

            // Exercise
            Test.startTest();
            Quality.StepsResult result = Quality.steps(request);
            Test.stopTest();

            // Verify
            List<JobStep__c> preSteps = getPreSteps(result);
            TestJobStep.ConfigJson configJson = (TestJobStep.ConfigJson) JSON.deserialize(preSteps[0].ConfigJson__c, TestJobStep.ConfigJson.class);

            System.assertEquals(NONE_VALUE, configJson.type, 'Test type should be None');
            System.assertEquals(1, preSteps.size(), 'Should have 1 preStep');
            System.assertEquals('Test', preSteps[0].Type__c, 'Step type should be Test');
            System.assertEquals(environmentId, configJson.environmentId, 'Environment Id should be same');
        }
    }

    @IsTest
    private static void executeWith1BeforeAnd1AfterQualityGateRule() {
        System.runAs(getRunAsUser()) {
            // Setup
            TestToolsSelector.mock(new List<TestTool__mdt>{ new TestTool__mdt(MasterLabel = NONE_VALUE, TestType__c = 'Mock Type') });

            Id extensionConfigurationId = getExtensionConfigurationId();

            new QualityGateRule()
                .action('Promotion')
                .sequence('Before')
                .tool(NONE_VALUE)
                .active(false)
                .name('Rule1')
                .add(
                    new QualityGateRuleCondition()
                        .platform('Other')
                        .environment(new Environment().platform('Other'))
                        .extensionConfiguration(extensionConfigurationId)
                );

            new QualityGateRule()
                .action('Promotion')
                .sequence('After')
                .tool(NONE_VALUE)
                .active(false)
                .name('Rule2')
                .add(
                    new QualityGateRuleCondition()
                        .platform('Other')
                        .pipeline(new Pipeline().setPlatform('Other'))
                        .extensionConfiguration(extensionConfigurationId)
                )
                .persist();

            List<Quality_Gate_Rule__c> qualityGateRulesToUpdate = new List<Quality_Gate_Rule__c>();
            for (Quality_Gate_Rule__c qualityGateRule : [SELECT Id, Status__c FROM Quality_Gate_Rule__c]) {
                qualityGateRule.Status__c = QualityGateConstants.ACTIVE;
                qualityGateRulesToUpdate.add(qualityGateRule);
            }
            update qualityGateRulesToUpdate;

            Id environmentId = [SELECT Id FROM Environment__c LIMIT 1].Id;
            Id pipelineId = [SELECT Id FROM Deployment_Flow__c LIMIT 1].Id;

            Quality.StepsRequest request = new Quality.StepsRequest();
            request.action = 'Promotion';
            request.pipeline = pipelineId;
            request.environment = environmentId;

            // Exercise
            Test.startTest();
            Quality.StepsResult result = Quality.steps(request);
            Test.stopTest();

            // Verify
            List<JobStep__c> preSteps = getPreSteps(result);
            TestJobStep.ConfigJson configJson = (TestJobStep.ConfigJson) JSON.deserialize(preSteps[0].ConfigJson__c, TestJobStep.ConfigJson.class);

            System.assertEquals(NONE_VALUE, configJson.type, 'Test type should be None');
            System.assertEquals(1, preSteps.size(), 'Should have 1 preStep');
            System.assertEquals('Test', preSteps[0].Type__c, 'Step type should be Test');
            System.assertEquals(environmentId, configJson.environmentId, 'Environment Id should be same');
        }
    }

    @IsTest
    private static void executeWith1BeforeAnd1AfterWithDifferentPlatformQualityGateRule() {
        System.runAs(getRunAsUser()) {
            // Setup
            TestToolsSelector.mock(new List<TestTool__mdt>{ new TestTool__mdt(MasterLabel = NONE_VALUE, TestType__c = 'Mock Type') });

            Id extensionConfigurationId = getExtensionConfigurationId();

            new QualityGateRule()
                .action('Promotion')
                .sequence('Before')
                .tool(NONE_VALUE)
                .active(false)
                .name('Rule1')
                .add(
                    new QualityGateRuleCondition()
                        .platform('Other')
                        .environment(new Environment().platform('Other'))
                        .extensionConfiguration(extensionConfigurationId)
                );

            new QualityGateRule()
                .action('Promotion')
                .sequence('After')
                .tool(NONE_VALUE)
                .active(false)
                .name('Rule2')
                .add(
                    new QualityGateRuleCondition()
                        .platform('Salesforce')
                        .pipeline(new Pipeline().setPlatform('Salesforce'))
                        .extensionConfiguration(extensionConfigurationId)
                )
                .persist();

            List<Quality_Gate_Rule__c> qualityGateRulesToUpdate = new List<Quality_Gate_Rule__c>();
            for (Quality_Gate_Rule__c qualityGateRule : [SELECT Id, Status__c FROM Quality_Gate_Rule__c]) {
                qualityGateRule.Status__c = QualityGateConstants.ACTIVE;
                qualityGateRulesToUpdate.add(qualityGateRule);
            }
            update qualityGateRulesToUpdate;

            Id environmentId = [SELECT Id FROM Environment__c LIMIT 1].Id;
            Id pipelineId = [SELECT Id FROM Deployment_Flow__c LIMIT 1].Id;

            Quality.StepsRequest request = new Quality.StepsRequest();
            request.platform = 'Other';
            request.action = 'Promotion';
            request.pipeline = pipelineId;
            request.environment = environmentId;

            // Exercise
            Test.startTest();
            Quality.StepsResult result = Quality.steps(request);
            Test.stopTest();

            // Verify
            List<JobStep__c> preSteps = getPreSteps(result);
            TestJobStep.ConfigJson configJson = (TestJobStep.ConfigJson) JSON.deserialize(preSteps[0].ConfigJson__c, TestJobStep.ConfigJson.class);

            System.assertEquals(NONE_VALUE, configJson.type, 'Test type should be None');
            System.assertEquals(1, preSteps.size(), 'Should have 1 preStep');
            System.assertEquals('Test', preSteps[0].Type__c, 'Step type should be Test');
            System.assertEquals(environmentId, configJson.environmentId, 'Environment Id should be same');
        }
    }

    @IsTest
    private static void executeBeforeCommitQualityGateRule() {
        System.runAs(getRunAsUser()) {
            // Setup
            TestToolsSelector.mock(new List<TestTool__mdt>{ new TestTool__mdt(MasterLabel = NONE_VALUE, TestType__c = 'Mock Type') });

            Id extensionConfigurationId = getExtensionConfigurationId();

            Quality_Gate_Rule__c qualityGateRule = (Quality_Gate_Rule__c) new QualityGateRule()
                .actions(new List<String>{ 'Commit' })
                .sequence('Before')
                .tool(NONE_VALUE)
                .active(false)
                .add(
                    new QualityGateRuleCondition()
                        .platform('Other')
                        .environment(new Environment().platform('Other'))
                        .extensionConfiguration(extensionConfigurationId)
                        .filterCriteria('{$Changes.Type.equals("ApexClass")}')
                )
                .persist();

            qualityGateRule.Status__c = QualityGateConstants.ACTIVE;
            update qualityGateRule;

            Id environmentId = [SELECT Id FROM Environment__c LIMIT 1].Id;

            Quality.StepsRequest request = new Quality.StepsRequest();
            request.action = 'Commit';
            request.platform = 'Other';
            request.environment = environmentId;
            request.metadataChanges = getMetadataChanges();

            // Exercise
            Test.startTest();
            Quality.StepsResult result = Quality.steps(request);
            Test.stopTest();

            // Verify
            List<JobStep__c> preSteps = getPreSteps(result);
            TestJobStep.ConfigJson configJson = (TestJobStep.ConfigJson) JSON.deserialize(preSteps[0].ConfigJson__c, TestJobStep.ConfigJson.class);

            System.assertEquals(NONE_VALUE, configJson.type, 'Test type should be None');
            System.assertEquals(1, preSteps.size(), 'Should have 1 preStep');
            System.assertEquals('Test', preSteps[0].Type__c, 'Step type should be Test');
            System.assertEquals(environmentId, configJson.environmentId, 'Environment Id should be same');
        }
    }

    @IsTest
    private static void contextIdsWhenBringsTestsFromStory() {
        System.runAs(getRunAsUser()) {
            // Setup
            createContextData();

            TestToolsSelector.mock(new List<TestTool__mdt>{ new TestTool__mdt(MasterLabel = NONE_VALUE, TestType__c = 'Mock Type') });

            Id extensionConfigurationId = getExtensionConfigurationId();

            Quality_Gate_Rule__c qualityGateRule = (Quality_Gate_Rule__c) new QualityGateRule()
                .action('Promotion')
                .sequence('Before')
                .tool(NONE_VALUE)
                .active(false)
                .name('Rule1')
                .add(new QualityGateRuleCondition().platform('Other').extensionConfiguration(extensionConfigurationId).testsFrom('User Story'))
                .persist();

            qualityGateRule.Status__c = QualityGateConstants.ACTIVE;
            update qualityGateRule;

            Quality.StepsRequest request = new Quality.StepsRequest();
            request.platform = 'Other';
            request.action = 'Promotion';
            request.contextIds = getUserStoryIds();

            // Exercise
            Test.startTest();
            Quality.StepsResult result = Quality.steps(request);
            Test.stopTest();

            // Verify
            List<JobStep__c> preSteps = getPreSteps(result);
            TestJobStep.ConfigJson configJson = (TestJobStep.ConfigJson) JSON.deserialize(preSteps[0].ConfigJson__c, TestJobStep.ConfigJson.class);

            System.assertEquals(10, configJson.contextIds.size(), 'There should be 7 user stories in contextIds');
        }
    }

    @IsTest
    private static void contextIdsWhenBringsTestsFromFeature() {
        System.runAs(getRunAsUser()) {
            // Setup
            createContextData();

            TestToolsSelector.mock(new List<TestTool__mdt>{ new TestTool__mdt(MasterLabel = NONE_VALUE, TestType__c = 'Mock Type') });

            Id extensionConfigurationId = getExtensionConfigurationId();

            Quality_Gate_Rule__c qualityGateRule = (Quality_Gate_Rule__c) new QualityGateRule()
                .action('Promotion')
                .sequence('Before')
                .tool(NONE_VALUE)
                .active(false)
                .name('Rule1')
                .add(new QualityGateRuleCondition().platform('Other').extensionConfiguration(extensionConfigurationId).testsFrom('Feature'))
                .persist();

            qualityGateRule.Status__c = QualityGateConstants.ACTIVE;
            update qualityGateRule;
            Quality.StepsRequest request = new Quality.StepsRequest();
            request.platform = 'Other';
            request.action = 'Promotion';
            request.contextIds = getUserStoryIds();

            // Exercise
            Test.startTest();
            Quality.StepsResult result = Quality.steps(request);
            Test.stopTest();

            // Verify
            List<JobStep__c> preSteps = getPreSteps(result);
            TestJobStep.ConfigJson configJson = (TestJobStep.ConfigJson) JSON.deserialize(preSteps[0].ConfigJson__c, TestJobStep.ConfigJson.class);

            System.assertEquals(5, configJson.contextIds.size(), 'There should be 5 features in contextIds');
        }
    }

    @IsTest
    private static void contextIdsWhenBringsTestsFromApplication() {
        System.runAs(getRunAsUser()) {
            // Setup
            createContextData();

            TestToolsSelector.mock(new List<TestTool__mdt>{ new TestTool__mdt(MasterLabel = NONE_VALUE, TestType__c = 'Mock Type') });

            Id extensionConfigurationId = getExtensionConfigurationId();

            Quality_Gate_Rule__c qualityGateRule = (Quality_Gate_Rule__c) new QualityGateRule()
                .action('Promotion')
                .sequence('Before')
                .tool(NONE_VALUE)
                .active(false)
                .name('Rule1')
                .add(new QualityGateRuleCondition().platform('Other').extensionConfiguration(extensionConfigurationId).testsFrom('Application'))
                .persist();

            qualityGateRule.Status__c = QualityGateConstants.ACTIVE;
            update qualityGateRule;

            Quality.StepsRequest request = new Quality.StepsRequest();
            request.platform = 'Other';
            request.action = 'Promotion';
            request.contextIds = getUserStoryIds();

            // Exercise
            Test.startTest();
            Quality.StepsResult result = Quality.steps(request);
            Test.stopTest();

            // Verify
            List<JobStep__c> preSteps = getPreSteps(result);
            TestJobStep.ConfigJson configJson = (TestJobStep.ConfigJson) JSON.deserialize(preSteps[0].ConfigJson__c, TestJobStep.ConfigJson.class);

            System.assertEquals(1, configJson.contextIds.size(), 'There should be 1 application in contextIds');
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
            .assign(new PermissionSetAssignment_t().configureAutomations())
            .persist();
        System.runAs(user) {
            new CopadoLicense().user(user).enableAll().persist();
            createExtensionConfiguration();
        }
    }
    private static User getRunAsUser() {
        return [SELECT Id FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1];
    }

    private static void createExtensionConfiguration() {
        ExtensionConfiguration__c extensionConfig = new ExtensionConfiguration__c(
            ExtensionTool__c = 'Manual Tests', // @Note: Has to be one of the packaged values for this picklist field
            ExtensionApplication__c = 'Test',
            Active__c = true
        );

        insert extensionConfig;
    }

    private static Id getExtensionConfigurationId() {
        return [SELECT Id FROM ExtensionConfiguration__c LIMIT 1].id;
    }

    private static List<Id> getUserStoryIds() {
        List<User_Story__c> stories = [SELECT Id FROM User_Story__c];
        return idsOnly(stories);
    }

    private static List<Id> idsOnly(List<SObject> records) {
        return new List<Id>(new Map<Id, SObject>(records).keySet());
    }

    private static Id getFeatureId() {
        return [SELECT Id FROM Application_Feature__c LIMIT 1].Id;
    }

    private static Id getApplicationId() {
        return [SELECT Id FROM Application__c LIMIT 1].Id;
    }

    private static void createContextData() {
        Application__c application1 = new Application__c();
        insert application1;

        Application_Feature__c feature1 = new Application_Feature__c();
        Application_Feature__c feature2 = new Application_Feature__c();
        Application_Feature__c feature3 = new Application_Feature__c();
        Application_Feature__c feature4 = new Application_Feature__c(Application__c = application1.Id);
        Application_Feature__c feature5 = new Application_Feature__c(Application__c = application1.Id);
        insert new List<Application_Feature__c>{ feature1, feature2, feature3, feature4, feature5 };

        User_Story__c userStory1 = new User_Story__c();
        User_Story__c userStory2 = new User_Story__c();
        User_Story__c userStory3 = new User_Story__c();
        User_Story__c userStory4 = new User_Story__c(US_Feature__c = feature1.Id);
        User_Story__c userStory5 = new User_Story__c(US_Feature__c = feature1.Id);
        User_Story__c userStory6 = new User_Story__c(US_Feature__c = feature1.Id);
        User_Story__c userStory7 = new User_Story__c(US_Feature__c = feature2.Id);
        User_Story__c userStory8 = new User_Story__c(US_Feature__c = feature3.Id);
        User_Story__c userStory9 = new User_Story__c(US_Feature__c = feature4.Id);
        User_Story__c userStory10 = new User_Story__c(US_Feature__c = feature5.Id);
        insert new List<User_Story__c>{
            userStory1,
            userStory2,
            userStory3,
            userStory4,
            userStory5,
            userStory6,
            userStory7,
            userStory8,
            userStory9,
            userStory10
        };
    }

    private static List<User_Story_Metadata__c> getMetadataChanges() {
        List<User_Story_Metadata__c> changes = new List<User_Story_Metadata__c>();
        User_Story_Metadata__c change = new User_Story_Metadata__c();
        change.Metadata_API_Name__c = 'TestApexClass';
        change.Type__c = 'ApexClass';
        changes.add(change);
        return changes;
    }

    private static List<JobStep__c> getPreSteps(Quality.StepsResult result) {
        for (Jobs.ExecutionStep stepModel : result.steps) {
            if (stepModel.sequence == QualityServiceImpl.BEFORE) {
                return stepModel.steps;
            }
        }
        return new List<JobStep__c>();
    }
}