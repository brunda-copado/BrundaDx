@SuppressWarnings('PMD.ExcessivePublicCount')
@IsTest
public with sharing class AutomationRule extends DomainBuilder {
    public AutomationRule() {
        super(Automation_Rule__c.SObjectType);
    }

    public AutomationRule name(String name) {
        return (AutomationRule) set(Automation_Rule__c.Name, name);
    }

    public AutomationRule active() {
        return (AutomationRule) set(Automation_Rule__c.Active__c, true);
    }

    public AutomationRule connector(String connector) {
        return (AutomationRule) set(Automation_Rule__c.Automation_Connector__c, connector);
    }

    public AutomationRule customConnector(String customConnector) {
        return (AutomationRule) set(Automation_Rule__c.Custom_Automation_Connector__c, customConnector);
    }

    public AutomationRule execution(String execution) {
        return (AutomationRule) set(Automation_Rule__c.Execution__c, execution);
    }

    public AutomationRule sourceAction(String sourceAction) {
        return (AutomationRule) set(Automation_Rule__c.Source_Action__c, sourceAction);
    }

    public AutomationRule sourceActionStatus(String status) {
        return (AutomationRule) set(Automation_Rule__c.Source_Action_Status__c, status);
    }

    public AutomationRule automatedAction(String automatedAction) {
        return (AutomationRule) set(Automation_Rule__c.Automated_Action__c, automatedAction);
    }

    public AutomationRule cronExpression(String cronExpression) {
        return (AutomationRule) set(Automation_Rule__c.Cron_Expression__c, cronExpression);
    }

    public AutomationRule lastExecutionDatetime(Datetime lastExecution) {
        return (AutomationRule) set(Automation_Rule__c.Last_Execution_Date_Time__c, lastExecution);
    }

    public AutomationRule filterCriteria(String filterCriteria) {
        return (AutomationRule) set(Automation_Rule__c.Filter_Criteria__c, filterCriteria);
    }

    public AutomationRule pipeline(Pipeline pipeline) {
        setParent(Automation_Rule__c.Pipeline__c, pipeline);
        return this;
    }

    public AutomationRule pipeline(Id pipeline) {
        set(Automation_Rule__c.Pipeline__c, pipeline);
        return this;
    }

    public AutomationRule environment(String environmentIds) {
        set(Automation_Rule__c.Environment__c, environmentIds);
        return this;
    }

    public AutomationRule stage(String stageIds) {
        set(Automation_Rule__c.Stage__c, stageIds);
        return this;
    }

    public AutomationRule excludedEnvironments(String environmentIds) {
        set(Automation_Rule__c.Excluded_Environments__c, environmentIds);
        return this;
    }

    public AutomationRule configJson(String json) {
        set(Automation_Rule__c.Config_Json__c, json);
        return this;
    }

    public AutomationRule qualityGateRuleCondition(String qualityGateRuleConditionId) {
        set(Automation_Rule__c.Quality_Gate_Rule_Condition__c, qualityGateRuleConditionId);
        return this;
    }

    public AutomationRule automatedActionCallback(String automatedActionCallback) {
        set(Automation_Rule__c.Automated_Action_Callback__c, automatedActionCallback);
        return this;
    }
}