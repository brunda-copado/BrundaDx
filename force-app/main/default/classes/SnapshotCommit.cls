@IsTest
public with sharing class SnapshotCommit extends DomainBuilder {
    public SnapshotCommit() {
        super(Git_Org_Commit__c.SObjectType);
    }

    public SnapshotCommit commitId(String commitId) {
        return (SnapshotCommit) set(Git_Org_Commit__c.Commit_Id__c, commitId);
    }

    public SnapshotCommit commitDate(Date commitDate) {
        return (SnapshotCommit) set(Git_Org_Commit__c.Commit_Date__c, commitDate);
    }

    public SnapshotCommit gitSnapshot(String gitSnapshot) {
        return (SnapshotCommit) set(Git_Org_Commit__c.Git_Backup__c, gitSnapshot);
    }

    public SnapshotCommit status(String status) {
        return (SnapshotCommit) set(Git_Org_Commit__c.Status__c, status);
    }

    public SnapshotCommit credentialId(String credentialId) {
        return (SnapshotCommit) set(Git_Org_Commit__c.Org__c, credentialId);
    }

    public SnapshotCommit gitOperation(string gitOperation) {
        return (SnapshotCommit) set(Git_Org_Commit__c.Git_Operation__c, gitOperation);
    }
}