public inherited sharing class AutomationRulesSelector extends fflib_SObjectSelector {
    // CTOR

    public AutomationRulesSelector() {
        this(true, true);
    }

    public AutomationRulesSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(false, enforceCRUD, enforceFLS, false);
    }

    // PUBLIC

    public SObjectType getSObjectType() {
        return Automation_Rule__c.sObjectType;
    }

    public List<SObjectField> getSObjectFieldList() {
        return new List<SObjectField>{
            Automation_Rule__c.Id,
            Automation_Rule__c.Name,
            Automation_Rule__c.Automated_Action__c,
            Automation_Rule__c.Automated_Action_Callback__c,
            Automation_Rule__c.Automation_Connector__c,
            Automation_Rule__c.Cron_Expression__c,
            Automation_Rule__c.Custom_Automation_Connector__c,
            Automation_Rule__c.Environment__c,
            Automation_Rule__c.Execution__c,
            Automation_Rule__c.Excluded_Environments__c,
            Automation_Rule__c.Last_Execution_Date_Time__c,
            Automation_Rule__c.Pipeline__c,
            Automation_Rule__c.Scheduled_Job_Id__c,
            Automation_Rule__c.Source_Action__c,
            Automation_Rule__c.Source_Action_Status__c,
            Automation_Rule__c.Stage__c,
            Automation_Rule__c.Filter_Criteria__c,
            Automation_Rule__c.Config_Json__c
        };
    }

    public Automation_Rule__c byId(Id recordId) {
        List<Automation_Rule__c> result = byIds(new Set<Id>{ recordId });
        return result.isEmpty() ? null : result[0];
    }

    public List<Automation_Rule__c> byIds(Set<Id> recordIds) {
        return (List<Automation_Rule__c>) selectSObjectsById(recordIds);
    }

    public List<Automation_Rule__c> byPipelineAndSourceAction(Set<Id> pipelines, Set<String> sourceActions) {
        return Database.query(
            newQueryFactory().setCondition('Pipeline__c IN :pipelines AND Source_Action__c IN :sourceActions AND Active__c = true').toSOQL()
        );
    }
}