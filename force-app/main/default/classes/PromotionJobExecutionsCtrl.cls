public with sharing class PromotionJobExecutionsCtrl {
    @AuraEnabled
    public static List<Id> getJobExecutionIds(String promotionId) {
        return new List<Id>(
            new Map<Id, JobExecution__c>(
                    [SELECT Id FROM JobExecution__c WHERE Promotion__c = :promotionId OR Deployment__r.Promotion__c = :promotionId WITH USER_MODE]
                )
                .keySet()
        );
    }
}