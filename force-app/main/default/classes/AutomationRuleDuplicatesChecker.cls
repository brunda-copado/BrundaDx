@SuppressWarnings('PMD.CyclomaticComplexity')
public with sharing class AutomationRuleDuplicatesChecker {
    private List<Automation_Rule__c> automationRules;
    private Map<Id, PipelineDescriptor> pipelineDescriptorById;

    // CTOR

    public AutomationRuleDuplicatesChecker(List<Automation_Rule__c> automationRules) {
        this.automationRules = automationRules;
        this.pipelineDescriptorById = new Map<Id, PipelineDescriptor>();
    }

    // PUBLIC

    public List<Automation_Rule__c> execute() {
        List<Automation_Rule__c> result = new List<Automation_Rule__c>();

        List<Automation_Rule__c> existingRules = getExistingRules();
        for (Automation_Rule__c automationRule : automationRules) {
            for (Automation_Rule__c existingRule : existingRules) {
                if (automationRule.Id == existingRule.Id) {
                    continue;
                }
                if (matches(automationRule, existingRule)) {
                    result.add(existingRule);
                }
            }
        }

        return result;
    }

    // PRIVATE

    private List<Automation_Rule__c> getExistingRules() {
        Set<Id> pipelineIds = new Set<Id>();
        Set<String> sourceActions = new Set<String>();
        for (Automation_Rule__c automationRule : automationRules) {
            pipelineIds.add(automationRule.Pipeline__c);
            sourceActions.add(automationRule.Source_Action__c);
        }
        return new AutomationRulesSelector().byPipelineAndSourceAction(pipelineIds, sourceActions);
    }

    private Boolean matches(Automation_Rule__c automationRule1, Automation_Rule__c automationRule2) {
        return configurationMatches(automationRule1, automationRule2) &&
            scopeMatches(automationRule1, automationRule2);
    }

    private Boolean configurationMatches(Automation_Rule__c automationRule1, Automation_Rule__c automationRule2) {
        return automationRule1.Pipeline__c == automationRule2.Pipeline__c &&
            automationRule1.Source_Action__c == automationRule2.Source_Action__c &&
            automationRule1.Source_Action_Status__c == automationRule2.Source_Action_Status__c &&
            getConnector(automationRule1) == getConnector(automationRule2);
    }

    private Boolean scopeMatches(Automation_Rule__c automationRule1, Automation_Rule__c automationRule2) {
        Boolean result = true;

        ScopeMode scopeRule1 = getScopeMode(automationRule1);
        ScopeMode scopeRule2 = getScopeMode(automationRule2);

        if (scopeRule1 == ScopeMode.ENVIRONMENTS && scopeRule2 == ScopeMode.ENVIRONMENTS) {
            result = sameEnvironment(automationRule1, automationRule2);
        } else if (scopeRule1 == ScopeMode.ENVIRONMENTS && scopeRule2 == ScopeMode.STAGES) {
            result = environmentBelongsToStage(automationRule1, automationRule2);
        } else if (scopeRule1 == ScopeMode.STAGES && scopeRule2 == ScopeMode.ENVIRONMENTS) {
            result = environmentBelongsToStage(automationRule2, automationRule1);
        } else if (scopeRule1 == ScopeMode.STAGES && scopeRule2 == ScopeMode.STAGES) {
            result = sameStage(automationRule1, automationRule2) && excludedEnvironmentsAreNotMutuallyExclusive(automationRule1, automationRule2);
        }

        return result;
    }

    private Boolean sameEnvironment(Automation_Rule__c automationRule1, Automation_Rule__c automationRule2) {
        Set<String> intersection = new Set<String>(getEnvironments(automationRule1));
        intersection.retainAll(getEnvironments(automationRule2));
        return !intersection.isEmpty();
    }

    private Boolean environmentBelongsToStage(Automation_Rule__c automationRule1, Automation_Rule__c automationRule2) {
        Set<String> environmentsRule1 = getEnvironments(automationRule1);
        Set<String> stagesRule2 = getStages(automationRule2);
        Set<String> excludedEnvironmentsRule2 = getExcludedEnvironments(automationRule2);

        // Note: at this point we know the pipeline is the same for both rules because the configuration fields matched
        PipelineDescriptor pipelineDescriptor = getPipelineDescriptor(automationRule1);

        Boolean environmentRule1BelongsToStageRule2 = false;
        for (String environmentId : environmentsRule1) {
            String stageId = pipelineDescriptor.getStageId(environmentId);
            if (stagesRule2.contains(stageId) && !excludedEnvironmentsRule2.contains(environmentId)) {
                environmentRule1BelongsToStageRule2 = true;
                break;
            }
        }

        return environmentRule1BelongsToStageRule2;
    }

    private Boolean sameStage(Automation_Rule__c automationRule1, Automation_Rule__c automationRule2) {
        Set<String> intersection = new Set<String>(getStages(automationRule1));
        intersection.retainAll(getStages(automationRule2));
        return !intersection.isEmpty();
    }

    private Boolean excludedEnvironmentsAreNotMutuallyExclusive(Automation_Rule__c automationRule1, Automation_Rule__c automationRule2) {
        // Note: at this point we know both rules work on the same stage because sameStage method was called previously
        Set<String> stagesRule1 = getStages(automationRule1);
        Set<String> stagesRule2 = getStages(automationRule2);
        Set<String> excludedEnvironmentsRule1 = getExcludedEnvironments(automationRule1);
        Set<String> excludedEnvironmentsRule2 = getExcludedEnvironments(automationRule2);

        // Note: at this point we know the pipeline is the same for both rules because the configuration fields matched
        PipelineDescriptor pipelineDescriptor = getPipelineDescriptor(automationRule1);
        Map<Id, PipelineDescriptor.Stage> stagesById = pipelineDescriptor.stages();

        Boolean result = false;
        for (String stage1 : stagesRule1) {
            if (stagesRule2.contains(stage1) && stagesById.containsKey(stage1)) {
                PipelineDescriptor.Stage stageDescriptor = stagesById.get(stage1);
                Set<String> stageEnvironments = new Set<String>(String.join(new List<Id>(stageDescriptor.environmentsById.keySet()), ',').split(','));
                Set<String> missingEnvironments = new Set<String>(stageEnvironments);
                missingEnvironments.removeAll(excludedEnvironmentsRule1);
                Boolean mutuallyExclusive = excludedEnvironmentsRule2.containsAll(missingEnvironments);
                if (!mutuallyExclusive) {
                    result = true;
                    break;
                }
            }
        }

        return result;
    }

    private Set<String> getEnvironments(Automation_Rule__c automationRule) {
        return String.isNotBlank(automationRule.Environment__c) ? new Set<String>(automationRule.Environment__c.split(',')) : new Set<String>();
    }

    private Set<String> getStages(Automation_Rule__c automationRule) {
        return String.isNotBlank(automationRule.Stage__c) ? new Set<String>(automationRule.Stage__c.split(',')) : new Set<String>();
    }

    private Set<String> getExcludedEnvironments(Automation_Rule__c automationRule) {
        return String.isNotBlank(automationRule.Excluded_Environments__c)
            ? new Set<String>(automationRule.Excluded_Environments__c.split(','))
            : new Set<String>();
    }

    private String getConnector(Automation_Rule__c automationRule) {
        return automationRule.Automation_Connector__c == AutomationRuleConstants.AUTOMATION_CONNECTOR_CUSTOM
            ? automationRule.Custom_Automation_Connector__c
            : automationRule.Automation_Connector__c;
    }

    private PipelineDescriptor getPipelineDescriptor(Automation_Rule__c automationRule) {
        Id pipelineId = automationRule.Pipeline__c;
        if (!pipelineDescriptorById.containsKey(pipelineId)) {
            pipelineDescriptorById.put(pipelineId, new PipelineDescriptor(pipelineId));
        }
        return pipelineDescriptorById.get(pipelineId);
    }

    private ScopeMode getScopeMode(Automation_Rule__c automationRule) {
        Set<String> environments = getEnvironments(automationRule);
        Set<String> stages = getStages(automationRule);

        if (!environments.isEmpty()) {
            return ScopeMode.ENVIRONMENTS;
        }
        if (!stages.isEmpty()) {
            return ScopeMode.STAGES;
        }
        return ScopeMode.NO_SCOPE;
    }

    private enum ScopeMode {
        NO_SCOPE,
        ENVIRONMENTS,
        STAGES
    }

    private with sharing class FilterCriteria {
        private String mainObject;
        private String whereCondition;
    }
}