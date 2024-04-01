public with sharing class UserStoryCommitProgressAlertsCtrl {
    @AuraEnabled(cacheable=false)
    public static List<JobExecution__c> getJobExecution(Id recordId) {
        return new JobExecutionsSelector().byUserStory(recordId);
    }

    // PMD False positive, as WITH USER_MODE is not supported yet
    @SuppressWarnings('PMD.ApexCRUDViolation')
    @AuraEnabled(cacheable=false)
    public static List<Promoted_User_Story__c> getLastPromotion(Id recordId) {
        return [
            SELECT Promotion__c, Promotion__r.Status__c
            FROM Promoted_User_Story__c
            WHERE User_Story__c = :recordId AND Status__c != 'Outdated' AND Promotion__r.Back_Promotion__c = FALSE
            WITH USER_MODE
            ORDER BY LastModifiedDate DESC
            LIMIT 1
        ];
    }
}