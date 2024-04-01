public with sharing class RunDeployJobTemplateHandler extends DeployJobTemplateHelper {
    // PUBLIC

    @AuraEnabled
    public static ValidationResponse validate(Id recordId) {
        ValidationResponse response = new ValidationResponse();

        List<Id> currentUserStories = getPromotedUserStories(recordId);
        response.promotedUserStoriesCreated = !currentUserStories.isEmpty();

        if (!response.promotedUserStoriesCreated) {
            return response;
        }
        JobExecution__c promotionJob = promotionJob(recordId);
        if (promotionJob != null) {
            response.promotionJobCompleted = promotionJob.Status__c == 'Successful';

            List<Id> storiesFromPromotionLastJob = getUserStoriesInPayload(promotionJob);
            if (
                new Set<Id>(currentUserStories).containsAll(new Set<Id>(storiesFromPromotionLastJob)) &&
                new Set<Id>(storiesFromPromotionLastJob).containsAll(new Set<Id>(currentUserStories))
            ) {
                response.sameMetadata = true;
            }
        }
        response.removalsConsidered = removalsConsidered(recordId);
        response.hasMetadata = [SELECT COUNT() FROM User_Story_Metadata__c WHERE User_Story__c IN :currentUserStories WITH USER_MODE] > 0;
        response.jobInProgress = jobInProgress(recordId);
        response.promotionIsCancelled = promotionIsCancelled(recordId);

        return response;
    }

    @AuraEnabled
    public static Boolean isJobInProgress(Id recordId) {
        return jobInProgress(recordId);
    }

    @AuraEnabled
    public static void execute(Id recordId, Boolean doNotRunJob, List<Id> deploymentSteps) {
        deploy(recordId, doNotRunJob, deploymentSteps);
    }

    // PRIVATE
    private static List<Id> getPromotedUserStories(Id recordId) {
        List<Id> result = new List<Id>();
        for (Promoted_User_Story__c promotedUserStory : new PromotedUserStoriesSelector().byPromotionId(new Set<Id>{ recordId })) {
            result.add(promotedUserStory.User_Story__c);
        }
        return result;
    }

    private static List<Id> getUserStoriesInPayload(JobExecution__c promotionJob) {
        ExecutionData executionData = (ExecutionData) JSON.deserialize(promotionJob.DataJson__c, ExecutionData.class);
        return executionData.userStoryIds;
    }

    // PMD False positive, as WITH USER_MODE is not supported yet
    @SuppressWarnings('PMD.ApexCRUDViolation')
    private static Boolean removalsConsidered(Id recordId) {
        Map<String, ContentDocumentLink> filesByName = new Map<String, ContentDocumentLink>();
        for (ContentDocumentLink documentLink : [
            SELECT ContentDocument.Title, ContentDocument.ContentModifiedDate
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :recordId
            WITH USER_MODE
        ]) {
            filesByName.put(documentLink.ContentDocument.Title, documentLink);
        }
        ContentDocumentLink ignoredChangesFile = filesByName.get(PromotionConstants.IGNORED_CHANGES_FILE_NAME.substringBefore('.'));
        ContentDocumentLink promotionChangesFile = filesByName.get(PromotionConstants.PROMOTE_FILE_NAME.substringBefore('.'));
        if (
            ignoredChangesFile == null ||
            promotionChangesFile == null ||
            ignoredChangesFile.ContentDocument.ContentModifiedDate < promotionChangesFile.ContentDocument.ContentModifiedDate
        ) {
            return true;
        }
        return false;
    }

    // INNER

    public with sharing class ValidationResponse {
        @AuraEnabled
        public Boolean promotedUserStoriesCreated = false;
        @AuraEnabled
        public Boolean hasMetadata = false;
        @AuraEnabled
        public Boolean jobInProgress = false;
        @AuraEnabled
        public Boolean promotionJobCompleted = false;
        @AuraEnabled
        public Boolean sameMetadata = false;
        @AuraEnabled
        public Boolean removalsConsidered = false;
        @AuraEnabled
        public Boolean promotionIsCancelled = false;
    }

    private with sharing class ExecutionData {
        private Id fileWithSelectedChanges;
        private List<Id> userStoryIds;
    }
}