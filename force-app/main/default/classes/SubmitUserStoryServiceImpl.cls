public with sharing class SubmitUserStoryServiceImpl {
    // PUBLIC

    public static Actions.SubmitUserStoryResult submit(Actions.SubmitUserStoryRequest request) {
        Actions.SubmitUserStoryResult result = new Actions.SubmitUserStoryResult();
        List<User_Story__c> userStories = getUserStory(request.userStoryId);

        if (!userStories.isEmpty()) {
            User_Story__c userStory = userStories[0];
            validateUserStorySubmit(userStory);
            markAsReadyToPromote(userStory);
            Automation_Rule__c automationRule = matchAutomationRule(userStory);
            result.automationEvent = automationRule != null ? createAutomationEvent(userStory) : null;
        }

        return result;
    }

    public static Actions.MatchAutomationRuleResult match(Actions.MatchAutomationRuleRequest request) {
        Actions.MatchAutomationRuleResult result = new Actions.MatchAutomationRuleResult();

        if (Schema.SObjectType.Automation_Rule__c.isAccessible()) {
            List<User_Story__c> userStories = getUserStory(request.userStoryId);

            if (!userStories.isEmpty()) {
                result.automationRule = matchAutomationRule(userStories[0]);
                result.userStory = userStories[0];
            }
        }

        return result;
    }

    // PRIVATE

    private static void validateUserStorySubmit(User_Story__c userStory) {
        List<String> errors = new UserStorySubmitValidator(userStory).execute();
        if (!errors.isEmpty()) {
            throw new ApplicationException(toString(errors));
        }
    }

    private static String toString(List<String> errors) {
        return String.join(errors, '\n');
    }

    private static void markAsReadyToPromote(User_Story__c userStory) {
        UserStories.bypassTrigger = true;
        DML.safeUpdate(
            new User_Story__c(Id = userStory.Id, Promote_Change__c = true),
            String.format(
                Label.ErrorWhileUpdating,
                new List<String>{
                    User_Story__c.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).getLabel(),
                    'SubmitUserStoryServiceImpl.markAsReadyToPromote'
                }
            )
        );
        UserStories.bypassTrigger = false;
    }

    private static Automation_Event__c createAutomationEvent(User_Story__c userStory) {
        return new GenerateAutomationEvent(
                ActionConstants.SUBMIT_USER_STORIES,
                AutomationRuleConstants.SOURCE_ACTION_STATUS_SUCCESSFUL,
                new FindPipeline().fromObject(userStory)
            )
            .setEnvironment(userStory.Environment__c)
            .setPayload(getPayload(userStory))
            .execute();
    }

    private static Automation_Rule__c matchAutomationRule(User_Story__c userStory) {
        Automation_Rule__c result;
        Id pipelineId = new FindPipeline().fromObject(userStory);

        for (Automation_Rule__c automationRule : byPipelineAndSubmitUserStoriesAction(pipelineId)) {
            if (scopeMatches(automationRule, userStory) && filterCriteriaMatches(automationRule, userStory)) {
                result = automationRule;
                break;
            }
        }

        return result;
    }

    private static Boolean scopeMatches(Automation_Rule__c automationRule, User_Story__c userStory) {
        return scopeNotDefined(automationRule) || environmentMatches(automationRule, userStory) || stageMatches(automationRule, userStory);
    }

    private static Boolean scopeNotDefined(Automation_Rule__c automationRule) {
        return String.isBlank(automationRule.Stage__c) && String.isBlank(automationRule.Environment__c);
    }

    private static Boolean environmentMatches(Automation_Rule__c automationRule, User_Story__c userStory) {
        return String.isNotBlank(automationRule.Environment__c) && automationRule.Environment__c.containsIgnoreCase(userStory.Environment__c);
    }

    private static Boolean stageMatches(Automation_Rule__c automationRule, User_Story__c userStory) {
        String userStoryStage = userStoryStage(userStory);
        return String.isNotBlank(automationRule.Stage__c) &&
            String.isNotBlank(userStoryStage) &&
            automationRule.Stage__c.containsIgnoreCase(userStoryStage) &&
            (String.isBlank(automationRule.Excluded_Environments__c) ||
            (String.isNotBlank(automationRule.Excluded_Environments__c) &&
            !automationRule.Excluded_Environments__c.containsIgnoreCase(userStory.Environment__c)));
    }

    private static String userStoryStage(User_Story__c userStory) {
        PipelineDescriptor pipelineDescriptor = new PipelineDescriptor(new FindPipeline().fromObject(userStory));
        return pipelineDescriptor.getStageId(userStory.Environment__c);
    }

    private static Boolean filterCriteriaMatches(Automation_Rule__c automationRule, User_Story__c userStory) {
        return filterCriteriaNotDefined(automationRule) || conditionMatches(automationRule, userStory);
    }

    private static Boolean filterCriteriaNotDefined(Automation_Rule__c automationRule) {
        return String.isBlank(automationRule.Filter_Criteria__c);
    }

    private static Boolean conditionMatches(Automation_Rule__c automationRule, User_Story__c userStory) {
        return new MatchAutomationRuleFilterCriteria().conditionMatches(automationRule, userStory);
    }

    @TestVisible
    private static String getPayload(User_Story__c userStory) {
        Payload payload = new Payload();
        payload.userStoryId = userStory.Id;
        payload.environmentId = userStory.Environment__c;
        payload.projectId = userStory.Project__c != null ? userStory.Project__c : userStory.Release__r.Project__c;
        payload.releaseId = userStory.Release__c;
        return JSON.serialize(payload);
    }

    // PMD False positive, as WITH USER_MODE is not supported yet
    @SuppressWarnings('PMD.ApexCRUDViolation')
    private static List<User_Story__c> getUserStory(Id userStoryId) {
        return [
            SELECT
                Id,
                Project__c,
                Environment__c,
                Release__c,
                Release__r.Project__c,
                Project__r.Deployment_Flow__c,
                Release__r.Project__r.Deployment_Flow__c,
                Exclude_From_CBM__c,
                Promote_Change__c
            FROM User_Story__c
            WHERE Id = :userStoryId
            WITH USER_MODE
            LIMIT 1
        ];
    }

    // PMD False positive, as WITH USER_MODE is not supported yet
    @SuppressWarnings('PMD.ApexCRUDViolation')
    private static List<Automation_Rule__c> byPipelineAndSubmitUserStoriesAction(Id pipelineId) {
        return [
            SELECT
                Id,
                Name,
                Automated_Action__c,
                Automation_Connector__c,
                Cron_Expression__c,
                Execution__c,
                Pipeline__c,
                Scheduled_Job_Id__c,
                Source_Action__c,
                Source_Action_Status__c,
                Stage__c,
                Environment__c,
                Excluded_Environments__c,
                Filter_Criteria__c
            FROM Automation_Rule__c
            WHERE Pipeline__c = :pipelineId AND Source_Action__c = :ActionConstants.SUBMIT_USER_STORIES AND Active__c = TRUE
            WITH USER_MODE
        ];
    }

    private class Payload {
        private String userStoryId;
        private String environmentId;
        private String projectId;
        private String releaseId;
    }
}