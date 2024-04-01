public with sharing class QualityAutomationEngine {
    Map<Id, Quality_Gate_Rule__c> ruleIdsToCreateAutomations;
    Set<Id> ruleIdsToDeleteAutomations;

    public QualityAutomationEngine(Map<Id, Quality_Gate_Rule__c> ruleIdsToCreateAutomations, Set<Id> ruleIdsToDeleteAutomations) {
        this.ruleIdsToCreateAutomations = ruleIdsToCreateAutomations;
        this.ruleIdsToDeleteAutomations = ruleIdsToDeleteAutomations;
    }

    public void execute() {
        Set<Id> ruleIds = new Set<Id>();

        ruleIds.addAll(ruleIdsToCreateAutomations.keyset());
        ruleIds.addAll(ruleIdsToDeleteAutomations);

        Map<Id, List<Quality_Gate_Rule_Condition__c>> conditionsByRuleId = conditionsByRuleId(ruleIds);
        if (!ruleIdsToCreateAutomations.isEmpty()) {
            createAutomations(ruleIdsToCreateAutomations, conditionsByRuleId);
        }

        if (!ruleIdsToDeleteAutomations.isEmpty()) {
            deleteAutomations(ruleIdsToDeleteAutomations, conditionsByRuleId);
        }
    }

    // PRIVATE

    private void createAutomations(Map<Id, Quality_Gate_Rule__c> rules, Map<Id, List<Quality_Gate_Rule_Condition__c>> conditionsByRuleId) {
        List<Automation_Rule__c> automationRulesToInsert = new List<Automation_Rule__c>();
        Map<String, List<String>> pipelineIdsByConditionId = pipelinesByConditionId(rules.keyset(), conditionsByRuleId);

        for (Quality_Gate_Rule__c rule : rules.values()) {
            for (Quality_Gate_Rule_Condition__c condition : conditionsByRuleId.get(rule.Id)) {
                for (String action : rule.Actions__c.split(';')) {
                    automationRulesToInsert.addAll(createAutomationRules(action, condition, pipelineIdsByConditionId.get(condition.Id)));
                }
            }
        }

        if (!automationRulesToInsert.isEmpty()) {
            DML.safeInsert(
                automationRulesToInsert,
                String.format(
                    Label.ErrorWhileInserting,
                    new List<String>{
                        Automation_Rule__c.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).getLabel(),
                        'QualityAutomationEngine.createAutomations'
                    }
                )
            );
        }
    }

    private Map<String, List<String>> pipelinesByConditionId(Set<Id> ruleIds, Map<Id, List<Quality_Gate_Rule_Condition__c>> conditionsByRuleId) {
        Map<String, List<String>> result = new Map<String, List<String>>();
        for (Id ruleId : ruleIds) {
            for (Quality_Gate_Rule_Condition__c condition : conditionsByRuleId.get(ruleId)) {
                result.put(
                    condition.Id,
                    condition.Pipeline__c != null ? new List<String>{ condition.Pipeline__c } : pipelineIds(condition.platform__c)
                );
            }
        }
        return result;
    }

    private void deleteAutomations(Set<Id> ruleIds, Map<Id, List<Quality_Gate_Rule_Condition__c>> conditionsByRuleId) {
        Map<Id, Map<Id, List<ConditionAutomation>>> automationRuleByConditionId = automationRulesByConditionId(ruleIds);
        List<Automation_Rule__c> automationRulesToUpdate = new List<Automation_Rule__c>();
        for (Id ruleId : ruleIds) {
            for (Quality_Gate_Rule_Condition__c condition : conditionsByRuleId.get(ruleId)) {
                Map<Id, List<ConditionAutomation>> automationsByPipelineId = automationRuleByConditionId.get(condition.Id);
                if (automationsByPipelineId != null) {
                    deactivateAutomations(automationsByPipelineId, automationRulesToUpdate);
                }
            }
        }

        if (!automationRulesToUpdate.isEmpty()) {
            DML.safeUpdate(
                automationRulesToUpdate,
                String.format(
                    Label.ErrorWhileUpdating,
                    new List<String>{
                        Automation_Rule__c.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).getLabel(),
                        'QualityAutomationEngine.deleteAutomations'
                    }
                )
            );
            DML.safeDelete(
                automationRulesToUpdate,
                String.format(
                    Label.ErrorWhileDeleting,
                    new List<String>{
                        Automation_Rule__c.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).getLabel(),
                        'QualityAutomationEngine.deleteAutomations'
                    }
                )
            );
        }
    }

    private void deactivateAutomations(Map<Id, List<ConditionAutomation>> automationsByPipelineId, List<Automation_Rule__c> automationRulesToUpdate) {
        for (Id pipelineId : automationsByPipelineId.keyset()) {
            for (ConditionAutomation conditionAutomation : automationsByPipelineId.get(pipelineId)) {
                for (Automation_Rule__c automationRule : conditionAutomation.automationRuleByAction.values()) {
                    automationRulesToUpdate.add(new Automation_Rule__c(Id = automationRule.Id, Active__c = false));
                }
            }
        }
    }

    private List<Automation_Rule__c> createAutomationRules(String action, Quality_Gate_Rule_Condition__c condition, List<String> pipelineIds) {
        List<Automation_Rule__c> automationRules = new List<Automation_Rule__c>();

        for (String pipelineId : pipelineIds) {
            Automation_Rule__c automationRule = new Automation_Rule__c();
            automationRule.Name = condition.Quality_Gate_Rule__r.Name + ' - ' + condition.Quality_Gate_Rule__r.Tool__c;
            automationRule.Pipeline__c = pipelineId;
            automationRule.Quality_Gate_Rule_Condition__c = condition.Id;
            automationRule.Source_Action__c = action;
            automationRule.Automated_Action__c = Label.Execute_Quality_Gate;
            automationRule.Automation_Connector__c = QualityAutomationConstants.QUALITY_CONNECTOR_BY_ACTION.get(action);
            automationRule.Source_Action_Status__c = AutomationRuleConstants.SOURCE_ACTION_STATUS_SUCCESSFUL;
            automationRule.Execution__c = AutomationRuleConstants.EXECUTION_IMMEDIATE;
            automationRule.Active__c = true;
            automationRules.add(automationRule);
        }
        return automationRules;
    }

    // PMD False positive, as WITH USER_MODE is not supported yet
    private List<String> pipelineIds(String platform) {
        List<String> result = new List<String>();
        for (Deployment_Flow__c pipeline : [SELECT Id FROM Deployment_Flow__c WHERE Platform__c = :platform AND Active__c = TRUE WITH USER_MODE]) {
            result.add(pipeline.Id);
        }
        return result;
    }

    private Map<Id, List<Quality_Gate_Rule_Condition__c>> conditionsByRuleId(Set<Id> qualityGateRuleIds) {
        return new QualityGateRuleConditionsSelector().byQualityGateRule(qualityGateRuleIds);
    }

    private class ConditionAutomation {
        private String conditionId;
        private String pipelineId;
        private Map<String, Automation_Rule__c> automationRuleByAction;

        private ConditionAutomation conditionId(String conditionId) {
            this.conditionId = conditionId;
            return this;
        }

        private ConditionAutomation pipelineId(String pipelineId) {
            this.pipelineId = pipelineId;
            return this;
        }
    }

    // PMD False positive, as WITH USER_MODE is not supported yet
    private Map<Id, Map<Id, List<ConditionAutomation>>> automationRulesByConditionId(Set<Id> qualityGateRuleIds) {
        Map<Id, Map<Id, List<ConditionAutomation>>> result = new Map<Id, Map<Id, List<ConditionAutomation>>>();

        for (Automation_Rule__c automationRule : [
            SELECT Id, Active__c, Pipeline__c, Source_Action__c, Quality_Gate_Rule_Condition__c
            FROM Automation_Rule__c
            WHERE Quality_Gate_Rule_Condition__r.Quality_Gate_Rule__c IN :qualityGateRuleIds AND Pipeline__r.Active__c = TRUE
            WITH USER_MODE
        ]) {
            if (!result.containsKey(automationRule.Quality_Gate_Rule_Condition__c)) {
                result.put(automationRule.Quality_Gate_Rule_Condition__c, new Map<Id, List<ConditionAutomation>>());
            }

            Map<Id, List<ConditionAutomation>> automationsByPipelineId = result.get(automationRule.Quality_Gate_Rule_Condition__c);
            if (!automationsByPipelineId.containsKey(automationRule.Pipeline__c)) {
                automationsByPipelineId.put(automationRule.Pipeline__c, new List<ConditionAutomation>{ createConditionAutomation(automationRule) });
            }

            for (ConditionAutomation conditionAutomation : automationsByPipelineId.get(automationRule.Pipeline__c)) {
                if (conditionAutomation.pipelineId == automationRule.Pipeline__c) {
                    conditionAutomation.automationRuleByAction.put(automationRule.Source_Action__c, automationRule);
                }
            }
        }
        return result;
    }

    private ConditionAutomation createConditionAutomation(Automation_Rule__c automationRule) {
        ConditionAutomation result = new ConditionAutomation()
            .conditionId(automationRule.Quality_Gate_Rule_Condition__c)
            .pipelineId(automationRule.Pipeline__c);
        result.automationRuleByAction = new Map<String, Automation_Rule__c>();
        return result;
    }
}