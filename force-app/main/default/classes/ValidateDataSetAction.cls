global with sharing class ValidateDataSetAction {
    global with sharing class Request {
        @InvocableVariable(label='Record Id')
        global String recordId;
    }
    global with sharing class Result {
        @InvocableVariable(label='Has Valid Files?')
        global Boolean hasValidFiles;
    }

    @InvocableMethod(
        label='Validate Data Set'
        description='Checks different conditions for the Data Set record (e.g. if the files for the Data Set are valid for a deployment).'
        category='Data Set'
    )
    global static List<Result> execute(List<Request> requests) {
        List<Result> results = new List<Result>();

        Set<Id> recordIds = getRecordIds(requests);
        DataSetValidator validator = new DataSetValidator(recordIds);

        for (Request request : requests) {
            Result result = getResult(request, validator);
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

    private static Result getResult(Request request, DataSetValidator validator) {
        Result result = new Result();
        result.hasValidFiles = false;

        Id recordId = getRecordId(request);
        if (recordId != null) {
            result.hasValidFiles = validator.hasValidFiles(recordId);
        }

        return result;
    }
}