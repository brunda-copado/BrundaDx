public with sharing class PromotionValidator {
    private Actions.PromotionRequest promotionRequest;
    private List<User_Story__c> userStories;
    private Promotion__c promotion;

    // PUBLIC

    public PromotionValidator(Actions.PromotionRequest promotionRequest) {
        this.promotionRequest = promotionRequest;
    }

    public ReturnData execute() {
        ReturnData result = new ReturnData();
        validateUserStoriesCountOrPromotedUserStories();
        if (String.isEmpty(promotionRequest.promotionId)) {
            userStories = userStories();
            result.userStories = userStories;
            validateRequestProject();
            validateUserStoriesProjectAndRelease();
        } else {
            List<Promotion__c> promotions = new PromotionsSelector()
                .promotionsDetailsForPromoteAndDeployActions(new Set<Id>{ promotionRequest.promotionId });
            promotion = promotions.isEmpty() ? new Promotion__c() : promotions[0];
            result.promotion = promotion;
            validateCancelledPromotion();
        }
        return result;
    }

    // PRIVATE

    private void validateUserStoriesCountOrPromotedUserStories() {
        if (
            promotionRequest.executePromotion && (String.isEmpty(promotionRequest.promotionId) && promotionRequest.userStoryIds.isEmpty()) ||
            (String.isNotEmpty(promotionRequest.promotionId) && !hasPromotedUserStories())
        ) {
            throw new ApplicationException(Label.Please_add_at_least_one_user_story_to_your_promotion);
        }
    }

    private void validateCancelledPromotion() {
        if (promotion.Status__c == PromotionConstants.STATUS_CANCELLED) {
            throw new ApplicationException(Label.CANCELLED_PROMOTIONS_ACTION);
        }
    }

    private void validateRequestProject() {
        if (String.isNotEmpty(promotionRequest.projectId)) {
            for (User_Story__c userStory : userStories) {
                if (
                    (userStory.Project__c != null && promotionRequest.projectId != userStory.Project__c) ||
                    (userStory.Release__c != null &&
                    promotionRequest.projectId != userStory.Release__r.Project__c)
                ) {
                    throw new ApplicationException(Label.Project_Id_Validation);
                }
            }
        }
    }

    private void validateUserStoriesProjectAndRelease() {
        Id firstProjectId = userStories.get(0).Project__c;
        Id firstReleaseId = userStories.get(0).Release__c;
        for (User_Story__c userStory : userStories) {
            if (userStory.Project__c != firstProjectId) {
                throw new ApplicationException(Label.Different_Projects_Promotion_Validation);
            }
            if (userStory.Release__c != firstReleaseId) {
                throw new ApplicationException(Label.Different_Releases_Promotion_Validation);
            }
        }
    }

    // PMD False positive, as WITH USER_MODE is not supported yet
    @SuppressWarnings('PMD.ApexCRUDViolation')
    private List<User_Story__c> userStories() {
        return [
            SELECT Id, Name, Project__c, Release__c, Release__r.Project__c
            FROM User_Story__c
            WHERE Id IN :promotionRequest.userStoryIds
            WITH USER_MODE
        ];
    }

    // PMD False positive, as WITH USER_MODE is not supported yet
    @SuppressWarnings('PMD.ApexCRUDViolation')
    private Boolean hasPromotedUserStories() {
        return [SELECT COUNT() FROM Promoted_User_Story__c WHERE Promotion__c = :promotionRequest.promotionId WITH USER_MODE] > 0;
    }

    // WRAPPER

    public with sharing class ReturnData {
        public List<User_Story__c> userStories;
        public Promotion__c promotion;
    }
}