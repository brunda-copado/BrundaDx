@IsTest
public with sharing class UserStoryCommit extends DomainBuilder {

    public UserStoryCommit(SnapshotCommit snapshotCommit) {
        super(User_Story_Commit__c.SObjectType);
        setParent(User_Story_Commit__c.Snapshot_Commit__c, snapshotCommit);
    }

    public UserStoryCommit userStoryId(String userStoryId) {
        return (UserStoryCommit) set(User_Story_Commit__c.User_Story__c, userStoryId);
    }

}