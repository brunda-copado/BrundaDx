public with sharing class DestinationOrgTriggerHandler extends fflib_SObjectDomain {
    // CONSTRUCTOR

    public DestinationOrgTriggerHandler(List<Destination_Org__c> records) {
        super(records);
    }

    // PUBLIC

    public override void onAfterInsert() {
        new DestinationOrgTriggerHelper(records, true).afterInsert();
    }

    public override void onAfterDelete() {
        new DestinationOrgTriggerHelper(records, true).afterDelete();
    }

    // INNER

    public class Constructor implements fflib_SObjectDomain.IConstructable {
        public fflib_SObjectDomain construct(List<SObject> records) {
            return new DestinationOrgTriggerHandler(records);
        }
    }
}