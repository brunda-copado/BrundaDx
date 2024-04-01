@IsTest
public with sharing class AutomationConnectorGeneratorTest {
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
    private static void standardConnector() {
        // Setup
        System.runAs(getUser()) {
            Deployment_Flow__c pipeline = getPipeline();

            Automation_Rule__c rule = (Automation_Rule__c) new AutomationRule()
                .pipeline(pipeline.Id)
                .active()
                .sourceAction(ActionConstants.PROMOTION_DEPLOYMENT)
                .automatedAction(ActionConstants.PROMOTION)
                .sourceActionStatus(AutomationRuleConstants.SOURCE_ACTION_STATUS_SUCCESSFUL)
                .connector(ACPromotionDeploymentToPromotion.class.getName())
                .execution(AutomationRuleConstants.EXECUTION_IMMEDIATE)
                .persist();

            Automation_Event__c event = (Automation_Event__c) new AutomationEvent()
                .pipelineId(pipeline.Id)
                .actionName(ActionConstants.PROMOTION_DEPLOYMENT)
                .actionStatus(AutomationRuleConstants.SOURCE_ACTION_STATUS_SUCCESSFUL)
                .actionResult('Test Result')
                .persist();

            // Exercise
            Test.startTest();
            AutomationConnector connector = new AutomationConnectorGenerator(new List<Automation_Event__c>{ event }, rule).execute();
            Test.stopTest();

            // Verify
            System.assert(connector instanceof ACPromotionDeploymentToPromotion, 'Connector class should match');
        }
    }

    @IsTest
    private static void customConnector() {
        // Setup
        System.runAs(getUser()) {
            Deployment_Flow__c pipeline = getPipeline();

            Automation_Rule__c rule = (Automation_Rule__c) new AutomationRule()
                .pipeline(pipeline.Id)
                .active()
                .sourceAction(ActionConstants.PROMOTION_DEPLOYMENT)
                .automatedAction(ActionConstants.PROMOTION)
                .sourceActionStatus(AutomationRuleConstants.SOURCE_ACTION_STATUS_SUCCESSFUL)
                .connector(AutomationRuleConstants.AUTOMATION_CONNECTOR_CUSTOM)
                .execution(AutomationRuleConstants.EXECUTION_IMMEDIATE)
                .customConnector(AutomationConnectorMock.class.getName())
                .persist();

            Automation_Event__c event = (Automation_Event__c) new AutomationEvent()
                .pipelineId(pipeline.Id)
                .actionName(ActionConstants.PROMOTION_DEPLOYMENT)
                .actionStatus(AutomationRuleConstants.SOURCE_ACTION_STATUS_SUCCESSFUL)
                .actionResult('Test Result')
                .persist();

            // Exercise
            Test.startTest();
            AutomationConnector connector = new AutomationConnectorGenerator(new List<Automation_Event__c>{ event }, rule).execute();
            Test.stopTest();

            // Verify
            System.assert(connector instanceof AutomationConnectorMock, 'Connector class should match');
        }
    }

    private static void createData() {
        new Pipeline().setPlatform('Other').active(true).persist();
    }

    private static User getUser() {
        return [SELECT Id FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1];
    }

    private static Deployment_Flow__c getPipeline() {
        return [SELECT Id FROM Deployment_Flow__c LIMIT 1];
    }
}