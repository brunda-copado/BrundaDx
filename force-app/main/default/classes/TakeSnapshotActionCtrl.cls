public with sharing class TakeSnapshotActionCtrl {
    @AuraEnabled
    public static void executeAction(String snapshotId, String message) {
        try {
            Actions.TakeGitSnapshotRequest request = new Actions.TakeGitSnapshotRequest();
            request.snapshotId = snapshotId;
            request.message = message;
            Actions.GitSnapshotService.takeSnapshot(request);
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }
    }
}