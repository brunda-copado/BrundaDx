public with sharing class SalesforcePipelineOperationsService extends PipelineOperationsHelper implements PipelineOperationsInterface {

    public PipelineManagerExtension.PipelineOperationsServiceJobsResult validation(
        PipelineManagerExtension.PipelineOperationsServiceJobsParameters jobParameters
    ) {
        createPromotionAndPromotedUserStories(jobParameters);
        jobParameters.promotionWrappers = result.promotionWrappers;
        Boolean hasApexCode = false;
        for (User_Story__c userStoryRecord : selectedUserStories) {
            if (!hasApexCode && userStoryRecord.Has_Apex_Code__c) {
                hasApexCode = true;
            }
            userStoryRecord.Last_Validation_Promotion__c = promotionByUserStoryReleases.get(userStoryRecord.Release__c).Id;
        }
        
        SObjectAccessDecision decision = Security.stripInaccessible(AccessType.UPDATABLE, selectedUserStories);
        update decision.getRecords();
        jobParameters.isCheckOnly = true;
        return deploy(jobParameters);
    }

    public PipelineManagerExtension.PipelineOperationsServiceJobsResult createPromotionAndPromotedUserStories(
        PipelineManagerExtension.PipelineOperationsServiceJobsParameters jobParameters
    ) {
        overlayWrapperRecord = jobParameters.overlayWrapperRecord;
        testLevelValue = jobParameters.testLevelValue;
        result = new PipelineManagerExtension.PipelineOperationsServiceJobsResult();
        preparePromotionAndRelations();
        return result;
    }

    public PipelineManagerExtension.PipelineOperationsServiceJobsResult promoteAndDeploy(
        PipelineManagerExtension.PipelineOperationsServiceJobsParameters jobParameters
    ) {
        createPromotionAndPromotedUserStories(jobParameters);
        jobParameters.promotionWrappers = result.promotionWrappers;
        return deploy(jobParameters);
    }

    public PipelineManagerExtension.PipelineOperationsServiceJobsResult deploy(
        PipelineManagerExtension.PipelineOperationsServiceJobsParameters jobParameters
    ) {
        result = new PipelineManagerExtension.PipelineOperationsServiceJobsResult();
        try {
            testLevelValuesByPromotionIds = new Map<String, String>();
            List<Promotion__c> promotions = new List<Promotion__c>();
            for (PipelineManagerExtension.PromotionWrapper promotionItem : jobParameters.promotionWrappers) {
                if (promotionItem.isSelected && promotionItem.promotion.Status__c != COMPLETED) {
                    promotionItem.promotion.Status__c = SCHEDULED;
                    promotions.add(promotionItem.promotion);
                }
                testLevelValuesByPromotionIds.put(promotionItem.promotion.Id, jobParameters.testLevelValue);
            }
            SObjectAccessDecision decision = Security.stripInaccessible(AccessType.UPDATABLE, promotions);
            update decision.getRecords();
            result.enabledPromotionBackPromotionPoller = true;
            for (Promotion__c promotionRecord : promotions) {
                if (!Test.isRunningTest()) {
                    DeployAPI.deployPromotionAsync(
                        promotionRecord.Id,
                        'CBM Promotion ' + promotionRecord.Name,
                        jobParameters.isCheckOnly,
                        false,
                        jobParameters.testLevelValue,
                        true,
                        UserInfo.getUserId()
                    );
                }
            }
            checkPromotionsStatuses();
            return result;
        } catch (Exception ex) {
            throw new PipelineOperationsHelperException(ex.getMessage());
        }
    }
}