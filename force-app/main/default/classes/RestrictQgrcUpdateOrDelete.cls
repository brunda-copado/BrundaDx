public with sharing class RestrictQgrcUpdateOrDelete {
    private List<Quality_Gate_Rule_Condition__c> records;

    // CTOR

    public RestrictQgrcUpdateOrDelete(List<Quality_Gate_Rule_Condition__c> records) {
        this.records = records;
    }

    // PUBLIC

    public void execute() {
        for (Quality_Gate_Rule_Condition__c record : records) {
            if (record.status__c == 'Active') {
                record.addError(Label.Deactive_Quality_Gate_Rule_Error);
            }
        }
    }
}