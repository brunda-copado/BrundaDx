public inherited sharing class ReleasesSelector extends fflib_SObjectSelector {
    public List<SObjectField> getSObjectFieldList() {
        return new List<SObjectField>{ Release__c.Id, Release__c.Project__c };
    }

    public SObjectType getSObjectType() {
        return Release__c.sObjectType;
    }

    public List<Release__c> byIds(Set<Id> ids) {
        return (List<Release__c>) Database.query(newQueryFactory().setEnforceFLS(true).setCondition('Id IN :ids').toSOQL());
    }
}