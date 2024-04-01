@SuppressWarnings('PMD.AvoidGlobalModifier')
global with sharing class AutomationEventCleaner implements Schedulable, Database.Batchable<sObject> {
    // GLOBAL

    global void execute(SchedulableContext context) {
        if (!Schema.sObjectType.Automation_Event__c.isDeletable()) {
            return;
        }
        Database.executeBatch(new AutomationEventCleaner());
    }

    global Database.QueryLocator start(Database.BatchableContext context) {
        // Note: just to make sure we don't delete any events that are currently being processed, let's leave a one-day margin
        return Database.getQueryLocator(
            [
                SELECT Id, Action_Name__c, Action_Status__c, CreatedDate, Environment_Id__c, Pipeline_Id__c, Stage_Id__c
                FROM Automation_Event__c
                WHERE CreatedDate <= :Datetime.now().addDays(-1)
                WITH SECURITY_ENFORCED
                ORDER BY Action_Name__c, Action_Status__c, Stage_Id__c, Environment_Id__c, CreatedDate
            ]
        );
    }

    global void execute(Database.BatchableContext context, List<sObject> scope) {
        if (!Schema.sObjectType.Automation_Event__c.isDeletable()) {
            return;
        }
        List<Automation_Event__c> automationEvents = (List<Automation_Event__c>) scope;

        Map<Id, List<Automation_Event__c>> automationEventsByRuleId = new AutomationRuleMatcher(automationEvents).execute();

        Set<Id> nonDeletableEvents = getNonDeletableEvents(automationEventsByRuleId);

        List<Automation_Event__c> automationEventsToDelete = new List<Automation_Event__c>();
        for (Automation_Event__c automationEvent : automationEvents) {
            if (!nonDeletableEvents.contains(automationEvent.Id)) {
                automationEventsToDelete.add(automationEvent);
            }
        }
        Utilities.Secure_DML(automationEventsToDelete, Utilities.DML_Action.DEL, schema.SObjectType.Automation_Event__c);
    }

    global void finish(Database.BatchableContext context) {
    }

    // PRIVATE

    private Set<Id> getNonDeletableEvents(Map<Id, List<Automation_Event__c>> automationEventsByRuleId) {
        Set<Id> result = new Set<Id>();

        Map<Id, Automation_Rule__c> automationRuleById = new Map<Id, Automation_Rule__c>(
            new AutomationRulesSelector().byIds(automationEventsByRuleId.keySet())
        );

        for (Id automationRuleId : automationEventsByRuleId.keySet()) {
            Automation_Rule__c automationRule = automationRuleById.get(automationRuleId);
            List<Automation_Event__c> automationEvents = automationEventsByRuleId.get(automationRuleId);
            result.addAll(getNonDeletableEvents(automationRule, automationEvents));
        }

        return result;
    }

    private Set<Id> getNonDeletableEvents(Automation_Rule__c automationRule, List<Automation_Event__c> automationEvents) {
        Set<Id> result = new Set<Id>();

        String execution = automationRule.Execution__c;
        Datetime lastExecutionDate = automationRule.Last_Execution_Date_Time__c;

        for (Automation_Event__c automationEvent : automationEvents) {
            // Note: as we discarded events from the last day in the query, we can assume all the events for an Immediate rule can be deleted
            if (execution == AutomationRuleConstants.EXECUTION_SCHEDULED && automationEvent.CreatedDate >= lastExecutionDate) {
                result.add(automationEvent.Id);
            }
        }

        return result;
    }
}