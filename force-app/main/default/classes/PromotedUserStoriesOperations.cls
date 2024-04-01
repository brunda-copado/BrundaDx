public with sharing class PromotedUserStoriesOperations {
    private final String PROMOTED_USER_STORY = 'Promoted User Story: ';
    private final String BACK_PROMOTED_USER_STORY = 'Back Promoted User Story: ';

    private Promotion__c promotion;
    private List<User_Story__c> userStories;

    // CONSTRUCTOR

    public PromotedUserStoriesOperations(Id userStoryId, Id promotionId) {
        this(new List<Id> { userStoryId }, promotionId);
    }

    public PromotedUserStoriesOperations(List<Id> userStoryIds, Id promotionId) {
        this(userStories(userStoryIds), promotion(promotionId));
    }

    public PromotedUserStoriesOperations(User_Story__c userStory, Promotion__c promotion) {
        this(new List<User_Story__c> {userStory}, promotion);
    }

    public PromotedUserStoriesOperations(List<User_Story__c> userStories, Promotion__c promotion) {
        this.promotion = promotion;
        this.userStories = userStories;
    }

    // PUBLIC

    public List<Promoted_User_Story__c> insertPromotedUserStories() {
        SObjectAccessDecision decision = Security.stripInaccessible(AccessType.CREATABLE, promotedUserStories());
        insert decision.getRecords();

        return (List<Promoted_User_Story__c>) decision.getRecords();
    }

    public List<Promoted_User_Story__c> promotedUserStories() {
        List<Promoted_User_Story__c> promotedUserStories = new List<Promoted_User_Story__c>();

        for(User_Story__c userStory : userStories) {
            promotedUserStories.add(asPromotedUserStory(userStory, promotion));
        }

        return promotedUserStories;
    }


    // PRIVATE

    private Promoted_User_Story__c asPromotedUserStory(User_Story__c userStory, Promotion__c promotion) {
        return new Promoted_User_Story__c(
                                        Name = promotedUserStoryName(userStory.Name),
                                        User_Story__c = userStory.Id,
                                        Promotion__c = promotion.Id
                                    );
    }

    private String promotedUserStoryName(String userStoryName) {
        return promotion.Back_Promotion__c ? BACK_PROMOTED_USER_STORY + userStoryName : PROMOTED_USER_STORY + userStoryName;
    }

    private static Promotion__c promotion(Id promotionId) {
        return [SELECT Back_Promotion__c FROM Promotion__c WHERE Id = :promotionId WITH SECURITY_ENFORCED];
    }

    private static List<User_Story__c> userStories(List<Id> userStoryIds) {
        return [SELECT Id, Name FROM User_Story__c WHERE Id IN :userStoryIds WITH SECURITY_ENFORCED];
    }
}