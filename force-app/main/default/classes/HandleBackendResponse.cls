public with sharing class HandleBackendResponse {
    private List<MC_Result__e> records;

    // CONSTRUCTOR

    public HandleBackendResponse(List<MC_Result__e> records) {
        this.records = records;
    }

    @SuppressWarnings('PMD.EmptyStatementBlock')
    public HandleBackendResponse() {
    }

    // PUBLIC
    @SuppressWarnings('PMD.ApexCRUDViolation')
    public void execute() {
        Map<Id, Result__c> resultsToUpdate = new Map<Id, Result__c>();

        Set<Id> eventResultIds = new Set<Id>();
        for (MC_Result__e event : records) {
            eventResultIds.add(event.ResultId__c);
        }

        Map<Id, Result__c> resultsById = new Map<Id, Result__c>(new ResultsSelector().byIds(eventResultIds));

        for (MC_Result__e event : records) {
            Result__c result = new Result__c(Id = event.ResultId__c);
            if (
                String.isNotBlank(event.Progress_Status__c) &&
                !(resultsById.get(event.ResultId__c).Status__c == 'Success' ||
                resultsById.get(event.ResultId__c).Status__c == 'Failed')
            ) {
                result.Progress_Status__c = event.Progress_Status__c;
            }
            resultsToUpdate.put(result.Id, result);
        }
        update resultsToUpdate.values();
    }
}