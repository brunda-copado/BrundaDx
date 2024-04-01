public with sharing class QualityGate {
    private Request request;

    // CONSTRUCTOR

    public QualityGate(Request request) {
        this.request = request;
    }

    // PUBLIC

    public Response getSteps() {
        assertRequest();

        Map<Id, Quality_Gate_Rule_Condition__c> conditionByRuleId = new QualityGateRuleConditionMatcher(request).execute();
        List<Quality_Gate_Rule__c> rules = new QualityGateRulesSelector().byId(conditionByRuleId.keyset());

        return asSteps(rules, conditionByRuleId);
    }

    // PRIVATE

    private void assertRequest() {
        if (
            String.isBlank(request.stage) &&
            String.isBlank(request.pipelineId) &&
            String.isBlank(request.platform) &&
            String.isBlank(request.environmentId)
        ) {
            throw new ApplicationException(Label.InValidQualityGateContext);
        }
    }

    private Response asSteps(List<Quality_Gate_Rule__c> rules, Map<Id, Quality_Gate_Rule_Condition__c> conditionByRuleId) {
        Response result = new Response();

        for (Quality_Gate_Rule__c rule : rules) {
            switch on rule.Execution_sequence__c {
                when 'Before' {
                    result.preSteps.add(asStep(rule, conditionByRuleId.get(rule.id)));
                }
            }
        }

        return result;
    }

    private JobStep__c asStep(Quality_Gate_Rule__c rule, Quality_Gate_Rule_Condition__c condition) {
        return new JobStep__c(
            ConfigJson__c = configJson(rule, condition),
            Type__c = 'Test',
            CustomType__c = 'Test',
            Name = rule.Name,
            Quality_Gate_Rule__c = rule.Id,
            Quality_Gate_Rule_Condition__c = condition?.Id
        );
    }

    private String configJson(Quality_Gate_Rule__c rule, Quality_Gate_Rule_Condition__c condition) {
        TestJobStep.ConfigJson result = new TestJobStep.ConfigJson();

        result.type = rule.Tool__c;
        result.environmentId = request.environmentId;
        result.propertiesOverride = rule.dataJson__c;
        if (request.contextIds != null) {
            result.contextIds = getContextIdsFrom(request.contextIds, condition.Tests_From__c);
        }

        return JSON.serialize(result);
    }

    private List<Id> getContextIdsFrom(List<Id> userStoriesIds, String bringTestsFrom) {
        Set<Id> result = new Set<Id>();

        if (String.isBlank(bringTestsFrom) || bringTestsFrom == 'User Story') {
            result.addAll(userStoriesIds);
        } else {
            for (User_Story__c userStory : new UserStoriesSelector().byIdsForMulticloud(new Set<Id>(userStoriesIds))) {
                if (bringTestsFrom == 'Feature' && String.isNotBlank(userStory.US_Feature__c)) {
                    result.add(userStory.US_Feature__c);
                } else if (
                    bringTestsFrom == 'Application' &&
                    String.isNotBlank(userStory.US_Feature__c) &&
                    String.isNotBlank(userStory.US_Feature__r.Application__c)
                ) {
                    result.add(userStory.US_Feature__r.Application__c);
                }
            }
        }

        return new List<Id>(result);
    }

    // INNER

    public class Response {
        public List<JobStep__c> preSteps = new List<JobStep__c>();
    }

    public class Request {
        public String stage;
        public String action;
        public Id pipelineId;
        public String platform;
        public String templateName;
        public Id environmentId;
        public List<Id> contextIds;
        public Id fileId;
        public List<User_Story_Metadata__c> metadataChanges;
    }
}