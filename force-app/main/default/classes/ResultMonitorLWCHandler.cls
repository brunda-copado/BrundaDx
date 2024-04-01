@SuppressWarnings('PMD.UnusedLocalVariable, PMD.CyclomaticComplexity, PMD.CognitiveComplexity')
public with sharing class ResultMonitorLWCHandler {
    // PUBLIC

    @AuraEnabled(cacheable=false)
    public static ResultStatusDetail result(Id recId, String objectApiName, String fieldApiName) {
        return new ResultStatusDetail(recId, objectApiName, fieldApiName).getData();
    }


    @AuraEnabled(cacheable=false)
    public static void resume(Id jobStepId) {
        String topicUri = Queue.QUEUE_TOPIC_URI + jobStepId;
        Eventbus.publish(new Event__e(Topic_Uri__c = topicUri, Payload__c = 'Execute'));
    }


    @AuraEnabled
    public static void releaseResource(Id jobStepId) {
        try {
            Queue.releaseResource(jobStepId);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }


    @AuraEnabled
    public static ResultStatusDetail.QueueStatus getQueuedJobs(Id jobStepId) {
        try {
            return new ResultStatusDetail.QueueStatus().getData(jobStepId);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}