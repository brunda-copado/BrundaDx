public inherited sharing class UserStoryMetadataSelector extends fflib_SObjectSelector {
    public UserStoryMetadataSelector() {
        this(true, true);
    }

    public UserStoryMetadataSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(false, enforceCRUD, enforceFLS, false);
    }

    // PUBLIC

    public SObjectType getSObjectType() {
        return User_Story_Metadata__c.sObjectType;
    }

    public List<SObjectField> getSObjectFieldList() {
        return new List<SObjectField>{
            User_Story_Metadata__c.Metadata_API_Name__c,
            User_Story_Metadata__c.Type__c,
            User_Story_Metadata__c.User_Story__c,
            User_Story_Metadata__c.Action__c,
            User_Story_Metadata__c.ModuleDirectory__c,
            User_Story_Metadata__c.Category__c,
            User_Story_Metadata__c.JsonInformation__c,
            User_Story_Metadata__c.Unique_ID__c
        };
    }

    public List<User_Story_Metadata__c> byUserStoryId(Id userStoryId) {
        return Database.query(newQueryFactory().setCondition(User_Story_Metadata__c.User_Story__c + '= :userStoryId').toSOQL());
    }

    public List<User_Story_Metadata__c> byUserStoryIds(Set<Id> ids) {
        return Database.query(selectFields().setCondition('User_Story__c IN :ids').setLimit(41000).toSOQL());
    }

    // PRIVATE

    private fflib_QueryFactory selectFields() {
        return newQueryFactory().selectFields(new List<String>{ 'User_Story__r.Name' });
    }
}