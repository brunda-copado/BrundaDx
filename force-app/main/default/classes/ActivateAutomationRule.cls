public with sharing class ActivateAutomationRule {

    private List<Automation_Rule__c> automationRules;
    private Map<String, Schema.SObjectField> automationRuleFieldMap;

    public ActivateAutomationRule(Set<Id> automationRuleIds) {
        this.automationRules = new AutomationRulesSelector().byIds(automationRuleIds);
        this.automationRuleFieldMap = Automation_Rule__c.SObjectType.getDescribe().fields.getMap();
    }
    
    @SuppressWarnings('PMD.OperationWithLimitsInLoop')
    public void execute() {
        checkPermissions();
        checkContinuousDelivery();
        checkDuplicatedRules();

        List<Automation_Rule__c> automationRulesToUpdate = new List<Automation_Rule__c>();
        
        for(Automation_Rule__c automationRule : automationRules) {
            List<String> missingFields = getMissingFields(automationRule);

            if(!missingFields.isEmpty()) {
                throw new ApplicationException(String.format(Label.ActivatingAutomationBodyErrorMessage, new List<String> {String.join(missingFields, ', ')}));
            }

            Automation_Rule__c automationRuleToUpdate = new Automation_Rule__c(Id = automationRule.Id, Active__c = true);
            if(automationRule.Execution__c == AutomationRuleConstants.EXECUTION_SCHEDULED) {
                AutomationRuleSchedule ruleSchedule = new AutomationRuleSchedule(automationRule.Id);
                // OperationWithLimitsInLoop - We are scheduling a proccess for every Automation Rule configured as Scheduled.
                // TODO - We need to document it properly or put a limit for the number of Scheduled Rules that can be activated.
                String jobID;
                try {
                    jobID = System.schedule(automationRule.Name + '_' + Datetime.now(), automationRule.Cron_Expression__c, ruleSchedule);
                } catch(Exception ex) {
                    throw new ApplicationException(Label.ActivatingAutomationScheduledError);
                }
                automationRuleToUpdate.Scheduled_Job_Id__c = jobID;
                automationRuleToUpdate.Last_Execution_Date_Time__c = System.now();
            }
            automationRulesToUpdate.add(automationRuleToUpdate);
        }
        DML.safeUpdate(
            automationRulesToUpdate,
            'Could not update the Automation Rule Status during the Activation ( ActivateAutomationRule.execute class )'
        );
    }

    // PRIVATE

    private List<String> getMissingFields(Automation_Rule__c automationRule) {
        List<String> result = new List<String>();

        Set<String> requiredFields = new Set<String> {
            Automation_Rule__c.Source_Action__c.getDescribe().getName(),
            Automation_Rule__c.Source_Action_Status__c.getDescribe().getName(),
            Automation_Rule__c.Automation_Connector__c.getDescribe().getName(),
            Automation_Rule__c.Execution__c.getDescribe().getName()
        };
        if(automationRule.Automation_Connector__c == AutomationRuleConstants.AUTOMATION_CONNECTOR_CUSTOM) {
            requiredFields.add(Automation_Rule__c.Custom_Automation_Connector__c.getDescribe().getName());
        }
        if(automationRule.Execution__c == AutomationRuleConstants.EXECUTION_SCHEDULED) {
            requiredFields.add(Automation_Rule__c.Cron_Expression__c.getDescribe().getName());
        }

        for(String field : requiredFields) {
            if(String.isBlank((String) automationRule.get(field))) {
                result.add(automationRuleFieldMap.get(field).getDescribe().getLabel());
            }
        }

        return result;
    }

    private void checkPermissions() {
        Boolean objectAccess = Schema.sObjectType.Automation_Rule__c.isUpdateable();
        Boolean fieldAccess = Schema.sObjectType.Automation_Rule__c.fields.Active__c.isUpdateable();
        if(!objectAccess || !fieldAccess) {
            throw new ApplicationException(Label.ActivatingAutomationPermissionsError);
        }
    }

    private void checkContinuousDelivery() {
        for(Automation_Rule__c automationRule : automationRules) {
            if(automationRule.Automation_Connector__c == AutomationRuleConstants.AUTOMATION_CONNECTOR_CUSTOM &&
                String.isNotBlank(automationRule.Automated_Action__c) &&
                automationRule.Automated_Action__c.contains(AutomationRuleConstants.CONTINUOUS_DELIVERY)
            ) {
                throw new ApplicationException(Label.ContinuousDeliveryReservedKeyword);
            }
        }
    }

    private void checkDuplicatedRules() {
        List<Automation_Rule__c> duplicatedRules = new AutomationRuleDuplicatesChecker(automationRules).execute();
        if(!duplicatedRules.isEmpty()) {
            throw new ApplicationException(Label.ActivatingAutomationDuplicatedError);
        }
    }
}