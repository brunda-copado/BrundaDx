public with sharing class PreventAlteringDefaultPipelineActions {
    private List<Pipeline_Action__c> pipelineActions;
    private Map<Id, SObject> old;

    // CTOR

    public PreventAlteringDefaultPipelineActions(List<Pipeline_Action__c> pipelineActions, Map<Id, SObject> old) {
        this.pipelineActions = pipelineActions;
        this.old = old;
    }

    // PUBLIC
    public void execute() {
        for (Pipeline_Action__c pipelineAction : pipelineActions) {
            if (pipelineAction.Default__c && !onlyTemplateHasChanged(pipelineAction)) {
                pipelineAction.addError(Label.DefaultPipelineActionsNotEditable);
            }
        }
    }

    private Boolean onlyTemplateHasChanged(Pipeline_Action__c pipelineAction) {
        Pipeline_Action__c oldRecord = (Pipeline_Action__c) old.get(pipelineAction.Id);
        return oldRecord.Action__c == pipelineAction.Action__c &&
            oldRecord.Platform__c == pipelineAction.Platform__c &&
            oldRecord.Pipeline__c == pipelineAction.Pipeline__c &&
            oldRecord.Environment__c == pipelineAction.Environment__c &&
            oldRecord.Job_Template__c != pipelineAction.Job_Template__c;
    }
}