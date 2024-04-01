@SuppressWarnings('PMD')
public with sharing class JobTemplateService extends PipelineOperationsHelper implements PipelineOperationsInterface {
    private PipelineManagerExtension.PipelineOperationsServiceJobsParameters innerJobParameters;
    private List<Promotion__c> promotions;
    private Set<Id> promotionIds;

    // PUBLIC

    public PipelineManagerExtension.PipelineOperationsServiceJobsResult validation(
        PipelineManagerExtension.PipelineOperationsServiceJobsParameters jobParameters
    ) {
        createPromotionAndPromotedUserStories(jobParameters);
        jobParameters.promotionWrappers = result.promotionWrappers;
        try {
            return commonOperations(jobParameters, true, true, true);
        } catch (Exception ex) {
            throw new PipelineOperationsHelperException(ex.getMessage());
        }
    }

    public PipelineManagerExtension.PipelineOperationsServiceJobsResult createPromotionAndPromotedUserStories(
        PipelineManagerExtension.PipelineOperationsServiceJobsParameters jobParameters
    ) {
        overlayWrapperRecord = jobParameters.overlayWrapperRecord;
        testLevelValue = jobParameters.testLevelValue;
        result = new PipelineManagerExtension.PipelineOperationsServiceJobsResult();
        insertPromotionAndRelations();
        return result;
    }

    public PipelineManagerExtension.PipelineOperationsServiceJobsResult promoteAndDeploy(
        PipelineManagerExtension.PipelineOperationsServiceJobsParameters jobParameters
    ) {
        createPromotionAndPromotedUserStories(jobParameters);
        jobParameters.promotionWrappers = result.promotionWrappers;
        try {
            return commonOperations(jobParameters, true, true);
        } catch (Exception ex) {
            throw new PipelineOperationsHelperException(ex.getMessage());
        }
    }

    public PipelineManagerExtension.PipelineOperationsServiceJobsResult deploy(
        PipelineManagerExtension.PipelineOperationsServiceJobsParameters jobParameters
    ) {
        result = new PipelineManagerExtension.PipelineOperationsServiceJobsResult();
        try {
            return commonOperations(jobParameters, true, true);
        } catch (Exception ex) {
            throw new PipelineOperationsHelperException(ex.getMessage());
        }
    }

    public PipelineManagerExtension.PipelineOperationsServiceJobsResult commonOperations(
        PipelineManagerExtension.PipelineOperationsServiceJobsParameters jobParameters,
        Boolean isPromoteAndDeploy,
        Boolean checkPromotionStatus
    ) {
        return commonOperations(jobParameters, isPromoteAndDeploy, checkPromotionStatus, false);
    }

    public PipelineManagerExtension.PipelineOperationsServiceJobsResult commonOperations(
        PipelineManagerExtension.PipelineOperationsServiceJobsParameters jobParameters,
        Boolean isPromoteAndDeploy,
        Boolean checkPromotionStatus,
        Boolean dryRun
    ) {
        innerJobParameters = jobParameters;
        updatePromotions();
        promotions = new PromotionsSelector().promotionsDetailsForPromoteAndDeployActions(promotionIds);

        populateVariables();
        if (checkPromotionStatus) {
            checkPromotionsStatuses();
            result.enabledPromotionBackPromotionPoller = true;
        }
        return result;
    }

    // PRIVATE

    private void insertPromotionAndRelations() {
        Set<Id> usIds = new Set<Id>();
        Set<Id> releaseIds = new Set<Id>();
        for (BranchManagementExtension.UserStoryWrapper userStoryWrapperItem : overlayWrapperRecord.userStories) {
            if (userStoryWrapperItem.isSelected) {
                usIds.add(userStoryWrapperItem.userStory.Id);
                releaseIds.add(userStoryWrapperItem.userStory.Release__c);
            }
        }

        if (usIds.isEmpty()) {
            throw new PipelineOperationsHelperException(Label.No_User_Stories_selected);
        }

        try {
            Map<Id, Map<Id, List<User_Story__c>>> userStoriesByReleaseAndProject = getUserStoriesByReleaseAndProject(usIds);

            Boolean isBackPromotion = overlayWrapperRecord.pathType.toLowerCase() == C_PULL;

            fflib_ISObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
                new List<Schema.SObjectType>{ Promotion__c.sObjectType, Promoted_User_Story__c.sObjectType }
            );

            List<Promotion__c> promotions = new List<Promotion__c>();
            for (Id projectId : userStoriesByReleaseAndProject.keySet()) {
                Map<Id, List<User_Story__c>> userStoriesByReleaseId = userStoriesByReleaseAndProject.get(projectId);
                for (Id releaseId : userStoriesByReleaseId.keySet()) {
                    List<User_Story__c> userStories = userStoriesByReleaseId.get(releaseId);
                    if (!userStories.isEmpty()) {
                        Promotion__c promotion = new Promotion__c(
                            Project__c = projectId,
                            Release__c = releaseId,
                            Back_Promotion__c = isBackPromotion
                        );
                        if (isBackPromotion) {
                            promotion.Destination_Environment__c = overlayWrapperRecord.toEnvId;
                        } else {
                            promotion.Source_Environment__c = overlayWrapperRecord.fromEnvId;
                        }
                        promotions.add(promotion);
                        uow.registerNew(promotion);
                        for (User_Story__c userStory : userStories) {
                            Promoted_User_Story__c promotedUserStory = new Promoted_User_Story__c(
                                Name = promotion.Back_Promotion__c
                                    ? PromotionConstants.BACK_PROMOTED_USER_STORY + userStory.Name
                                    : PromotionConstants.PROMOTED_USER_STORY + userStory.Name,
                                Promotion__c = promotion.Id,
                                User_Story__c = userStory.Id
                            );
                            uow.registerNew(promotedUserStory, Promoted_User_Story__c.Promotion__c, promotion);
                        }
                    }
                }
            }

            uow.commitWork();

            Set<Id> promotionIds = new Map<Id, Promotion__c>(promotions).keySet();
            getPendingPromotions(promotionIds);
        } catch (Exception ex) {
            throw new PipelineOperationsHelperException(ex.getMessage());
        }
    }

    private void updatePromotions() {
        promotions = new List<Promotion__c>();
        promotionIds = new Set<Id>();
        for (PipelineManagerExtension.PromotionWrapper promotionItem : innerJobParameters.promotionWrappers) {
            if (promotionItem.isSelected && promotionItem.promotion.Status__c != COMPLETED) {
                promotionItem.promotion.Status__c = IN_PROGRESS;
                promotions.add(promotionItem.promotion);
                promotionIds.add(promotionItem.promotion.Id);
            }
        }

        PromotionTriggerHelper.bypassPromotionTrigger = true;
        SObjectAccessDecision promotionDecision = Security.stripInaccessible(AccessType.UPDATABLE, promotions);
        update promotionDecision.getRecords();
        promotions.clear();
    }

    private void populateVariables() {
        testLevelValuesByPromotionIds = new Map<String, String>();
        for (Promotion__c promotionRecord : promotions) {
            testLevelValuesByPromotionIds.put(promotionRecord.Id, '');
        }
    }

    private Map<Id, Map<Id, List<User_Story__c>>> getUserStoriesByReleaseAndProject(Set<Id> usIds) {
        Map<Id, Map<Id, List<User_Story__c>>> result = new Map<Id, Map<Id, List<User_Story__c>>>();

        for (User_Story__c userStory : new UserStoriesSelector().byIds(usIds)) {
            String projectId = String.isNotBlank(userStory.Project__c) ? userStory.Project__c : userStory.Release__r.Project__c;
            String releaseId = userStory.Release__c;

            if (!result.containsKey(projectId)) {
                result.put(projectId, new Map<Id, List<User_Story__c>>());
            }
            Map<Id, List<User_Story__c>> userStoriesByReleaseId = result.get(projectId);
            if (!userStoriesByReleaseId.containsKey(releaseId)) {
                userStoriesByReleaseId.put(releaseId, new List<User_Story__c>());
            }
            List<User_Story__c> userStories = userStoriesByReleaseId.get(releaseId);
            userStories.add(userStory);
        }

        return result;
    }
}