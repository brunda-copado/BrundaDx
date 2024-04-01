public with sharing class RemoveUserStoryBundleServiceImpl {
    // PUBLIC

    public static Actions.RemoveUserStoryBundleResult remove(Actions.RemoveUserStoryBundleRequest request) {
        Actions.RemoveUserStoryBundleResult response = new Actions.RemoveUserStoryBundleResult();

        List<Bundled_Story__c> bundledStories = getBundledUserStories(request.packageVersionId);

        List<Id> remaininUserStoryIds = getRemainingUserStoriesInBundle(bundledStories, request.userStoryIds);
        new UserStoryBundleValidator(remaininUserStoryIds).run();

        response.bundledUserStories = deleteBundledStories(bundledStories, request.userStoryIds);

        return response;
    }

    // PRIVATE

    private static List<Bundled_Story__c> getBundledUserStories(Id packageVersionId) {
        return [
            SELECT Id, User_Story__c, Package_Version__c
            FROM Bundled_Story__c
            WHERE Package_Version__c = :packageVersionId
            WITH SECURITY_ENFORCED
        ];
    }

    private static List<Id> getRemainingUserStoriesInBundle(List<Bundled_Story__c> bundledStories, List<Id> userStoryIdsToRemove) {
        List<Id> result = new List<Id>();

        for (Bundled_Story__c bundledStory : bundledStories) {
            if (!userStoryIdsToRemove.contains(bundledStory.User_Story__c)) {
                result.add(bundledStory.User_Story__c);
            }
        }

        return result;
    }

    private static List<Bundled_Story__c> deleteBundledStories(List<Bundled_Story__c> bundledStories, List<Id> userStoryIdsToRemove) {
        List<Bundled_Story__c> result = new List<Bundled_Story__c>();

        List<Bundled_Story__c> bundlesToDelete = new List<Bundled_Story__c>();
        for (Bundled_Story__c bundledStory : bundledStories) {
            if (userStoryIdsToRemove.contains(bundledStory.User_Story__c)) {
                bundlesToDelete.add(bundledStory);
            } else {
                result.add(bundledStory);
            }
        }

        DML.safeDelete(
            bundlesToDelete,
            String.format(
                Label.ErrorWhileDeleting,
                new List<String>{
                    Bundled_Story__c.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).getLabel(),
                    'RemoveUserStoryBundleServiceImpl.deleteBundledStories'
                }
            )
        );

        return result;
    }
}