public with sharing class SetOverridesPipelineAction {
    private List<Pipeline_Action__c> pipelineActions;

    // CTOR

    public SetOverridesPipelineAction(List<Pipeline_Action__c> pipelineActions) {
        this.pipelineActions = pipelineActions;
    }

    // PUBLIC
    public void execute() {
        Map<String, Pipeline_Action__c> pipelineActionByCombinations = getExistingCombinations();

        for (Pipeline_Action__c pipelineAction : pipelineActions) {
            if (!pipelineAction.Default__c) {
                String combination = pipelineActionCombination(pipelineAction);
                if (pipelineActionByCombinations.containsKey(combination)) {
                    Pipeline_Action__c existingPipelineAction = pipelineActionByCombinations.get(combination);
                    pipelineAction.Overrides_Pipeline_Action__c = existingPipelineAction.Id;
                }
            }
        }
    }

    private Map<String, Pipeline_Action__c> getExistingCombinations() {
        Map<String, Pipeline_Action__c> result = new Map<String, Pipeline_Action__c>();

        List<Pipeline_Action__c> existingPipelineActions = new PipelineActionsSelector()
            .forOverrides(actions(pipelineActions), pipelineIds(pipelineActions));

        for (Pipeline_Action__c existingPipelineAction : existingPipelineActions) {
            String combination = pipelineActionCombination(existingPipelineAction);
            result.put(combination, existingPipelineAction);
        }

        return result;
    }

    private String pipelineActionCombination(Pipeline_Action__c pipelineAction) {
        return String.valueOf(pipelineAction.Action__c) + String.valueOf(pipelineAction.Pipeline__c);
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
}