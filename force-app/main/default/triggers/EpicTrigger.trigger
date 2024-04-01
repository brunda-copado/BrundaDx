trigger EpicTrigger on Epic__c (before delete, after insert, after undelete, after update) {
	TriggerFactory.createAndExecuteHandler(EpicTriggerHandler.class);
}