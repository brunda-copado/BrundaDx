public with sharing class PreventForbiddenPipelineActions {
    private static final Set<String> FORBIDDEN_ACTIONS = new Set<String>{ ActionConstants.SUBMIT_USER_STORIES };
    private List<Pipeline_Action__c> pipelineActions;
    private Map<Id, SObject> oldRecords;

    //CTOR
    public PreventForbiddenPipelineActions(List<Pipeline_Action__c> pipelineActions, Map<Id, sObject> oldRecords) {
        this.pipelineActions = pipelineActions;
        this.oldRecords = oldRecords;
    }

    // PUBLIC
    public void execute() {
        for (Pipeline_Action__c record : pipelineActions) {
            if (
                FORBIDDEN_ACTIONS.contains(record.Action__c) &&
                ((oldRecords != null && record.Action__c != ((Pipeline_Action__c) oldRecords.get(record.Id)).Action__c) || oldRecords == null)
            ) {
                record.addError(String.format(Label.Pipeline_Action_Forbidden_Action, new List<String>{ getPicklistLabel(record.Action__c) }));
            }
        }
    }

    //PRIVATE

    @SuppressWarnings('PMD.EagerlyLoadedDescribeSObjectResult')
    private String getPicklistLabel(String picklistValue) {
        String result;

        List<Schema.PicklistEntry> picklistEntries = Schema.Pipeline_Action__c.Action__c.getDescribe().getPicklistValues();

        for (Schema.PicklistEntry picklistEntry : picklistEntries) {
            if (picklistEntry.getValue() == picklistValue) {
                result = picklistEntry.getLabel();
                break;
            }
        }

        return result;
    }
}