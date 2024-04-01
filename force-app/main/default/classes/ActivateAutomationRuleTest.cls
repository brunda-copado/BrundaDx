@IsTest
private class ActivateAutomationRuleTest {

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
        }
    }

    @IsTest
    private static void activateRuleWithoutRequiredFields() {
        // Setup
        System.runAs(getUser()) {
            Automation_Rule__c rule = (Automation_Rule__c) new AutomationRule()
                .pipeline(new Pipeline())
                .sourceAction(null)
                .sourceActionStatus(null)
                .connector(null)
                .execution(null)
                .persist();

            List<String> missingFields = new List<String> {
                Automation_Rule__c.Source_Action__c.getDescribe().getLabel(),
                Automation_Rule__c.Source_Action_Status__c.getDescribe().getLabel(),
                Automation_Rule__c.Automation_Connector__c.getDescribe().getLabel(),
                Automation_Rule__c.Execution__c.getDescribe().getLabel()
            };
            String expectedErrorMessage = String.format(Label.ActivatingAutomationBodyErrorMessage, new List<String> {String.join(missingFields, ', ')});

            Exception expectedException;

            // Exercise
            Test.startTest();
            try {
                new ActivateAutomationRule(new Set<Id> {rule.Id}).execute();
            } catch(Exception ex) {
                expectedException = ex;
            }
            Test.stopTest();

            // Verify
            Automation_Rule__c resultRule = [SELECT Active__c FROM Automation_Rule__c WHERE Id = :rule.Id];
            System.assertEquals(false, resultRule.Active__c, 'Rule should not be active');
            System.assertNotEquals(null, expectedException, 'An exception should be thrown');
            System.assertEquals(expectedErrorMessage, expectedException.getMessage(), 'Exception message does not match');
        }
    }

    @IsTest
    private static void activateRuleWithoutPemissions() {
        // Setup
        Automation_Rule__c rule;
        System.runAs(getUser()) {
            rule = (Automation_Rule__c) new AutomationRule()
                .pipeline(new Pipeline())
                .sourceAction(null)
                .sourceActionStatus(null)
                .connector(null)
                .execution(null)
                .persist();
        }

        System.runAs(getUserWithoutPermissions()) {
            Exception expectedException;

            // Exercise
            Test.startTest();
            try {
                new ActivateAutomationRule(new Set<Id> {rule.Id}).execute();
            } catch(Exception ex) {
                expectedException = ex;
            }
            Test.stopTest();

            // Verify
            Automation_Rule__c resultRule = [SELECT Active__c FROM Automation_Rule__c WHERE Id = :rule.Id];
            System.assertEquals(false, resultRule.Active__c, 'Rule should not be active');
            System.assertNotEquals(null, expectedException, 'An exception should be thrown');
            System.assertEquals(Label.ActivatingAutomationPermissionsError, expectedException.getMessage(), 'Exception message does not match');
        }
    }

    @IsTest
    private static void activateRuleWithoutCustomConnectorAndCronExpression() {
        // Setup
        System.runAs(getUser()) {
            Automation_Rule__c rule = (Automation_Rule__c) new AutomationRule()
                .pipeline(new Pipeline())
                .sourceAction(null)
                .sourceActionStatus(null)
                .connector(AutomationRuleConstants.AUTOMATION_CONNECTOR_CUSTOM)
                .execution(AutomationRuleConstants.EXECUTION_SCHEDULED)
                .persist();

            List<String> missingFields = new List<String> {
                Automation_Rule__c.Source_Action__c.getDescribe().getLabel(),
                Automation_Rule__c.Source_Action_Status__c.getDescribe().getLabel(),
                Automation_Rule__c.Custom_Automation_Connector__c.getDescribe().getLabel(),
                Automation_Rule__c.Cron_Expression__c.getDescribe().getLabel()
            };
            String expectedErrorMessage = String.format(Label.ActivatingAutomationBodyErrorMessage, new List<String> {String.join(missingFields, ', ')});

            Exception expectedException;

            // Exercise
            Test.startTest();
            try {
                new ActivateAutomationRule(new Set<Id> {rule.Id}).execute();
            } catch(Exception ex) {
                expectedException = ex;
            }
            Test.stopTest();

            // Verify
            Automation_Rule__c resultRule = [SELECT Active__c FROM Automation_Rule__c WHERE Id = :rule.Id];
            System.assertEquals(false, resultRule.Active__c, 'Rule should not be active');
            System.assertNotEquals(null, expectedException, 'An exception should be thrown');
            System.assertEquals(expectedErrorMessage, expectedException.getMessage(), 'Exception message does not match');
        }
    }

    @IsTest
    private static void activateRuleWithSchedule() {
        // Setup
        System.runAs(getUser()) {
            String cronExpression = '0 20 * * * ?';
            Automation_Rule__c rule = (Automation_Rule__c) new AutomationRule()
                .pipeline(new Pipeline())
                .sourceAction(ActionConstants.PROMOTION_DEPLOYMENT)
                .automatedAction(ActionConstants.PROMOTION)
                .sourceActionStatus(AutomationRuleConstants.SOURCE_ACTION_STATUS_SUCCESSFUL)
                .connector(AutomationRuleConstants.AUTOMATION_CONNECTOR_CUSTOM)
                .execution(AutomationRuleConstants.EXECUTION_SCHEDULED)
                .customConnector(AutomationConnectorMock.class.getName())
                .cronExpression(cronExpression)
                .persist();

            // Exercise
            Test.startTest();
            new ActivateAutomationRule(new Set<Id> {rule.Id}).execute();
            Test.stopTest();

            // Verify
            Automation_Rule__c resultRule = [SELECT Active__c, Scheduled_Job_Id__c FROM Automation_Rule__c WHERE Id = :rule.Id];
            System.assertEquals(true, resultRule.Active__c, 'Rule should be activated');
            List<CronTrigger> scheduledJobs = [SELECT Id, CronExpression FROM CronTrigger WHERE Id = :resultRule.Scheduled_Job_Id__c];
            System.assertEquals(1, scheduledJobs.size(), 'One job should be scheduled');
            System.assertEquals(cronExpression, scheduledJobs[0].CronExpression, 'Cron expression should match');
        }
    }

    @IsTest
    private static void activateRuleWithScheduleAndInvalidCronExpression() {
        // Setup
        System.runAs(getUser()) {
            String cronExpression = '1 1 1 1 1 1';
            Automation_Rule__c rule = (Automation_Rule__c) new AutomationRule()
                .pipeline(new Pipeline())
                .sourceAction(ActionConstants.PROMOTION_DEPLOYMENT)
                .automatedAction(ActionConstants.PROMOTION)
                .sourceActionStatus(AutomationRuleConstants.SOURCE_ACTION_STATUS_SUCCESSFUL)
                .connector(AutomationRuleConstants.AUTOMATION_CONNECTOR_CUSTOM)
                .execution(AutomationRuleConstants.EXECUTION_SCHEDULED)
                .customConnector(AutomationConnectorMock.class.getName())
                .cronExpression(cronExpression)
                .persist();

            Exception expectedException;

            // Exercise
            Test.startTest();
            try {
                new ActivateAutomationRule(new Set<Id> {rule.Id}).execute();
            } catch(Exception ex) {
                expectedException = ex;
            }
            Test.stopTest();

            // Verify
            System.assertNotEquals(null, expectedException, 'An exception should be thrown');
            System.assertEquals(Label.ActivatingAutomationScheduledError, expectedException.getMessage(), 'Error message should match');
            Automation_Rule__c resultRule = [SELECT Active__c, Scheduled_Job_Id__c FROM Automation_Rule__c WHERE Id = :rule.Id];
            System.assertEquals(false, resultRule.Active__c, 'Rule should not be activated');
            List<CronTrigger> scheduledJobs = [SELECT Id FROM CronTrigger WHERE Id = :resultRule.Scheduled_Job_Id__c];
            System.assertEquals(0, scheduledJobs.size(), 'The job should not be scheduled');
        }
    }

    @IsTest
    private static void activateRuleWithCustomConnectorAndContinuousDeliveryKeyword() {
        // Setup
        System.runAs(getUser()) {
            Automation_Rule__c rule = (Automation_Rule__c) new AutomationRule()
                .pipeline(new Pipeline())
                .sourceAction(ActionConstants.PROMOTION_DEPLOYMENT)
                .automatedAction(AutomationRuleConstants.CONTINUOUS_DELIVERY + ' - ' + ActionConstants.PROMOTION)
                .sourceActionStatus(AutomationRuleConstants.SOURCE_ACTION_STATUS_SUCCESSFUL)
                .connector(AutomationRuleConstants.AUTOMATION_CONNECTOR_CUSTOM)
                .execution(AutomationRuleConstants.EXECUTION_IMMEDIATE)
                .customConnector(AutomationConnectorMock.class.getName())
                .persist();

            Exception expectedException;

            // Exercise
            Test.startTest();
            try {
                new ActivateAutomationRule(new Set<Id> {rule.Id}).execute();
            } catch(Exception ex) {
                expectedException = ex;
            }
            Test.stopTest();

            // Verify
            Automation_Rule__c resultRule = [SELECT Active__c FROM Automation_Rule__c WHERE Id = :rule.Id];
            System.assertEquals(false, resultRule.Active__c, 'Rule should not be active');
            System.assertNotEquals(null, expectedException, 'An exception should be thrown');
            System.assertEquals(Label.ContinuousDeliveryReservedKeyword, expectedException.getMessage(), 'Exception message does not match');
        }
    }

    @IsTest
    private static void activateRuleWithStandardConnectorAndContinuousDeliveryKeyword() {
        // Setup
        System.runAs(getUser()) {
            Automation_Rule__c rule = (Automation_Rule__c) new AutomationRule()
                .pipeline(new Pipeline())
                .sourceAction(ActionConstants.PROMOTION_DEPLOYMENT)
                .automatedAction(AutomationRuleConstants.CONTINUOUS_DELIVERY + ' - ' + ActionConstants.PROMOTION)
                .sourceActionStatus(AutomationRuleConstants.SOURCE_ACTION_STATUS_SUCCESSFUL)
                .connector(ACPromotionDeploymentToPromotion.class.getName())
                .execution(AutomationRuleConstants.EXECUTION_IMMEDIATE)
                .persist();

            // Exercise
            Test.startTest();
            new ActivateAutomationRule(new Set<Id> {rule.Id}).execute();
            Test.stopTest();

            // Verify
            Automation_Rule__c resultRule = [SELECT Active__c, Scheduled_Job_Id__c FROM Automation_Rule__c WHERE Id = :rule.Id];
            System.assertEquals(true, resultRule.Active__c, 'Rule should be activated');
        }
    }

    @IsTest
    private static void activateRuleWithDuplicatedRule() {
        // Setup
        System.runAs(getUser()) {

            Deployment_Flow__c pipeline = (Deployment_Flow__c) new Pipeline().persist();

            new AutomationRule()
                .active()
                .pipeline(pipeline.Id)
                .sourceAction(ActionConstants.PROMOTION_DEPLOYMENT)
                .sourceActionStatus(AutomationRuleConstants.SOURCE_ACTION_STATUS_SUCCESSFUL)
                .connector(AutomationRuleConstants.AUTOMATION_CONNECTOR_CUSTOM)
                .execution(AutomationRuleConstants.EXECUTION_IMMEDIATE)
                .customConnector(AutomationConnectorMock.class.getName());

            Automation_Rule__c rule = (Automation_Rule__c) new AutomationRule()
                .pipeline(pipeline.Id)
                .sourceAction(ActionConstants.PROMOTION_DEPLOYMENT)
                .sourceActionStatus(AutomationRuleConstants.SOURCE_ACTION_STATUS_SUCCESSFUL)
                .connector(AutomationRuleConstants.AUTOMATION_CONNECTOR_CUSTOM)
                .execution(AutomationRuleConstants.EXECUTION_IMMEDIATE)
                .customConnector(AutomationConnectorMock.class.getName())
                .persist();

            Exception expectedException;

            // Exercise
            Test.startTest();
            try {
                new ActivateAutomationRule(new Set<Id> {rule.Id}).execute();
            } catch(Exception ex) {
                expectedException = ex;
            }
            Test.stopTest();

            // Verify
            Automation_Rule__c resultRule = [SELECT Active__c FROM Automation_Rule__c WHERE Id = :rule.Id];
            System.assertEquals(false, resultRule.Active__c, 'Rule should not be active');
            System.assertNotEquals(null, expectedException, 'An exception should be thrown');
            System.assertEquals(Label.ActivatingAutomationDuplicatedError, expectedException.getMessage(), 'Exception message does not match');
        }
    }

    private static User getUser() {
        return [SELECT Id FROM User WHERE Profile.Name = 'Standard User' AND Alias = 'TestUsr2' ORDER BY CreatedDate DESC LIMIT 1];
    }

    private static User getUserWithoutPermissions() {
        return [SELECT Id FROM User WHERE Profile.Name = 'Standard User' AND Alias = 'TestUsr1' ORDER BY CreatedDate DESC LIMIT 1];
    }
}