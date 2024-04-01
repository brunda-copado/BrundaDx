public with sharing class UpdateStepStatus {
    private static final String STEP_PENDING = 'Pending';
    private static final String STEP_COMPLETE = 'Complete';
    private static final String STEP_INCOMPLETE = 'Incomplete';

    @TestVisible
    private static List<Event__e> eventList = new List<Event__e>();

    @AuraEnabled(cacheable=false)
    public static void handleUpdate(Id jobId, String stepStatus, String comments) {
        try {
            JobStep__c step = [SELECT Result__c FROM JobStep__c WHERE Id = :jobId WITH SECURITY_ENFORCED LIMIT 1];

            if (stepStatus == STEP_PENDING) {
                Result__c result = new Result__c(Id = step.Result__c,
                                                Status__c = label.INPROGRESS,
                                                End_Time__c = null,
                                                Result_Data__c = comments);

                DML.safeUpdate(
                    result,
                    'Could not update a Result object for the Update Step Status execution ( UpdateStepStatus.handleUpdate class )'
                );

                DML.safeUpdate(
                    new JobStep__c(Id = step.Id, ResultDataJson__c = comments),
                    'Could not update a Step object for the Update Step Status execution ( UpdateStepStatus.handleUpdate class )'
                );
            } else {
                OnJobStepComplete.EventPayload payload = stepStatus == STEP_COMPLETE
                                                        ? new OnJobStepComplete.EventPayload(true, '', comments)
                                                        : stepStatus == STEP_INCOMPLETE 
                                                            ? new OnJobStepComplete.EventPayload(false, comments, '')
                                                            : null;
                eventList.add(new Event__e(Payload__c = JSON.serialize(payload), Topic_Uri__c = OnJobStepComplete.STEP_ENDPOINT + step.Result__c));
                EventBus.publish(eventList);
            }
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }
    }
}