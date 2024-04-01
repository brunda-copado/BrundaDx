trigger SprintTrigger on Sprint__c(before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    fflib_SObjectDomain.triggerHandler(SprintTriggerHandler.class);
}