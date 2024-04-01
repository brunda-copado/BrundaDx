public with sharing class NewSnapshotIntermediaryController {
    // PUBLIC

    @AuraEnabled(cacheable=true)
    public static String getClassicURL() {
        try {
            Pagereference pr = Page.EditGitBackup;
            return pr.getUrl();
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    // False positive since we can not put CRUD for PermissionSetAssignment
    @SuppressWarnings('PMD.ApexCRUDViolation')
    @AuraEnabled(cacheable=true)
    public static Boolean userHasSnapshotPermission() {
        return Utilities.checkPermission('Configure_Snapshot', new Set<Id>{UserInfo.getUserId()}, false);
    }
}