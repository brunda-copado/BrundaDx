@IsTest
private class ContinuousDeliverySetupControllerTest {
    @TestSetup
    private static void makeData() {
        TestUtilities.getAllMultilicense();
        new User_t()
            .alias('TestUsr1')
            .assign(new PermissionSetAssignment_t().copadoUser())
            .assign(new PermissionSetAssignment_t().executeAutomations());
        User user = (User) new User_t()
            .alias('TestUsr2')
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
    private static void getStageConnections() {
        // Setup
        System.runAs(getUser()) {
            Deployment_Flow__c pipeline = getPipeline();

            // Exercise
            Test.startTest();
            List<Stage_Connection__c> stageConnections = ContinuousDeliverySetupController.getStageConnections(pipeline.Id);
            Test.stopTest();

            // Verify
            System.assertEquals(3, stageConnections.size(), 'There are three stage connections');
        }
    }

    @IsTest
    private static void continuousDeliveryWizardWihtoutPermission() {
        // Setup
        System.runAs(getUserWithoutPermissions()) {
            Deployment_Flow__c pipeline = getPipeline();

            // Exercise
            Test.startTest();
            String message = '';
            try {
                ContinuousDeliverySetupController.checkPermissions(pipeline.Id);
            } catch (Exception ex) {
                message = ex.getMessage();
            }
            Test.stopTest();

            // Verify
            System.assertNotEquals('', message, 'There are permission issue');
        }
    }

    @IsTest
    private static void continuousDeliveryWizardWihtoutStages() {
        // Setup
        System.runAs(getUser()) {
            Deployment_Flow__c pipeline = getPipeline();
            delete [SELECT Id FROM Stage_Connection__c];

            // Exercise
            Test.startTest();
            String message = '';
            try {
                ContinuousDeliverySetupController.checkPermissions(pipeline.Id);
            } catch (Exception ex) {
                message = ex.getMessage();
            }
            Test.stopTest();

            // Verify
            System.assertEquals(Label.CD_Setup_No_Stages, message, 'Message does not match');
        }
    }

    @IsTest
    private static void continuousDeliveryWizardWihtOneStageConnection() {
        // Setup
        System.runAs(getUser()) {
            Deployment_Flow__c pipeline = getPipeline();
            delete [SELECT Id FROM Stage_Connection__c LIMIT 2];

            // Exercise
            Test.startTest();
            String message = '';
            try {
                ContinuousDeliverySetupController.checkPermissions(pipeline.Id);
            } catch (Exception ex) {
                message = ex.getMessage();
            }
            Test.stopTest();

            // Verify
            System.assertEquals(Label.CD_Setup_No_Stages, message, 'Message does not match');
        }
    }

    @IsTest
    private static void getEnvironments() {
        // Setup
        System.runAs(getUser()) {
            Deployment_Flow__c pipeline = getPipeline();
            List<Id> stageIds = new List<Id>();
            for (Stage__c stage : getStages()) {
                stageIds.add(stage.Id);
            }

            // Exercise
            Test.startTest();
            List<Environment__c> environments = ContinuousDeliverySetupController.getEnvironments(pipeline.Id, stageIds);
            Test.stopTest();

            // Verify
            System.assertEquals(3, environments.size(), 'There are three environments');
        }
    }

    @IsTest
    private static void getAutomationRules() {
        // Setup
        System.runAs(getUser()) {
            Deployment_Flow__c pipeline = getPipeline();
            List<Id> stageIds = new List<Id>();
            List<String> stageNames = new List<String>();
            for (Stage__c stage : getStages()) {
                stageIds.add(stage.Id);
                stageNames.add(stage.Display_Name__c);
            }
            List<Id> environmentIds = new List<Id>();
            List<String> environmentNames = new List<String>();
            for (Environment__c environment : getPipelineEnvironments()) {
                environmentIds.add(environment.Id);
                environmentNames.add(environment.Name);
            }
            new AutomationRule()
                .pipeline(new Pipeline())
                .active()
                .sourceAction(ActionConstants.PROMOTION_DEPLOYMENT)
                .automatedAction(AutomationRuleConstants.CONTINUOUS_DELIVERY + ' - ' + ActionConstants.PROMOTION)
                .sourceActionStatus(AutomationRuleConstants.SOURCE_ACTION_STATUS_SUCCESSFUL)
                .connector(ACPromotionDeploymentToPromotion.class.getName())
                .execution(AutomationRuleConstants.EXECUTION_IMMEDIATE);
            new AutomationRule()
                .pipeline(pipeline.Id)
                .active()
                .name('Test 1')
                .sourceAction(ActionConstants.PROMOTION_DEPLOYMENT)
                .automatedAction(AutomationRuleConstants.CONTINUOUS_DELIVERY + ' - ' + ActionConstants.PROMOTION)
                .sourceActionStatus(AutomationRuleConstants.SOURCE_ACTION_STATUS_SUCCESSFUL)
                .connector(ACPromotionDeploymentToPromotion.class.getName())
                .execution(AutomationRuleConstants.EXECUTION_IMMEDIATE)
                .stage(String.join(stageIds, ','));
            new AutomationRule()
                .pipeline(pipeline.Id)
                .active()
                .name('Test 2')
                .sourceAction(ActionConstants.PROMOTION_DEPLOYMENT)
                .automatedAction(AutomationRuleConstants.CONTINUOUS_DELIVERY + ' - ' + ActionConstants.PROMOTION)
                .sourceActionStatus(AutomationRuleConstants.SOURCE_ACTION_STATUS_SUCCESSFUL)
                .connector(ACPromotionDeploymentToBackPromotion.class.getName())
                .execution(AutomationRuleConstants.EXECUTION_IMMEDIATE)
                .environment(String.join(environmentIds, ','))
                .persist();

            // Exercise
            Test.startTest();
            List<ContinuousDeliverySetupController.AutomationRule> automationRules = ContinuousDeliverySetupController.getAutomationRules(
                pipeline.Id
            );
            Test.stopTest();

            // Verify
            System.assertEquals(2, automationRules.size(), 'There are two existing rules');
            System.assertEquals(String.join(stageNames, ', '), automationRules[0].stages, 'Stages should match');
            System.assertEquals('Test 1', automationRules[0].name, 'Name should match');
            System.assertEquals(String.join(environmentNames, ', '), automationRules[1].environments, 'Environments should match');
            System.assertEquals('Test 2', automationRules[1].name, 'Name should match');
        }
    }

    @IsTest
    private static void activateAutomationsForPipeline() {
        System.runAs(getUser()) {
            // Setup
            Deployment_Flow__c pipeline = getPipeline();

            ContinuousDeliverySetupController.ConfigurationSettings configSettings = new ContinuousDeliverySetupController.ConfigurationSettings();
            configSettings.uptoStage = new List<String>{};
            configSettings.selectedEnvironments = new List<String>{};

            ContinuousDeliverySetupController.ConfigurationJSON configJson = new ContinuousDeliverySetupController.ConfigurationJSON();
            configJson.promotionSettings = configSettings;
            configJson.backpromotionSettings = configSettings;

            Automation_Rule__c existingRule = (Automation_Rule__c) new AutomationRule()
                .name('test')
                .automatedAction(AutomationRuleConstants.CONTINUOUS_DELIVERY + ' - ' + ActionConstants.PROMOTION)
                .connector(ACPromotionDeploymentToPromotion.class.getName())
                .execution(AutomationRuleConstants.EXECUTION_IMMEDIATE)
                .pipeline(pipeline.Id)
                .sourceAction(ActionConstants.PROMOTION_DEPLOYMENT)
                .sourceActionStatus(AutomationRuleConstants.SOURCE_ACTION_STATUS_SUCCESSFUL)
                .active()
                .persist();

            // Exercise
            Test.startTest();
            ContinuousDeliverySetupController.activateAutomations(pipeline.Id, JSON.serialize(configJson));
            Test.stopTest();

            // Verify
            List<Automation_Rule__c> existingRules = [SELECT Id FROM Automation_Rule__c WHERE Id = :existingRule.Id];
            System.assertEquals(0, existingRules.size(), 'Rule should be deleted');
            List<Automation_Rule__c> rules = [SELECT Id, Pipeline__c, Stage__c, Environment__c FROM Automation_Rule__c];
            System.assertEquals(2, rules.size(), 'There should be 2 new rules');
            for (Automation_Rule__c rule : rules) {
                System.assertEquals(pipeline.Id, rules[0].Pipeline__c, 'The pipeline should match');
                System.assertEquals(null, rules[0].Stage__c, 'The stage should be empty');
                System.assertEquals(null, rules[0].Environment__c, 'The environment should be empty');
            }
        }
    }

    @IsTest
    private static void activateAutomationsForPromotionWithEnvironment() {
        System.runAs(getUser()) {
            // Setup
            Deployment_Flow__c pipeline = getPipeline();
            Deployment_Flow_Step__c pipelineConnection = getPipelineConnection();

            ContinuousDeliverySetupController.ConfigurationSettings configSettings = new ContinuousDeliverySetupController.ConfigurationSettings();
            configSettings.uptoStage = new List<String>{ pipelineConnection.Stage_Connection__r.Stage__r.Name };
            configSettings.selectedEnvironments = new List<String>{ pipelineConnection.Source_Environment__r.Name };

            ContinuousDeliverySetupController.ConfigurationJSON configJson = new ContinuousDeliverySetupController.ConfigurationJSON();
            configJson.promotionSettings = configSettings;
            configJson.backpromotionSettings = null;

            Automation_Rule__c existingRule = (Automation_Rule__c) new AutomationRule()
                .name('test')
                .automatedAction(AutomationRuleConstants.CONTINUOUS_DELIVERY + ' - ' + ActionConstants.PROMOTION)
                .connector(ACPromotionDeploymentToPromotion.class.getName())
                .execution(AutomationRuleConstants.EXECUTION_IMMEDIATE)
                .pipeline(pipeline.Id)
                .sourceAction(ActionConstants.PROMOTION_DEPLOYMENT)
                .sourceActionStatus(AutomationRuleConstants.SOURCE_ACTION_STATUS_SUCCESSFUL)
                .active()
                .persist();

            // Exercise
            Test.startTest();
            ContinuousDeliverySetupController.activateAutomations(pipeline.Id, JSON.serialize(configJson));
            Test.stopTest();

            // Verify
            List<Automation_Rule__c> existingRules = [SELECT Id FROM Automation_Rule__c WHERE Id = :existingRule.Id];
            System.assertEquals(0, existingRules.size(), 'Rule should be deleted');
            List<Automation_Rule__c> rules = [
                SELECT
                    Id,
                    Name,
                    Automated_Action__c,
                    Automation_Connector__c,
                    Execution__c,
                    Pipeline__c,
                    Source_Action__c,
                    Source_Action_Status__c,
                    Environment__c,
                    Stage__c
                FROM Automation_Rule__c
            ];
            System.assertEquals(1, rules.size(), 'There should be 1 new rule');
            System.assertEquals(ContinuousDeliverySetupController.RULE_NAME_PROMOTION, rules[0].Name, 'The name should match');
            System.assertEquals(
                AutomationRuleConstants.CONTINUOUS_DELIVERY + ' - ' + new ACPromotionDeploymentToPromotion().getAutomatedActionName(),
                rules[0].Automated_Action__c,
                'The automated action should match'
            );
            System.assertEquals(
                ACPromotionDeploymentToPromotion.class.getName(),
                rules[0].Automation_Connector__c,
                'The automation connector should match'
            );
            System.assertEquals(AutomationRuleConstants.EXECUTION_IMMEDIATE, rules[0].Execution__c, 'The execution should match');
            System.assertEquals(pipeline.Id, rules[0].Pipeline__c, 'The pipeline should match');
            System.assertEquals(ActionConstants.PROMOTION_DEPLOYMENT, rules[0].Source_Action__c, 'The source action should match');
            System.assertEquals(
                AutomationRuleConstants.SOURCE_ACTION_STATUS_SUCCESSFUL,
                rules[0].Source_Action_Status__c,
                'The source action status should match'
            );
            System.assertEquals(pipelineConnection.Source_Environment__c, rules[0].Environment__c, 'The environment should match');
            System.assertEquals(null, rules[0].Stage__c, 'The stage should be empty');
        }
    }

    @IsTest
    private static void activateAutomationsForBackPromotionWithStage() {
        System.runAs(getUser()) {
            // Setup
            Deployment_Flow__c pipeline = getPipeline();
            Deployment_Flow_Step__c pipelineConnection = getPipelineConnection();

            ContinuousDeliverySetupController.ConfigurationSettings configSettings = new ContinuousDeliverySetupController.ConfigurationSettings();
            configSettings.uptoStage = new List<String>{ pipelineConnection.Stage_Connection__r.Stage__r.Name };
            configSettings.selectedEnvironments = null;

            ContinuousDeliverySetupController.ConfigurationJSON configJson = new ContinuousDeliverySetupController.ConfigurationJSON();
            configJson.promotionSettings = null;
            configJson.backpromotionSettings = configSettings;

            Automation_Rule__c existingRule = (Automation_Rule__c) new AutomationRule()
                .name('test')
                .automatedAction(AutomationRuleConstants.CONTINUOUS_DELIVERY + ' - ' + ActionConstants.PROMOTION)
                .connector(ACPromotionDeploymentToPromotion.class.getName())
                .execution(AutomationRuleConstants.EXECUTION_IMMEDIATE)
                .pipeline(pipeline.Id)
                .sourceAction(ActionConstants.PROMOTION_DEPLOYMENT)
                .sourceActionStatus(AutomationRuleConstants.SOURCE_ACTION_STATUS_SUCCESSFUL)
                .active()
                .persist();

            // Exercise
            Test.startTest();
            ContinuousDeliverySetupController.activateAutomations(pipeline.Id, JSON.serialize(configJson));
            Test.stopTest();

            // Verify
            List<Automation_Rule__c> existingRules = [SELECT Id FROM Automation_Rule__c WHERE Id = :existingRule.Id];
            System.assertEquals(0, existingRules.size(), 'Rule should be deleted');
            List<Automation_Rule__c> rules = [
                SELECT
                    Id,
                    Name,
                    Automated_Action__c,
                    Automation_Connector__c,
                    Execution__c,
                    Pipeline__c,
                    Source_Action__c,
                    Source_Action_Status__c,
                    Environment__c,
                    Stage__c
                FROM Automation_Rule__c
            ];
            System.assertEquals(1, rules.size(), 'There should be 2 new rules');
            System.assertEquals(ContinuousDeliverySetupController.RULE_NAME_BACK_PROMOTION, rules[0].Name, 'The name should match');
            System.assertEquals(
                AutomationRuleConstants.CONTINUOUS_DELIVERY + ' - ' + new ACPromotionDeploymentToBackPromotion().getAutomatedActionName(),
                rules[0].Automated_Action__c,
                'The automated action should match'
            );
            System.assertEquals(
                ACPromotionDeploymentToBackPromotion.class.getName(),
                rules[0].Automation_Connector__c,
                'The automation connector should match'
            );
            System.assertEquals(AutomationRuleConstants.EXECUTION_IMMEDIATE, rules[0].Execution__c, 'The execution should match');
            System.assertEquals(pipeline.Id, rules[0].Pipeline__c, 'The pipeline should match');
            System.assertEquals(ActionConstants.PROMOTION_DEPLOYMENT, rules[0].Source_Action__c, 'The source action should match');
            System.assertEquals(
                AutomationRuleConstants.SOURCE_ACTION_STATUS_SUCCESSFUL,
                rules[0].Source_Action_Status__c,
                'The source action status should match'
            );
            System.assertEquals(null, rules[0].Environment__c, 'The environment should be empty');
            System.assertEquals(pipelineConnection.Stage_Connection__r.Stage__c, rules[0].Stage__c, 'The stage should match');
        }
    }

    @IsTest
    private static void activateAutomationsSkippingActions() {
        System.runAs(getUser()) {
            // Setup
            Deployment_Flow__c pipeline = getPipeline();

            ContinuousDeliverySetupController.ConfigurationJSON configJson = new ContinuousDeliverySetupController.ConfigurationJSON();
            configJson.promotionSettings = null;
            configJson.backpromotionSettings = null;

            new AutomationRule()
                .name('test')
                .automatedAction(AutomationRuleConstants.CONTINUOUS_DELIVERY + ' - ' + ActionConstants.PROMOTION)
                .connector(ACPromotionDeploymentToPromotion.class.getName())
                .execution(AutomationRuleConstants.EXECUTION_IMMEDIATE)
                .pipeline(pipeline.Id)
                .sourceAction(ActionConstants.PROMOTION_DEPLOYMENT)
                .sourceActionStatus(AutomationRuleConstants.SOURCE_ACTION_STATUS_SUCCESSFUL)
                .active()
                .persist();

            // Exercise
            Test.startTest();
            ContinuousDeliverySetupController.activateAutomations(pipeline.Id, JSON.serialize(configJson));
            Test.stopTest();

            // Verify
            List<Automation_Rule__c> existingRules = [SELECT Id FROM Automation_Rule__c];
            System.assertEquals(0, existingRules.size(), 'Rule should be deleted and no new rules created');
        }
    }

    @IsTest
    private static void getDuplicatedAutomationRule() {
        // Setup
        System.runAs(getUser()) {
            Deployment_Flow__c pipeline = (Deployment_Flow__c) new Pipeline().persist();

            new AutomationRule()
                .pipeline(pipeline.Id)
                .active()
                .sourceAction(ActionConstants.PROMOTION_DEPLOYMENT)
                .automatedAction(AutomationRuleConstants.CONTINUOUS_DELIVERY + ' - ' + ActionConstants.PROMOTION)
                .sourceActionStatus(AutomationRuleConstants.SOURCE_ACTION_STATUS_SUCCESSFUL)
                .connector(ACPromotionDeploymentToPromotion.class.getName())
                .execution(AutomationRuleConstants.EXECUTION_IMMEDIATE);

            Automation_Rule__c rule1 = (Automation_Rule__c) new AutomationRule()
                .pipeline(pipeline.Id)
                .active()
                .sourceAction(ActionConstants.PROMOTION_DEPLOYMENT)
                .automatedAction(ActionConstants.PROMOTION)
                .sourceActionStatus(AutomationRuleConstants.SOURCE_ACTION_STATUS_SUCCESSFUL)
                .connector(ACPromotionDeploymentToPromotion.class.getName())
                .execution(AutomationRuleConstants.EXECUTION_IMMEDIATE)
                .persist();

            new AutomationRule()
                .pipeline(pipeline.Id)
                .active()
                .sourceAction(ActionConstants.PROMOTION_DEPLOYMENT)
                .automatedAction(AutomationRuleConstants.CONTINUOUS_DELIVERY + ' - ' + ActionConstants.PROMOTION)
                .sourceActionStatus(AutomationRuleConstants.SOURCE_ACTION_STATUS_SUCCESSFUL)
                .connector(ACPromotionDeploymentToBackPromotion.class.getName())
                .execution(AutomationRuleConstants.EXECUTION_IMMEDIATE);

            Automation_Rule__c rule2 = (Automation_Rule__c) new AutomationRule()
                .pipeline(pipeline.Id)
                .active()
                .sourceAction(ActionConstants.PROMOTION_DEPLOYMENT)
                .automatedAction(ActionConstants.PROMOTION)
                .sourceActionStatus(AutomationRuleConstants.SOURCE_ACTION_STATUS_SUCCESSFUL)
                .connector(ACPromotionDeploymentToBackPromotion.class.getName())
                .execution(AutomationRuleConstants.EXECUTION_IMMEDIATE)
                .persist();

            ContinuousDeliverySetupController.ConfigurationJSON configJSON = new ContinuousDeliverySetupController.ConfigurationJSON();
            configJSON.promotionSettings = new ContinuousDeliverySetupController.ConfigurationSettings();
            configJSON.promotionSettings.uptoStage = new List<String> {'Production'};
            configJSON.backpromotionSettings = new ContinuousDeliverySetupController.ConfigurationSettings();
            configJSON.backpromotionSettings.uptoStage = new List<String> {'Production'};

            // Exercise
            Test.startTest();
            List<Automation_Rule__c> duplicates = ContinuousDeliverySetupController.getDuplicatedAutomationRule(pipeline.Id, JSON.serialize(configJson));
            Test.stopTest();

            // Verify
            System.assertEquals(2, duplicates.size(), 'Duplicates checker should return one element');
            System.assertEquals(rule1.Id, duplicates[0].Id, 'Automation Rule returned should match');
            System.assertEquals(rule2.Id, duplicates[1].Id, 'Automation Rule returned should match');
        }
    }

    private static void createData() {
        //TODO fix data to connect next stage on the connection (null pointer because of that)
        Stage devStage = new Stage().name('Dev').metaStage('Build');
        Stage testStage = new Stage().name('Test').metaStage('Test');
        Stage productionStage = new Stage().name('Production').metaStage('Production');

        Environment dev1 = new Environment().name('dev1').type('Sandbox').platform('Other').add(new Credential());
        Environment uat = new Environment().name('uat').type('Sandbox').platform('Other').add(new Credential());
        Environment prod = new Environment().name('prod').type('Sandbox').platform('Other').add(new Credential());

        StageConnection devStageConnection = new StageConnection().stage(devStage);
        StageConnection testStageConnection = new StageConnection().stage(testStage);
        StageConnection productionStageConnection = new StageConnection().stage(productionStage);

        new Pipeline()
            .active(true)
            .mainBranch('main')
            .setPlatform('Other')
            .add(new Connection(dev1, uat).branch('dev1').stageConnection(devStageConnection))
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
        return [SELECT Id FROM User WHERE Profile.Name = 'Standard User' AND Alias = 'TestUsr2' ORDER BY CreatedDate DESC LIMIT 1];
    }

    private static User getUserWithoutPermissions() {
        return [SELECT Id FROM User WHERE Profile.Name = 'Standard User' AND Alias = 'TestUsr1' ORDER BY CreatedDate DESC LIMIT 1];
    }

    private static Deployment_Flow__c getPipeline() {
        return [SELECT Id FROM Deployment_Flow__c LIMIT 1];
    }

    private static Deployment_Flow_Step__c getPipelineConnection() {
        return [
            SELECT Id, Source_Environment__c, Source_Environment__r.Name, Stage_Connection__r.Stage__c, Stage_Connection__r.Stage__r.Name
            FROM Deployment_Flow_Step__c
            LIMIT 1
        ];
    }

    private static List<Stage__c> getStages() {
        return [SELECT Id, Name, Display_Name__c FROM Stage__c];
    }

    private static List<Environment__c> getPipelineEnvironments() {
        return [SELECT Id, Name FROM Environment__c];
    }

    private static Stage_Connection__c getStageConnections(String stageName) {
        return [SELECT Id FROM Stage_Connection__c WHERE Stage__r.Name = :stageName];
    }
}