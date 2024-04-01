global inherited sharing class TakeGitSnapshotServiceInv{
    @InvocableMethod(label='Take Snapshot' description='Take a snapshot from an Environment' category='Copado Multi-Cloud')
    global static List<Actions.TakeGitSnapshotResult> executeInv(List<Actions.TakeGitSnapshotRequest> takeSnapRequests){

        Integer bulkSize = 1;
        if (takeSnapRequests.size() > bulkSize){
            throw new ApplicationException(Label.OnlyOneRequestAvailable);
        }
        
        Actions.TakeGitSnapshotResult[] takeSnapResults = new Actions.TakeGitSnapshotResult[]{};
        
        for(Actions.TakeGitSnapshotRequest r : takeSnapRequests){
            takeSnapResults.add(Actions.GitSnapshotService.takeSnapshot(r));
        }

        return takeSnapResults;
    }
}