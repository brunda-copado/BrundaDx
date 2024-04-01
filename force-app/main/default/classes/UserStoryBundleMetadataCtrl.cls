public with sharing class UserStoryBundleMetadataCtrl {
    @AuraEnabled(cacheable=false)
    public static List<Id> getUserStoryIds(Id packageVersionId) {
        try {
            Set<Id> result = new Set<Id>();
            for (Bundled_Story__c bundledUserStory : [
                SELECT User_Story__c
                FROM Bundled_Story__c
                WHERE Package_Version__c = :packageVersionId
                WITH SECURITY_ENFORCED
            ]) {
                result.add(bundledUserStory.User_Story__c);
            }
            return new List<Id>(result);
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }
    }
}