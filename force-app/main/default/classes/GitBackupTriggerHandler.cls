@SuppressWarnings('PMD.EmptyStatementBlock, PMD.AvoidDeeplyNestedIfStmts, PMD.CognitiveComplexity, PMD.CyclomaticComplexity ')
public with sharing class GitBackupTriggerHandler implements ITrigger {
    private ValidateGitSnapshot gitSnapshotValidator;

    String feature = !LicenseHelper.isCopadoEnabled() ? 'CCM Git Backup' : 'Git Backup';
    public class ApplicationException extends Exception {
    }

    public GitBackupTriggerHandler() {
    }

    public void bulkBefore() {
        //prevent any DML for non Copado enabled users

        if (!Trigger.isDelete) {
            if (!GitSnapshotHelper.byPassClassicCodeGitSnapshot(Trigger.New)) {
                if (Trigger.isInsert || Trigger.isUpdate) {
                    if (LicenseHelper.isLicensesExceeded()) {
                        for (Git_Backup__c st : (List<Git_Backup__c>) Trigger.New) {
                            if (st.Pipeline__c == null) {
                                st.addError(Label.LICENSES_EXCEEDED);
                            }
                        }
                    }
                }
                if (Trigger.isInsert && !LicenseHelper.isCopadoEnabled()) {
                    throw new ApplicationException(Label.COPADO_DEPLOYER_LICENSE_NOT_ENABLED);
                }
            } else {
                gitSnapshotValidator = new ValidateGitSnapshot().forTrigger((List<Git_Backup__c>) Trigger.New);
                GitSnapshotHelper.prepareGitRepositories(Trigger.new);
            }
        } else if (!Trigger.isUndelete && Trigger.isDelete && GitSnapshotHelper.byPassClassicCodeGitSnapshot(Trigger.Old)) {
            GitSnapshotHelper.prepareGitRepositories(Trigger.old);
            GitSnapshotHelper.getSnapshotCommits(Trigger.old);
        }
    }

    public void bulkAfter() {
    }

    public void beforeInsert(SObject so) {
        //PLATFORM LOGIC
        if (GitSnapshotHelper.byPassClassicCodeGitSnapshot(new List<Git_Backup__c>{ (Git_Backup__c) so })) {
            List<String> errorMessages = gitSnapshotValidator.execute((Git_Backup__c) so);
            if (!errorMessages.isEmpty()) {
                so.addError(errorMessages[0]);
            }

            //CLASSIC LOGIC
        } else if (!FeatureHelper.isFeatureEnabled('Git Backup')) {
            so.addError(Label.FEATURE_NOT_SUPPORTED + ': Git Backup');
        }
    }

    public void beforeUpdate(SObject oldSo, SObject so) {
        //PLATFORM LOGIC
        if (GitSnapshotHelper.byPassClassicCodeGitSnapshot(new List<Git_Backup__c>{ (Git_Backup__c) so })) {
            List<String> errorMessages = gitSnapshotValidator.execute((Git_Backup__c) so);
            if (!errorMessages.isEmpty()) {
                so.addError(errorMessages[0]);
            }

            //CLEAN CRON EXPRESSION IF Snapshot_Frequency__c is NONE
            GitSnapshotHelper.cleanCronExp((Git_Backup__c) so, (Git_Backup__c) oldSo);
            //CLASSIC LOGIC
        } else if (!FeatureHelper.isFeatureEnabled('Git Backup')) {
            so.addError(Label.FEATURE_NOT_SUPPORTED + ': Git Backup');
        }
    }

    public void beforeDelete(SObject so) {
        if (GitSnapshotHelper.byPassClassicCodeGitSnapshot(new List<Git_Backup__c>{ (Git_Backup__c) so })) {
            GitSnapshotHelper.prepareJobsToAbortOnDelete((Git_Backup__c) so);
        }
    }

    public void afterInsert(SObject so) {
        //PLATFORM LOGIC
        if (GitSnapshotHelper.byPassClassicCodeGitSnapshot(new List<Git_Backup__c>{ (Git_Backup__c) so })) {
            GitSnapshotHelper.scheduleGitSnapshot((Git_Backup__c) so, null);
            GitSnapshotHelper.populateExternalId((Git_Backup__c) so);

            //CLASSIC LOGIC
        } else {
            GitBackupTriggerHelper.isScheduled((Git_Backup__c) so);
        }
    }

    public void afterUpdate(SObject oldSo, SObject so) {
        //PLATFORM LOGIC
        if (GitSnapshotHelper.byPassClassicCodeGitSnapshot(new List<Git_Backup__c>{ (Git_Backup__c) so })) {
            GitSnapshotHelper.scheduleGitSnapshot((Git_Backup__c) so, (Git_Backup__c) oldSo);

            //CLASSIC LOGIC
        } else {
            GitBackupTriggerHelper.isScheduled((Git_Backup__c) so);
        }
    }

    public void afterDelete(SObject so) {
    }

    public void afterUndelete(SObject so) {
    }
    public void andFinally() {
        GitBackupTriggerHelper.enforceScheduler();
        GitSnapshotHelper.updateExternalId();
        GitSnapshotHelper.abortSnapshotJobs();
        GitSnapshotHelper.scheduleSnapshots();
        GitSnapshotHelper.deleteCommits();
    }
}