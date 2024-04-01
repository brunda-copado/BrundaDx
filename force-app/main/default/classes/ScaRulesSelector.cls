public inherited sharing class ScaRulesSelector extends fflib_SObjectSelector {
    public List<SObjectField> getSObjectFieldList() {
        return new List<SObjectField>{
            Static_Code_Analysis_Rule__c.Id,
            Static_Code_Analysis_Rule__c.Rule_Name__c,
            Static_Code_Analysis_Rule__c.Priority__c,
            Static_Code_Analysis_Rule__c.Message__c
        };
    }

    public SObjectType getSObjectType() {
        return Static_Code_Analysis_Rule__c.sObjectType;
    }

    public List<Static_Code_Analysis_Rule__c> bySettingId(Id id) {
        return (List<Static_Code_Analysis_Rule__c>) Database.query(newQueryFactory().setEnforceFLS(true).setCondition('Static_Code_Analysis_Settings__c = :id').toSOQL());
    }
}