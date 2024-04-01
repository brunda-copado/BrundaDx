public with sharing class SetJobTemplateApiName {
    private List<JobTemplate__c> records;

    // CONSTRUCTOR

    public SetJobTemplateApiName(List<JobTemplate__c> records) {
        this.records = records;
    }

    // PUBLIC

    public void execute() {
        for (JobTemplate__c record : records) {
            record.ApiName__c = String.isNotBlank(record.Name)
                ? record.Name.trim().replaceAll('[^a-zA-Z0-9]+', '_').replaceAll(' ', '_') + '_' + Integer.valueOf(record.Version__c)
                : record.Name + '_' + Integer.valueOf(record.Version__c);
        }
    }
}