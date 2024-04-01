public with sharing class Stages extends fflib_SObjectDomain {
    // CTOR

    public Stages(List<Stage__c> records) {
        super(records);
    }

    // PUBLIC

    public override void onBeforeDelete() {
        new PreventDeletionOfStagesInUse(records).execute();
    }

    // INNER

    public class Constructor implements fflib_SObjectDomain.IConstructable {
        public fflib_SObjectDomain construct(List<SObject> records) {
            return new Stages(records);
        }
    }
}