public inherited sharing class UserStoryCommitsSelector extends fflib_SObjectSelector {
    // CONSTRUCTOR

    public UserStoryCommitsSelector() {
        this(true);
    }

    public UserStoryCommitsSelector(Boolean enforceFLS) {
        super(false, true, enforceFLS);
    }

    // PUBLIC

    public SObjectType getSObjectType() {
        return User_Story_Commit__c.sObjectType;
    }

    public List<SObjectField> getSObjectFieldList() {
        return new List<SObjectField>{
            User_Story_Commit__c.Snapshot_Commit__c,
            User_Story_Commit__c.User_Story__c
        };
    }

    public List<User_Story_Commit__c> byUserStory(Set<Id> userStoryIds) {
        return Database.query(newQueryFactory().setCondition('User_Story__c IN :userStoryIds').toSOQL());
    }

    public List<User_Story_Commit__c> byIds(Set<Id> ids) {
        return Database.query(selectFields().setCondition('Id IN :ids').toSOQL());
    }

    // PRIVATE

    private fflib_QueryFactory selectFields() {
        return newQueryFactory()
            .selectField('User_Story__r.Name');
    }
}