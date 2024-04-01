@SuppressWarnings('PMD.CyclomaticComplexity')
public with sharing class AutomationRuleMatcher {
    private List<Automation_Event__c> automationEvents;

    // CONSTRUCTOR

    public AutomationRuleMatcher(List<Automation_Event__c> automationEvents) {
        this.automationEvents = automationEvents;
    }

    // PUBLIC

    // NOTE: we have 3 levels of filtering
    // 1. Trigger (what action in pipeline triggered the rule)
    // 2. Behavior (if it's success/failed)
    // 3. Scope (what environment or stage is set)
    // In future, If any new matching criteria is added in this class, please make sure to update SubmitUserStoryService.match as well.
    public Map<Id, List<Automation_Event__c>> execute() {
        List<Automation_Rule__c> automationRules = selectAutomationRulesByTrigger(automationEvents);

        Map<Id, List<Automation_Rule__c>> automationRulesByAutomationEvent = new Map<Id, List<Automation_Rule__c>>();
        for (Automation_Event__c automationEvent : automationEvents) {
            List<Automation_Rule__c> matchingRules = new List<Automation_Rule__c>();
            for (Automation_Rule__c automationRule : automationRules) {
                if (matches(automationRule, automationEvent)) {
                    matchingRules.add(automationRule);
                }
            }
            automationRulesByAutomationEvent.put(automationEvent.Id, matchingRules);
        }

        Map<Id, List<Automation_Event__c>> automationEventsByRule = groupByRule(automationRulesByAutomationEvent);
        return automationEventsByRule;
    }

    // PRIVATE

    private List<Automation_Rule__c> selectAutomationRulesByTrigger(List<Automation_Event__c> automationEvents) {
        Set<Id> pipelineIds = new Set<Id>();
        Set<String> sourceActions = new Set<String>();
        for (Automation_Event__c automationEvent : automationEvents) {
            pipelineIds.add(automationEvent.Pipeline_Id__c);
            sourceActions.add(automationEvent.Action_Name__c);
        }
        List<Automation_Rule__c> result = new AutomationRulesSelector().byPipelineAndSourceAction(pipelineIds, sourceActions);
        return result;
    }

    private Map<Id, List<Automation_Event__c>> groupByRule(Map<Id, List<Automation_Rule__c>> automationRulesByAutomationEvent) {
        Map<Id, List<Automation_Event__c>> result = new Map<Id, List<Automation_Event__c>>();

        Map<Id, Automation_Event__c> automationEventById = new Map<Id, Automation_Event__c>(this.automationEvents);

        for (Id automationEventId : automationRulesByAutomationEvent.keySet()) {
            Automation_Event__c automationEvent = automationEventById.get(automationEventId);
            List<Automation_Rule__c> automationRules = automationRulesByAutomationEvent.get(automationEventId);
            for (Automation_Rule__c automationRule : automationRules) {
                Id automationRuleId = automationRule.Id;
                if (!result.containsKey(automationRuleId)) {
                    result.put(automationRuleId, new List<Automation_Event__c>());
                }
                result.get(automationRuleId).add(automationEvent);
            }
        }

        return result;
    }

    private Boolean matches(Automation_Rule__c automationRule, Automation_Event__c automationEvent) {
        return triggerMatches(automationRule, automationEvent) &&
            behaviorMatches(automationRule, automationEvent) &&
            scopeMatches(automationRule, automationEvent);
    }

    private Boolean triggerMatches(Automation_Rule__c automationRule, Automation_Event__c automationEvent) {
        return pipelineMatches(automationRule, automationEvent) && actionMatches(automationRule, automationEvent);
    }

    private Boolean behaviorMatches(Automation_Rule__c automationRule, Automation_Event__c automationEvent) {
        return statusMatches(automationRule, automationEvent);
    }

    private Boolean scopeMatches(Automation_Rule__c automationRule, Automation_Event__c automationEvent) {
        return scopeNotDefined(automationRule) ||
            environmentMatches(automationRule, automationEvent) ||
            stageMatches(automationRule, automationEvent);
    }

    private Boolean pipelineMatches(Automation_Rule__c automationRule, Automation_Event__c automationEvent) {
        return automationRule.Pipeline__c == automationEvent.Pipeline_Id__c;
    }

    private Boolean actionMatches(Automation_Rule__c automationRule, Automation_Event__c automationEvent) {
        return automationRule.Source_Action__c == automationEvent.Action_Name__c;
    }

    private Boolean statusMatches(Automation_Rule__c automationRule, Automation_Event__c automationEvent) {
        return automationRule.Source_Action_Status__c == automationEvent.Action_Status__c;
    }

    private Boolean scopeNotDefined(Automation_Rule__c automationRule) {
        return String.isBlank(automationRule.Stage__c) && String.isBlank(automationRule.Environment__c);
    }

    private Boolean environmentMatches(Automation_Rule__c automationRule, Automation_Event__c automationEvent) {
        return String.isNotBlank(automationEvent.Environment_Id__c) &&
            String.isNotBlank(automationRule.Environment__c) &&
            automationRule.Environment__c.containsIgnoreCase(automationEvent.Environment_Id__c);
    }

    private Boolean stageMatches(Automation_Rule__c automationRule, Automation_Event__c automationEvent) {
        return String.isNotBlank(automationEvent.Stage_Id__c) &&
            String.isNotBlank(automationRule.Stage__c) &&
            automationRule.Stage__c.containsIgnoreCase(automationEvent.Stage_Id__c) &&
            (String.isBlank(automationRule.Excluded_Environments__c) ||
            (String.isNotBlank(automationRule.Excluded_Environments__c) &&
            (String.isBlank(automationEvent.Environment_Id__c) ||
            (String.isNotBlank(automationEvent.Environment_Id__c) &&
            !automationRule.Excluded_Environments__c.containsIgnoreCase(automationEvent.Environment_Id__c)))));
    }
}