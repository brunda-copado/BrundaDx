public inherited sharing class QualityGateRulesSelector extends fflib_SObjectSelector {
    public SObjectType getSObjectType() {
        return Quality_Gate_Rule__c.sObjectType;
    }

    public List<SObjectField> getSObjectFieldList() {
        return new List<SObjectField>{
            Quality_Gate_Rule__c.Id,
            Quality_Gate_Rule__c.Name,
            Quality_Gate_Rule__c.Actions__c,
            Quality_Gate_Rule__c.Tool__c,
            Quality_Gate_Rule__c.Type__c,
            Quality_Gate_Rule__c.Status__c,
            Quality_Gate_Rule__c.dataJson__c,
            Quality_Gate_Rule__c.Execution_sequence__c
        };
    }

    public Quality_Gate_Rule__c byId(Id recordId) {
        return byId(new Set<Id>{ recordId }).get(0);
    }

    public List<Quality_Gate_Rule__c> byId(Set<Id> recordIds) {
        return (List<Quality_Gate_Rule__c>) selectSObjectsById(new Set<Id>(recordIds));
    }

    public List<Quality_Gate_Rule__c> byActiveMeetingAnyFilter(List<String> filters) {
        String rule = Quality_Gate_Rule__c.Status__c + ' = \'Active\'';
        if (!filters.isEmpty()) {
            rule += ' AND ' + String.join(filters, ' AND ');
        }
        return Database.query(newQueryFactory().setCondition(rule).toSOQL());
    }
}