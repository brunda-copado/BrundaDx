public inherited sharing class CancelFunctionServiceImpl {
    // PUBLIC

    public static CopadoFunctions.CancelResult execute(String resultId) {
        if(resultId == null) {
            throw new ApplicationException(String.format(Label.MissingRequiredParameters, new List<String> {'Result Id'}));
        }

        Result__c result = new ResultsSelector().byId(resultId);

        if(result.Status__c != 'In Progress') {
            throw new ApplicationException(Label.Stop_Execution_Error_Completed);
        }

        HttpCallout request = new FunctionCallout(result.Id)
            .userId(UserInfo.getUserId())
            .apiKey(new Settings().mySettings.API_Key__c)
            .requestTimeout(20000)
            .payload(payload(result))
            .build()
            .request();

        if(request.response().getStatusCode() != 201) {
            throw new ApplicationException(Label.Stop_Execution_Error_Connecting);
        }

        DML.safeUpdate(new Result__c(
            Id = result.Id,
            Progress_Status__c = 'Cancelling'
        ), String.format(Label.ErrorWhileUpdating,
            new List<String> {Result__c.SObjectType.getDescribe().getLabel(), 'CancelFunctionServiceImpl.execute'})
        );

        return new CopadoFunctions.CancelResult(resultId);
    }


    // PRIVATE

    private static String payload(Result__c aResult) {
        Function__c aFunction = new Function__c(
            Id = aResult.Function__c,
            API_Name__c = aResult.Function__r.API_Name__c,
            Script__c = aResult.Function__r.Script__c,
            Image_Name__c = aResult.Function__r.Image_Name__c,
            Parameters__c = JSON.serialize(new List<Parameter>()),
            Options__c = JSON.serialize(new List<Parameter>{ new Parameter('AbortJob', 'true') }),
            Worker_Size__c = aResult.Function__r.Worker_Size__c
        );
        return new FunctionPayload(aFunction).resultId(aResult.Id).toJson();
    }
}