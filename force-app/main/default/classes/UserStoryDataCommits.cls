public with sharing class UserStoryDataCommits extends fflib_SObjectDomain {
    // CONSTRUCTOR

    public UserStoryDataCommits(List<User_Story_Data_Commit__c> records) {
        super(records);
    }

    // PUBLIC

    public override void onAfterInsert() {
        new GenerateDataCommitDeploymentTask(records).execute();
    }

    public override void onBeforeDelete() {
        new DeleteDataCommitDeploymentTask(records).execute();
    }

    // INNER

    public class Constructor implements fflib_SObjectDomain.IConstructable {
        public fflib_SObjectDomain construct(List<SObject> records) {
            return new UserStoryDataCommits(records);
        }
    }
}