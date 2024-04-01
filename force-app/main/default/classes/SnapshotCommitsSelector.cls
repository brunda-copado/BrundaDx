public inherited sharing class SnapshotCommitsSelector extends fflib_SObjectSelector {
    public SObjectType getSObjectType() {
        return Git_Org_Commit__c.sObjectType;
    }

    public List<SObjectField> getSObjectFieldList() {
        return new List<SObjectField>{
            Git_Org_Commit__c.Org__c,
            Git_Org_Commit__c.Git_Backup__c,
            Git_Org_Commit__c.Git_Operation__c,
            Git_Org_Commit__c.Commit_Message__c
        };
    }

    public List<Git_Org_Commit__c> byIds(Set<Id> snapshotCommits) {
        return Database.query(newQueryFactory().setCondition('Id IN :snapshotCommits').toSOQL());
    }
}