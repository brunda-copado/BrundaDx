public inherited sharing class GitRepositoriesSelector extends fflib_SObjectSelector {
    public SObjectType getSObjectType() {
        return Git_Repository__c.sObjectType;
    }

    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{
            Git_Repository__c.Id,
            Git_Repository__c.Name,
            Git_Repository__c.Git_Provider__c,
            Git_Repository__c.URI__c,
            Git_Repository__c.Source_Format__c,
            Git_Repository__c.Tag_Base_URL__c,
            Git_Repository__c.Commit_Base_URL__c,
            Git_Repository__c.Branch_Base_URL__c,
            Git_Repository__c.Pull_Request_Base_URL__c,
            Git_Repository__c.Allow_Functions_Git_Cache__c,
            Git_Repository__c.Is_repository_connected_via_copa_tunnel__c
        };
    }

    public List<Git_Repository__c> byId(List<Id> recordIds) {
        return byId(new Set<Id>(recordIds));
    }

    public List<Git_Repository__c> byId(Set<Id> recordIds) {
        return (List<Git_Repository__c>) selectSObjectsById(recordIds);
    }
}