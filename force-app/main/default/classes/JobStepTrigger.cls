public with sharing class JobStepTrigger extends fflib_SObjectDomain {
    // CONSTRUCTOR

    public JobStepTrigger(List<JobStep__c> records) {
        super(records);
    }

    // PUBLIC

    public override void onApplyDefaults() {
        new SetJobStepApiName(records).execute();
    }

    public override void onValidate() {
        new RestrictStandardStepModification(records).execute();
    }

    public override void onValidate(Map<Id, SObject> oldMap) {
        new RestrictStandardStepModification(records).execute();
    }

    public override void onBeforeDelete() {
        new RestrictTestStepDeletion(records).run();
        new RestrictStandardStepModification(records).execute();
        new ReleaseQueue(records).execute();
    }

    public override void onBeforeUpdate(Map<Id, SObject> oldMap) {
        new ReorderDeploymentJobSteps(records, (Map<Id, JobStep__c>) oldMap).execute();
    }

    // INNER

    public class Constructor implements fflib_SObjectDomain.IConstructable {
        public fflib_SObjectDomain construct(List<SObject> records) {
            return new JobStepTrigger(records);
        }
    }
}