public inherited sharing class UserStoryDataCommitsSelector extends fflib_SObjectSelector {
    public SObjectType getSObjectType() {
        return User_Story_Data_Commit__c.sObjectType;
    }

    public List<SObjectField> getSObjectFieldList() {
        return new List<SObjectField>{
            User_Story_Data_Commit__c.Id,
            User_Story_Data_Commit__c.Name,
            User_Story_Data_Commit__c.Data_Set__c,
            User_Story_Data_Commit__c.User_Story__c,
            User_Story_Data_Commit__c.Execution_Job__c,
            User_Story_Data_Commit__c.Status__c
        };
    }

    public UserStoryDataCommitsSelector() {
        this(true);
    }

    public UserStoryDataCommitsSelector(Boolean enforceFLS) {
        super(false, true, enforceFLS);
    }

    public Map<Id, List<User_Story_Data_Commit__c>> byUserStory(Set<Id> userStoryIds) {
        Map<Id, List<User_Story_Data_Commit__c>> result = new Map<Id, List<User_Story_Data_Commit__c>>();

        for (Id userStoryId : userStoryIds) {
            result.put(userStoryId, new List<User_Story_Data_Commit__c>());
        }

        fflib_QueryFactory query = newQueryFactory()
            .setCondition(User_Story_Data_Commit__c.User_Story__c + ' IN :userStoryIds')
            .setOrdering(User_Story_Data_Commit__c.Commit_Date__c, fflib_QueryFactory.SortOrder.DESCENDING, true);
        configureRelatedSelector(query);

        for (User_Story_Data_Commit__c userStoryDataCommit : (List<User_Story_Data_Commit__c>) Database.query(query.toSOQL())) {
            Id userStoryId = userStoryDataCommit.User_Story__c;
            result.get(userStoryId).add(userStoryDataCommit);
        }
        return result;
    }

    public Map<Id, Map<Id, List<User_Story_Data_Commit__c>>> byUserStoryGroupByDataSet(Set<Id> userStoryIds) {
        Map<Id, Map<Id, List<User_Story_Data_Commit__c>>> result = new Map<Id, Map<Id, List<User_Story_Data_Commit__c>>>();

        Map<Id, List<User_Story_Data_Commit__c>> dataCommitsByUserStory = byUserStory(userStoryIds);

        for (Id userStoryId : userStoryIds) {
            Map<Id, List<User_Story_Data_Commit__c>> dataCommitsByDataSet = new Map<Id, List<User_Story_Data_Commit__c>>();

            List<User_Story_Data_Commit__c> userStoryDataCommits = dataCommitsByUserStory.get(userStoryId);
            for (User_Story_Data_Commit__c dataCommit : userStoryDataCommits) {
                Id dataSetId = dataCommit.Data_Set__c;
                if (!dataCommitsByDataSet.containsKey(dataSetId)) {
                    dataCommitsByDataSet.put(dataSetId, new List<User_Story_Data_Commit__c>());
                }
                dataCommitsByDataSet.get(dataSetId).add(dataCommit);
            }

            result.put(userStoryId, dataCommitsByDataSet);
        }

        return result;
    }

    private void configureRelatedSelector(fflib_QueryFactory query) {
        fflib_SObjectSelector dataSetsSelector = new DataSetsSelector();
        dataSetsSelector.configureQueryFactoryFields(query, Schema.sObjectType.User_Story_Data_Commit__c.fields.Data_Set__c.getRelationshipName());
        fflib_SObjectSelector deploymentsSelector = new DeploymentsSelector();
        deploymentsSelector.configureQueryFactoryFields(
            query,
            Schema.sObjectType.User_Story_Data_Commit__c.fields.Execution_Job__c.getRelationshipName()
        );
    }
}