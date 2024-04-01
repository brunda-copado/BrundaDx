public with sharing class RestrictQgrDuplicate {
    private List<Quality_Gate_Rule__c> records;
    private Set<String> duplicateCriteriaFields;

    // CTOR

    public RestrictQgrDuplicate(List<Quality_Gate_Rule__c> records) {
        this.records = records;
        this.duplicateCriteriaFields = duplicateCriteriaFields();
    }

    // PUBLIC

    public void execute() {
        for (Quality_Gate_Rule__c record : records) {
            if (record.status__c == 'Active' && isDuplicate(record)) {
                record.addError(Label.Duplicate_Quality_Gate_Rule_Error);
            }
        }
    }

    // PRIVATE

    private Boolean isDuplicate(Quality_Gate_Rule__c record) {
        // Approach to find the duplicates can be custom logic instead of the query filter to retrieve duplicate records
        // to avoid query in the loop. But since this is designed early in the implementation, we will not have more than 1 duplicate records.
        // Single record will be inserted/updated as per current design.
        List<Quality_Gate_Rule__c> duplicateRules = new FindDuplicates(record, duplicateCriteriaFields).execute();
        return !duplicateRules.isEmpty();
    }

    private Set<String> duplicateCriteriaFields() {
        Set<String> fields = new Set<String>();
        fields.add(Schema.SObjectType.Quality_Gate_Rule__c.fields.Tool__c.getName());
        fields.add(Schema.SObjectType.Quality_Gate_Rule__c.fields.Execution_sequence__c.getName());
        fields.add(Schema.SObjectType.Quality_Gate_Rule__c.fields.Actions__c.getName());
        fields.add(Schema.SObjectType.Quality_Gate_Rule__c.fields.Id.getName());
        return fields;
    }
}