public with sharing virtual class ACPromotionDeploymentToBackPromotion extends ACPromotionDeploymentToPromotion {
    private static final String BACK_PROMOTION_CONFIG_COMPONENT = 'backPromotionAutomationScope';

    protected override Boolean isBackPromotion() {
        return true;
    }

    protected override AutomationConnector createConnector(PromoteAction.Request request) {
        ACPromotionDeploymentToBackPromotion connector = new ACPromotionDeploymentToBackPromotion();
        connector.request = request;
        return connector;
    }

    protected override Map<Id, Set<Id>> getNextEnvironments(List<Promotion__c> promotions) {
        Map<Id, Set<Id>> result = new Map<Id, Set<Id>>();

        // Note: even if there are multiple events grouped, they all belong to the same pipeline
        Id pipelineId = new FindPipeline().fromObject(promotions[0]);
        List<Deployment_Flow_Step__c> connections = new DeploymentFlowStepsSelector().byPipeline(new Set<Id>{ pipelineId }).get(pipelineId);

        JsonData configJson = getConfig();

        for (Promotion__c promotion : promotions) {
            Id promotionId = promotion.Id;
            if (!result.containsKey(promotionId)) {
                result.put(promotionId, new Set<Id>());
            }
            for (Deployment_Flow_Step__c connection : connections) {
                if (
                    promotion.Source_Environment__c != connection.Source_Environment__c &&
                    promotion.Destination_Environment__c == connection.Destination_Environment__c &&
                    !configJson?.excludedEnvironmentsForBackPromotion?.contains(connection.Source_Environment__c)
                ) {
                    result.get(promotionId).add(connection.Source_Environment__c);
                }
            }
        }
        return result;
    }

    // PUBLIC

    public override String getUIComponentName() {
        return (String.isBlank(Settings.ns) ? 'c:' : 'copado:') + BACK_PROMOTION_CONFIG_COMPONENT;
    }

    private JsonData getConfig() {
        JsonData result = new JsonData();

        if (String.isNotBlank(context?.automationRule?.Config_Json__c)) {
            try {
                result = (JsonData) JSON.deserialize(context.automationRule.Config_Json__c, JsonData.class);
            } catch (Exception ex) {
                // Note - Silently ignore any exception
            }
        }

        if (result.excludedEnvironmentsForBackPromotion == null) {
            result.excludedEnvironmentsForBackPromotion = new List<String>();
        }

        return result;
    }

    // INNER

    public class JsonData {
        public List<String> excludedEnvironmentsForBackPromotion = new List<String>();
    }
}