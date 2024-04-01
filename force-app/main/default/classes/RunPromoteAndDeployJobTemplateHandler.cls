public with sharing class RunPromoteAndDeployJobTemplateHandler extends DeployJobTemplateHelper {
    // PUBLIC

    @AuraEnabled
    public static ValidationResponse validate(Id recordId) {
        ValidationResponse response = new ValidationResponse();

        response.promotedUserStoriesCreated = isPromotedUserStoriesCreated(recordId);
        response.jobInProgress = jobInProgress(recordId);
        response.promotionIsCancelled = promotionIsCancelled(recordId);

        return response;
    }

    @AuraEnabled
    public static void execute(Id recordId, List<Id> deploymentSteps) {
        promoteAndDeploy(recordId, deploymentSteps);
    }

    // INNER

    public with sharing class ValidationResponse {
        @AuraEnabled
        public Boolean promotedUserStoriesCreated = false;
        @AuraEnabled
        public Boolean jobInProgress = false;
        @AuraEnabled
        public Boolean promotionIsCancelled = false;
    }
}