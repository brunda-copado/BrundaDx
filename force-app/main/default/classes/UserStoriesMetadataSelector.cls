public inherited sharing class UserStoriesMetadataSelector extends fflib_SObjectSelector {
    private static final String INDEXING_ENABLED = 'AND User_Story__r.Project__r.Index_Metadata__c = true AND User_Story__r.Stop_Indexing_Metadata__c = false AND (User_Story__r.Platform__c = NULL OR User_Story__r.Platform__c = \'Salesforce\')';
    private static final String GIT_REPOSITORY_EQUALS = ' AND User_Story__r.Project__r.Deployment_Flow__r.Git_Repository__c IN :repoIds ';
    public List<SObjectField> getSObjectFieldList() {
        return new List<SObjectField>{
            User_Story_Metadata__c.Id,
            User_Story_Metadata__c.Action__c,
            User_Story_Metadata__c.Category__c,
            User_Story_Metadata__c.Metadata_API_Name__c,
            User_Story_Metadata__c.ModuleDirectory__c,
            User_Story_Metadata__c.LastModifiedDate,
            User_Story_Metadata__c.Type__c,
            User_Story_Metadata__c.Status__c,
            User_Story_Metadata__c.User_Story__c,
            User_Story_Metadata__c.JsonInformation__c
        };
    }

    public SObjectType getSObjectType() {
        return User_Story_Metadata__c.sObjectType;
    }

    public Database.QueryLocator byStoryStatus(Set<Id> ids, String status) {
        return Database.getQueryLocator(newQueryFactory().setEnforceFLS(true).setCondition('User_Story__c = :ids AND Status__c = :status').toSOQL());
    }

    public List<User_Story_Metadata__c> byUserStoryId(Set<Id> ids) {
        fflib_QueryFactory query = newQueryFactory()
            .setEnforceFLS(true)
            .selectFields(new List<String>{ 'LastModifiedBy.Name' })
            .setCondition(User_Story_Metadata__c.User_Story__c + ' IN :ids');
        return (List<User_Story_Metadata__c>) Database.query(query.toSOQL());
    }

    public List<User_Story_Metadata__c> byStoryIdsIndexingEnabled(Set<Id> ids) {
        fflib_QueryFactory query = newQueryFactory().setEnforceFLS(true).setCondition('User_Story__c = :ids ' + INDEXING_ENABLED);
        return (List<User_Story_Metadata__c>) Database.query(query.toSOQL());
    }

    public Database.QueryLocator byMetadataIndexingEnabled(Set<String> apiNames) {
        return Database.getQueryLocator(
            newQueryFactory().setEnforceFLS(true).setCondition('Metadata_API_Name__c = :apiNames ' + INDEXING_ENABLED).toSOQL()
        );
    }

    public Database.QueryLocator byMetadatanameStatusIndexingEnabled(Set<String> apiNames, String status) {
        return byMetadatanameStatusIndexingEnabled(apiNames, status, null);
    }

    public Database.QueryLocator byMetadatanameStatusIndexingEnabled(Set<String> apiNames, String status, Set<Id> userStoryIds) {
        Set<Id> repoIds = getRepositoryIds(userStoryIds);
        String additionalQuery = !repoIds.isEmpty() 
                                    ? GIT_REPOSITORY_EQUALS
                                : '';

        return Database.getQueryLocator(
            newQueryFactory()
                .setEnforceFLS(true)
                .setCondition('Status__c = :status AND Metadata_API_Name__c = :apiNames ' + additionalQuery + INDEXING_ENABLED)
                .toSOQL()
        );
    }

    private Set<Id> getRepositoryIds(Set<Id> userStoryIds){
        Set<Id> repoIds = new Set<Id>();
        if(null != userStoryIds){
            for(User_Story__c userStory : new UserStoriesSelector().byUserStoryIds(userStoryIds).values()){
                repoIds.add(userStory.Project__r.Deployment_Flow__r.Git_Repository__c);
            }
        }
        return repoIds;
    }
}