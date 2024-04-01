trigger CustomConnectedAppTrigger on Custom_Connected_App_Info__c (before delete, before update, before insert, after insert, after undelete, after update) {
    TriggerFactory.createAndExecuteHandler(CustomConnectedAppTriggerHandler.class);
}