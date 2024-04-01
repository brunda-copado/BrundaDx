public with sharing class TestStepCallback implements TestsStepCallback {
    public void execute(Id resultId, String status) {
        Logger.trace(resultId, 'TestStepCallback.execute', 'Status: ', status);
        Result__c result = [SELECT JobStep__r.JobExecution__c, Error_Message__c, Result_Data__c FROM Result__c WHERE Id = :resultId WITH SECURITY_ENFORCED];
        
        Database.SaveResult saveResult = EventBus.publish(stepCompletionEvent(result, status));
        if (!saveResult.isSuccess()) {
            for (Database.Error err : saveResult.getErrors()) {
                ApplicationException appEx = new ApplicationException(Label.Error_Publishing_Event + err.getStatusCode() + ' - ' + err.getMessage());
                Logger.error(String.valueOf(resultId), 'TestStepCallback.execute', 'Result: ', result,  appEx);
                throw appEx;
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
        OnJobStepComplete.EventPayload payload = new OnJobStepComplete.EventPayload(isSuccess, result.Error_Message__c, result.Result_Data__c);

        return JSON.serialize(payload);
    }

    private String topicUri(Id resultId) {
        return OnJobStepComplete.STEP_ENDPOINT + resultId;
    }
}