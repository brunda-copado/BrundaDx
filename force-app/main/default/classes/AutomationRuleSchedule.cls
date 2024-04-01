public with sharing class AutomationRuleSchedule implements Schedulable, Database.Batchable<sObject>, Database.Stateful {
    private Id automationRuleId;
    private Id pipelineId;
    private Datetime lastExecution;
    private Datetime currentExecution;
    private Map<Id, List<Automation_Event__c>> matcherResult;

    // CONSTRUCTOR

    public AutomationRuleSchedule(Id automationRuleId) {
        this.automationRuleId = automationRuleId;
        // Note: needed in case we call the batch directly
        configure();
    }

    // PUBLIC

    public void execute(SchedulableContext context) {
        configure();
        DML.safeUpdate(
            new Automation_Rule__c(Id = automationRuleId, Last_Execution_Date_Time__c = currentExecution),
            'Could not update the Automation Rule object on the Automation Rule Schedule ( AutomationRuleSchedule.execute class )'
        );
        if(!Test.isRunningTest()) { Database.executeBatch(this); }
    }

    // PMD False positive, as WITH USER_MODE is not supported yet
    public Database.QueryLocator start(Database.BatchableContext context) {
        return Database.getQueryLocator(
            [
                SELECT Id, Action_Name__c, Action_Result__c, Action_Status__c, CreatedDate, Environment_Id__c, Pipeline_Id__c, Stage_Id__c, Payload__c
                FROM Automation_Event__c
                WHERE Pipeline_Id__c = :pipelineId AND CreatedDate > :lastExecution AND CreatedDate <= :currentExecution
                WITH USER_MODE
                ORDER BY Action_Name__c, Action_Status__c, Stage_Id__c, Environment_Id__c, CreatedDate
            ]
        );
    }

    public void execute(Database.BatchableContext context, List<sObject> scope) {
        List<Automation_Event__c> automationEvents = (List<Automation_Event__c>) scope;

        Map<Id, List<Automation_Event__c>> chunkMatcherResult = new AutomationRuleMatcher(automationEvents).execute();
        if (chunkMatcherResult.containsKey(automationRuleId)) {
            List<Automation_Event__c> matchingEvents = chunkMatcherResult.get(automationRuleId);
            matcherResult.get(automationRuleId).addAll(matchingEvents);
        }
    }

    public void finish(Database.BatchableContext context) {
        new AutomationEngine(matcherResult).execution(AutomationRuleConstants.EXECUTION_SCHEDULED).execute();
    }

    // PRIVATE

    private AutomationRuleSchedule configure() {
        Automation_Rule__c automationRule = new AutomationRulesSelector().byId(automationRuleId);
        this.pipelineId = automationRule.Pipeline__c;
        this.lastExecution = automationRule.Last_Execution_Date_Time__c;
        this.currentExecution = System.now();
        this.matcherResult = new Map<Id, List<Automation_Event__c>>{ automationRuleId => new List<Automation_Event__c>() };
        return this;
    }
}