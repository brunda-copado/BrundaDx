public with sharing class RestrictQualityGateUpdateOrDelete {
    private static final String STATUS_FIELD = Schema.SObjectType.Quality_Gate_Rule__c.fields.Status__c.getName();

    private List<sObject> records;
    private Map<Id, SObject> oldRecords;

    // CTOR

    public RestrictQualityGateUpdateOrDelete(List<sObject> records, Map<Id, SObject> oldRecords) {
        this.records = records;
        this.oldRecords = oldRecords;
    }

    // PUBLIC

    public void execute() {
        for (sObject record : records) {
            sObject oldRecord = oldRecords?.get(record.Id);

            if (
                record.get(STATUS_FIELD) == QualityGateConstants.ACTIVE &&
                ((oldRecord != null && oldRecord.get(STATUS_FIELD) == QualityGateConstants.ACTIVE) || oldRecord == null)
            ) {
                record.addError(Label.Deactive_Quality_Gate_Rule_Error);
            }
        }
    }
}