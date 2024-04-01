@IsTest
private class QualityGateRuleConditionMatcherTest {
    @IsTest
    private static void matchFilterCriteria() {
        System.runAs(getRunAsUser()) {
            // Setup
            Id extensionConfigurationId = getExtensionConfigurationId();
            Environment environment = new Environment().platform('Other');

            createQualityGateRule()
                .add(
                    new QualityGateRuleCondition()
                        .platform('Other')
                        .environment(environment)
                        .extensionConfiguration(extensionConfigurationId)
                        .filterCriteria(
                            '({$Changes.Type.equals("ApexClass")} || {$Changes.Type.equals("ApexTrigger")}) && {$Changes.Name.notContains("Opportunity")}'
                        )
                )
                .persist();

            activateQualityGateRules();

            QualityGate.Request request = getQualityGateRequest(environment.Id);

            // Exercise
            Test.startTest();
            Map<Id, Quality_Gate_Rule_Condition__c> conditionByRuleId = new QualityGateRuleConditionMatcher(request).execute();
            Test.stopTest();

            // Verify
            System.assertEquals(1, conditionByRuleId.size(), 'Should have 1 QGR record');
        }
    }

    @isTest
    private static void matchFilterCriteriaWithSpaces() {
        System.runAs(getRunAsUser()) {
            // Setup
            Id extensionConfigurationId = getExtensionConfigurationId();
            Environment environment = new Environment().platform('Other');

            createQualityGateRule()
                .add(
                    new QualityGateRuleCondition()
                        .platform('Other')
                        .environment(environment)
                        .extensionConfiguration(extensionConfigurationId)
                        .filterCriteria(
                            '({$Changes.Name.contains("Test Mock")} || {$Changes.Type.equals("ApexTrigger")}) && {$Changes.Name.notContains("Opportunity")}'
                        )
                )
                .persist();

            activateQualityGateRules();

            QualityGate.Request request = getQualityGateRequest(environment.Id);

            // Exercise
            Test.startTest();
            Map<Id, Quality_Gate_Rule_Condition__c> conditionByRuleId = new QualityGateRuleConditionMatcher(request).execute();
            Test.stopTest();

            // Verify
            System.assertEquals(0, conditionByRuleId.size(), 'Should not have QGR record');
        }
    }

    @isTest
    private static void matchFilterCriteriaWithDirectory() {
        System.runAs(getRunAsUser()) {
            // Setup
            Id extensionConfigurationId = getExtensionConfigurationId();
            Environment environment = new Environment().platform('Other');

            createQualityGateRule()
                .add(
                    new QualityGateRuleCondition()
                        .platform('Other')
                        .environment(environment)
                        .extensionConfiguration(extensionConfigurationId)
                        .filterCriteria(
                            '({$Changes.Directory.contains("force-app/main/default/classes")} || {$Changes.Type.equals("ApexTrigger")}) && {$Changes.Name.notContains("Opportunity")}'
                        )
                )
                .persist();

            activateQualityGateRules();

            QualityGate.Request request = getQualityGateRequest(environment.Id);

            // Exercise
            Test.startTest();
            Map<Id, Quality_Gate_Rule_Condition__c> conditionByRuleId = new QualityGateRuleConditionMatcher(request).execute();
            Test.stopTest();

            // Verify
            System.assertEquals(1, conditionByRuleId.size(), 'Should have 1 QGR record');
        }
    }

