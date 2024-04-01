public with sharing class CheckDuplicatedPipelineActions {
    private List<Pipeline_Action__c> pipelineActions;

    // CTOR

    public CheckDuplicatedPipelineActions(List<Pipeline_Action__c> pipelineActions) {
        this.pipelineActions = pipelineActions;
    }

    // PUBLIC

    public void execute() {
        Map<String, Id> combinations = getExistingCombinations();

        for (Pipeline_Action__c pipelineAction : pipelineActions) {
            String combination = pipelineActionCombination(pipelineAction);
            if (combinations.containsKey(combination) && pipelineAction.Id != combinations.get(combination)) {
                pipelineAction.addError(Label.DuplicatedPipelineAction);
            }
            combinations.put(combination, pipelineAction.Id);
        }
    }

    private Map<String, Id> getExistingCombinations() {
        Map<String, Id> result = new Map<String, Id>();

        List<Pipeline_Action__c> existingPipelineActions = new PipelineActionsSelector()
            .forDuplicates(actions(pipelineActions), pipelineIds(pipelineActions), environmentIds(pipelineActions));

        for (Pipeline_Action__c existingPipelineAction : existingPipelineActions) {
            String combination = pipelineActionCombination(existingPipelineAction);
            result.put(combination, existingPipelineAction.Id);
        }

        return result;
    }

    private String pipelineActionCombination(Pipeline_Action__c pipelineAction) {
        return String.valueOf(pipelineAction.Action__c) +
            String.valueOf(pipelineAction.Pipeline__c) +
            (!pipelineAction.Default__c ? String.valueOf(pipelineAction.Environment__c) : '');
    }

    private Set<String> actions(List<Pipeline_Action__c> pipelineActions) {
        Set<String> result = new Set<String>();
        for (Pipeline_Action__c pipelineAction : pipelineActions) {
            result.add(pipelineAction.Action__c);
        }
        return result;
    }

    private Set<Id> pipelineIds(List<Pipeline_Action__c> pipelineActions) {
        Set<Id> result = new Set<Id>();
        for (Pipeline_Action__c pipelineAction : pipelineActions) {
            result.add(pipelineAction.Pipeline__c);
        }
        return result;
    }

    private Set<Id> environmentIds(List<Pipeline_Action__c> pipelineActions) {
        Set<Id> result = new Set<Id>();
        for (Pipeline_Action__c pipelineAction : pipelineActions) {
            Id environmentId = pipelineAction.Environment__c;
            if (String.isNotBlank(environmentId)) {
                result.add(environmentId);
            }
        }
        return result;
    }
}