trigger UserStoryTrigger on User_Story__c(
    after delete,
    after insert,
    after undelete,
    after update,
    before delete,
    before insert,
    before update
) {
    if(!UserStories.bypassTrigger) {
        // Note: This handler contains the legacy code for User Story Trigger
        TriggerFactory.createAndExecuteHandler(UserStoryTriggerHandler.class);

        // Note: The new domain layer for handling, validating and routing of trigger events
        // Moving forward add new fetures and existing features to this layer
        fflib_SObjectDomain.triggerHandler(UserStories.class);
    }
}