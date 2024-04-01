public with sharing class UpdatePromoteAndDeployOnUserStories {

    private Set<Id> promotionIds;
    
    public UpdatePromoteAndDeployOnUserStories(Set<Id> promotionIds) {
        this.promotionIds = promotionIds;
    }

    public void execute() {
        List<User_Story__c> userStoriesToUpd = new List<User_Story__c>();
        for (Promoted_User_Story__c promotedUserStory : getPromotedUserStories()) {
            userStoriesToUpd.add(new User_Story__c(
                Id = promotedUserStory.User_Story__c,
                Promote_and_Deploy__c = false
            ));
        }
        UserStories.bypassTrigger = true;
        DML.safeUpdate(userStoriesToUpd, 'Could not update User Stories Promote And Deploy ( UpdatePromoteAndDeployOnUserStories.execute class )');
        UserStories.bypassTrigger = false;
    }

    private List<Promoted_User_Story__c> getPromotedUserStories() {
        return [
            SELECT User_Story__c
            FROM Promoted_User_Story__c
            WHERE Promotion__c IN :promotionIds
            WITH SECURITY_ENFORCED
        ];
    }
}