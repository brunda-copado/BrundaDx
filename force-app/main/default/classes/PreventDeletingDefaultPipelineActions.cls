public with sharing class PreventDeletingDefaultPipelineActions {
    private List<Pipeline_Action__c> pipelineActions;

    // CTOR

    public PreventDeletingDefaultPipelineActions(List<Pipeline_Action__c> pipelineActions) {
        this.pipelineActions = pipelineActions;
    }

    // PUBLIC
    public void execute() {
        for (Pipeline_Action__c pipelineAction : pipelineActions) {
            if (pipelineAction.Default__c) {
                pipelineAction.addError(Label.DefaultPipelineActionsNotEditable);
            }
        }
    }
}