global with sharing class CheckContentDocumentPermissionAction {
    global with sharing class Request {
        @InvocableVariable(label='Record Id')
        global String recordId;
    }
    global with sharing class Result {
        @InvocableVariable(label='Can Delete Files')
        global Boolean canDeleteFiles;
    }

    @InvocableMethod(
        label='Check File Permission'
        description='Checks if the current user is allowed to perform operations on the Files related to this records.'
        category='Files'
    )
    global static List<Result> execute(List<Request> requests) {
        List<Result> results = new List<Result>();

        Set<Id> recordIds = getRecordIds(requests);
        Map<Id, Set<Id>> contentDocumentIdsByRecordId = SalesforceFilesService.contentDocumentIdsOfRecord(recordIds);
        Set<Id> allContentDocumentIds = flatten(contentDocumentIdsByRecordId);
        ContentDocumentPermissionManager permissionManager = new ContentDocumentPermissionManager(allContentDocumentIds);

        for (Request request : requests) {
            Result result = getResult(request, contentDocumentIdsByRecordId, permissionManager);
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

    private static Result getResult(
        Request request,
        Map<Id, Set<Id>> contentDocumentIdsByRecordId,
        ContentDocumentPermissionManager permissionManager
    ) {
        Result result = new Result();
        result.canDeleteFiles = false;

        Id recordId = getRecordId(request);
        if (recordId != null && contentDocumentIdsByRecordId.containsKey(recordId)) {
            Set<Id> contentDocumentIds = contentDocumentIdsByRecordId.get(recordId);
            result.canDeleteFiles = permissionManager.canDelete(contentDocumentIds);
        }

        return result;
    }

    private static Set<Id> flatten(Map<Id, Set<Id>> collectionsByKey) {
        Set<Id> result = new Set<Id>();

        for (Set<Id> collection : collectionsByKey.values()) {
            result.addAll(collection);
        }

        return result;
    }
}