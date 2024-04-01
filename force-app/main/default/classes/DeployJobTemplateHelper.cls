public with sharing virtual class DeployJobTemplateHelper {
    // PUBLIC
    public static void promote(String promotionId, Boolean doNotRunJob) {
        DeploymentConstant constant = new DeploymentConstant();
        if (!doNotRunJob) {
            updatePromotion(promotionId, constant.IN_PROGRESS);
        }

        PromoteRequest request = new PromoteRequest();
        request.promotionId = promotionId;
        request.executePromotion = true;
        request.executeDeployment = false;
        request.doNotRunJob = doNotRunJob;
        promote(request);
    }

    public static void deploy(String promotionId, Boolean doNotRunJob, List<Id> deploymentSteps) {
        PromotionDeployAction.Request request = new PromotionDeployAction.Request();
        request.promotionId = promotionId;
        request.executeDeployment = true;

        PromotionOtherInformation otherInformation = new PromotionOtherInformation();
        otherInformation.doNotRunJob = doNotRunJob;
        otherInformation.deploymentSteps = deploymentSteps;
        request.otherInformation = JSON.serialize(otherInformation);
        PromotionDeployAction.deploy(new List<PromotionDeployAction.Request>{ request });
    }

    public static void promoteAndDeploy(String promotionId, List<Id> deploymentSteps) {
        DeploymentConstant constant = new DeploymentConstant();
        updatePromotion(promotionId, constant.IN_PROGRESS);

        PromoteRequest request = new PromoteRequest();
        request.promotionId = promotionId;
        request.executePromotion = true;
        request.executeDeployment = true;
        request.deploymentSteps = deploymentSteps;

        promote(request);
    }

    public static Boolean jobInProgress(String promotionId) {
        DeploymentConstant constant = new DeploymentConstant();
        JobExecution__c promotionJob = promotionJob(promotionId);
        JobExecution__c deploymentJob = deploymentJob(promotionId);
        return promotionJob?.Status__c == constant.IN_PROGRESS ||
            deploymentJob?.Status__c == constant.IN_PROGRESS ||
            promotionJob?.Status__c == constant.NOT_STARTED ||
            deploymentJob?.Status__c == constant.NOT_STARTED ||
            promotionJob?.Status__c == constant.QUEUED ||
            deploymentJob?.Status__c == constant.QUEUED;
    }

    public static Boolean isPromotedUserStoriesCreated(Id promotionId) {
        return (new PromotedUserStoriesSelector().byPromotionId(new Set<Id>{ promotionId })).size() > 0;
    }

    public static JobExecution__c promotionJob(String promotionId) {
        return new JobExecutionsSelector().byPromotionId(promotionId);
    }

    public static JobExecution__c deploymentJob(String promotionId) {
        JobExecution__c result = null;
        Deployment__c deployment = new DeploymentsSelector().byPromotionId(promotionId);
        if (deployment != null) {
            result = new JobExecutionsSelector().byDeploymentId(deployment.Id);
        }
        return result;
    }

    // PMD False positive, as WITH USER_MODE is not supported yet
    @SuppressWarnings('PMD.ApexCRUDViolation')
    public static Boolean noPromotionJobNeeded(Id promotionId) {
        Set<Id> userStoyIds = new Set<Id>();
        for (Promoted_User_Story__c promotedUserStory : [
            SELECT User_Story__c
            FROM Promoted_User_Story__c
            WHERE Promotion__c = :promotionId
            WITH USER_MODE
        ]) {
            userStoyIds.add(promotedUserStory.User_Story__c);
        }
        return [SELECT COUNT() FROM User_Story_Metadata__c WHERE User_Story__c IN :userStoyIds WITH USER_MODE] == 0;
    }

    // PMD False positive, as WITH USER_MODE is not supported yet
    @SuppressWarnings('PMD.ApexCRUDViolation')
    public static Boolean promotionIsCancelled(Id promotionId) {
        DeploymentConstant constant = new DeploymentConstant();
        Promotion__c promotion = [
            SELECT Status__c
            FROM Promotion__c
            WHERE Id = :promotionId
            WITH USER_MODE
        ];

        return promotion.Status__c == constant.CANCELLED;
    }

    // PRIVATE
    private static void promote(PromoteRequest tempRequest) {
        PromoteAction.Request request = new PromoteAction.Request();
        request.promotionId = tempRequest.promotionId;
        request.executePromotion = tempRequest.executePromotion;
        request.executeDeployment = tempRequest.executeDeployment;
        request.deploymentDryRun = false;
        PromotionOtherInformation otherInformation = new PromotionOtherInformation();
        otherInformation.doNotRunJob = tempRequest.doNotRunJob != null ? tempRequest.doNotRunJob : false;
        otherInformation.deploymentSteps = tempRequest.deploymentSteps;
        request.otherInformation = JSON.serialize(otherInformation);

        PromoteAction.promote(new List<PromoteAction.Request>{ request });
    }

    private static void updatePromotion(Id promotionId, String status) {
        List<SObject> records = new List<SObject>{ new Promotion__c(Id = promotionId, Status__c = status) };

        PromotionTriggerHelper.bypassPromotionTrigger = true;
        DML.safeUpdate(
            records,
            'Could not update the status for a Promotion object on executing action ( DeployJobTemplateHelper.updatePromotion class )'
        );
    }

    // WRAPPER
    public with sharing class PromoteRequest {
        public String promotionId;
        public Boolean executePromotion;
        public Boolean executeDeployment;
        public Boolean doNotRunJob;
        public List<Id> deploymentSteps;
    }
}