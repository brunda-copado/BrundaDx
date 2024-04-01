public with sharing class AddUserStoryBundleServiceImpl {
    // PUBLIC

    public static Actions.AddUserStoryBundleResult add(Actions.AddUserStoryBundleRequest request) {
        Actions.AddUserStoryBundleResult response = new Actions.AddUserStoryBundleResult();
        List<Id> userStoryIds = getUserStoriesInBundle(request.packageVersionId);

        List<Id> userStoryIdsToAdd = new List<Id>();
        for (Id userStoryId : request.userStoryIds) {
            if (!userStoryIds.contains(userStoryId)) {
                userStoryIdsToAdd.add(userStoryId);
            }
        }

        userStoryIds.addAll(userStoryIdsToAdd);

        new UserStoryBundleValidator(userStoryIds).run();

        response.bundledUserStories = createBundledStories(request.packageVersionId, userStoryIdsToAdd);
        return response;
    }

    // PRIVATE

    private static List<Bundled_Story__c> createBundledStories(Id packageVersionId, List<Id> userStoryIds) {
        List<Bundled_Story__c> result = new List<Bundled_Story__c>();
        for (Id userStoryId : userStoryIds) {
            result.add(new Bundled_Story__c(User_Story__c = userStoryId, Package_Version__c = packageVersionId));
        }

        DML.safeInsert(
            result,
            String.format(
                Label.ErrorWhileInserting,
                new List<String>{
                    Bundled_Story__c.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).getLabel(),
                    'AddUserStoryBundleServiceImpl.createBundledStories'
                }
            )
        );
        return result;
    }

    private static List<Id> getUserStoriesInBundle(Id packageVersionId) {
        List<Id> result = new List<Id>();

        for (Bundled_Story__c bundledStory : [
            SELECT User_Story__c
            FROM Bundled_Story__c
            WHERE Package_Version__c = :packageVersionId
            WITH SECURITY_ENFORCED
        ]) {
            result.add(bundledStory.User_Story__c);
        }

        return result;
    }
}