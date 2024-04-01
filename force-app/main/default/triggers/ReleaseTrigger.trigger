trigger ReleaseTrigger on Release__c (before delete, after insert, after undelete, after update) {
	TriggerFactory.createAndExecuteHandler(ReleaseTriggerHandler.class);
}