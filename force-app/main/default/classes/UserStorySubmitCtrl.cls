public with sharing class UserStorySubmitCtrl {
    @AuraEnabled
    public static SubmitData getData(Id userStoryId) {
        try {
            SubmitData result = new SubmitData();
            List<User_Story__c> userStories = new UserStoriesSelector().byIdsForMulticloud(new Set<Id>{ userStoryId });
            if (!userStories.isEmpty()) {
                User_Story__c userStory = userStories[0];
                List<Deployment_Flow_Step__c> pipelineConnections = getPipelineConnections(userStory);
                result.errorList = new UserStorySubmitValidator(userStory).pipelineConnections(pipelineConnections).execute();
                result.userStoryName = userStory.Name;
                result.userStoryReadyToPromote = userStory.Promote_Change__c;
                result.hasLastFailedPromotion = hasLastFailedPromotion(userStory);
                result.pipelineId = new FindPipeline().fromObject(userStory);
                if (result.errorList.isEmpty()) {
                    result.automationRule = getAutomationRule(userStory);
                    result.automationRuleScheduledJobDateTime = getScheduledAutomationDateTime(result.automationRule);
                    setSourceAndDestinationEnvironmentName(userStory, pipelineConnections, result);
                }
            }
            return result;
        } catch (Exception ex) {
            throw new ApplicationException().auraHandled(ex);
        }
    }

    @AuraEnabled
    public static void resubmitUserStory(Id userStoryId) {
        try {
            // Extra step required to enable resubmit user story in case of last failed promotion
            UserStories.bypassTrigger = true;
            udpateUserStory(new User_Story__c(Id = userStoryId, Promote_Change__c = false));
            UserStories.bypassTrigger = false;

            udpateUserStory(new User_Story__c(Id = userStoryId, Promote_Change__c = true));
        } catch (Exception ex) {
            throw new ApplicationException().auraHandled(ex);
        }
    }

    // PRIVATE

    private static List<Deployment_Flow_Step__c> getPipelineConnections(User_Story__c userStory) {
        List<Deployment_Flow_Step__c> result = new List<Deployment_Flow_Step__c>();
        Id pipelineId = new FindPipeline().fromObject(userStory);

        if (pipelineId != null && userStory.Environment__c != null) {
            result = [
                SELECT Id, Source_Environment__c, Source_Environment__r.Name, Destination_Environment__r.Name
                FROM Deployment_Flow_Step__c
                WHERE
                    (Source_Environment__c = :userStory.Environment__c
                    OR Destination_Environment__c = :userStory.Environment__c)
                    AND Deployment_Flow__c = :pipelineId
                WITH USER_MODE
            ];
        }

        return result;
    }

    private static void setSourceAndDestinationEnvironmentName(
        User_Story__c userStory,
        List<Deployment_Flow_Step__c> pipelineConnections,
        SubmitData result
    ) {
        for (Deployment_Flow_Step__c pipelineConnection : pipelineConnections) {
            if (pipelineConnection.Source_Environment__c == userStory.Environment__c) {
                result.sourceEnvironmentName = pipelineConnection.Source_Environment__r.Name;
                result.destinationEnvironmentName = pipelineConnection.Destination_Environment__r.Name;
            }
        }
    }

    private static Automation_Rule__c getAutomationRule(User_Story__c userStory) {
        Actions.MatchAutomationRuleRequest request = new Actions.MatchAutomationRuleRequest();
        request.userStoryId = userStory.Id;

        Actions.MatchAutomationRuleResult result = Actions.SubmitUserStoryService.match(request);
        return result.automationRule;
    }

    // PMD False positive, as WITH USER_MODE is not supported yet
    private static String getScheduledAutomationDateTime(Automation_Rule__c automationRule) {
        String result = '';

        if (automationRule != null && automationRule.Execution__c == 'Scheduled' && automationRule.Scheduled_Job_Id__c != null) {
            for (CronTrigger cronTrigger : [
                SELECT Id, NextFireTime
                FROM CronTrigger
                WHERE Id = :automationRule.Scheduled_Job_Id__c AND NextFireTime != NULL
                WITH USER_MODE
            ]) {
                result = cronTrigger.NextFireTime.format();
            }
        }
        return result;
    }

    // PMD False positive, as WITH USER_MODE is not supported yet
    private static Boolean hasLastFailedPromotion(User_Story__c userStory) {
        List<Promoted_User_Story__c> promotedUserStories = [
            SELECT Id, Promotion__r.Status__c
            FROM Promoted_User_Story__c
            WHERE User_Story__c = :userStory.Id
            AND Promotion__r.Back_Promotion__c = false
            WITH USER_MODE
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        return !promotedUserStories.isEmpty() && promotedUserStories[0].Promotion__r.Status__c == PromotionConstants.STATUS_COMPLETED_WITH_ERRORS;
    }

    private static void udpateUserStory(User_Story__c userStory) {
        DML.safeUpdate(
            userStory,
            String.format(
                Label.ErrorWhileUpdating,
                new List<String>{
                    User_Story__c.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).getLabel(),
                    'UserStorySubmitCtrl.udpateUserStory'
                }
            )
        );
    }

    public with sharing class SubmitData {
        @AuraEnabled
        public String userStoryName;
        @AuraEnabled
        public Boolean userStoryReadyToPromote;
        @AuraEnabled
        public String pipelineId;
        @AuraEnabled
        public String sourceEnvironmentName;
        @AuraEnabled
        public String destinationEnvironmentName;
        @AuraEnabled
        public Automation_Rule__c automationRule;
        @AuraEnabled
        public String automationRuleScheduledJobDateTime;
        @AuraEnabled
        public Boolean hasLastFailedPromotion;
        @AuraEnabled
        public List<String> errorList;
    }
}