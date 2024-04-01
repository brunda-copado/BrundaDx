public with sharing class FunctionStepCallback implements MCCallBack {

    // PUBLIC

    public void execute(Function__c function, Result__c result, String status) {
        Logger.trace(result.Id, 'FunctionStepCallback.execute', '', null);
        
        if (Test.isRunningTest()) {
            new OnJobStepComplete(new List<Event__e>{ stepCompletionEvent(result, status) }).execute();
        } else {          
            Database.SaveResult saveResult = EventBus.publish(stepCompletionEvent(result, status));
            if (!saveResult.isSuccess()) {
                for (Database.Error err : saveResult.getErrors()) {
                    ApplicationException appEx = new ApplicationException(Label.Error_Publishing_Event + err.getStatusCode() + ' - ' + err.getMessage());
                    Logger.error(String.valueOf(result.Id), 'FunctionStepCallback.execute', 'Result: ', result, appEx);
                    throw appEx;
                }
            }
        }
    }

    // PRIVATE

    private Event__e stepCompletionEvent(Result__c result, String status) {
        Event__e event = new Event__e();
        event.Topic_Uri__c = topicUri(result.Id);
        event.Payload__c = payload(result, status);

        return event;
    }

    private String payload(Result__c result, String status) {
        Boolean isSuccess = status == 'Success';
        OnJobStepComplete.EventPayload payload = new OnJobStepComplete.EventPayload(
            isSuccess,
            result.Error_Message__c,
            result.Result_Data__c
        );

        return JSON.serialize(payload);
    }

    private String topicUri(Id resultId) {
        return OnJobStepComplete.STEP_ENDPOINT + resultId;
    }
}