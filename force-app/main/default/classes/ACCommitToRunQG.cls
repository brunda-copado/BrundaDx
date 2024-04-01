public with sharing virtual class ACCommitToRunQG extends ACPromotionToRunQG {
    // PROTECTED

    protected override AutomationConnector createConnector(Actions.RunTestRequest request) {
        ACCommitToRunQG connector = new ACCommitToRunQG();
        connector.request = request;
        return connector;
    }

    protected override Map<Id, List<Id>> getContextIds(String bringTestsFrom) {
        Map<Id, List<Id>> result = new Map<Id, List<Id>>();
        User_Story_Commit__c userStoryCommit = (User_Story_Commit__c) actionRecord;
        result.put(actionId, contextIds(userStoryCommit, bringTestsFrom));
        return result;
    }

    protected override String getEnvironment() {
        Id result;
        if (!context.automationEvents.isEmpty()) {
            result = context.automationEvents[0].Environment_Id__c;
        }

        return result;
    }

    protected override String automatedActionName() {
        return Label.Execute_Quality_Gate;
    }

    protected override String getActionId() {
        Id result;

        if (!context.automationEvents.isEmpty()) {
            ExecutionRequestData data = (ExecutionRequestData) JSON.deserialize(
                context.automationEvents[0].Action_Result__c,
                ExecutionRequestData.class
            );
            result = data.userStorycommit?.Id;
        }

        return result;
    }

    protected override sObject getActionRecord() {
        return getUserStoryCommit(getActionId());
    }

    protected override Boolean assertQualityRuleIsMatching() {
        User_Story_Commit__c userStoryCommit = (User_Story_Commit__c) actionRecord;
        if (userStoryCommit.Status__c == CommitConstants.STATUS_NO_CHANGES) {
            return false;
        }
        Quality.MatchingRulesRequest qualityRequest = new Quality.MatchingRulesRequest();
        qualityRequest.action = ActionConstants.COMMIT_ACTION;
        qualityRequest.pipeline = new FindPipeline().fromObject(userStoryCommit.User_Story__r);
        qualityRequest.platform = userStoryCommit.User_Story__r.Platform__c;
        qualityRequest.templateName = new ActionTemplate(ActionConstants.COMMIT_ACTION).userStory(userStoryCommit.User_Story__r).getApiName();
        qualityRequest.environment = userStoryCommit.User_Story__r.Environment__c;
        qualityRequest.metadataChanges = getMetadata();
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
    private User_Story_Commit__c getUserStoryCommit(Id commitId) {
        return [
            SELECT
                Status__c,
                User_Story__c,
                User_Story__r.US_Feature__c,
                User_Story__r.US_Feature__r.Application__c,
                User_Story__r.Project__r.Deployment_Flow__c,
                User_Story__r.Release__r.Project__r.Deployment_Flow__c,
                User_Story__r.Platform__c,
                User_story__r.Environment__c
            FROM User_Story_Commit__c
            WHERE Id = :commitId
            WITH USER_MODE
            LIMIT 1
        ];
    }

    private List<Id> contextIds(User_Story_Commit__c userStoryCommit, String bringTestsFrom) {
        List<Id> result = new List<Id>();

        Boolean usFeatureIsNotBlank = String.isNotBlank(userStoryCommit.User_Story__r.US_Feature__c);
        Boolean usApplicationIsNotBlank = String.isNotBlank(userStoryCommit.User_Story__r.US_Feature__r.Application__c);

        if (bringTestsFrom == QualityGateConstants.TESTS_FROM_USER_STORY) {
            result.add(userStoryCommit.User_Story__c);
        } else if (bringTestsFrom == QualityGateConstants.TESTS_FROM_FEATURE && usFeatureIsNotBlank) {
            result.add(userStoryCommit.User_Story__r.US_Feature__c);
        } else if (bringTestsFrom == QualityGateConstants.TESTS_FROM_APPLICATION && usFeatureIsNotBlank && usApplicationIsNotBlank) {
            result.add(userStoryCommit.User_Story__r.US_Feature__r.Application__c);
        }

        return result;
    }

    private List<User_Story_Metadata__c> getMetadata() {
        List<Actions.CommitChange> changes = getListOfChangesFromFile();
        List<User_Story_Metadata__c> result = new List<User_Story_Metadata__c>();
        for (Actions.CommitChange change : changes) {
            result.add(new User_Story_Metadata__c(ModuleDirectory__c = change.m, Type__c = change.t, Metadata_API_Name__c = change.n));
        }
        return result;
    }

    private List<Actions.CommitChange> getListOfChangesFromFile() {
        List<Actions.CommitChange> result = new List<Actions.CommitChange>();
        if (!context.automationEvents.isEmpty()) {
            ExecutionRequestData data = (ExecutionRequestData) JSON.deserialize(
                context.automationEvents[0].Action_Result__c,
                ExecutionRequestData.class
            );
            Id jobExecutionId = data.jobExecution?.Id;
            List<JobExecution__c> jobExecutions = [SELECT DataJson__c FROM JobExecution__c WHERE Id = :jobExecutionId WITH USER_MODE LIMIT 1];
            if (!jobExecutions.isEmpty() && String.isNotBlank(jobExecutions[0].DataJson__c)) {
                JobPayload payload = (JobPayload) JSON.deserialize(jobExecutions[0].DataJson__c, JobPayload.class);
                ContentVersion contentVersion = new ContentVersionsSelector().byId(new Set<Id>{ payload.fileWithSelectedChanges })[0];
                result = (List<Actions.CommitChange>) JSON.deserialize(contentVersion.VersionData.toString(), List<Actions.CommitChange>.class);
            }
        }
        return result;
    }

    // WRAPPER
    private class ExecutionRequestData {
        private JobExecution__c jobExecution;
        private User_Story_Commit__c userStorycommit;
    }

    private class JobPayload {
        private String fileWithSelectedChanges;
    }
}