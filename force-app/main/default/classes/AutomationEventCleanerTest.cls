@IsTest
private with sharing class AutomationEventCleanerTest {
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
    private static void executeBatch() {
        // Setup
        System.runAs(getUser()) {
            Deployment_Flow__c pipeline = getPipeline();

            new AutomationRule()
                .pipeline(pipeline.Id)
                .active()
                .sourceAction(ActionConstants.PROMOTION_DEPLOYMENT)
                .automatedAction(ActionConstants.PROMOTION)
                .sourceActionStatus(AutomationRuleConstants.SOURCE_ACTION_STATUS_SUCCESSFUL)
                .connector(AutomationRuleConstants.AUTOMATION_CONNECTOR_CUSTOM)
                .execution(AutomationRuleConstants.EXECUTION_SCHEDULED)
                .cronExpression('0 0 0 ? * * *')
                .lastExecutionDatetime(System.now().addDays(3))
                .customConnector(AutomationConnectorMock.class.getName());

            new AutomationRule()
                .pipeline(pipeline.Id)
                .active()
                .sourceAction(ActionConstants.COMMIT_ACTION)
                .automatedAction(ActionConstants.PROMOTION)
                .sourceActionStatus(AutomationRuleConstants.SOURCE_ACTION_STATUS_SUCCESSFUL)
                .connector(AutomationRuleConstants.AUTOMATION_CONNECTOR_CUSTOM)
                .execution(AutomationRuleConstants.EXECUTION_IMMEDIATE)
                .customConnector(AutomationConnectorMock.class.getName())
                .persist();

            // create matching events for immediate rule
            Automation_Event__c event1 = (Automation_Event__C) new AutomationEvent()
                .pipelineId(pipeline.Id)
                .actionName(ActionConstants.COMMIT_ACTION)
                .actionStatus(AutomationRuleConstants.SOURCE_ACTION_STATUS_SUCCESSFUL)
                .actionResult('TestImmediateCanNotBeDeleted')
                .persist();

            Automation_Event__c event2 = (Automation_Event__C) new AutomationEvent()
                .pipelineId(pipeline.Id)
                .actionName(ActionConstants.COMMIT_ACTION)
                .actionStatus(AutomationRuleConstants.SOURCE_ACTION_STATUS_SUCCESSFUL)
                .actionResult('TestImmediate')
                .persist();
            Test.setCreatedDate(event2.Id, System.now().addDays(-2));

            // create matching event for scheduled rule
            Automation_Event__c event3 = (Automation_Event__C) new AutomationEvent()
                .pipelineId(pipeline.Id)
                .actionName(ActionConstants.PROMOTION_DEPLOYMENT)
                .actionStatus(AutomationRuleConstants.SOURCE_ACTION_STATUS_SUCCESSFUL)
                .actionResult('TestScheduled')
                .persist();

            // create non-matching event
            Automation_Event__c event4 = (Automation_Event__C) new AutomationEvent()
                .pipelineId(pipeline.Id)
                .actionName(ActionConstants.CREATE_PACKAGE_VERSION)
                .actionStatus(AutomationRuleConstants.SOURCE_ACTION_STATUS_SUCCESSFUL)
                .actionResult('TestImmediate')
                .persist();
            Test.setCreatedDate(event4.Id, System.now().addDays(-2));

            Set<Id> expectedEvents = new Set<Id>{ event1.Id, event3.Id };

            // Exercise
            Test.startTest();
            Database.executeBatch(new AutomationEventCleaner());
            Test.stopTest();

            // Verify
            List<Automation_Event__c> automationEvents = [SELECT Id FROM Automation_Event__c];
            System.assertEquals(
                2,
                automationEvents.size(),
                'Two events should remain (for immediate rule but recent and for scheduled rule not executed yet). Others should be deleted.'
            );
            for (Automation_Event__c automationEvent : automationEvents) {
                System.assert(expectedEvents.contains(automationEvent.Id), 'Non deletable events should remain.');
            }
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