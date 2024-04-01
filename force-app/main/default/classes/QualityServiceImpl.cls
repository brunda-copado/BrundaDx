@SuppressWarnings('PMD.CyclomaticComplexity')
public inherited sharing class QualityServiceImpl {
    @TestVisible
    private static final String BEFORE = 'Before';
    private static final String TEST_TYPE = 'Test';

    // PUBLIC

    public static Quality.MatchingRulesResult matchingRules(Quality.MatchingRulesRequest request) {
        Quality.MatchingRulesResult result = new Quality.MatchingRulesResult();
        result.qualityGates = new List<Quality_Gate_Rule_Condition__c>();

        Map<Id, Quality_Gate_Rule_Condition__c> conditionByRuleId = new QualityGateRuleConditionMatcher(request).execute();
        if (!conditionByRuleId.isEmpty()) {
            Map<Id, Quality_Gate_Rule__c> ruleById = new Map<Id, Quality_Gate_Rule__c>(
                new QualityGateRulesSelector().byId(conditionByRuleId.keyset())
            );

            for (Quality_Gate_Rule_Condition__c condition : conditionByRuleId.values()) {
                condition.Quality_Gate_Rule__r = ruleById.get(condition.Quality_Gate_Rule__c);
            }
            result.qualityGates.addAll(conditionByRuleId.values());
        }

        return result;
    }

    public static Quality.StepsResult steps(Quality.StepsRequest request) {
        Quality.StepsResult result = new Quality.StepsResult();
        result.steps = new List<Jobs.ExecutionStep>();

        assertRequest(request);

        Map<Id, Quality_Gate_Rule_Condition__c> conditionByRuleId = new QualityGateRuleConditionMatcher(request).execute();
        if (!conditionByRuleId.isEmpty()) {
            List<Quality_Gate_Rule__c> rules = new QualityGateRulesSelector().byId(conditionByRuleId.keyset());
            result.steps.addAll(asSteps(request, rules, conditionByRuleId));
        }

        return result;
    }

    // PRIVATE

    private static void assertRequest(Quality.StepsRequest request) {
        if (String.isBlank(request.pipeline) && String.isBlank(request.platform) && String.isBlank(request.environment)) {
            throw new ApplicationException(Label.InValidQualityGateContext);
        }
    }

    private static List<Jobs.ExecutionStep> asSteps(
        Quality.StepsRequest request,
        List<Quality_Gate_Rule__c> rules,
        Map<Id, Quality_Gate_Rule_Condition__c> conditionByRuleId
    ) {
        List<Jobs.ExecutionStep> result = new List<Jobs.ExecutionStep>();

        Jobs.ExecutionStep preSteps = new Jobs.ExecutionStep();
        preSteps.sequence = BEFORE;
        preSteps.steps = new List<JobStep__c>();

        for (Quality_Gate_Rule__c rule : rules) {
            switch on rule.Execution_sequence__c {
                when 'Before' {
                    preSteps.steps.add(asStep(request, rule, conditionByRuleId.get(rule.id)));
                }
            }
        }

        if (!preSteps.steps.isEmpty()) {
            result.add(preSteps);
        }

        return result;
    }

    private static JobStep__c asStep(Quality.StepsRequest request, Quality_Gate_Rule__c rule, Quality_Gate_Rule_Condition__c condition) {
        return new JobStep__c(
            ConfigJson__c = configJson(request, rule, condition),
            Type__c = TEST_TYPE,
            CustomType__c = TEST_TYPE,
            Name = rule.Name,
            Quality_Gate_Rule__c = rule.Id,
            Quality_Gate_Rule_Condition__c = condition?.Id
        );
    }

    private static String configJson(Quality.StepsRequest request, Quality_Gate_Rule__c rule, Quality_Gate_Rule_Condition__c condition) {
        TestJobStep.ConfigJson result = new TestJobStep.ConfigJson();

        result.type = rule.Tool__c;
        result.environmentId = request.environment;
        result.propertiesOverride = rule.dataJson__c;
        if (request.contextIds != null) {
            result.contextIds = getContextIdsFrom(request.contextIds, condition.Tests_From__c);
        }

        return JSON.serialize(result);
    }

    private static List<Id> getContextIdsFrom(List<Id> userStoriesIds, String bringTestsFrom) {
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
}