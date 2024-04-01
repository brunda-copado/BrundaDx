public with sharing class QualityAutomation {
    private List<Quality_Gate_Rule__c> records;
    private Map<Id, Quality_Gate_Rule__c> oldRecords;

    // CTOR

    public QualityAutomation(List<sObject> records, Map<Id, sObject> oldRecords) {
        this.records = (List<Quality_Gate_Rule__c>) records;
        this.oldRecords = (Map<Id, Quality_Gate_Rule__c>) oldRecords;
    }

    // PUBLIC

    public void execute() {
        Map<Id, Quality_Gate_Rule__c> ruleIdsToCreateAutomations = new Map<Id, Quality_Gate_Rule__c>();
        Set<Id> ruleIdsToDeleteAutomations = new Set<Id>();

        for (Quality_Gate_Rule__c record : records) {
            Quality_Gate_Rule__c oldRecord = oldRecords?.get(record.Id);
            if (createAutomationCriteriaMatch(record, oldRecord)) {
                ruleIdsToCreateAutomations.put(record.Id, record);
            }

            if (deleteAutomationCriteriaMatch(record, oldRecord)) {
                ruleIdsToDeleteAutomations.add(record.Id);
            }
        }

        if (!ruleIdsToCreateAutomations.isEmpty() || !ruleIdsToDeleteAutomations.isEmpty()) {
            new QualityAutomationEngine(ruleIdsToCreateAutomations, ruleIdsToDeleteAutomations).execute();
        }
    }

    // PRIVATE

    private Boolean createAutomationCriteriaMatch(Quality_Gate_Rule__c record, Quality_Gate_Rule__c oldRecord) {
        return isActiveUpdated(record, oldRecord) &&
            record.Status__c == QualityGateConstants.ACTIVE &&
            record.Execution_sequence__c == QualityGateConstants.AFTER;
    }

    private Boolean deleteAutomationCriteriaMatch(Quality_Gate_Rule__c record, Quality_Gate_Rule__c oldRecord) {
        return isActiveUpdated(record, oldRecord) &&
            record.Status__c == QualityGateConstants.INACTIVE &&
            record.Execution_sequence__c == QualityGateConstants.AFTER;
    }

    private Boolean isActiveUpdated(Quality_Gate_Rule__c record, Quality_Gate_Rule__c oldRecord) {
        return record.Status__c != oldRecord?.Status__c;
    }
}