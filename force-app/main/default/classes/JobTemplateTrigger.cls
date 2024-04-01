public with sharing class JobTemplateTrigger extends fflib_SObjectDomain {

    // CONSTRUCTOR

    public JobTemplateTrigger(List<JobTemplate__c> records) {
        super(records);
    }


    // PUBLIC

    public override void onApplyDefaults() {
        new SetJobTemplateApiName(records).execute();
    }


    public override void onValidate() {
        new ValidateJobTemplateVolumeOption(records).execute();
        new RestrictStandardTemplateModification(records).execute();
    }


    public override void onValidate(Map<Id, SObject> oldMap) {
        new ValidateJobTemplateVolumeOption(records).execute();
        new RestrictStandardTemplateModification(records, (Map<Id, JobTemplate__c>)oldMap).execute();
    }


    public override void onBeforeDelete() {
        new RestrictStandardTemplateModification(records).execute();
    }


    // INNER

    public class Constructor implements fflib_SObjectDomain.IConstructable {
        public fflib_SObjectDomain construct(List<SObject> records) {
            return new JobTemplateTrigger(records);
        }
    }
}