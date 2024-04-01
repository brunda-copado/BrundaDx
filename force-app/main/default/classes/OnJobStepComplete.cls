public with sharing class OnJobStepComplete implements Queueable, Finalizer, Database.AllowsCallouts {
    public static final String STEP_ENDPOINT = '/events/copado/v1/step-result/';
    public static final String FAILED = 'Failed';
    private List<Event__e> records;

    // CONSTRUCTOR

    public OnJobStepComplete(List<Event__e> records) {
        this.records = records;
    }

    // Invocable

    @InvocableMethod(label='Job Step Complete')
    public static List<Id> execute(List<Event__e> events) {
        new OnJobStepComplete(filterRelevant(events)).execute();

        return eventOwners(events);
    }

    // PUBLIC
    @SuppressWarnings('PMD.OperationWithLimitsInLoop')
    public void execute() {
        for (Integer i = 0; (i < records.size() && i < 25); i++) {
            Event__e event = records.remove(0);
            Logger.trace(event.Id, 'OnJobStepComplete.execute()', 'Step completion event: ', event);

            if (Test.isRunningTest()) {
                executeNextStep(event);
            } else {
                System.enqueueJob(new OnJobStepComplete(new List<Event__e>{ event }));
            }
        }

        if (!records.isEmpty()) {
            System.enqueueJob(this);
        }
    }

    public void execute(QueueableContext context) {
        Event__e event = records.remove(0);
        executeNextStep(event);
    }

    private void executeNextStep(Event__e event) {
        Id resultId = Id.valueOf(event.Topic_Uri__c.substringAfter(STEP_ENDPOINT));
        EventPayload payload = asEventPayload(event.Payload__c);

        Result__c currentResult = updateStatus(resultId, payload);
        List<Queue__c> queueInProgress = [SELECT Id, Resource__c FROM Queue__c WHERE ContextId__c = :currentResult.JobStep__c AND Status__c = 'In Progress' WITH USER_MODE];

        String transactionId = transactionId(currentResult);
        List<Queue__c> blockedQueues = new List<Queue__c>();

        if(transactionId != null) {
            blockedQueues = [SELECT Id, Resource__c, ContextId__c FROM Queue__c WHERE transaction__c = :transactionId AND Status__c = 'Blocked' WITH USER_MODE];
        }

        Logger.trace(resultId, 'Queue.releaseResource', 'configJson__c: ', currentResult.JobStep__r.configJson__c);

        if (
            !queueInProgress.isEmpty() &&
            ((payload.status() != FAILED && blockQueueForTransaction(currentResult)) ||
            (payload.status() == FAILED && blockQueueOnError(currentResult.JobStep__r)))
        ) {
            Queue.block(currentResult.JobStep__c);
            Id nextResultId = new StepCallback().execute(currentResult.JobStep__r.JobExecution__c, payload);
        } else {
            Id nextResultId = new StepCallback().execute(currentResult.JobStep__r.JobExecution__c, payload);
            if (!queueInProgress.isEmpty()) {
                Queue.releaseResource(currentResult.JobStep__c);
            }
        }

        // Note: This will release quee if the failed step is not using queue, but its adjacent step is blocking queue
        // In that case we need to release all the queues blocked by adjacent steps as soon as the JE fails
        if(payload.status() == FAILED && !blockedQueues.isEmpty()) {
            Set<Id> blockedContextIds = blockedContextIds(blockedQueues);
            Queue.releaseResource(blockedContextIds);
        }

        if (!records.isEmpty()) {
            System.attachFinalizer(this);
        }
    }

    public void execute(FinalizerContext ctx) {
        if (!records.isEmpty()) {
            new OnJobStepComplete(records).execute();
        }
    }

    // PRIVATE

    private Set<Id> blockedContextIds(List<Queue__c> blockedQueues) {
        Set<Id> result = new Set<Id>();

        for(Queue__c blockedQueue : blockedQueues) {
            result.add(blockedQueue.ContextId__c);
        }

        return result;
    }

    private String transactionId(Result__c currentResult) {
        try {
            String serializedJson = currentResult.JobStep__r.JobExecution__r.DataJson__c;
            Map<String, Object> dataJson = (Map<String, Object>) Json.deserializeUntyped(serializedJson);

            return dataJson.containsKey('transactionId') ? (String) dataJson.get('transactionId') : null;
        } catch (Exception ex) {
            return null;
        }
    }


    private Boolean blockQueueForTransaction(Result__c currentResult) {
        try {
            String serializedJson = currentResult.JobStep__r.JobExecution__r.DataJson__c;
            Map<String, Object> dataJson = (Map<String, Object>) Json.deserializeUntyped(serializedJson);

            return dataJson.containsKey('blockQueueForTransaction') ? (Boolean) dataJson.get('blockQueueForTransaction') : false;
        } catch (Exception ex) {
            return false;
        }
    }

    private Boolean blockQueueOnError(JobStep__c step) {
        try {
            Map<String, Object> configJson = (Map<String, Object>) JSON.deserializeUntyped(step.ConfigJson__c);

            return configJson.containsKey('blockQueueOnError') ? (Boolean) configJson.get('blockQueueOnError') : false;
        } catch (Exception ex) {
            return false;
        }
    }

    private static List<Id> eventOwners(List<Event__e> events) {
        List<Id> result = new List<Id>();

        for (Event__e event : events) {
            result.add(event.CreatedById);
        }

        return result;
    }

    private Result__c updateStatus(Id resultId, EventPayload payload) {
        Result__c result = new ResultsSelector().byId(resultId);

        if (result.Status__c == 'Cancelled') {
            payload.status = result.Status__c;
        }

        if (result.Job_Type__c != 'Function') {
            Result__c resultToUpdate = new Result__c(
                Id = resultId,
                Status__c = payload.status(),
                Result_Data__c = payload.data,
                Error_Message__c = payload.isSuccess ? '' : payload.errorMessage,
                End_Time__c = DateTime.now()
            );
            DML.safeUpdate(
                resultToUpdate,
                'Could not update the Result after complete a Job Step execution ( OnJobStepComplete.updateStatus class )'
            );
        }

        JobStep__c step = new JobStep__c(Id = result.JobStep__c, ResultDataJson__c = payload.data);
        DML.safeUpdate(step, 'Could not update the Job Step after complete a Job Step execution ( OnJobStepComplete.updateStatus class )');

        return result;
    }

    private EventPayload asEventPayload(String payload) {
        EventPayload result;

        try {
            result = (EventPayload) JSON.deserialize(payload, EventPayload.class);
        } catch (Exception ex) {
            result = new EventPayload(false, Label.invalidStepPayload);
        }

        return result;
    }

    private static List<Event__e> filterRelevant(List<Event__e> arbitraryEvents) {
        List<Event__e> result = new List<Event__e>();

        for (Event__e event : arbitraryEvents) {
            if (isRelevant(event)) {
                result.add(event);
            }
        }

        return result;
    }

    private static Boolean isRelevant(Event__e event) {
        return (event.Topic_Uri__c != null && event.Topic_Uri__c.startsWith(STEP_ENDPOINT) && isResult(event));
    }

    private static Boolean isResult(Event__e event) {
        String recordId = event.Topic_Uri__c.substringAfter(STEP_ENDPOINT);

        return (objectType(recordId) == 'Result__c');
    }

    private static String objectType(Id recordId) {
        return (String.isNotBlank(recordId) ? recordId.getSObjectType().getDescribe().getLocalName() : '');
    }

    // INNER
    public class EventPayload {
        @AuraEnabled
        public String data;

        @AuraEnabled
        public String errorMessage;

        @AuraEnabled
        public Boolean isSuccess = false;

        private String status;

        public EventPayload(Boolean isSuccess) {
            this.isSuccess = isSuccess;
        }

        public EventPayload(Boolean isSuccess, String errorMessage) {
            this.isSuccess = isSuccess;
            this.errorMessage = errorMessage;
        }

        public EventPayload(Boolean isSuccess, String errorMessage, String data) {
            this.data = data;
            this.isSuccess = isSuccess;
            this.errorMessage = errorMessage;
        }

        public String status() {
            if (String.isNotBlank(status)) {
                return status;
            }
            return (isSuccess) ? 'Success' : 'Failed';
        }
    }
}