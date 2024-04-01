trigger UserStoryTaskTrigger on User_Story_Task__c (after delete, after insert, after undelete, 
after update, before delete, before insert, before update) {
	TriggerFactory.createAndExecuteHandler(UserStoryTaskTriggerHandler.class);
}