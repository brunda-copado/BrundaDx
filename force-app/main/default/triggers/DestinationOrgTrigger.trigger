trigger DestinationOrgTrigger on Destination_Org__c(after delete, after insert, after update, before delete, before insert, before update) {
    fflib_SObjectDomain.triggerHandler(DestinationOrgTriggerHandler.class);
}