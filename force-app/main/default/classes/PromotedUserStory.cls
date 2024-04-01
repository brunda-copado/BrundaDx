@IsTest
public with sharing class PromotedUserStory extends DomainBuilder {
    public PromotedUserStory() {
        super(Promoted_User_Story__c.SObjectType);
    }

    public PromotedUserStory userStory(Id userStoryId) {
        return (PromotedUserStory) set(Promoted_User_Story__c.User_Story__c, userStoryId);
    }

    public PromotedUserStory promotion(Id promotionId) {
        return (PromotedUserStory) set(Promoted_User_Story__c.Promotion__c, promotionId);
    }
}