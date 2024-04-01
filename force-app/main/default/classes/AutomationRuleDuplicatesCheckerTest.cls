@IsTest
private with sharing class AutomationRuleDuplicatesCheckerTest {
    @TestSetup
    private static void makeData() {
        TestUtilities.getAllMultilicense();
        User user = (User) new User_t()
            .assign(new PermissionSetAssignment_t().copadoUser())
            .assign(new PermissionSetAssignment_t().configureAutomations())
            .assign(new PermissionSetAssignment_t().executeAutomations())
            .persist();
        System.runAs(user) {
            new CopadoLicense().user(user).enableAll().persist();
            createData();
        }
    }

    @IsTest
    private static void duplicatedNoScope() {
        // Setup
        System.runAs(getUser()) {
            Deployment_Flow__c pipeline = getPipeline();

            Automation_Rule__c rule1 = (Automation_Rule__c) new AutomationRule()
                .pipeline(pipeline.Id)
                .active()
                .sourceAction(ActionConstants.PROMOTION_DEPLOYMENT)
                .automatedAction(ActionConstants.PROMOTION)
                .sourceActionStatus(AutomationRuleConstants.SOURCE_ACTION_STATUS_SUCCESSFUL)
                .connector(ACPromotionDeploymentToPromotion.class.getName())
                .execution(AutomationRuleConstants.EXECUTION_SCHEDULED)
                .persist();

            Automation_Rule__c rule2 = (Automation_Rule__c) new AutomationRule()
                .pipeline(pipeline.Id)
                .sourceAction(ActionConstants.PROMOTION_DEPLOYMENT)
                .automatedAction(ActionConstants.PROMOTION)
                .sourceActionStatus(AutomationRuleConstants.SOURCE_ACTION_STATUS_SUCCESSFUL)
                .connector(ACPromotionDeploymentToPromotion.class.getName())
                .execution(AutomationRuleConstants.EXECUTION_IMMEDIATE)
                .persist();

            // Exercise
            Test.startTest();
            List<Automation_Rule__c> duplicates = new AutomationRuleDuplicatesChecker(new List<Automation_Rule__c>{ rule2 }).execute();
            Test.stopTest();

            // Verify
            System.assertEquals(1, duplicates.size(), 'Duplicates checker should return one element');
            System.assertEquals(rule1.Id, duplicates[0].Id, 'Automation Rule returned should match');
        }
    }

    @IsTest
    private static void duplicatedEnvironment() {
        // Setup
        System.runAs(getUser()) {
            Deployment_Flow__c pipeline = getPipeline();
            Environment__c dev1Environment = getEnvironment('dev1');

            Automation_Rule__c rule1 = (Automation_Rule__c) new AutomationRule()
                .pipeline(pipeline.Id)
                .active()
                .sourceAction(ActionConstants.PROMOTION_DEPLOYMENT)
                .automatedAction(ActionConstants.PROMOTION)
                .sourceActionStatus(AutomationRuleConstants.SOURCE_ACTION_STATUS_SUCCESSFUL)
                .connector(AutomationRuleConstants.AUTOMATION_CONNECTOR_CUSTOM)
                .execution(AutomationRuleConstants.EXECUTION_SCHEDULED)
                .customConnector(AutomationConnectorMock.class.getName())
                .environment(dev1Environment.Id)
                .persist();

            Automation_Rule__c rule2 = (Automation_Rule__c) new AutomationRule()
                .pipeline(pipeline.Id)
                .sourceAction(ActionConstants.PROMOTION_DEPLOYMENT)
                .automatedAction(ActionConstants.PROMOTION)
                .sourceActionStatus(AutomationRuleConstants.SOURCE_ACTION_STATUS_SUCCESSFUL)
                .connector(AutomationRuleConstants.AUTOMATION_CONNECTOR_CUSTOM)
                .execution(AutomationRuleConstants.EXECUTION_IMMEDIATE)
                .customConnector(AutomationConnectorMock.class.getName())
                .environment(dev1Environment.Id)
                .persist();

            // Exercise
            Test.startTest();
            List<Automation_Rule__c> duplicates = new AutomationRuleDuplicatesChecker(new List<Automation_Rule__c>{ rule2 }).execute();
            Test.stopTest();

            // Verify
            System.assertEquals(1, duplicates.size(), 'Duplicates checker should return one element');
            System.assertEquals(rule1.Id, duplicates[0].Id, 'Automation Rule returned should match');
        }
    }

    @IsTest
    private static void duplicatedStage() {
        // Setup
        System.runAs(getUser()) {
            Deployment_Flow__c pipeline = getPipeline();
            Stage__c stage = getStage('Dev');

            Automation_Rule__c rule1 = (Automation_Rule__c) new AutomationRule()
                .pipeline(pipeline.Id)
                .active()
                .sourceAction(ActionConstants.PROMOTION_DEPLOYMENT)
                .automatedAction(ActionConstants.PROMOTION)
                .sourceActionStatus(AutomationRuleConstants.SOURCE_ACTION_STATUS_SUCCESSFUL)
                .connector(AutomationRuleConstants.AUTOMATION_CONNECTOR_CUSTOM)
                .execution(AutomationRuleConstants.EXECUTION_SCHEDULED)
                .customConnector(AutomationConnectorMock.class.getName())
                .stage(stage.Id)
                .persist();

            Automation_Rule__c rule2 = (Automation_Rule__c) new AutomationRule()
                .pipeline(pipeline.Id)
                .sourceAction(ActionConstants.PROMOTION_DEPLOYMENT)
                .automatedAction(ActionConstants.PROMOTION)
                .sourceActionStatus(AutomationRuleConstants.SOURCE_ACTION_STATUS_SUCCESSFUL)
                .connector(AutomationRuleConstants.AUTOMATION_CONNECTOR_CUSTOM)
                .execution(AutomationRuleConstants.EXECUTION_IMMEDIATE)
                .customConnector(AutomationConnectorMock.class.getName())
                .stage(stage.Id)
                .persist();

            // Exercise
            Test.startTest();
            List<Automation_Rule__c> duplicates = new AutomationRuleDuplicatesChecker(new List<Automation_Rule__c>{ rule2 }).execute();
            Test.stopTest();

            // Verify
            System.assertEquals(1, duplicates.size(), 'Duplicates checker should return one element');
            System.assertEquals(rule1.Id, duplicates[0].Id, 'Automation Rule returned should match');
        }
    }

    @IsTest
    private static void duplicatedEnvironmentInStage() {
        // Setup
        System.runAs(getUser()) {
            Deployment_Flow__c pipeline = getPipeline();
            Environment__c dev1Environment = getEnvironment('dev1');
            Stage__c stage = getStage('Dev');

            Automation_Rule__c rule1 = (Automation_Rule__c) new AutomationRule()
                .pipeline(pipeline.Id)
                .sourceAction(ActionConstants.PROMOTION_DEPLOYMENT)
                .automatedAction(ActionConstants.PROMOTION)
                .sourceActionStatus(AutomationRuleConstants.SOURCE_ACTION_STATUS_SUCCESSFUL)
                .connector(AutomationRuleConstants.AUTOMATION_CONNECTOR_CUSTOM)
                .execution(AutomationRuleConstants.EXECUTION_SCHEDULED)
                .customConnector(AutomationConnectorMock.class.getName())
                .environment(dev1Environment.Id)
                .persist();

            Automation_Rule__c rule2 = (Automation_Rule__c) new AutomationRule()
                .pipeline(pipeline.Id)
                .active()
                .sourceAction(ActionConstants.PROMOTION_DEPLOYMENT)
                .automatedAction(ActionConstants.PROMOTION)
                .sourceActionStatus(AutomationRuleConstants.SOURCE_ACTION_STATUS_SUCCESSFUL)
                .connector(AutomationRuleConstants.AUTOMATION_CONNECTOR_CUSTOM)
                .execution(AutomationRuleConstants.EXECUTION_IMMEDIATE)
                .customConnector(AutomationConnectorMock.class.getName())
                .stage(stage.Id)
                .persist();

            // Exercise
            Test.startTest();
            List<Automation_Rule__c> duplicates = new AutomationRuleDuplicatesChecker(new List<Automation_Rule__c>{ rule1 }).execute();
            Test.stopTest();

            // Verify
            System.assertEquals(1, duplicates.size(), 'Duplicates checker should return one element');
            System.assertEquals(rule2.Id, duplicates[0].Id, 'Automation Rule returned should match');
        }
    }

    @IsTest
    private static void duplicatedStageFromEnvironment() {
        // Setup
        System.runAs(getUser()) {
            Deployment_Flow__c pipeline = getPipeline();
            Environment__c dev1Environment = getEnvironment('dev1');
            Stage__c stage = getStage('Dev');

            Automation_Rule__c rule1 = (Automation_Rule__c) new AutomationRule()
                .pipeline(pipeline.Id)
                .active()
                .sourceAction(ActionConstants.PROMOTION_DEPLOYMENT)
                .automatedAction(ActionConstants.PROMOTION)
                .sourceActionStatus(AutomationRuleConstants.SOURCE_ACTION_STATUS_SUCCESSFUL)
                .connector(AutomationRuleConstants.AUTOMATION_CONNECTOR_CUSTOM)
                .execution(AutomationRuleConstants.EXECUTION_SCHEDULED)
                .customConnector(AutomationConnectorMock.class.getName())
                .environment(dev1Environment.Id)
                .persist();

            Automation_Rule__c rule2 = (Automation_Rule__c) new AutomationRule()
                .pipeline(pipeline.Id)
                .sourceAction(ActionConstants.PROMOTION_DEPLOYMENT)
                .automatedAction(ActionConstants.PROMOTION)
                .sourceActionStatus(AutomationRuleConstants.SOURCE_ACTION_STATUS_SUCCESSFUL)
                .connector(AutomationRuleConstants.AUTOMATION_CONNECTOR_CUSTOM)
                .execution(AutomationRuleConstants.EXECUTION_IMMEDIATE)
                .customConnector(AutomationConnectorMock.class.getName())
                .stage(stage.Id)
                .persist();

            // Exercise
            Test.startTest();
            List<Automation_Rule__c> duplicates = new AutomationRuleDuplicatesChecker(new List<Automation_Rule__c>{ rule2 }).execute();
            Test.stopTest();

            // Verify
            System.assertEquals(1, duplicates.size(), 'Duplicates checker should return one element');
            System.assertEquals(rule1.Id, duplicates[0].Id, 'Automation Rule returned should match');
        }
    }

    @IsTest
    private static void duplicatedFilterCriteria() {
        // Setup
        System.runAs(getUser()) {
            Deployment_Flow__c pipeline = getPipeline();

            FilterCriteria criteria1 = new FilterCriteria();
            criteria1.mainObject = Schema.SObjectType.User_Story__c.getName();
            criteria1.whereCondition = 'Name != null';
            Automation_Rule__c rule1 = (Automation_Rule__c) new AutomationRule()
                .pipeline(pipeline.Id)
                .active()
                .sourceAction(ActionConstants.PROMOTION_DEPLOYMENT)
                .automatedAction(ActionConstants.PROMOTION)
                .sourceActionStatus(AutomationRuleConstants.SOURCE_ACTION_STATUS_SUCCESSFUL)
                .connector(ACPromotionDeploymentToPromotion.class.getName())
                .execution(AutomationRuleConstants.EXECUTION_SCHEDULED)
                .filterCriteria(JSON.serialize(criteria1))
                .persist();

            FilterCriteria criteria2 = new FilterCriteria();
            criteria2.mainObject = Schema.SObjectType.User_Story__c.getName();
            criteria2.whereCondition = 'Name != null';
            Automation_Rule__c rule2 = (Automation_Rule__c) new AutomationRule()
                .pipeline(pipeline.Id)
                .sourceAction(ActionConstants.PROMOTION_DEPLOYMENT)
                .automatedAction(ActionConstants.PROMOTION)
                .sourceActionStatus(AutomationRuleConstants.SOURCE_ACTION_STATUS_SUCCESSFUL)
                .connector(ACPromotionDeploymentToPromotion.class.getName())
                .execution(AutomationRuleConstants.EXECUTION_IMMEDIATE)
                .filterCriteria(JSON.serialize(criteria2))
                .persist();

            // Exercise
            Test.startTest();
            List<Automation_Rule__c> duplicates = new AutomationRuleDuplicatesChecker(new List<Automation_Rule__c>{ rule2 }).execute();
            Test.stopTest();

            // Verify
            System.assertEquals(1, duplicates.size(), 'Duplicates checker should return one element');
            System.assertEquals(rule1.Id, duplicates[0].Id, 'Automation Rule returned should match');
        }
    }

    @IsTest
    private static void duplicatesByFilterCriteria() {
        // Setup
        System.runAs(getUser()) {
            Deployment_Flow__c pipeline = getPipeline();

            FilterCriteria criteria1 = new FilterCriteria();
            criteria1.mainObject = Schema.SObjectType.User_Story__c.getName();
            criteria1.whereCondition = 'Name != null';
            new AutomationRule()
                .pipeline(pipeline.Id)
                .active()
                .sourceAction(ActionConstants.PROMOTION_DEPLOYMENT)
                .automatedAction(ActionConstants.PROMOTION)
                .sourceActionStatus(AutomationRuleConstants.SOURCE_ACTION_STATUS_SUCCESSFUL)
                .connector(ACPromotionDeploymentToPromotion.class.getName())
                .execution(AutomationRuleConstants.EXECUTION_SCHEDULED)
                .filterCriteria(JSON.serialize(criteria1))
                .persist();

            Automation_Rule__c rule2 = (Automation_Rule__c) new AutomationRule()
                .pipeline(pipeline.Id)
                .sourceAction(ActionConstants.PROMOTION_DEPLOYMENT)
                .automatedAction(ActionConstants.PROMOTION)
                .sourceActionStatus(AutomationRuleConstants.SOURCE_ACTION_STATUS_SUCCESSFUL)
                .connector(ACPromotionDeploymentToPromotion.class.getName())
                .execution(AutomationRuleConstants.EXECUTION_IMMEDIATE)
                .persist();

            // Exercise
            Test.startTest();
            List<Automation_Rule__c> duplicates = new AutomationRuleDuplicatesChecker(new List<Automation_Rule__c>{ rule2 }).execute();
            Test.stopTest();

            // Verify
            System.assert(!duplicates.isEmpty(), 'Should be duplicates (Filter Criteria is not a part of duplicate logic.)');
        }
    }

    @IsTest
    private static void noDuplicatesEnvironmentExcluded() {
        // Setup
        System.runAs(getUser()) {
            Deployment_Flow__c pipeline = getPipeline();
            Environment__c dev1Environment = getEnvironment('dev1');
            Stage__c stage = getStage('Dev');

            new AutomationRule()
                .pipeline(pipeline.Id)
                .active()
                .sourceAction(ActionConstants.PROMOTION_DEPLOYMENT)
                .automatedAction(ActionConstants.PROMOTION)
                .sourceActionStatus(AutomationRuleConstants.SOURCE_ACTION_STATUS_SUCCESSFUL)
                .connector(AutomationRuleConstants.AUTOMATION_CONNECTOR_CUSTOM)
                .execution(AutomationRuleConstants.EXECUTION_SCHEDULED)
                .customConnector(AutomationConnectorMock.class.getName())
                .environment(dev1Environment.Id);

            Automation_Rule__c rule2 = (Automation_Rule__c) new AutomationRule()
                .pipeline(pipeline.Id)
                .sourceAction(ActionConstants.PROMOTION_DEPLOYMENT)
                .automatedAction(ActionConstants.PROMOTION)
                .sourceActionStatus(AutomationRuleConstants.SOURCE_ACTION_STATUS_SUCCESSFUL)
                .connector(AutomationRuleConstants.AUTOMATION_CONNECTOR_CUSTOM)
                .execution(AutomationRuleConstants.EXECUTION_IMMEDIATE)
                .customConnector(AutomationConnectorMock.class.getName())
                .stage(stage.Id)
                .excludedEnvironments(dev1Environment.Id)
                .persist();

            // Exercise
            Test.startTest();
            List<Automation_Rule__c> duplicates = new AutomationRuleDuplicatesChecker(new List<Automation_Rule__c>{ rule2 }).execute();
            Test.stopTest();

            // Verify
            System.assert(duplicates.isEmpty(), 'Should not be duplicates');
        }
    }

    @IsTest
    private static void noDuplicates() {
        // Setup
        System.runAs(getUser()) {
            Deployment_Flow__c pipeline = getPipeline();
            Environment__c dev1Environment = getEnvironment('dev1');
            Environment__c dev2Environment = getEnvironment('dev2');
            Stage__c stage = getStage('Dev');

            new AutomationRule()
                .pipeline(pipeline.Id)
                .active()
                .sourceAction(ActionConstants.PROMOTION_DEPLOYMENT)
                .automatedAction(ActionConstants.PROMOTION)
                .sourceActionStatus(AutomationRuleConstants.SOURCE_ACTION_STATUS_SUCCESSFUL)
                .connector(AutomationRuleConstants.AUTOMATION_CONNECTOR_CUSTOM)
                .execution(AutomationRuleConstants.EXECUTION_SCHEDULED)
                .customConnector(AutomationConnectorMock.class.getName())
                .stage(stage.Id)
                .excludedEnvironments(dev1Environment.Id);

            Automation_Rule__c rule = (Automation_Rule__c) new AutomationRule()
                .pipeline(pipeline.Id)
                .sourceAction(ActionConstants.PROMOTION_DEPLOYMENT)
                .automatedAction(ActionConstants.PROMOTION)
                .sourceActionStatus(AutomationRuleConstants.SOURCE_ACTION_STATUS_SUCCESSFUL)
                .connector(AutomationRuleConstants.AUTOMATION_CONNECTOR_CUSTOM)
                .execution(AutomationRuleConstants.EXECUTION_IMMEDIATE)
                .customConnector(AutomationConnectorMock.class.getName())
                .stage(stage.Id)
                .excludedEnvironments(dev2Environment.Id)
                .persist();

            // Exercise
            Test.startTest();
            List<Automation_Rule__c> duplicates = new AutomationRuleDuplicatesChecker(new List<Automation_Rule__c>{ rule }).execute();
            Test.stopTest();

            // Verify
            System.assert(duplicates.isEmpty(), 'Should not be duplicates');
        }
    }

    @IsTest
    private static void duplicatedRuleNotActive() {
        // Setup
        System.runAs(getUser()) {
            Deployment_Flow__c pipeline = getPipeline();

            new AutomationRule()
                .pipeline(pipeline.Id)
                .sourceAction(ActionConstants.PROMOTION_DEPLOYMENT)
                .automatedAction(ActionConstants.PROMOTION)
                .sourceActionStatus(AutomationRuleConstants.SOURCE_ACTION_STATUS_SUCCESSFUL)
                .connector(AutomationRuleConstants.AUTOMATION_CONNECTOR_CUSTOM)
                .execution(AutomationRuleConstants.EXECUTION_IMMEDIATE)
                .customConnector(AutomationConnectorMock.class.getName());

            Automation_Rule__c rule = (Automation_Rule__c) new AutomationRule()
                .pipeline(pipeline.Id)
                .active()
                .sourceAction(ActionConstants.PROMOTION_DEPLOYMENT)
                .automatedAction(ActionConstants.PROMOTION)
                .sourceActionStatus(AutomationRuleConstants.SOURCE_ACTION_STATUS_SUCCESSFUL)
                .connector(AutomationRuleConstants.AUTOMATION_CONNECTOR_CUSTOM)
                .execution(AutomationRuleConstants.EXECUTION_SCHEDULED)
                .customConnector(AutomationConnectorMock.class.getName())
                .persist();

            // Exercise
            Test.startTest();
            List<Automation_Rule__c> duplicates = new AutomationRuleDuplicatesChecker(new List<Automation_Rule__c>{ rule }).execute();
            Test.stopTest();

            // Verify
            System.assert(duplicates.isEmpty(), 'Should not be duplicates');
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
            .add(new Connection(integration, uat).branch('int').stageConnection(testStageConnection))
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

    private static User getUser() {
        return [SELECT Id FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1];
    }

    private static Deployment_Flow__c getPipeline() {
        return [SELECT Id FROM Deployment_Flow__c LIMIT 1];
    }

    private static Environment__c getEnvironment() {
        return [SELECT Id FROM Environment__c LIMIT 1];
    }

    private static Environment__c getEnvironment(String name) {
        return [SELECT Id FROM Environment__c WHERE Name = :name LIMIT 1];
    }

    private static Stage__c getStage() {
        return [SELECT Id FROM Stage__c LIMIT 1];
    }

    private static Stage__c getStage(String name) {
        return [SELECT Id FROM Stage__c WHERE Name = :name LIMIT 1];
    }

    private static Stage_Connection__c getStageConnections(String stageName) {
        return [SELECT Id FROM Stage_Connection__c WHERE Stage__r.Name = :stageName];
    }

    private with sharing class FilterCriteria {
        private String mainObject;
        private String whereCondition;
    }
}