public with sharing class JobStepTriggerHandler extends fflib_SObjectDomain {

    // CONSTRUCTOR

    public JobStepTriggerHandler(List<JobStep__c> records) {
        super(records);
    }


    // PUBLIC

    public override void onApplyDefaults() {
        new SetJobStepApiName(records).execute();
    }


    // INNER

    public class Constructor implements fflib_SObjectDomain.IConstructable {
        public fflib_SObjectDomain construct(List<SObject> records) {
            return new JobStepTriggerHandler(records);
        }
    }
}