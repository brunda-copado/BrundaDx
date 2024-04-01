global with sharing class DeleteOldContentVersionsAction {
    global with sharing class Request {
        @InvocableVariable(label='Record Id')
        global String recordId;
    }
    global with sharing class Result {
        @InvocableVariable(label='ContentDocument Ids')
        global List<Id> contentDocumentIds;
    }

    @InvocableMethod(
        label='Delete Old Versions From Record Files'
        description='Deletes all the versions of record Files, leaving only the last one. Returns the new File Id with the latest version (as original File is removed due to limitations deleting versions in Salesforce).'
        category='Files'
    )
    global static List<Result> execute(List<Request> requests) {
        List<Result> results = new List<Result>();

        Set<Id> recordIds = getRecordIds(requests);

        new ContentVersionDeleter().fromRecords(recordIds).deleteOldVersions();

        Map<Id, Set<Id>> newContentDocumentIdsByRecordId = SalesforceFilesService.contentDocumentIdsOfRecord(recordIds);

        for (Request request : requests) {
            Result result = getResult(request, newContentDocumentIdsByRecordId);
            results.add(result);
        }

        return results;
    }

    private static Set<Id> getRecordIds(List<Request> requests) {
        Set<Id> result = new Set<Id>();

        for (Request request : requests) {
            Id recordId = getRecordId(request);
            if (recordId != null) {
                result.add(request.recordId);
            }
        }

        return result;
    }

    private static Id getRecordId(Request request) {
        Id result;
        if (String.isNotBlank(request.recordId) && request.recordId instanceof Id) {
            result = request.recordId;
        }
        return result;
    }

    private static Result getResult(Request request, Map<Id, Set<Id>> newContentDocumentIdsByRecordId) {
        Result result = new Result();
        result.contentDocumentIds = new List<Id>();

        Id recordId = getRecordId(request);
        if (recordId != null && newContentDocumentIdsByRecordId.containsKey(recordId)) {
            Set<Id> newContentDocumentIds = newContentDocumentIdsByRecordId.get(recordId);
            result.contentDocumentIds.addAll(newContentDocumentIds);
        }

        return result;
    }
}