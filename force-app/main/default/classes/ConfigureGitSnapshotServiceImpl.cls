public with sharing class ConfigureGitSnapshotServiceImpl {
    // PUBLIC

    public static Actions.ConfigureGitSnapshotResult configure(Actions.ConfigureGitSnapshotRequest request) {
        Id snapshotId = upsertSnapshot(request);

        Actions.ConfigureGitSnapshotResult response = new Actions.ConfigureGitSnapshotResult();
        // After upsert we are populating the external id of the snapshot record, to get the populated value, we need fresh SOQL
        Git_Backup__c snapshot = getExistingSnapshotDetails(snapshotId);
        response.snapshot = snapshot;
        return response;
    }

    // PRIVATE

    private static Id upsertSnapshot(Actions.ConfigureGitSnapshotRequest request) {
        // To find the existing records we will use External Id field from request
        Git_Backup__c snapshot = request.externalId != null ? getExistingSnapshotDetails(request.externalId) : new Git_Backup__c();
        snapshot.name = request.name;
        snapshot.Branch__c = request.branch;
        snapshot.Org__c = request.credentialId;
        snapshot.Git_Repository__c = request.repositoryId;
        snapshot.Other_Information__c = request.additionalInformation;
        snapshot.Scope__c = request.scope;
        snapshot.Pipeline__c = request.pipelineId;
        snapshot.External_Id__c = request.externalId;

        Boolean isSchedule = request.cronExpression != null;
        snapshot.Cron_Expression__c = isSchedule ? request.cronExpression : '';
        snapshot.Snapshot_Frequency__c = isSchedule ? 'Schedule' : 'None';

        DML.safeUpsert(snapshot, 'ConfigureGitSnapshotServiceImpl.upsertSnapshot');
        return snapshot.Id;
    }

    private static Git_Backup__c getExistingSnapshotDetails(String recordId) {
        List<Git_Backup__c> result = [
            SELECT
                Id,
                Branch__c,
                Org__c,
                Git_Repository__c,
                Other_Information__c,
                Scope__c,
                Pipeline__c,
                External_Id__c,
                Cron_Expression__c,
                Snapshot_Frequency__c
            FROM Git_Backup__c
            WHERE External_Id__c = :recordId OR Id = :recordId
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];

        return !result.isEmpty() ? result[0] : new Git_Backup__c();
    }
}