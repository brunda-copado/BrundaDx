public with sharing class ValidateUserStoryHasSomethingToPromote {
    private User_Story__c userStory;

    // CTOR

    public ValidateUserStoryHasSomethingToPromote(User_Story__c userStory) {
        this.userStory = userStory;
    }

    // PUBLIC

    public Boolean execute() {
        return hasMetadata() || hasDeploymentSteps();
    }

    private Boolean hasDeploymentSteps() {
        return !OrderDeploymentStepsController.getAllDeploymentSteps(userStory.Id).isEmpty();
    }

    // PMD False positive, as WITH USER_MODE is not supported yet
    @SuppressWarnings('PMD.ApexCRUDViolation')
    private Boolean hasMetadata() {
        return [SELECT COUNT() FROM User_Story_Metadata__c WHERE User_Story__c = :userStory.Id WITH USER_MODE] > 0;
    }
}