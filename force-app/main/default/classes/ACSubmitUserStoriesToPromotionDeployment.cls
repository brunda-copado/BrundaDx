public with sharing virtual class ACSubmitUserStoriesToPromotionDeployment extends ACPromotionDeploymentToPromotion {
    // PROTECTED

    protected override AutomationConnector createConnector(PromoteAction.Request request) {
        ACSubmitUserStoriesToPromotionDeployment connector = new ACSubmitUserStoriesToPromotionDeployment();
        connector.request = request;
        return connector;
    }

    protected override Map<Id, Map<Id, Map<Id, Set<Id>>>> combineEvents() {
        Map<String, Payload> payloadByuserStoryId = getPayloadByUserStory(context.automationEvents);
        return groupUserStoriesForPromotion(payloadByuserStoryId);
    }

    // PRIVATE

    private Map<String, Payload> getPayloadByUserStory(List<Automation_Event__c> events) {
        Map<String, Payload> result = new Map<String, Payload>();
        for (Automation_Event__c event : events) {
            Payload payload = parsePayloadJson(event.Payload__c);
            if (payload != null) {
                result.put(payload.userStoryId, payload);
            }
        }
        return result;
    }

    // Note: grouping stories by Project -> Release -> Source Environment
    private Map<Id, Map<Id, Map<Id, Set<Id>>>> groupUserStoriesForPromotion(Map<String, Payload> payloadByuserStoryId) {
        Map<Id, Map<Id, Map<Id, Set<Id>>>> result = new Map<Id, Map<Id, Map<Id, Set<Id>>>>();

        for (String userStoryId : readyToPromoteUserStories(payloadByuserStoryId.keyset()).keyset()) {
            Payload payload = payloadByuserStoryId.get(userStoryId);
            Id projectId = payload.projectId;
            Id releaseId = payload.releaseId;
            Id environmentId = payload.environmentId;

            if (!result.containsKey(projectId)) {
                result.put(projectId, new Map<Id, Map<Id, Set<Id>>>());
            }
            Map<Id, Map<Id, Set<Id>>> userStoryIdsByEnvironmentIdByReleaseId = result.get(projectId);
            if (!userStoryIdsByEnvironmentIdByReleaseId.containsKey(releaseId)) {
                userStoryIdsByEnvironmentIdByReleaseId.put(releaseId, new Map<Id, Set<Id>>());
            }
            Map<Id, Set<Id>> userStoryIdsByEnvironmentId = userStoryIdsByEnvironmentIdByReleaseId.get(releaseId);
            if (!userStoryIdsByEnvironmentId.containsKey(environmentId)) {
                userStoryIdsByEnvironmentId.put(environmentId, new Set<Id>());
            }
            userStoryIdsByEnvironmentId.get(environmentId).add(payload.userStoryId);
        }

        return result;
    }

    private Payload parsePayloadJson(String payload) {
        return (String.isNotBlank(payload)) ? (Payload) JSON.deserialize(payload, Payload.class) : null;
    }

    // PMD False positive, as WITH USER_MODE is not supported yet
    @SuppressWarnings('PMD.ApexCRUDViolation')
    private Map<String, User_Story__c> readyToPromoteUserStories(Set<String> userStoryIds) {
        return new Map<String, User_Story__c>([SELECT Id FROM User_Story__c WHERE Id = :userStoryIds AND Promote_Change__c = TRUE WITH USER_MODE]);
    }

    // WRAPPER
    private class Payload {
        private String userStoryId;
        private String environmentId;
        private String projectId;
        private String releaseId;
    }
}