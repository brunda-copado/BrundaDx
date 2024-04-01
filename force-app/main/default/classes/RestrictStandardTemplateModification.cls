public with sharing class RestrictStandardTemplateModification {
    private List<JobTemplate__c> records;
    private Map<Id, JobTemplate__c> oldRecords = new Map<Id, JobTemplate__c>();

    // CONSTRUCTOR

    public RestrictStandardTemplateModification(List<JobTemplate__c> records) {
        this.records = records;
    }


    public RestrictStandardTemplateModification(List<JobTemplate__c> records, Map<Id, JobTemplate__c> oldRecords) {
        this.records = records;
        this.oldRecords = oldRecords;
    }


    // PUBLIC

    public void execute() {

        if(!isStandardEditAllowed()) {
            for(JobTemplate__c record : records) {
                if(isStandard(record)) {
                    record.addError(Label.StandardTemplateModificationNotAllowed);
                }
            }
        }
    }


    // PRIVATE

    private Boolean isStandard(JobTemplate__c record) {
        JobTemplate__c oldRecord = oldRecords.get(record.Id);

        return (record.Type__c == 'Standard' || oldRecord?.Type__c == 'Standard');
    }


    private Boolean isStandardEditAllowed() {
        Settings__c setting = Settings__c.getOrgDefaults();

        return Boolean.valueOf(setting.Enable_Standard_Job_Template_Edit__c);
    }
}