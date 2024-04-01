public with sharing class DeactivateAutomationRule {

    List<Automation_Rule__c> automationRules;

    public DeactivateAutomationRule(Set<Id> automationRuleIds) {
        this.automationRules = new AutomationRulesSelector().byIds(automationRuleIds);
    }
    
    public void execute() {
        checkPermissions();

        List<Automation_Rule__c> automationRulesToUpdate = new List<Automation_Rule__c>();
        Set<Id> scheduleJobIds = new Set<Id>();
        
        for(Automation_Rule__c automationRule : automationRules) {
            Automation_Rule__c automationRuleToUpdate = new Automation_Rule__c(Id = automationRule.Id, Active__c = false);
            if(automationRule.Execution__c == AutomationRuleConstants.EXECUTION_SCHEDULED) {
                scheduleJobIds.add(automationRule.Scheduled_Job_Id__c);
                automationRuleToUpdate.Scheduled_Job_Id__c = null;
                automationRuleToUpdate.Last_Execution_Date_Time__c = null;
            }
            automationRulesToUpdate.add(automationRuleToUpdate);
        }

        abortScheduledJobs(scheduleJobIds);

        DML.safeUpdate(
            automationRulesToUpdate,
            'Could not update the Automation Rule Status during the Deactivation ( DeactivateAutomationRule.execute class )'
        );
    }

    // PRIVATE

    @SuppressWarnings('PMD.ApexCRUDViolation')
    private void abortScheduledJobs(Set<Id> scheduledJobIds) {
        List<CronTrigger> scheduledJobs = [SELECT Id FROM CronTrigger WHERE Id IN :scheduledJobIds];
        for(CronTrigger scheduledJob : scheduledJobs) {
            System.abortJob(scheduledJob.Id);
        }
    }

    private void checkPermissions() {
        Boolean objectAccess = Schema.sObjectType.Automation_Rule__c.isUpdateable();
        Boolean fieldAccess = Schema.sObjectType.Automation_Rule__c.fields.Active__c.isUpdateable();
        if(!objectAccess || !fieldAccess) {
            throw new ApplicationException(Label.ActivatingAutomationPermissionsError);
        }
    }
}