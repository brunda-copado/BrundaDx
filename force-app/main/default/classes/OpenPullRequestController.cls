public with sharing class OpenPullRequestController {
    @AuraEnabled(cacheable=false)
    public static Response getData(Id recordId) {
        try {
            Response result = new Response();
            Promotion__c promotion = getPromotion(recordId);
            result.promotion = promotion;
            result.pipeline = getPipeline(promotion);
            result.destinationEnvironmentBranch = getDestinationEnvironmentBranch(promotion);
            result.isMerged = promotionIsMerged(promotion.Id);
            return result;
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }
    }

    private static Promotion__c getPromotion(Id recordId) {
        return [
            SELECT
                Project__r.Deployment_Flow__r.Git_Repository__r.Pull_Request_Base_URL__c,
                Project__r.Deployment_Flow__r.Git_Repository__c,
                Project__r.Deployment_Flow__r.Main_Branch__c,
                Project__r.Deployment_Flow__r.Git_Repository__r.Git_Provider__c,
                Release__r.Project__r.Deployment_Flow__c,
                Release__r.Project__r.Deployment_Flow__r.Git_Repository__r.Pull_Request_Base_URL__c,
                Release__r.Project__r.Deployment_Flow__r.Git_Repository__c,
                Release__r.Project__r.Deployment_Flow__r.Main_Branch__c,
                Release__r.Project__r.Deployment_Flow__r.Git_Repository__r.Git_Provider__c,
                Name,
                Destination_Environment__c
            FROM Promotion__c
            WHERE Id = :recordId
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];
    }

    private static String getDestinationEnvironmentBranch(Promotion__c promotion) {
        Id pipelineId = getPipeline(promotion)?.Id;
        Id destinationEnvironmentId = promotion.Destination_Environment__c;
        List<Deployment_Flow_Step__c> flowStep = [
            SELECT Branch__c
            FROM Deployment_Flow_Step__c
            WHERE Deployment_Flow__c = :pipelineId AND Source_Environment__c = :destinationEnvironmentId
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];
        return !flowStep.isEmpty() && String.isNotBlank(flowStep[0].Branch__c) ? flowStep[0].Branch__c : getBranchFromPipeline(promotion);
    }

    private static Boolean promotionIsMerged(Id promotionId) {
        return new JobExecutionsSelector().byPromotionId(promotionId)?.Status__c == JobExecutionConstants.STATUS_SUCCESSFUL;
    }

    private static Deployment_Flow__c getPipeline(Promotion__c promotion) {
        return String.isNotBlank(promotion.Project__r.Deployment_Flow__c)
            ? promotion.Project__r.Deployment_Flow__r
            : String.isNotBlank(promotion.Release__r.Project__r.Deployment_Flow__c) ? promotion.Release__r.Project__r.Deployment_Flow__r : null;
    }

    private static String getBranchFromPipeline(Promotion__c promotion) {
        return String.isNotBlank(promotion.Project__r.Deployment_Flow__r.Main_Branch__c)
            ? promotion.Project__r.Deployment_Flow__r.Main_Branch__c
            : String.isNotBlank(promotion.Release__r.Project__r.Deployment_Flow__r.Main_Branch__c)
                  ? promotion.Release__r.Project__r.Deployment_Flow__r.Main_Branch__c
                  : null;
    }

    public with sharing class Response {
        @AuraEnabled
        public Promotion__c promotion;
        @AuraEnabled
        public Deployment_Flow__c pipeline;
        @AuraEnabled
        public String destinationEnvironmentBranch;
        @AuraEnabled
        public Boolean isMerged;
    }
}