public with sharing class PromotionUserStoryMetadatasHandler {
    // PUBLIC

    @AuraEnabled
    public static List<Id> getUserStoryIds(Id promotionId) {
        List<Id> userStoryIds = new List<Id>();
        for (Promoted_User_Story__c promotedUserStoryRecord : [
            SELECT User_Story__c
            FROM Promoted_User_Story__c
            WHERE Promotion__c = :promotionId
            WITH SECURITY_ENFORCED
        ]) {
            userStoryIds.add(promotedUserStoryRecord.User_Story__c);
        }
        return userStoryIds;
    }
}