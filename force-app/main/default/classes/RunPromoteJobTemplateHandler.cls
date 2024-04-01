public with sharing class RunPromoteJobTemplateHandler extends DeployJobTemplateHelper {
    // PUBLIC

    @AuraEnabled
    public static ValidationResponse validate(Id recordId) {
        ValidationResponse response = new ValidationResponse();
        response.promotedUserStoriesCreated = isPromotedUserStoriesCreated(recordId);
        response.hasMetadata = !noPromotionJobNeeded(recordId);
        response.jobInProgress = jobInProgress(recordId);
        response.promotionIsCancelled = promotionIsCancelled(recordId);
        return response;
    }

    @AuraEnabled
    public static Boolean isJobInProgress(Id recordId) {
        return jobInProgress(recordId);
    }

    @AuraEnabled
    public static void execute(Id recordId, Boolean doNotRunJob) {
        promote(recordId, doNotRunJob);
    }

    // INNER

    public with sharing class ValidationResponse {
        @AuraEnabled
        public Boolean promotedUserStoriesCreated = false;
        @AuraEnabled
        public Boolean hasMetadata = false;
        @AuraEnabled
        public Boolean jobInProgress = false;
        @AuraEnabled
        public Boolean promotionIsCancelled = false;
    }
}