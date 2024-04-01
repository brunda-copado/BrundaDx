public with sharing class RestrictQgrcDuplicate {
    private List<Quality_Gate_Rule_Condition__c> records;
    private Set<String> duplicateCriteriaFields;

    // CTOR

    public RestrictQgrcDuplicate(List<Quality_Gate_Rule_Condition__c> records) {
        this.records = records;
        this.duplicateCriteriaFields = duplicateCriteriaFields();
    }

    // PUBLIC

    public void execute() {
        Map<Id, List<Quality_Gate_Rule_Condition__c>> conditionsByRuleId = conditionsByRuleId();
        for (Quality_Gate_Rule_Condition__c record : records) {
            if (record.status__c == 'Active') {
                if (isDuplicate(record)) {
                    record.addError(Label.Duplicate_Quality_Gate_Rule_Condition);
                } else if (
                    conditionsByRuleId.get(record.Quality_Gate_Rule__c).size() > 1 &&
                    isSimilar(conditionsByRuleId.get(record.Quality_Gate_Rule__c), record)
                ) {
                    record.addError(Label.Similar_Quality_Gate_Rule_Condition_Error);
                }
            }
        }
    }

    // PRIVATE

    private Map<Id, List<Quality_Gate_Rule_Condition__c>> conditionsByRuleId() {
        Set<Id> qualityGateRuleIds = new Set<Id>();
        for (Quality_Gate_Rule_Condition__c record : records) {
            if (record.status__c == 'Active') {
                qualityGateRuleIds.add(record.Quality_Gate_Rule__c);
            }
        }
        Map<Id, List<Quality_Gate_Rule_Condition__c>> conditionsByRuleId = new QualityGateRuleConditionsSelector()
            .byQualityGateRule(qualityGateRuleIds);
        return conditionsByRuleId;
    }

    private Boolean isDuplicate(Quality_Gate_Rule_Condition__c record) {
        // Approach to find the duplicates can be custom logic instead of the query filter to retrieve duplicate records
        // to avoid query in the loop. But since this is designed early in the implementation, we will not have more than 1 duplicate records.
        // Single record will be inserted/updated as per current design.
        List<Quality_Gate_Rule_Condition__c> duplicateRecords = new FindDuplicates(record, duplicateCriteriaFields).execute();
        Boolean result = !duplicateRecords.isEmpty();

        for (Quality_Gate_Rule_Condition__c condition : duplicateRecords) {
            result = record.Filter_Criteria__c == condition.Filter_Criteria__c;
        }

        return result;
    }

    private Boolean isSimilar(List<Quality_Gate_Rule_Condition__c> conditionsByRuleId, Quality_Gate_Rule_Condition__c record) {
        Integer conditionWeight = new CalculateQGConditionWeight(record).execute();

        for (Quality_Gate_Rule_Condition__c condition : conditionsByRuleId) {
            Integer duplicateConditionWeight = new CalculateQGConditionWeight(condition).execute();
            if (condition.Id != record.Id && conditionWeight == duplicateConditionWeight) {
                return true;
            }
        }

        return false;
    }

    private Set<String> duplicateCriteriaFields() {
        Set<String> fields = new Set<String>();
        fields.add(Schema.SObjectType.Quality_Gate_Rule_Condition__c.fields.Platform__c.getName());
        fields.add(Schema.SObjectType.Quality_Gate_Rule_Condition__c.fields.Pipeline__c.getName());
        fields.add(Schema.SObjectType.Quality_Gate_Rule_Condition__c.fields.Stage__c.getName());
        fields.add(Schema.SObjectType.Quality_Gate_Rule_Condition__c.fields.Environment__c.getName());
        fields.add(Schema.SObjectType.Quality_Gate_Rule_Condition__c.fields.Quality_Gate_Rule__c.getName());
        fields.add(Schema.SObjectType.Quality_Gate_Rule_Condition__c.fields.Id.getName());
        return fields;
    }
}