trigger UserStoryDependencyTrigger on Team_Dependency__c(after delete, after insert, after update, before delete, before insert, before update) {
    fflib_SObjectDomain.triggerHandler(UserStoryDependencyTriggerHandler.class);
}