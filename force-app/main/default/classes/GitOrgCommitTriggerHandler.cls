@SuppressWarnings('PMD.EmptyStatementBlock')
public with sharing class GitOrgCommitTriggerHandler implements ITrigger {
    public static Boolean bypassTrigger = false;

    public class ApplicationException extends Exception {
    }

    public GitOrgCommitTriggerHandler() {
    }

    public void bulkBefore() {
        if (!GitOrgCommitTriggerHandler.bypassTrigger) {
            //Query Credentials
            if (Trigger.isInsert) {
                GitSnapshotCommitTriggerHelper.getGitSnapshot(Trigger.new);
            }
        }
    }

    public void bulkAfter() {
    }

    public void beforeInsert(SObject so) {
        if (!GitOrgCommitTriggerHandler.bypassTrigger) {
            if (!GitSnapshotCommitTriggerHelper.bypassClassicCodeSnapshotCommit((Git_Org_Commit__c) so)) {
                GitOrgCommitTriggerHelper.setCommitDate((Git_Org_Commit__c) so);
            }
        }
    }

    public void beforeUpdate(SObject oldSo, SObject so) {
    }

    public void beforeDelete(SObject so) {
    }

    public void afterInsert(SObject so) {
        if (!GitOrgCommitTriggerHandler.bypassTrigger) {
            if (!GitSnapshotCommitTriggerHelper.bypassClassicCodeSnapshotCommit((Git_Org_Commit__c) so)) {
                GitOrgCommitTriggerHelper.updateOrgLastCommit((Git_Org_Commit__c) so);
            }
        }
    }

    public void afterUpdate(SObject oldSo, SObject so) {
    }

    public void afterDelete(SObject so) {
    }

    public void afterUndelete(SObject so) {
    }

    public void andFinally() {
        if (!GitOrgCommitTriggerHandler.bypassTrigger) {
            if (Trigger.isAfter) {
                GitOrgCommitTriggerHelper.updateOrgCredentialLastBackup();
            }
        }
    }
}