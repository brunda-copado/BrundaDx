public with sharing class ReleaseQueue {
    private List<SObject> records;

    // CONSTRUCTOR

    public ReleaseQueue(List<SObject> records) {
        this.records = records;
    }

    // PUBLIC

    public void execute() {
        Set<Id> stepIds = new Map<Id, SObject>(records).keySet();
        List<Queue__c> relevantQueues = [SELECT ContextId__c, Status__c FROM Queue__c WHERE ContextId__c IN :stepIds WITH USER_MODE];
        Set<Id> releaseResourceQueue = new Set<Id>();
        Set<Id> removeQueue = new Set<Id>();

        for (Queue__c relevantQueue : relevantQueues) {
            if (relevantQueue.Status__c == 'In Progress') {
                releaseResourceQueue.add((Id) relevantQueue.ContextId__c);
            } else if (relevantQueue.Status__c == 'Queued') {
                removeQueue.add((Id) relevantQueue.ContextId__c);
            }
        }

        if(!removeQueue.isEmpty()) {
            Queue.remove(removeQueue);
        }

        if(!releaseResourceQueue.isEmpty()) {
            Queue.releaseResource(releaseResourceQueue);
        }
    }
}