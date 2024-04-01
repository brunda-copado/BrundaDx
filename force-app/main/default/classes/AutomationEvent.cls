@IsTest
public with sharing class AutomationEvent extends DomainBuilder {
    public AutomationEvent() {
        super(Automation_Event__c.SObjectType);
    }

    public AutomationEvent name(String name) {
        return (AutomationEvent) set(Automation_Event__c.Name, name);
    }

    public AutomationEvent actionName(String actionName) {
        return (AutomationEvent) set(Automation_Event__c.Action_Name__c, actionName);
    }

    public AutomationEvent actionResult(String actionResult) {
        return (AutomationEvent) set(Automation_Event__c.Action_Result__c, actionResult);
    }

    public AutomationEvent actionStatus(String actionStatus) {
        return (AutomationEvent) set(Automation_Event__c.Action_Status__c, actionStatus);
    }

    public AutomationEvent environmentId(String environmentId) {
        return (AutomationEvent) set(Automation_Event__c.Environment_Id__c, environmentId);
    }

    public AutomationEvent pipelineId(String pipelineId) {
        return (AutomationEvent) set(Automation_Event__c.Pipeline_Id__c, pipelineId);
    }

    public AutomationEvent stageId(String stageId) {
        return (AutomationEvent) set(Automation_Event__c.Stage_Id__c, stageId);
    }

    public AutomationEvent payload(String payload) {
        return (AutomationEvent) set(Automation_Event__c.Payload__c, payload);
    }
}