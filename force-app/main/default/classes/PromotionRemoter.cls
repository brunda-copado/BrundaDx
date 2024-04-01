public with sharing class PromotionRemoter {
    @SuppressWarnings('PMD.EmptyStatementBlock')
    public PromotionRemoter(ApexPages.StandardController pipelineController) {
    }

    @RemoteAction
    public static void executePromotionAction(String promotionId, Boolean isValidation) {
        Actions.PromotionRequest request = new Actions.PromotionRequest();
        request.promotionId = promotionId;
        request.executePromotion = true;
        request.executeDeployment = true;
        request.deploymentDryRun = isValidation;
        Actions.PromotionService.execute(request);
    }
}