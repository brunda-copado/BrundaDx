trigger StageConnectionTrigger on Stage_Connection__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
    fflib_SObjectDomain.triggerHandler(StageConnections.class);
}