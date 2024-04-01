public class QualityAutomationConstants {
    public static final Map<String, String> QUALITY_CONNECTOR_BY_ACTION = new Map<String, String>{
        ActionConstants.COMMIT_ACTION => 'ACCommitToRunQG',
        ActionConstants.PROMOTION => 'ACPromotionToRunQG',
        ActionConstants.PROMOTION_DEPLOYMENT => 'ACPromotionDeploymentToRunQG'
    };

}