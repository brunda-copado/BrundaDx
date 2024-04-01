public with sharing virtual class ACPromotionToRunQG extends AutomationConnector {
    protected Actions.RunTestRequest request;
    protected Automation_Rule__c automationRule;
    protected Id actionId;
    protected sObject actionRecord;

    // PUBLIC

    public override List<AutomationConnector> getConnectors(AutomationConnectorContext context) {
        List<AutomationConnector> connectors = new List<AutomationConnector>();
        automationRule = getAutomationRule();
        actionId = getActionId();
        actionRecord = getActionRecord();
        Boolean qualityGateRuleIsMatching = assertQualityRuleIsMatching();
        if (!qualityGateRuleIsMatching) {
            return connectors;
        }
        // Find contextIds based on the QGRC Tests From
        Map<Id, List<Id>> contextIdsByActionId = getContextIds(automationRule.Quality_Gate_Rule_Condition__r.Tests_From__c);
        for (Id actionId : contextIdsByActionId.keyset()) {
            Actions.RunTestRequest request = prepareRequest(contextIdsByActionId.get(actionId), automationRule, actionId);
            AutomationConnector connector = createConnector(request);
            connector.context = context;
            connectors.add(connector);
        }

        return connectors;
    }

    public override String executeAutomation() {
        return Actions.RunTestService.execute(request).jobExecution.Id;
    }

    public override String getAutomatedActionName() {
        return automatedActionName();
    }

    // PROTECTED

    protected virtual AutomationConnector createConnector(Actions.RunTestRequest request) {
        ACPromotionToRunQG connector = new ACPromotionToRunQG();
        connector.request = request;
        return connector;
    }

    protected virtual Map<Id, List<Id>> getContextIds(String bringTestsFrom) {
        Map<Id, List<Id>> result = new Map<Id, List<Id>>();
        Promotion__c promotion = (Promotion__c) actionRecord;
        result.put(actionId, contextIds(promotion.Promoted_User_Stories__r, bringTestsFrom));
        return result;
    }

    protected virtual String getEnvironment() {
        Promotion__c promotion = (Promotion__c) actionRecord;
        return promotion.Source_Environment__c;
    }

    protected virtual String getParentContext(Id actionId) {
        return actionId;
    }

    protected virtual String automatedActionName() {
        return Label.Execute_Quality_Gate;
    }

    protected virtual String getActionId() {
        Id result;
        if (!context.automationEvents.isEmpty()) {
            ExecutionRequestData data = (ExecutionRequestData) JSON.deserialize(
                context.automationEvents[0].Action_Result__c,
                ExecutionRequestData.class
            );
            Id jobExecutionId = data.jobExecution?.Id;

            List<JobExecution__c> jobExecutions = [SELECT DataJson__c FROM JobExecution__c WHERE Id = :jobExecutionId WITH USER_MODE LIMIT 1];
            if (!jobExecutions.isEmpty() && String.isNotBlank(jobExecutions[0].DataJson__c)) {
                JobPayload payload = (JobPayload) JSON.deserialize(jobExecutions[0].DataJson__c, JobPayload.class);
                result = payload.promotionId;
            }
        }

        return result;
    }

    protected virtual sObject getActionRecord() {
        return getPromotion(getActionId());
    }

    protected virtual Boolean assertQualityRuleIsMatching() {
        Promotion__c promotion = (Promotion__c) actionRecord;
        if (promotion.Status__c == PromotionConstants.STATUS_MERGE_CONFLICT) {
            return false;
        }
        Quality.MatchingRulesRequest qualityRequest = new Quality.MatchingRulesRequest();
        qualityRequest.action = ActionConstants.PROMOTION;
        qualityRequest.pipeline = new FindPipeline().fromObject(promotion);
        qualityRequest.platform = promotion.Platform__c;
        qualityRequest.templateName = new ActionTemplate(ActionConstants.PROMOTION).promotion(promotion).getApiName();
        qualityRequest.environment = promotion.Destination_Environment__c;
        qualityRequest.metadataChanges = getMetadata(promotion);
        Quality.MatchingRulesResult matchingRulesResult = Quality.matchingRules(qualityRequest);
        for (Quality_Gate_Rule_Condition__c condition : matchingRulesResult.qualityGates) {
            if (condition.Id == automationRule.Quality_Gate_Rule_Condition__c) {
                return true;
            }
        }
        return false;
    }

    // PRIVATE

    // PMD False positive, as WITH USER_MODE is not supported yet
    private Automation_Rule__c getAutomationRule() {
        return [
            SELECT
                Automated_Action_Callback__c,
                Quality_Gate_Rule_Condition__c,
                Quality_Gate_Rule_Condition__r.Extension_Configuration__c,
                Quality_Gate_Rule_Condition__r.Extension_Configuration__r.ExtensionTool__c,
                Quality_Gate_Rule_Condition__r.AcceptanceCriteria__c,
                Quality_Gate_Rule_Condition__r.Tests_From__c
            FROM Automation_Rule__c
            WHERE Id = :context.automationRule.Id
            WITH USER_MODE
            LIMIT 1
        ];
    }

    private List<User_Story_Metadata__c> getMetadata(Promotion__c promotion) {
        Set<Id> userStories = new Set<Id>();
        for (Promoted_User_Story__c promotedUserStory : promotion.Promoted_User_Stories__r) {
            userStories.add(promotedUserStory.User_Story__c);
        }
        return [
            SELECT
                Id,
                Metadata_API_Name__c,
                Type__c,
                ModuleDirectory__c,
                Action__c,
                Category__c,
                JsonInformation__c,
                User_Story__c,
                User_Story__r.Name
            FROM User_Story_Metadata__c
            WHERE User_Story__c IN :userStories
            WITH USER_MODE
        ];
    }

    // PMD False positive, as WITH USER_MODE is not supported yet
    private Promotion__c getPromotion(Id promotionId) {
        return [
            SELECT
                Status__c,
                Source_Environment__c,
                Destination_Environment__c,
                Project__r.Deployment_Flow__c,
                Release__r.Project__r.Deployment_Flow__c,
                Platform__c,
                (SELECT Id, User_Story__c, User_Story__r.US_Feature__c, User_Story__r.US_Feature__r.Application__c FROM Promoted_User_Stories__r)
            FROM Promotion__c
            WHERE Id = :promotionId
            WITH USER_MODE
        ];
    }

    private List<Id> contextIds(List<Promoted_User_Story__c> promotedUserStories, String bringTestsFrom) {
        List<Id> result = new List<Id>();
        for (Promoted_User_Story__c promotedUserStory : promotedUserStories) {
            Boolean usFeatureIsNotBlank = String.isNotBlank(promotedUserStory.User_Story__r.US_Feature__c);
            Boolean usApplicationIsNotBlank = String.isNotBlank(promotedUserStory.User_Story__r.US_Feature__r.Application__c);

            if (bringTestsFrom == QualityGateConstants.TESTS_FROM_USER_STORY) {
                result.add(promotedUserStory.User_Story__c);
            } else if (bringTestsFrom == QualityGateConstants.TESTS_FROM_FEATURE && usFeatureIsNotBlank) {
                result.add(promotedUserStory.User_Story__r.US_Feature__c);
            } else if (bringTestsFrom == QualityGateConstants.TESTS_FROM_APPLICATION && usFeatureIsNotBlank && usApplicationIsNotBlank) {
                result.add(promotedUserStory.User_Story__r.US_Feature__r.Application__c);
            }
        }
        return result;
    }

    private Actions.RunTestRequest prepareRequest(List<Id> contextIds, Automation_Rule__c automationRule, Id actionId) {
        Actions.RunTestRequest request = new Actions.RunTestRequest();
        request.tool = automationRule.Quality_Gate_Rule_Condition__r.Extension_Configuration__r.ExtensionTool__c;
        request.contextIds = contextIds;
        request.extensionConfigurationId = automationRule.Quality_Gate_Rule_Condition__r.Extension_Configuration__c;
        request.acceptanceCriteria = automationRule.Quality_Gate_Rule_Condition__r.AcceptanceCriteria__c;
        request.actionCallback = automationRule.Automated_Action_Callback__c;
        request.environmentId = getEnvironment();

        RunTestOtherInformation otherInformation = new RunTestOtherInformation();
        otherInformation.qualityCheck = automationRule.Quality_Gate_Rule_Condition__c;
        otherInformation.parentContextId = actionId;
        otherInformation.parentJobExecutionId = context.automationEvents[0].Job_Execution_Id__c;
        request.otherInformation = JSON.serialize(otherInformation);
        return request;
    }

    // WRAPPER
    private class ExecutionRequestData {
        private JobExecution__c jobExecution;
    }

    private class JobPayload {
        private String promotionId;
    }
}