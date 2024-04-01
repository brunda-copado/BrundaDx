public with sharing class UserStoryBundleValidator {
    private List<Id> userStoriesIds;
    private List<User_Story__c> userStories;
    private Integer metadataCount;

    // CONSTRUCTOR

    public UserStoryBundleValidator(List<Id> userStoriesIds) {
        this.userStoriesIds = userStoriesIds;
    }

    // PUBLIC

    public void run() {
        checkCustomPermission();
        checkNumberUserStories();
        checkEnvironmentAndProject();
        checkMetadataAndDeploymentTasks();
        checkAlreadyBundled();
        checkPipelineAction();
    }

    // PRIVATE

    private void checkCustomPermission() {
        Boolean hasCustomPermission = FeatureManagement.checkPermission(CustomPermissionConstants.USER_STORY_BUNDLE_CUSTOM_PERMISSION);
        if (!hasCustomPermission) {
            throw new ApplicationException(Label.USB_Error_No_Custom_Permission);
        }
    }

    private void checkNumberUserStories() {
        if (userStoriesIds.isEmpty() || userStoriesIds.size() == 1) {
            throw new ApplicationException(Label.USB_WARNING_NO_US_SELECTED);
        }
        userStories = [
            SELECT Id, Environment__c, Project__c, Project__r.Deployment_Flow__c, Release__r.Project__r.Deployment_Flow__c
            FROM User_Story__c
            WHERE Id IN :userStoriesIds
            WITH SECURITY_ENFORCED
        ];
    }

    private void checkEnvironmentAndProject() {
        Id firstEnvironmentId = userStories.get(0).Environment__c;
        Id firstProjectId = userStories.get(0).Project__c;

        for (User_Story__c userStory : userStories) {
            if (userStory.Environment__c != firstEnvironmentId) {
                throw new ApplicationException(Label.USB_WARNING_DIFFERENT_ENVIRONMENTS);
            }
            if (userStory.Project__c != firstProjectId) {
                throw new ApplicationException(Label.USB_WARNING_DIFFERENT_PROJECTS);
            }
        }
    }

    private void checkMetadataAndDeploymentTasks() {
        metadataCount = [SELECT COUNT() FROM User_Story_Metadata__c WHERE User_Story__c IN :userStories WITH SECURITY_ENFORCED];
        Integer deploymentStepsCount = [SELECT COUNT() FROM JobStep__c WHERE UserStory__c IN :userStories WITH SECURITY_ENFORCED];

        if (metadataCount == 0 && deploymentStepsCount == 0) {
            throw new ApplicationException(Label.No_Metadata_Or_Deployment_Task);
        }

        if (metadataCount > 8000) {
            throw new ApplicationException(Label.Bundle_Metadata_Limit);
        }
    }

    private void checkAlreadyBundled() {
        Set<Id> userStoryIdsFromLockedBundle = new Set<Id>();
        for (Bundled_Story__c bundledStory : [
            SELECT User_Story__c
            FROM Bundled_Story__c
            WHERE Package_Version__r.Status__c = 'Locked'
            WITH SECURITY_ENFORCED
        ]) {
            userStoryIdsFromLockedBundle.add(bundledStory.User_Story__c);
        }

        for (User_Story__c userStory : userStories) {
            if (userStoryIdsFromLockedBundle.contains(userStory.Id)) {
                throw new ApplicationException(Label.User_Story_Part_Of_Other_Bundle);
            }
        }
    }

    private void checkPipelineAction() {
        if (metadataCount != 0) {
            Id pipelineId = new FindPipeline().fromObject(userStories.get(0));
            Boolean commitActionAvailable =
                [
                    SELECT COUNT()
                    FROM Pipeline_Action__c
                    WHERE Pipeline__c = :pipelineId AND Action__c = :ActionConstants.COMMIT_ACTION
                    WITH SECURITY_ENFORCED
                ] > 0;
            if (!commitActionAvailable) {
                throw new ApplicationException(Label.No_Action_For_Bundle);
            }
        }
    }
}