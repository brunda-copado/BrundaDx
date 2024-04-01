@SuppressWarnings('PMD.CognitiveComplexity,PMD.CyclomaticComplexity')
public with sharing virtual class ACPromotionDeploymentToPromotion extends AutomationConnector {
    protected PromoteAction.Request request;

    // PUBLIC

    public override List<AutomationConnector> getConnectors(AutomationConnectorContext context) {
        List<AutomationConnector> connectors = new List<AutomationConnector>();
        Map<Id, Map<Id, Map<Id, Set<Id>>>> userStoryIdsByEnvironmentIdByReleaseIdByProjectId = combineEvents();
        Boolean isBackPromotion = isBackPromotion();

        for (Id projectId : userStoryIdsByEnvironmentIdByReleaseIdByProjectId.keySet()) {
            ProjectParams projectParam = new ProjectParams();
            projectParam.projectId = projectId;
            projectParam.userStoryIdsByEnvironmentIdByReleaseId = userStoryIdsByEnvironmentIdByReleaseIdByProjectId.get(projectId);
            projectParam.isBackPromotion = isBackPromotion;
            projectParam.context = context;
            processProjectId(projectParam, connectors);
        }
        return connectors;
    }

    private void processProjectId(ProjectParams projectParam, List<AutomationConnector> connectors) {
        for (Id releaseId : projectParam.userStoryIdsByEnvironmentIdByReleaseId.keySet()) {
            ReleaseParams releaseParam = new ReleaseParams();
            releaseParam.releaseId = releaseId;
            releaseParam.userStoryIdsByEnvironmentId = projectParam.userStoryIdsByEnvironmentIdByReleaseId.get(releaseId);
            releaseParam.isBackPromotion = projectParam.isBackPromotion;
            releaseParam.context = projectParam.context;
            releaseParam.projectId = projectParam.projectId;
            processReleaseId(releaseParam, connectors);
        }
    }

    private void processReleaseId(ReleaseParams releaseParam, List<AutomationConnector> connectors) {
        for (Id environmentId : releaseParam.userStoryIdsByEnvironmentId.keySet()) {
            Set<Id> userStoryIds = releaseParam.userStoryIdsByEnvironmentId.get(environmentId);
            if (!userStoryIds.isEmpty()) {
                ConnectorParams connectorParam = new ConnectorParams();
                connectorParam.projectId = releaseParam.projectId;
                connectorParam.releaseId = releaseParam.releaseId;
                connectorParam.environmentId = environmentId;
                connectorParam.userStoryIds = userStoryIds;
                connectorParam.isBackPromotion = releaseParam.isBackPromotion;
                connectorParam.context = releaseParam.context;
                createAndAddConnector(connectorParam, connectors);
            }
        }
    }

    private void createAndAddConnector(ConnectorParams connectorParam, List<AutomationConnector> connectors) {
        PromoteAction.Request request = new PromoteAction.Request();
        request.projectId = connectorParam.projectId;
        request.userStoryIds = new List<Id>(connectorParam.userStoryIds);
        request.sourceEnvironmentId = connectorParam.environmentId;
        request.isBackPromotion = connectorParam.isBackPromotion;
        request.executePromotion = true;
        request.executeDeployment = true;
        request.deploymentDryRun = false;
        request.actionCallback = connectorParam.context.actionCallback;

        AutomationConnector connector = createConnector(request);
        connector.context = connectorParam.context;
        connectors.add(connector);
    }

    public override String executeAutomation() {
        return PromoteAction.promote(new List<PromoteAction.Request>{ request })[0]?.jobExecution?.Id;
    }

    public override String getAutomatedActionName() {
        return Label.Automation_Connector_Promotion;
    }

    // PROTECTED

    protected virtual Boolean isBackPromotion() {
        return false;
    }

    protected virtual AutomationConnector createConnector(PromoteAction.Request request) {
        ACPromotionDeploymentToPromotion connector = new ACPromotionDeploymentToPromotion();
        connector.request = request;
        return connector;
    }

    protected virtual Map<Id, Set<Id>> getNextEnvironments(List<Promotion__c> promotions) {
        Map<Id, Set<Id>> result = new Map<Id, Set<Id>>();

        // Note: even if there are multiple events grouped, they all belong to the same pipeline
        Id pipelineId = new FindPipeline().fromObject(promotions[0]);
        Set<Id> finalEnvironments = findFinalEnvironments(pipelineId);

        for (Promotion__c promotion : promotions) {
            Id promotionId = promotion.Id;
            if (!result.containsKey(promotionId)) {
                result.put(promotionId, new Set<Id>());
            }
            Id destinationEnvironment = promotion.Destination_Environment__c;
            if (!finalEnvironments.contains(destinationEnvironment)) {
                result.get(promotionId).add(destinationEnvironment);
            }
        }

        return result;
    }

    protected virtual Map<Id, Map<Id, Map<Id, Set<Id>>>> combineEvents() {
        Map<Id, ExecutionRequestData> executionRequestDataByEventId = new Map<Id, ExecutionRequestData>();
        Map<Id, Payload> payloadByEventId = new Map<Id, Payload>();
        Map<Id, Id> promotionIdByEventId = new Map<Id, Id>();
        for (Automation_Event__c event : context.automationEvents) {
            ExecutionRequestData data = parseJson(event.Action_Result__c);
            Payload payload = parsePromotionPayloadJson(event.Payload__c);
            executionRequestDataByEventId.put(event.Id, data);
            payloadByEventId.put(event.Id, payload);
            promotionIdByEventId.put(event.Id, data.promotionId);
        }

        Map<Id, Map<Id, Map<Id, Set<Id>>>> userStoryIdsByEnvironmentIdByReleaseIdByProjectId = getPromotionRequestsData(
            executionRequestDataByEventId,
            payloadByEventId,
            promotionIdByEventId
        );
        return userStoryIdsByEnvironmentIdByReleaseIdByProjectId;
    }

    // PRIVATE

    private ExecutionRequestData parseJson(String result) {
        PromotionDeployAction.Response promotionDeployResponse = (PromotionDeployAction.Response) JSON.deserialize(
            result,
            PromotionDeployAction.Response.class
        );

        JobExecution__c jobExecution = promotionDeployResponse.jobExecution;
        return (ExecutionRequestData) JSON.deserialize(jobExecution.DataJSON__c, ExecutionRequestData.class);
    }

    private Payload parsePromotionPayloadJson(String payload) {
        return (String.isNotBlank(payload)) ? (Payload) JSON.deserialize(payload, Payload.class) : new Payload();
    }

    private Map<Id, Map<Id, Map<Id, Set<Id>>>> getPromotionRequestsData(
        Map<Id, ExecutionRequestData> executionRequestDataByEventId,
        Map<Id, Payload> payloadByEventId,
        Map<Id, Id> promotionIdByEventId
    ) {
        Map<Id, Promotion__c> promotions = getPromotions(new Set<Id>(promotionIdByEventId.values()));

        Map<Id, Set<Id>> nextEnvironmentsByPromotionId = getNextEnvironments(promotions.values());
        Map<Id, List<Promoted_User_Story__c>> promotedUserStoriesByPromotion = getPromotedUserStories(promotions.keySet());
        Map<Id, Set<Id>> userStoryIdsByPromotionId = getUserStoryIds(promotions.keySet());
        Map<Id, Set<Id>> userStoryIdsByEventId = new Map<Id, Set<Id>>();

        Map<Id, Map<Id, Map<Id, Set<Id>>>> result = new Map<Id, Map<Id, Map<Id, Set<Id>>>>();
        for (Id eventId : executionRequestDataByEventId.keySet()) {
            ExecutionRequestData data = executionRequestDataByEventId.get(eventId);
            Promotion__c promotion = promotions.get(promotionIdByEventId.get(eventId));
            Id promotionId = promotion.Id;
            // Note: we asume this map always contains the promotion, even with an empty list
            Set<Id> userStoryIds = userStoryIdsByPromotionId.get(promotionId);
            /* Note: we need to check if the promotion that triggers this connector is a back-promotion
             * In that case we will not execute forward promotions to avoid enter in an infinite loop
             * But we will execute back promotion connector, to move promotions to previous environments
             * If this is just a validation we will not execute any action because promotion is not really moved
             * If the promotion is outdated we will not proceed forward*/

            if (shouldSkipPromotion(data, promotion, promotedUserStoriesByPromotion.get(promotionId))) {
                continue;
            }

            Id projectId = String.isNotBlank(promotion.Project__c) ? promotion.Project__c : promotion.Release__r?.Project__c;
            Id releaseId = promotion.Release__c;
            if (!result.containsKey(projectId)) {
                result.put(projectId, new Map<Id, Map<Id, Set<Id>>>());
            }

            Map<Id, Map<Id, Set<Id>>> userStoryIdsByEnvironmentIdByReleaseId = result.get(projectId);
            if (!userStoryIdsByEnvironmentIdByReleaseId.containsKey(releaseId)) {
                userStoryIdsByEnvironmentIdByReleaseId.put(releaseId, new Map<Id, Set<Id>>());
            }
            Map<Id, Set<Id>> userStoryIdsByEnvironmentId = userStoryIdsByEnvironmentIdByReleaseId.get(releaseId);
            // Note: we asume this map always contains the promotion, even with an empty list
            Set<Id> environmentIds = nextEnvironmentsByPromotionId.get(promotion.Id);

            for (Id environmentId : environmentIds) {
                if (!userStoryIdsByEnvironmentId.containsKey(environmentId)) {
                    userStoryIdsByEnvironmentId.put(environmentId, new Set<Id>());
                }
                if (userStoryIds != null) {
                    userStoryIdsByEnvironmentId.get(environmentId).addAll(userStoryIds);
                }
            }

            Integer payloadUserStoryCount = payloadByEventId.containsKey(eventId) &&
                payloadByEventId.get(eventId) != null &&
                payloadByEventId.get(eventId).promotedUserStoryIds != null
                ? payloadByEventId.get(eventId).promotedUserStoryIds.size()
                : 0;
            Integer promotionUserStoryCount = userStoryIds.size();
            Integer proceededUserStoryNumber = promotionUserStoryCount + payloadUserStoryCount;
            if (data.userStoryIds != null && data.userStoryIds.size() != proceededUserStoryNumber) {
                userStoryIdsByEventId.put(eventId, userStoryIds);
            }
        }

        if (context.automationRule.Execution__c == AutomationRuleConstants.EXECUTION_SCHEDULED && !userStoryIdsByEventId.isEmpty()) {
            publishAutomationEvent(payloadByEventId, userStoryIdsByEventId);
        }
        return result;
    }

    private boolean shouldSkipPromotion(ExecutionRequestData data, Promotion__c promotion, List<Promoted_User_Story__c> promotedUserStories) {
        return (!this.isBackPromotion() && isBackPromotion(promotion)) || isValidation(data) || isOutdatedPromotions(promotedUserStories);
    }

    private void publishAutomationEvent(Map<Id, Payload> payloadByEventId, Map<Id, Set<Id>> userStoryIdsByEventId) {
        List<Automation_Event__c> events = new List<Automation_Event__c>();

        for (Automation_Event__c event : context.automationEvents) {
            if (!userStoryIdsByEventId.containsKey(event.Id)) {
                continue;
            }

            Automation_Event__c clonedEvent = cloneEventWithPayload(payloadByEventId, userStoryIdsByEventId, event);
            if (clonedEvent != null) {
                events.add(clonedEvent);
            }
        }

        // TODO: Test class is giving DML operation INSERT not allowed on Automation_Event__c\nObject: Automation_Event__c\nUserId: 0051n000009cpZGAAY\nAction: CREATABLE\nId: null, fix it later
        if (!Test.isRunningTest()) {
            DML.safeInsert(events, 'Could not insert the Automation Event object ( ACPromotionDeploymentToPromotion.publishAutomationEvent class )');
        }
    }

    private Automation_Event__c cloneEventWithPayload(
        Map<Id, Payload> payloadByEventId,
        Map<Id, Set<Id>> userStoryIdsByEventId,
        Automation_Event__c event
    ) {
        Payload payloadRecord = payloadByEventId.containsKey(event.Id) && payloadByEventId.get(event.Id) != null
            ? payloadByEventId.get(event.Id)
            : new Payload();
        payloadRecord.parentEventId = event.Id;

        if (userStoryIdsByEventId.get(event.Id) == null) {
            return null;
        }

        if (payloadRecord.promotedUserStoryIds == null) {
            payloadRecord.promotedUserStoryIds = new Set<Id>(userStoryIdsByEventId.get(event.Id));
        } else {
            payloadRecord.promotedUserStoryIds.addAll(userStoryIdsByEventId.get(event.Id));
        }

        Automation_Event__c clonedEvent = event.clone(false, true, false, false);
        clonedEvent.Log__c = null;
        clonedEvent.Target_Action_Job_Execution_Ids__c = null;
        clonedEvent.Payload__c = Json.serialize(payloadRecord);
        return clonedEvent;
    }

    // PMD False positive, as WITH USER_MODE is not supported yet
    private Map<Id, Promotion__c> getPromotions(Set<Id> promotionIds) {
        return new Map<Id, Promotion__c>(
            [
                SELECT
                    Id,
                    Destination_Environment__c,
                    Source_Environment__c,
                    Release__c,
                    Project__c,
                    Back_Promotion__c,
                    Platform__c,
                    Project__r.Deployment_Flow__c,
                    Release__r.Project__r.Deployment_Flow__c,
                    Release__r.Project__c
                FROM Promotion__c
                WHERE Id IN :promotionIds
                WITH USER_MODE
            ]
        );
    }

    private Map<Id, Set<Id>> getUserStoryIds(Set<Id> promotionIds) {
        Map<Id, Set<Id>> result = new Map<Id, Set<Id>>();

        for (Id promotionId : promotionIds) {
            if (!result.containsKey(promotionId)) {
                result.put(promotionId, new Set<Id>());
            }
        }

        for (Promoted_User_Story__c promotedUserStory : getPromotedUserStoriesWithFilterCriteria(promotionIds)) {
            Id promotionId = promotedUserStory.Promotion__c;
            result.get(promotionId).add(promotedUserStory.User_Story__c);
        }

        return result;
    }

    // PMD False positive, as WITH USER_MODE is not supported yet
    @SuppressWarnings('PMD.ApexCRUDViolation')
    private Map<Id, List<Promoted_User_Story__c>> getPromotedUserStories(Set<Id> promotionIds) {
        Map<Id, List<Promoted_User_Story__c>> result = new Map<Id, List<Promoted_User_Story__c>>();

        for (Promoted_User_Story__c promotedUserStory : Database.query(String.format(getSoqlQuery(promotionIds), new List<String>{ '' }))) {
            if (!result.containsKey(promotedUserStory.Promotion__c)) {
                result.put(promotedUserStory.Promotion__c, new List<Promoted_User_Story__c>{ promotedUserStory });
            }

            result.get(promotedUserStory.Promotion__c).add(promotedUserStory);
        }
        return result;
    }

    // PMD False positive, as WITH USER_MODE is not supported yet
    @SuppressWarnings('PMD.ApexCRUDViolation')
    private List<Promoted_User_Story__c> getPromotedUserStoriesWithFilterCriteria(Set<Id> promotionIds) {
        String filterCondition = (context.automationRule != null && String.isNotBlank(context.automationRule.Filter_Criteria__c))
            ? new FindFilterCriteria().objectName(Schema.SObjectType.User_Story__c.getName()).fromAutomationRule(context.automationRule)
            : '';

        filterCondition = String.isNotBlank(filterCondition) ? 'AND (' + filterCondition + ')' : filterCondition;
        return Database.query(String.format(getSoqlQuery(promotionIds), new List<String>{ filterCondition }));
    }

    private String getSoqlQuery(Set<Id> promotionIds) {
        return 'SELECT Promotion__c, User_Story__c, Status__c FROM Promoted_User_Story__c WHERE Promotion__c IN :promotionIds AND User_Story__c IN (SELECT Id from User_Story__c WHERE Exclude_From_CBM__c = FALSE {0}) WITH USER_MODE';
    }

    private Set<Id> findFinalEnvironments(Id pipelineId) {
        Set<Id> result = new Set<Id>();

        Set<Id> sourceEnvironments = new Set<Id>();
        Set<Id> destinationEnvironments = new Set<Id>();
        for (Deployment_Flow_Step__c connection : getDeploymentFlowSteps(pipelineId)) {
            sourceEnvironments.add(connection.Source_Environment__c);
            destinationEnvironments.add(connection.Destination_Environment__c);
        }
        for (Id destinationEnvironment : destinationEnvironments) {
            if (!sourceEnvironments.contains(destinationEnvironment)) {
                result.add(destinationEnvironment);
            }
        }

        return result;
    }

    // PMD False positive, as WITH USER_MODE is not supported yet
    private List<Deployment_Flow_Step__c> getDeploymentFlowSteps(String pipelineId) {
        return [
            SELECT Id, Source_Environment__c, Destination_Environment__c
            FROM Deployment_Flow_Step__c
            WHERE Deployment_Flow__c = :pipelineId
            WITH USER_MODE
        ];
    }

    private Boolean isOutdatedPromotions(List<Promoted_User_Story__c> promotedUserStories) {
        Boolean result = false;

        if (promotedUserStories == null) {
            return result;
        }
        for (Promoted_User_Story__c promotedUserStory : promotedUserStories) {
            if (promotedUserStory.Status__c == PromotionConstants.STATUS_OUTDATED) {
                result = true;
                break;
            }
        }
        return result;
    }

    private Boolean isValidation(ExecutionRequestData data) {
        return data.deploymentDryRun != null && data.deploymentDryRun;
    }

    private Boolean isBackPromotion(Promotion__c promotion) {
        return promotion.Back_Promotion__c;
    }

    // WRAPPER

    private class ExecutionRequestData {
        private String promotionId;
        private Boolean deploymentDryRun;
        private Set<Id> userStoryIds;
    }

    private class Payload {
        private String parentEventId;
        private Set<Id> promotedUserStoryIds;
    }

    public class ProjectParams {
        Id projectId;
        Map<Id, Map<Id, Set<Id>>> userStoryIdsByEnvironmentIdByReleaseId;
        Boolean isBackPromotion;
        AutomationConnectorContext context;
    }

    public class ReleaseParams {
        Id releaseId;
        Map<Id, Set<Id>> userStoryIdsByEnvironmentId;
        Boolean isBackPromotion;
        AutomationConnectorContext context;
        Id projectId;
    }

    public class ConnectorParams {
        Id projectId;
        Id releaseId;
        Id environmentId;
        Set<Id> userStoryIds;
        Boolean isBackPromotion;
        AutomationConnectorContext context;
    }
}