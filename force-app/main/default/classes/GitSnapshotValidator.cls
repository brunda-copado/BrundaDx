public with sharing class GitSnapshotValidator {
    //PUBLIC

    @AuraEnabled
    public static List<CopadoAlert> validateDataForRecordPage(Id recordId) {
        Git_Backup__c snapshot = getExistingSnapshotDetails(recordId);
        List<String> errors = new ValidateGitSnapshot().mode(ValidateGitSnapshot.ValidationMode.PAGE_MODE).execute(snapshot);
        List<CopadoAlert> result = new List<CopadoAlert>();
        for (String error : errors) {
            result.add(new CopadoAlert().variant(CopadoAlert.Variant.ERROR).message(error));
        }
        return !result.isEmpty() ? result : null;
    }

    //PRIVATE

    @SuppressWarnings('PMD.ApexCRUDViolation')
    private static Git_Backup__c getExistingSnapshotDetails(String recordId) {
        // False Positive: we are using system mode as we need access to all fields (to avoid 2 queries), then we are checking permissions in the validator
        return [
            SELECT
                Id,
                CreatedById,
                Branch__c,
                Org__c,
                Org__r.Name,
                Org__r.Platform__c,
                Org__r.Oauth_Signature__c,
                Org__r.Environment__c,
                Git_Repository__c,
                Git_Repository__r.Name,
                Other_Information__c,
                Scope__c,
                Pipeline__c,
                External_Id__c,
                Cron_Expression__c,
                Snapshot_Frequency__c
            FROM Git_Backup__c
            WHERE External_Id__c = :recordId OR Id = :recordId
            LIMIT 1
        ];
    }
}