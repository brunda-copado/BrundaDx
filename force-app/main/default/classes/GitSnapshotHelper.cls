@SuppressWarnings('PMD.CognitiveComplexity,PMD.CyclomaticComplexity,PMD.OperationWithLimitsInLoop')
public with sharing class GitSnapshotHelper {
    private static Boolean alreadyUpdated = false;
    private static final String SALESFORCE = 'Salesforce';
    private static final String SCHEDULE = 'Schedule';
    private static final String NONE = 'None';

    private static Map<Id, Git_Repository__c> gitRepositoryById = new Map<Id, Git_Repository__c>();
    private static List<Git_Backup__c> snapshotsToUpdateIds = new List<Git_Backup__c>();
    public static list<Git_Backup__c> snapshotsToSchedule = new List<Git_Backup__c>();
    public static list<Git_Backup__c> snapshotsToAbort = new List<Git_Backup__c>();
    public static List<Git_Org_Commit__c> commitsToDelete = new List<Git_Org_Commit__c>();

    public static Boolean byPassClassicCodeGitSnapshot(Git_Backup__c[] snapshots) {
        for (Git_Backup__c snap : snapshots) {
            if (snap.Pipeline__c == null) {
                return false;
            }
        }
        return true;
    }

    public static void prepareGitRepositories(List<Git_Backup__c> gitSnapshots) {
        set<Id> gitRepositoryIds = new Set<Id>();
        for (Git_Backup__c gitSnapshot : gitSnapshots) {
            gitRepositoryIds.add(gitSnapshot.Git_Repository__c);
        }
        gitRepositoryById = new Map<Id, Git_Repository__c>(
            [SELECT Id, Name FROM Git_Repository__c WHERE Id IN :gitRepositoryIds WITH SECURITY_ENFORCED]
        );
    }

    public static void scheduleSnapshots() {
        for (Git_Backup__c gitSnapshot : snapshotsToSchedule) {
            try {
                System.schedule(getJobName(gitSnapshot), gitSnapshot.Cron_Expression__c, new GitSnapshotScheduler(gitSnapshot.Id));
            } catch (StringException e) {
                gitSnapshot.addError(Label.InvalidCronExpressionMessage);
            }
        }
        snapshotsToSchedule.clear();
    }

    @SuppressWarnings('PMD.ApexCRUDViolation')
    public static void abortSnapshotJobs() {
        Map<Id, String> gitSnapshotJobNameById = new Map<Id, String>();
        for (Git_Backup__c gitSnapshot : snapshotsToAbort) {
            gitSnapshotJobNameById.put(gitSnapshot.Id, getJobName(gitSnapshot));
        }

        if (!gitSnapshotJobNameById.isEmpty()) {
            for (CronTrigger cronJob : [
                SELECT Id, State, CronjobDetail.Name, CronJobDetail.Id, NextFireTime
                FROM CronTrigger
                WHERE CronjobDetail.Name IN :gitSnapshotJobNameById.values()
            ]) {
                System.abortJob(cronJob.Id);
            }
        }
        snapshotsToAbort.clear();
    }

    public static void prepareJobsToAbortOnDelete(Git_Backup__c gitSnapshot) {
        snapshotsToAbort.add(gitSnapshot);
    }

    public static void cleanCronExp(Git_Backup__c gitSnapshot, Git_Backup__c oldGitSnapshot) {
        if (
            gitSnapshot.Snapshot_Frequency__c == NONE &&
            isChanged(gitSnapshot, oldGitSnapshot, Schema.SObjectType.Git_Backup__c.fields.Snapshot_Frequency__c.getName()) &&
            gitSnapshot.Cron_Expression__c != null
        ) {
            gitSnapshot.Cron_Expression__c = null;
        }
    }

    public static Void scheduleGitSnapshot(Git_Backup__c gitSnapshot, Git_Backup__c oldGitSnapshot) {
        if (oldGitSnapshot == null) {
            //INSERT WE DONT HAVE OLD SNAPSHOT

            if (
                gitSnapshot.Snapshot_Frequency__c != null &&
                gitSnapshot.Snapshot_Frequency__c == SCHEDULE &&
                gitSnapshot.Cron_Expression__c != null
            ) {
                snapshotsToSchedule.add(gitSnapshot);
            }
        } else {
            // Update Cron Expression
            if (
                gitSnapshot.Snapshot_Frequency__c == SCHEDULE &&
                gitSnapshot.Cron_Expression__c != null &&
                isChanged(gitSnapshot, oldGitSnapshot, Schema.SObjectType.Git_Backup__c.fields.Cron_Expression__c.getName())
            ) {
                snapshotsToAbort.add(gitSnapshot);
                snapshotsToSchedule.add(gitSnapshot);

                // Changing Frequency to None
            } else if (
                gitSnapshot.Snapshot_Frequency__c == NONE &&
                isChanged(gitSnapshot, oldGitSnapshot, Schema.SObjectType.Git_Backup__c.fields.Snapshot_Frequency__c.getName())
            ) {
                snapshotsToAbort.add(gitSnapshot);
            }
        }
    }

    public static void populateExternalId(Git_Backup__c newSnapshot) {
        if (String.isBlank(newSnapshot.External_Id__c)) {
            snapshotsToUpdateIds.add(new Git_Backup__c(Id = newSnapshot.Id, External_Id__c = newSnapshot.Id));
        }
    }

    // False positive since it will work in trigger context and we are updating the trigger context object, no need to check FLS or CRUD
    public static void updateExternalId() {
        if (!snapshotsToUpdateIds.isEmpty() && !alreadyUpdated) {
            List<Git_Backup__c> newGitList = snapshotsToUpdateIds.deepClone(true, true, true);
            snapshotsToUpdateIds.clear();

            update newGitList; // NOPMD
            alreadyUpdated = true;
        }
    }

    // PMD False positive, as WITH USER_MODE is not supported yet
    @SuppressWarnings('PMD.ApexCRUDViolation')
    public static void getSnapshotCommits(List<Git_Backup__c> gitSnapshots) {
        Set<Id> gitSnapshotIds = new Map<Id, Git_Backup__c>(gitSnapshots).keySet();
        List<Git_Org_Commit__c> commits = [SELECT Id FROM Git_Org_Commit__c WHERE Git_Backup__c IN :gitSnapshotIds WITH USER_MODE];
        commitsToDelete.addAll(commits);
    }

    public static void deleteCommits() {
        if (!commitsToDelete.isEmpty()) {
            DML.safeDelete(
                commitsToDelete,
                String.format(
                    Label.ErrorWhileDeleting,
                    new List<String>{
                        Git_Org_Commit__c.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).getLabel(),
                        'GitSnapshotHelper.deleteCommits'
                    }
                )
            );
            commitsToDelete.clear();
        }
    }

    // PRIVATE

    private static Boolean isChanged(SObject so, SObject oldSo, String fieldName) {
        return so.get(fieldName) != oldSo.get(fieldName);
    }

    private static String getJobName(Git_Backup__c gitSnapshot) {
        return gitSnapshot.Id + '_' + gitRepositoryById.get(gitSnapshot.Git_Repository__c).Name;
    }
}