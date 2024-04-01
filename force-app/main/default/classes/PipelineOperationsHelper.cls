public with sharing virtual class PipelineOperationsHelper {
    public BranchManagementExtension.OverlayWrapper overlayWrapperRecord;
    public String testLevelValue;
    public PipelineManagerExtension.PipelineOperationsServiceJobsResult result;
    public List<User_Story__c> selectedUserStories;
    public Map<String, Promotion__c> promotionByUserStoryReleases;
    public Map<String, String> testLevelValuesByPromotionIds { get; set; }
    public final String C_PULL = 'pull';
    public final String RUN_LOCAL_TESTS = 'RunLocalTests';
    public final String PROMOTED_USER_STORY = 'Promoted User Story: ';
    public final String BACK_PROMOTED_USER_STORY = 'Back Promoted User Story: ';
    public final String COMPLETED = 'Completed';
    public final String NOT_STARTED = 'Not started';
    public final String IN_PROGRESS = 'In Progress';
    public final String SCHEDULED = 'Scheduled';
    public final String DEPLOY_NOW = 'Deploy now';
    public final String DRAFT = 'Draft';

    public void preparePromotionAndRelations() {
        promotionByUserStoryReleases = new Map<String, Promotion__c>();
        List<Promotion__c> promotions = new List<Promotion__c>();
        selectedUserStories = new List<User_Story__c>();

        for (BranchManagementExtension.UserStoryWrapper userStoryWrapperItem : overlayWrapperRecord.userStories) {
            if (userStoryWrapperItem.isSelected) {
                selectedUserStories.add(userStoryWrapperItem.userStory);
                if (!promotionByUserStoryReleases.containsKey(userStoryWrapperItem.userStory.Release__c)) {
                    Promotion__c promotionRecord = createNewPromotionRecordAndReturnIt(userStoryWrapperItem.userStory);
                    promotionByUserStoryReleases.put(userStoryWrapperItem.userStory.Release__c, promotionRecord);
                }
            }
        }
        
        if (selectedUserStories.isEmpty()) {
            throw new PipelineOperationsHelperException(Label.CBM2_at_least1_us);
        }
        try {
            promotions = promotionByUserStoryReleases.values();
            SObjectAccessDecision decision = Security.stripInaccessible(AccessType.CREATABLE, promotions);
            insert decision.getRecords();
            promotions = (List<Promotion__c>) decision.getRecords();

            Set<Id> promotionIds = new Set<Id>();
            for (Promotion__c promotionRecord : promotions) {
                promotionByUserStoryReleases.put(promotionRecord.Release__c, promotionRecord);
                promotionIds.add(promotionRecord.Id);
            }
            addUserStoriesToPromotion(promotionByUserStoryReleases);
            getPendingPromotions(promotionIds);
        } catch (Exception ex) {
            throw new PipelineOperationsHelperException(ex.getMessage());
        }
    }

    private Promotion__c createNewPromotionRecordAndReturnIt(User_Story__c userStoryRecord) {
        Boolean isBackPromotion = overlayWrapperRecord.pathType.toLowerCase() == C_PULL;

        Promotion__c promotion = new PromotionOperations(userStoryRecord.Environment__c, overlayWrapperRecord.toEnvId, isBackPromotion)
                .projectId(userStoryRecord.Project__c)
                .releaseId(userStoryRecord.Release__c)
                .promotion();
        // TODO: Clarify if this is needed from architects
        promotion.Send_Deployment_Complete_email__c = true;
        return promotion;
    }

    private void addUserStoriesToPromotion(Map<String, Promotion__c> promotionByUserStoryReleases) {
        List<Promoted_User_Story__c> promotedUserStoriesToBeInserted = new List<Promoted_User_Story__c>();
        for (User_Story__c userStoryRecord : selectedUserStories) {
            Promotion__c promotion = promotionByUserStoryReleases.get(userStoryRecord.Release__c);

            promotedUserStoriesToBeInserted.add((new PromotedUserStoriesOperations(userStoryRecord, promotion).promotedUserStories())[0]);
        }

        SObjectAccessDecision decision = Security.stripInaccessible(AccessType.CREATABLE, promotedUserStoriesToBeInserted);
        insert decision.getRecords();
    }

    public void getPendingPromotions(Set<Id> promotionIds) {
        if (overlayWrapperRecord.toEnvRunAllTests) {
            testLevelValue = RUN_LOCAL_TESTS;
        }

        Boolean isBackPromotion = overlayWrapperRecord.pathType.toLowerCase() == C_PULL;
        String promotionQuery = 'SELECT Id, Back_Promotion__c, Source_Environment__c, Destination_Environment__c, Connection_Behavior__c';
        promotionQuery = PipelineManagerExtension.prepareFieldsetQuery(Schema.SObjectType.Promotion__c.fieldSets.Pipeline_Manager, promotionQuery);
        promotionQuery += ', (SELECT Id, User_Story__c FROM Promoted_User_Stories__r)';
        promotionQuery += ' FROM Promotion__c WHERE Id = :promotionIds AND Back_Promotion__c = :isBackPromotion WITH SECURITY_ENFORCED LIMIT 1000';
        List<Promotion__c> promotions = (List<Promotion__c>) Database.query(promotionQuery);
        Map<Promotion__c, Set<Id>> userStoryIdsByPromotions = new Map<Promotion__c, Set<Id>>();
        for (Promotion__c promotionRecord : promotions) {
            Set<Id> userStoryIds = new Set<Id>();
            for (Promoted_User_Story__c promotedUserStoryRecord : promotionRecord.Promoted_User_Stories__r) {
                if (userStoryIdsByPromotions.containsKey(promotionRecord)) {
                    userStoryIds = userStoryIdsByPromotions.get(promotionRecord);
                }
                userStoryIds.add(promotedUserStoryRecord.User_Story__c);
            }
            if (!userStoryIds.isEmpty()) {
                userStoryIdsByPromotions.put(promotionRecord, userStoryIds);
            }
        }
        if (!userStoryIdsByPromotions.isEmpty()) {
            Map<Promotion__c, List<User_Story__c>> userStoriesByPromotion = GlobalUtilities.getUserStoriesDependencies(userStoryIdsByPromotions);
            List<PipelineManagerExtension.PromotionWrapper> promotionWrappers = new List<PipelineManagerExtension.PromotionWrapper>();
            Map<Id, List<User_Story__c>> userStoriesByPromotionForDependencies = new Map<Id, List<User_Story__c>>();
            for (Promotion__c promotionRecord : promotions) {
                if (userStoryIdsByPromotions.containsKey(promotionRecord) && !promotionRecord.Back_Promotion__c) {
                    if (userStoriesByPromotion.containsKey(promotionRecord) && !userStoriesByPromotion.get(promotionRecord).isEmpty()) {
                        promotionWrappers.add(new PipelineManagerExtension.PromotionWrapper(promotionRecord, testLevelValue, true));
                        userStoriesByPromotionForDependencies.put(promotionRecord.Id, userStoriesByPromotion.get(promotionRecord));
                    } else {
                        promotionWrappers.add(new PipelineManagerExtension.PromotionWrapper(promotionRecord, testLevelValue));
                    }
                } else {
                    promotionWrappers.add(new PipelineManagerExtension.PromotionWrapper(promotionRecord, testLevelValue));
                }
            }

            result.promotionWrappers = promotionWrappers;
            result.userStoriesByPromotionForDependencies = userStoriesByPromotionForDependencies;
        }
    }

    public void checkPromotionsStatuses() {
        Integer completedPromotionCount = 0;
        List<PipelineManagerExtension.PromotionWrapper> newPromotionWrappers = new List<PipelineManagerExtension.PromotionWrapper>();
        String promotionQuery = 'SELECT Id, Name, Destination_Environment__c, Source_Environment__c, Project__c, Release__c, Status__c, Connection_Behavior__c ';
        promotionQuery = PipelineManagerExtension.prepareFieldsetQuery(Schema.SObjectType.Promotion__c.fieldSets.Pipeline_Manager, promotionQuery);
        Set<String> promotionIdSet = testLevelValuesByPromotionIds.keySet();
        promotionQuery += ' FROM Promotion__c WHERE Id IN :promotionIdSet AND Status__c != \'Cancelled\' WITH SECURITY_ENFORCED LIMIT 1000';
        List<Promotion__c> promotions = (List<Promotion__c>) Database.query(promotionQuery);

        for (Promotion__c promotionRecord : promotions) {
            newPromotionWrappers.add(
                new PipelineManagerExtension.PromotionWrapper(promotionRecord, testLevelValuesByPromotionIds.get(promotionRecord.Id))
            );
            if (promotionRecord.Status__c != 'Draft' && promotionRecord.Status__c != SCHEDULED && promotionRecord.Status__c != IN_PROGRESS) {
                completedPromotionCount++;
            }
        }
        if (promotions.size() == completedPromotionCount) {
            result.enabledPromotionBackPromotionPoller = false;
        }
        result.testLevelValuesByPromotionIds = testLevelValuesByPromotionIds;
        result.promotionWrappers = newPromotionWrappers;
    }

    public class PipelineOperationsHelperException extends Exception {
    }
}