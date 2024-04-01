public with sharing class BundledStoriesRelatedListCtrl {
    private static final String UTILITY_RECORD_TYPE = 'Utility';

    // PUBLIC

    @AuraEnabled(cacheable=false)
    public static List<Id> getUserStoryIds(Id userStoryId) {
        try {
            Set<Id> result = new Set<Id>();

            if (isUserStoryBundle(userStoryId)) {
                Set<Id> bundledStories = getBundledUserStories(userStoryId);
                result.addAll(bundledStories);
            } else {
                Set<Id> userStoryBundles = getUserStoryBundles(userStoryId);
                result.addAll(userStoryBundles);
            }

            return new List<Id>(result);
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }
    }

    // PRIVATE

    private static Boolean isUserStoryBundle(Id userStoryId) {
        Boolean result = false;

        List<User_Story__c> userStories = [SELECT RecordType.Name FROM User_Story__c WHERE Id = :userStoryId WITH SECURITY_ENFORCED LIMIT 1];

        if (!userStories.isEmpty()) {
            result = userStories[0].RecordType.Name == UTILITY_RECORD_TYPE;
        }

        return result;
    }

    private static Set<Id> getBundledUserStories(Id userStoryBundleId) {
        Set<Id> result = new Set<Id>();

        for (Bundled_Story__c bundledUserStory : [
            SELECT User_Story__c
            FROM Bundled_Story__c
            WHERE Package_Version__c IN (SELECT Id FROM Artifact_Version__c WHERE User_Story__c = :userStoryBundleId)
            WITH SECURITY_ENFORCED
        ]) {
            result.add(bundledUserStory.User_Story__c);
        }

        return result;
    }

    private static Set<Id> getUserStoryBundles(Id userStoryId) {
        Set<Id> result = new Set<Id>();

        for (Bundled_Story__c bundledUserStory : [
            SELECT Package_Version__r.User_Story__c
            FROM Bundled_Story__c
            WHERE User_Story__c = :userStoryId
            WITH SECURITY_ENFORCED
        ]) {
            result.add(bundledUserStory.Package_Version__r.User_Story__c);
        }

        return result;
    }
}