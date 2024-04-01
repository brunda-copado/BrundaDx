/**
 * A new domain layer has been added in UserStoryTrigger.apxt
 * Add new feature in that domain and if possible refactor and move existing code to that Domain
 */

/* Note: As we are implementing ITrigger, it is mandatory to mention all methods even if respective trigger events are not added in trigger.*/
@SuppressWarnings('PMD.EmptyStatementBlock')
public with sharing class UserStoryTriggerHandler implements ITrigger {
    public UserStoryTriggerHandler() {
    }

    public void bulkBefore() {
        UserStoryTriggerHelper.prepareMaps();
    }

    /**
     * Modifier is set to private after checking that it was not being referenced anywhere else,
     * so that way the scope of the method funcionality can be reduced and more clear
     */
    private void beforeCommon(SObject oldSo, SObject so) {
        UserStoryTriggerHelper.setProject((User_Story__c) so);
        UserStoryTriggerHelper.setEnvironment((User_Story__c) so);
        UserStoryTriggerHelper.checkSprints((User_Story__c) oldSo, (User_Story__c) so);
        UserStoryTriggerHelper.setOrderBeforeUpdate((User_Story__c) oldSo, (User_Story__c) so);
    }

    public void beforeInsert(SObject so) {
        beforeCommon(null, so);
        UserStoryTriggerHelper.validatePromoteFieldsOnInsert((User_Story__c) so);
    }

    public void beforeUpdate(SObject oldSo, SObject so) {
        beforeCommon(oldSo, so);
        UserStoryTriggerHelper.setChildPromotedUserStoriesAsOutdated((User_Story__c) oldSo, (User_Story__c) so);
        UserStoryTriggerHelper.validatePromoteFieldsOnUpdate((User_Story__c) oldSo, (User_Story__c) so);
    }

    public void beforeDelete(SObject so) {
        UserStoryTriggerHelper.getDeletedUSforDependencyDelete((User_Story__c) so);
    }

    public void bulkAfter() {
    }

    public void afterInsert(SObject so) {
        afterCommon(null, so);
    }

    public void afterUpdate(SObject oldSo, SObject so) {
        afterCommon(oldSo, so);
        UserStoryTriggerHelper.addUserStoryToSubmitQueue((User_Story__c) oldSo, (User_Story__c) so);
        UserStoryTriggerHelper.addUserStoryToPromoteDeployQueue((User_Story__c) oldSo, (User_Story__c) so);
        UserStoryTriggerHelper.checkIndexMetadataChanged((User_Story__c) oldSo, (User_Story__c) so);
        UserStoryTriggerHelper.getReleaseAndTeamForUserStory((User_Story__c) oldSo, (User_Story__c) so);
        UserStoryTriggerHelper.getCompletedUSforDependency((User_Story__c) oldSo, (User_Story__c) so);
    }

    public void afterDelete(SObject so) {
        afterCommon(null, so);
    }

    public void afterUndelete(SObject so) {
        afterCommon(null, so);
    }

    public void andFinally() {
        if (Trigger.isUpdate) {
            if (Trigger.isAfter) {
                UserStoryTriggerHelper.submitUserStories();
                UserStoryTriggerHelper.promoteAndDeployUserStories();
                UserStoryTriggerHelper.updateUserStoryDependencies();
            }
        }
        if (Trigger.isAfter) {
            UserStoryTriggerHelper.updateSprintVelocity();
        }
        if (Trigger.isBefore) {
            if (Trigger.isDelete) {
                UserStoryTriggerHelper.cascadeDeleteUSDependencies();
            }
        }
        UserStoryTriggerHelper.executeIndexMetadataJob();
        UserStoryTriggerHelper.updateOutdatedPromotedUserStories();
    }

    // PRIVATE

    private void afterCommon(SObject oldSo, SObject so) {
        UserStoryTriggerHelper.getSprintVelocity(oldSo, so);
    }
}