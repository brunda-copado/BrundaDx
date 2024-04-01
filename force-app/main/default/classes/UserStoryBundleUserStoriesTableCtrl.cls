public with sharing class UserStoryBundleUserStoriesTableCtrl {
    private static final String UTILITY = 'Utility';
    private static final String LOCKED = 'Locked';

    //PUBLIC

    @AuraEnabled
    public static List<Id> fetchAvailableUserStoryIds(String packageVersionId) {
        List<Id> userStoryIds = new List<Id>();
        String bundleRecordTypeId = Schema.SObjectType.User_Story__c.getRecordTypeInfosByDeveloperName().get(UTILITY).getRecordTypeId();
        List<Bundled_Story__c> bundledStoriesInPackageVersion = fetchExistingUserStoryIds(new Set<Id>{ packageVersionId });

        Set<Id> userStoryIdsInPackageVersion = new Set<Id>();
        for (Bundled_Story__c bundledStory : bundledStoriesInPackageVersion) {
            userStoryIdsInPackageVersion.add(bundledStory.User_Story__c);
        }
        String environment = !bundledStoriesInPackageVersion.isEmpty() ? bundledStoriesInPackageVersion[0].User_Story__r.Environment__c : '';
        String project = !bundledStoriesInPackageVersion.isEmpty() ? bundledStoriesInPackageVersion[0].User_Story__r.Project__c : '';

        for (User_Story__c userStory : [
            SELECT Id
            FROM User_Story__c
            WHERE
                Id NOT IN :userStoryIdsInPackageVersion
                AND RecordTypeId != :bundleRecordTypeId
                AND Project__c = :project
                AND Environment__c = :environment
            WITH SECURITY_ENFORCED
            ORDER BY LastModifiedDate DESC
        ]) {
            userStoryIds.add(userStory.Id);
        }
        return userStoryIds;
    }

    @auraEnabled
    public static void addSelectedUserStories(Id packageVersionId, List<Id> userStoryIds) {
        Actions.AddUserStoryBundleRequest request = new Actions.AddUserStoryBundleRequest();

        request.packageVersionId = packageVersionId;
        request.userStoryIds = userStoryIds;
        Actions.UserStoryBundleService.add(request);
    }

    @auraEnabled
    public static void removeSelectedUserStories(Id packageVersionId, List<Id> bundledStoryIds) {
        List<Id> userStoryIds = getBundledStoryUserStoryIds(bundledStoryIds);

        Actions.RemoveUserStoryBundleRequest request = new Actions.RemoveUserStoryBundleRequest();
        request.packageVersionId = packageVersionId;
        request.userStoryIds = userStoryIds;

        Actions.UserStoryBundleService.remove(request);
    }

    // PRIVATE

    private static List<Bundled_Story__c> fetchExistingUserStoryIds(Set<Id> packageVersionIds) {
        return [
            SELECT User_Story__c, User_Story__r.Environment__c, User_Story__r.Project__c
            FROM Bundled_Story__c
            WHERE Package_Version__c IN :packageVersionIds
            WITH SECURITY_ENFORCED
        ];
    }

    private static List<Id> getBundledStoryUserStoryIds(List<Id> bundledStoryIds) {
        List<Id> userStoryIds = new List<Id>();
        for (Bundled_Story__c bundledStory : [SELECT User_Story__c FROM Bundled_Story__c WHERE Id IN :bundledStoryIds WITH SECURITY_ENFORCED]) {
            userStoryIds.add(bundledStory.User_Story__c);
        }

        return userStoryIds;
    }
}