    @isTest
    private static void matchFilterCriteriaWithMultipleValues() {
        System.runAs(getRunAsUser()) {
            // Setup
            Id extensionConfigurationId = getExtensionConfigurationId();
            Environment environment = new Environment().platform('Other');

            createQualityGateRule()
                .add(
                    new QualityGateRuleCondition()
                        .platform('Other')
                        .environment(environment)
                        .extensionConfiguration(extensionConfigurationId)
                        .filterCriteria(
                            '({$Changes.Type.contains("ApexClass,ApexComponent,ApexTrigger")} || {$Changes.Type.equals("ApexTrigger")}) && {$Changes.Name.notContains("Opportunity")}'
                        )
                )
                .persist();

            activateQualityGateRules();

            QualityGate.Request request = getQualityGateRequest(environment.Id);

            Map<Id, Quality_Gate_Rule_Condition__c> conditionByRuleId = new Map<Id, Quality_Gate_Rule_Condition__c>();

            // Exercise
            Test.startTest();

            try {
                conditionByRuleId = new QualityGateRuleConditionMatcher(request).execute();
            } catch (Exception e) {
                // Verify
                System.assertEquals(
                    true,
                    e.getMessage()
                        .Contains('Invalid filter criteria expression syntax: {$Changes.Type.contains("ApexClass,ApexComponent,ApexTrigger")}'),
                    'Error Message shoould be thrown'
                );
            }

            Test.stopTest();

            // Verify
            System.assertEquals(0, conditionByRuleId.size(), 'Should not have QGR record');
        }
    }

