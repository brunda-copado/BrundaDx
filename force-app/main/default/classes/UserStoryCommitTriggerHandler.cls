@SuppressWarnings('PMD.EmptyStatementBlock')
public with sharing class UserStoryCommitTriggerHandler implements ITrigger {
    public static Boolean bypassTrigger = false;

    public class ApplicationException extends Exception {
    }
    public UserStoryCommitTriggerHandler() {
    }

    public void bulkBefore() {
        if (!UserStoryCommitTriggerHandler.bypassTrigger) {
            UserStoryCommitTriggerHelper.prepareData();
        }
    }

    public void bulkAfter() {
    }

    public void beforeInsert(SObject so) {
        if (!UserStoryCommitTriggerHandler.bypassTrigger) {
            UserStoryCommitTriggerHelper.setNewDefaults((User_Story_Commit__c) so);
        }
    }

    public void beforeUpdate(SObject oldSo, SObject so) {
    }

    public void beforeDelete(SObject so) {
    }

    public void afterInsert(SObject so) {
        if (!UserStoryCommitTriggerHandler.bypassTrigger) {
            UserStoryCommitTriggerHelper.prepareLatestCommitDateData(Trigger.newMap);
        }
    }

    public void afterUpdate(SObject oldSo, SObject so) {
    }

    public void afterDelete(SObject so) {
    }

    public void afterUndelete(SObject so) {
    }
    public void andFinally() {
        if (!UserStoryCommitTriggerHandler.bypassTrigger) {
            UserStoryCommitTriggerHelper.dmlOperations();
        }
    }
}