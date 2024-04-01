public with sharing class UserStoryBundleCommitCallback implements JobExecutionCallback {
    private static final String USER_STORY_BUNDLE_STATUS_OPEN = 'Open';

    // PUBLIC

    public void execute(JobExecution__c job, String status) {
        ExecutionData executionData = (ExecutionData) JSON.deserialize(job.DataJson__c, ExecutionData.class);
        User_Story__c userStoryBundle = getUserStoryBundle(executionData.userStoryId);
        User_Story_Commit__c userStoryCommit = getUserStoryCommit(executionData.userStoryCommitId);

        if (userStoryCommit.Status__c == CommitConstants.STATUS_FAILED) {
            Artifact_Version__c packageVersion = getPackageVersion(userStoryBundle);
            unlockBundle(packageVersion);
            includeChildStoriesIntoPipeline(packageVersion);
        }
    }

    // PRIVATE

    private static User_Story__c getUserStoryBundle(String userStoryId) {
        List<User_Story__c> userStories = [SELECT Id FROM User_Story__c WHERE Id = :userStoryId WITH SECURITY_ENFORCED LIMIT 1];
        return userStories[0];
    }

    private static User_Story_Commit__c getUserStoryCommit(String userStoryCommitId) {
        List<User_Story_Commit__c> userStoryCommit = [
            SELECT Status__c
            FROM User_Story_Commit__c
            WHERE Id = :userStoryCommitId
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];
        return userStoryCommit[0];
    }

    private static Artifact_Version__c getPackageVersion(User_Story__c parentStory) {
        return [SELECT Id, Status__c FROM Artifact_Version__c WHERE User_Story__c = :parentStory.Id WITH SECURITY_ENFORCED LIMIT 1];
    }

    private static void unlockBundle(Artifact_Version__c packageVersion) {
        packageVersion.Status__c = USER_STORY_BUNDLE_STATUS_OPEN;

        ArtifactVersionTriggerHandler.bypassTrigger = true;
        DML.safeUpdate(
            packageVersion,
            String.format(
                Label.ErrorWhileUpdating,
                new List<String>{
                    Artifact_Version__c.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).getLabel(),
                    'UserStoryBundleCommitCallback.unlockBundle'
                }
            )
        );
        ArtifactVersionTriggerHandler.bypassTrigger = false;
    }

    private static void includeChildStoriesIntoPipeline(Artifact_Version__c packageVersion) {
        UserStories.bypassTrigger = true;
        DML.safeUpdate(
            getChildUserStories(packageVersion),
            String.format(
                Label.ErrorWhileUpdating,
                new List<String>{
                    User_Story__c.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).getLabel(),
                    'UserStoryBundleCommitCallback.includeChildStoriesIntoPipeline'
                }
            )
        );
        UserStories.bypassTrigger = false;
    }

    private static List<User_Story__c> getChildUserStories(Artifact_Version__c packageVersion){
        List<User_Story__c> result = new List<User_Story__c>();

        for (Bundled_Story__c bundledStory : [
            SELECT Id, User_Story__c
            FROM Bundled_Story__c
            WHERE Package_Version__c = :packageVersion.Id
            WITH SECURITY_ENFORCED
        ]) {
            User_Story__c userStory = new User_Story__c(
                Id = bundledStory.User_Story__c,
                Stop_Indexing_Metadata__c = false,
                Exclude_From_CBM__c = false
            );

            result.add(userStory);
        }

        return result;
    }

    // INNER

    private with sharing class ExecutionData {
        private String userStoryId;
        private String userStoryCommitId;
    }
}