    @IsTest
    private static void notMatchFilterCriteria() {
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
                            '{$Changes.Type.equals("ApexClass")} && {$Changes.Type.equals(".cls")} && ( {$Changes.Directory.equals("ApexTrigger")} || ( {$Changes.Name.equals("abc")} || {$Changes.Name.equals("RunTestsAction")} ))'
                        )
                )
                .persist();

            activateQualityGateRules();

            Id environmentId = [SELECT Id FROM Environment__c LIMIT 1].Id;

            QualityGate.Request request = getQualityGateRequest(environmentId);

            // Exercise
            Test.startTest();
            Map<Id, Quality_Gate_Rule_Condition__c> conditionByRuleId = new QualityGateRuleConditionMatcher(request).execute();
            Test.stopTest();

            // Verify
            System.assertEquals(0, conditionByRuleId.size(), 'Should Not have matching QGR');
        }
    }

    @IsTest
    private static void multipleQGRConditionMatch() {
        System.runAs(getRunAsUser()) {
            // Setup
            Id extensionConfigurationId = getExtensionConfigurationId();

            Environment environment = new Environment().platform('Other');

            createQualityGateRule()
                .add(
                    new QualityGateRuleCondition()
                        .platform('Other')
                        .environment(environment)
                        .extensionConfiguration(extensionConfigurationId)
                        .filterCriteria(
                            '({$Changes.Type.equals("ApexClass")} || {$Changes.Directory.equals("ApexTrigger")}) && {$Changes.Name.notContains("Opportunity")}'
                        )
                )
                .add(new QualityGateRuleCondition().platform('Other').environment(environment).extensionConfiguration(extensionConfigurationId))
                .add(
                    new QualityGateRuleCondition()
                        .platform('Other')
                        .environment(environment)
                        .extensionConfiguration(extensionConfigurationId)
                        .filterCriteria('({$Changes.Type.equals("ApexClass")} || {$Changes.Directory.equals("ApexTrigger")})')
                )
                .persist();

            activateQualityGateRules();

            QualityGate.Request request = getQualityGateRequest(environment.Id);

            // Exercise
            Test.startTest();
            Map<Id, Quality_Gate_Rule_Condition__c> conditionByRuleId = new QualityGateRuleConditionMatcher(request).execute();
            Test.stopTest();

            // Verify
            System.assertEquals(1, conditionByRuleId.size(), 'Should have 1 QGR with matching condition');
            System.assertEquals(1, conditionByRuleId.values().size(), 'Should have 1 matching condition which has highest weight');
            Integer weight = new CalculateQGConditionWeight(conditionByRuleId.values()[0]).execute();

            // Scope Weight: 'Platform' => 5 + 'Environment' => 20
            // Criteria Weight: Min ('Type' => 10 * 'equals' => 10, 'Directory' => 20 * 'equals' => 10) + 'Name' => 30 * 'notContains' => 4
            System.assertEquals(245, weight, 'Weight should be 245 (Scope weight: 25 + Filter Criteria weight: 220)');
        }
    }

    @IsTest
    private static void noMatchWithStage() {
        System.runAs(getRunAsUser()) {
            // Setup
            Id extensionConfigurationId = getExtensionConfigurationId();

            Deployment_Flow__c pipeline = getPipeline();
            Environment__c environment = getEnvironment('dev1');
            Stage__c stage = getStage('Test');

            createQualityGateRule()
                .add(
                    new QualityGateRuleCondition()
                        .platform('Other')
                        .pipelineId(pipeline.Id)
                        .environmentId(environment.Id)
                        .stageId(stage.Id)
                        .extensionConfiguration(extensionConfigurationId)
                        .filterCriteria(
                            '({$Changes.Type.equals("ApexClass")} || {$Changes.Directory.equals("ApexTrigger")}) && {$Changes.Name.notContains("Opportunity")}'
                        )
                )
                .add(new QualityGateRuleCondition().platform('Other').environmentId(environment.Id).extensionConfiguration(extensionConfigurationId))
                .add(
                    new QualityGateRuleCondition()
                        .platform('Other')
                        .extensionConfiguration(extensionConfigurationId)
                        .filterCriteria('({$Changes.Type.equals("ApexClass")} || {$Changes.Directory.equals("ApexTrigger")})')
                )
                .persist();

            activateQualityGateRules();

            QualityGate.Request request = getQualityGateRequest(environment.Id);
            request.pipelineId = pipeline.Id;

            // Exercise
            Test.startTest();
            Map<Id, Quality_Gate_Rule_Condition__c> conditionByRuleId = new QualityGateRuleConditionMatcher(request).execute();
            Test.stopTest();

            // Verify
            System.assertEquals(1, conditionByRuleId.size(), 'Should have 1 QGR with matching condition');
            System.assertEquals(1, conditionByRuleId.values().size(), 'Should have 1 matching condition');
            System.assertEquals(null, conditionByRuleId.values()[0].Stage__c, 'Should have 1 matching condition');
        }
    }

    @IsTest
    private static void matchWithStage() {
        System.runAs(getRunAsUser()) {
            // Setup
            Id extensionConfigurationId = getExtensionConfigurationId();

            Deployment_Flow__c pipeline = getPipeline();
            Environment__c environment = getEnvironment('dev1');
            Stage__c stage = getStage('Dev');

            createQualityGateRule()
                .add(
                    new QualityGateRuleCondition()
                        .platform('Other')
                        .pipelineId(pipeline.Id)
                        .environmentId(environment.Id)
                        .stageId(stage.Id)
                        .extensionConfiguration(extensionConfigurationId)
                        .filterCriteria(
                            '({$Changes.Type.equals("ApexClass")} || {$Changes.Directory.equals("ApexTrigger")}) && {$Changes.Name.notContains("Opportunity")}'
                        )
                )
                .add(new QualityGateRuleCondition().platform('Other').environmentId(environment.Id).extensionConfiguration(extensionConfigurationId))
                .add(
                    new QualityGateRuleCondition()
                        .platform('Other')
                        .extensionConfiguration(extensionConfigurationId)
                        .filterCriteria('({$Changes.Type.equals("ApexClass")} || {$Changes.Directory.equals("ApexTrigger")})')
                )
                .persist();

            activateQualityGateRules();

            QualityGate.Request request = getQualityGateRequest(environment.Id);
            request.pipelineId = pipeline.Id;

            // Exercise
            Test.startTest();
            Map<Id, Quality_Gate_Rule_Condition__c> conditionByRuleId = new QualityGateRuleConditionMatcher(request).execute();
            Test.stopTest();

            // Verify
            System.assertEquals(1, conditionByRuleId.size(), 'Should have 1 QGR with matching condition');
            System.assertEquals(1, conditionByRuleId.values().size(), 'Should have 1 matching condition');
            System.assertEquals(stage.Id, conditionByRuleId.values()[0].Stage__c, 'Should have 1 matching condition');
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
            createExtensionConfiguration();
            createData();
        }
    }

    private static void createData() {
        Stage devStage = new Stage().name('Dev').metaStage('Build');
        Stage testStage = new Stage().name('Test').metaStage('Test');
        Stage productionStage = new Stage().name('Production').metaStage('Production');

        Environment dev1 = new Environment().name('dev1').type('Sandbox').platform('Other').add(new Credential());
        Environment dev2 = new Environment().name('dev2').type('Sandbox').platform('Other').add(new Credential());
        Environment integration = new Environment().name('int').type('Sandbox').platform('Other').add(new Credential());
        Environment uat = new Environment().name('uat').type('Sandbox').platform('Other').add(new Credential());
        Environment prod = new Environment().name('prod').type('Sandbox').platform('Other').add(new Credential());

        StageConnection devStageConnection = new StageConnection().stage(devStage);
        StageConnection testStageConnection = new StageConnection().stage(testStage);
        StageConnection productionStageConnection = new StageConnection().stage(productionStage);

        new Pipeline()
            .active(true)
            .mainBranch('main')
            .setPlatform('Other')
            .add(new Connection(dev1, integration).branch('dev1').stageConnection(devStageConnection))
            .add(new Connection(dev2, integration).branch('dev2').stageConnection(devStageConnection))
            .add(new Connection(integration, uat).branch('int').stageConnection(devStageConnection))
            .add(new Connection(uat, prod).branch('uat').stageConnection(testStageConnection))
            .add(devStageConnection)
            .add(testStageConnection)
            .add(productionStageConnection)
            .persist();

        Stage_Connection__c devStageConnectionRecord = getStageConnections('Dev');
        Stage_Connection__c testStageConnectionRecord = getStageConnections('Test');
        Stage_Connection__c prodStageConnectionRecord = getStageConnections('Production');
        devStageConnectionRecord.Next_Stage_Connection__c = testStageConnectionRecord.Id;
        testStageConnectionRecord.Next_Stage_Connection__c = prodStageConnectionRecord.Id;
        update new List<Stage_Connection__c>{ devStageConnectionRecord, testStageConnectionRecord };
    }

    private static Deployment_Flow__c getPipeline() {
        return [SELECT Id FROM Deployment_Flow__c LIMIT 1];
    }

    private static Environment__c getEnvironment(String name) {
        return [SELECT Id FROM Environment__c WHERE Name = :name LIMIT 1];
    }

    private static Stage__c getStage(String name) {
        return [SELECT Id FROM Stage__c WHERE Name = :name LIMIT 1];
    }

    private static Stage_Connection__c getStageConnections(String stageName) {
        return [SELECT Id FROM Stage_Connection__c WHERE Stage__r.Name = :stageName];
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

    private static User_Story__c createUserStory() {
        return (User_Story__c) new UserStory()
            .add(new UserStoryMetadata().name('TestClass').type('ApexClass'))
            .add(new UserStoryMetadata().name('MyClass').type('ApexClass'))
            .persist();
    }

    private static QualityGate.Request getQualityGateRequest(Id environmentId) {
        User_Story__c userStory = createUserStory();
        QualityGate.Request request = new QualityGate.Request();
        request.action = 'Promotion';
        request.platform = 'Other';
        request.environmentId = environmentId;
        request.contextIds = new List<Id>{ userStory.Id };
        request.metadataChanges = getMetadataChanges();
        return request;
    }

    private static List<User_Story_Metadata__c> getMetadataChanges() {
        List<User_Story_Metadata__c> changes = new List<User_Story_Metadata__c>();
        User_Story_Metadata__c change = new User_Story_Metadata__c();
        change.Metadata_API_Name__c = 'TestApexClass';
        change.Type__c = 'ApexClass';
        change.ModuleDirectory__c = 'force-app/main/default/classes';
        changes.add(change);
        return changes;
    }

    private static User getRunAsUser() {
        return [SELECT Id FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1];
    }

    private static Id getExtensionConfigurationId() {
        return [SELECT Id FROM ExtensionConfiguration__c LIMIT 1].id;
    }

    private static Id getQualityGateRuleId() {
        return [SELECT Id FROM Quality_Gate_rule__c LIMIT 1].id;
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

    private static void activateQualityGateRules() {
        Quality_Gate_Rule__c rule = [SELECT Id, Status__c FROM Quality_Gate_Rule__c LIMIT 1];
        rule.Status__c = QualityGateConstants.ACTIVE;
        update rule;
    }
}