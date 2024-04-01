@IsTest
private class DeactivateAutomationRuleTest {
    
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
    private static void deactivateRuleWithSchedule() {
        // Setup
        System.runAs(getUser()) {
            new AutomationRule()
                .pipeline(new Pipeline())
                .sourceAction(ActionConstants.PROMOTION_DEPLOYMENT)
                .automatedAction(ActionConstants.PROMOTION)
                .sourceActionStatus(AutomationRuleConstants.SOURCE_ACTION_STATUS_SUCCESSFUL)
                .connector(AutomationRuleConstants.AUTOMATION_CONNECTOR_CUSTOM)
                .execution(AutomationRuleConstants.EXECUTION_SCHEDULED)
                .customConnector(AutomationConnectorMock.class.getName())
                .cronExpression('0 15 * * * ?');
            new AutomationRule()
                .pipeline(new Pipeline())
                .sourceAction(ActionConstants.PROMOTION_DEPLOYMENT)
                .automatedAction(ActionConstants.PROMOTION)
                .sourceActionStatus(AutomationRuleConstants.SOURCE_ACTION_STATUS_SUCCESSFUL)
                .connector(AutomationRuleConstants.AUTOMATION_CONNECTOR_CUSTOM)
                .execution(AutomationRuleConstants.EXECUTION_SCHEDULED)
                .customConnector(AutomationConnectorMock.class.getName())
                .cronExpression('0 20 * * * ?')
                .persist();

            List<Automation_Rule__c> automationRules = [SELECT Id FROM Automation_Rule__c];
            Set<Id> automationRuleIds = new Map<Id, Automation_Rule__c>(automationRules).keySet();
            new ActivateAutomationRule(automationRuleIds).execute();

            List<Automation_Rule__c> activeRules = [SELECT Active__c, Scheduled_Job_Id__c FROM Automation_Rule__c WHERE Id IN :automationRuleIds];
            Set<Id> scheduledJobIds = new Set<Id>();
            for(Automation_Rule__c activeRule : activeRules) {
                System.assertEquals(true, activeRule.Active__c, 'Rule should be activated');
                scheduledJobIds.add(activeRule.Scheduled_Job_Id__c);
            }
            List<CronTrigger> scheduledJobs = [SELECT Id, CronExpression FROM CronTrigger WHERE Id IN :scheduledJobIds];
            System.assertEquals(2, scheduledJobs.size(), 'One job should be scheduled');

            // Exercise
            Test.startTest();
            new DeactivateAutomationRule(automationRuleIds).execute();
            Test.stopTest();

            // Verify
            List<Automation_Rule__c> resultRules = [SELECT Active__c, Scheduled_Job_Id__c FROM Automation_Rule__c WHERE Id IN :automationRuleIds];
            System.assertEquals(2, resultRules.size(), 'There should be 2 Automation Rules');
            for(Automation_Rule__c resultRule : resultRules) {
                System.assertEquals(false, resultRule.Active__c, 'Rule should be deactivated');
                System.assertEquals(null, resultRule.Scheduled_Job_Id__c, 'Scheduled Job Id should be null');
            }
            scheduledJobs = [SELECT Id, CronExpression FROM CronTrigger WHERE Id = :scheduledJobIds];
            System.assertEquals(0, scheduledJobs.size(), 'The scheduled job should be aborted');
        }
    }

    @IsTest
    private static void deactivateRuleWithoutPemissions() {
        // Setup
        Automation_Rule__c rule;
        System.runAs(getUser()) {
            rule = (Automation_Rule__c) new AutomationRule()
                .active()
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
                new DeactivateAutomationRule(new Set<Id> { rule.Id }).execute();
            } catch(Exception ex) {
                expectedException = ex;
            }
            Test.stopTest();

            // Verify
            Automation_Rule__c resultRule = [SELECT Active__c FROM Automation_Rule__c WHERE Id = :rule.Id];
            System.assertEquals(true, resultRule.Active__c, 'Rule should be active');
            System.assertNotEquals(null, expectedException, 'An exception should be thrown');
            System.assertEquals(Label.ActivatingAutomationPermissionsError, expectedException.getMessage(), 'Exception message does not match');
        }
    }

    private static User getUser() {
        return [SELECT Id FROM User WHERE Profile.Name = 'Standard User' AND Alias = 'TestUsr2' ORDER BY CreatedDate DESC LIMIT 1];
    }

    private static User getUserWithoutPermissions() {
        return [SELECT Id FROM User WHERE Profile.Name = 'Standard User' AND Alias = 'TestUsr1' ORDER BY CreatedDate DESC LIMIT 1];
    }

}