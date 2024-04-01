public with sharing class SprintTriggerHandler extends fflib_SObjectDomain {
    // CONSTRUCTOR

    public SprintTriggerHandler(List<Sprint__c> records) {
        super(records);
    }

    // PUBLIC

    public override void onBeforeUpdate(Map<Id, SObject> old) {
        new SprintVelocityRollUp(records, (Map<Id, Sprint__c>) old).execute();
    }

    // INNER

    public class Constructor implements fflib_SObjectDomain.IConstructable {
        public fflib_SObjectDomain construct(List<SObject> records) {
            return new SprintTriggerHandler(records);
        }
    }
}