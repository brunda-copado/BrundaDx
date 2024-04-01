public inherited sharing class RecordMatchingFormulaSelector extends fflib_SObjectSelector{
    
    public SObjectType getSObjectType() {
        return Record_Matching_Formula__c.sObjectType;
    }

    public List<SObjectField> getSObjectFieldList() {
        return new List<SObjectField>{
            Record_Matching_Formula__c.Id,
            Record_Matching_Formula__c.Name,
            Record_Matching_Formula__c.Object__c,
            Record_Matching_Formula__c.Configuration_Source_Org__c,
            Record_Matching_Formula__c.Hash_Formula__c,
            Record_Matching_Formula__c.Field_1__c,
            Record_Matching_Formula__c.Field_2__c,
            Record_Matching_Formula__c.Field_3__c,
            Record_Matching_Formula__c.Field_Labels__c
        };
    }

    public RecordMatchingFormulaSelector() {
        this(true);
    }

    public RecordMatchingFormulaSelector(Boolean enforceFLS) {
        super(false, true, enforceFLS);
    }

    public List<Record_Matching_Formula__c> byId(Set<Id> recordIds) {
        return (List<Record_Matching_Formula__c>) selectSObjectsById(recordIds);
    }

    public List<Record_Matching_Formula__c> byObjectName(String objectName) {
        fflib_QueryFactory query = newQueryFactory().setCondition(Record_Matching_Formula__c.Object__c + ' =: objectName');
        return (List<Record_Matching_Formula__c>) Database.query(query.toSOQL());
    }

}