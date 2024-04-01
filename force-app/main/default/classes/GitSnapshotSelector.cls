public inherited sharing class GitSnapshotSelector extends fflib_SObjectSelector {
    public List<SObjectField> getSObjectFieldList() {
        return new List<SObjectField>{ Git_Backup__c.Id, Git_Backup__c.Org__c, Git_Backup__c.Pipeline__c };
    }

    public SObjectType getSObjectType() {
        return Git_Backup__c.sObjectType;
    }

    public List<Git_Backup__c> byCredentialRepoSnapshotOnly(Id orgId, Id repositoryId) {
        return Database.query(
            newQueryFactory()
                .setEnforceFLS(true)
                .setCondition('Org__c = :orgId AND Git_Repository__c = :repositoryId AND Git_Snapshot_Permissions__c != \'Allow Snapshots Only\'')
                .toSOQL()
        );
    }

    public List<Git_Backup__c> byIds(Set<Id> gitSnapshots) {
        return Database.query(
            newQueryFactory()
                .selectField('Org__r.Platform__c')
                .selectField('Org__r.Oauth_Signature__c')
                .selectField('Org__r.Environment__c')
                .selectField('Org__r.Environment__r.Platform__c')
                .selectField('Pipeline__r.Active__c')
                .selectField('Pipeline__r.Platform__c')
                .setCondition('Id IN :gitSnapshots')
                .toSOQL()
        );
    }
}