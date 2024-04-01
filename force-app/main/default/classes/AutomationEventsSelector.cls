public inherited sharing class AutomationEventsSelector extends fflib_SObjectSelector {
    // CTOR

    public AutomationEventsSelector() {
        this(true, true);
    }

    public AutomationEventsSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(false, enforceCRUD, enforceFLS, false);
    }

    // PUBLIC

    public SObjectType getSObjectType() {
        return Automation_Event__c.sObjectType;
    }

    public List<SObjectField> getSObjectFieldList() {
        return new List<SObjectField>{
            Automation_Event__c.Id,
            Automation_Event__c.Action_Name__c,
            Automation_Event__c.Action_Result__c,
            Automation_Event__c.Action_Status__c,
            Automation_Event__c.Environment_Id__c,
            Automation_Event__c.Job_Execution_Id__c,
            Automation_Event__c.Log__c,
            Automation_Event__c.Pipeline_Id__c,
            Automation_Event__c.Stage_Id__c,
            Automation_Event__c.Target_Action_Job_Execution_Ids__c,
            Automation_Event__c.Target_Action_Number__c,
            Automation_Event__c.Payload__c
        };
    }

    public List<Automation_Event__c> byId(Set<Id> recordIds) {
        return (List<Automation_Event__c>) selectSObjectsById(recordIds);
    }

    public Automation_Event__c byId(Id recordId) {
        List<Automation_Event__c> result = byId(new Set<Id>{ recordId });
        return result.isEmpty() ? null : result[0];
    }

}