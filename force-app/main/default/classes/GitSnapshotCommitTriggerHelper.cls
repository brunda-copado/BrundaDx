public with sharing class GitSnapshotCommitTriggerHelper {
    private static final String SALESFORCE = 'Salesforce';
    private static Map<String, Git_Backup__c> gitSnapshotsById = new Map<String, Git_Backup__c>();

    public static void getGitSnapshot(Git_Org_Commit__c[] commits) {
        Set<Id> gitSnapshotIds = new Set<Id>();
        for (Git_Org_Commit__c snapShotCommit : commits) {
            if (String.isNotEmpty(snapShotCommit.Git_Backup__c)) {
                gitSnapshotIds.add(snapShotCommit.Git_Backup__c);
            }
        }
        gitSnapshotsById = new Map<String, Git_Backup__c>(new GitSnapshotSelector().byIds(gitSnapshotIds));
    }

    public static Boolean byPassClassicCodeSnapshotCommit(Git_Org_Commit__c snapShotCommit) {
        return gitSnapshotsById.containsKey(snapShotCommit.Git_Backup__c) && gitSnapshotsById.get(snapShotCommit.Git_Backup__c)?.Pipeline__c != null;
    }
}