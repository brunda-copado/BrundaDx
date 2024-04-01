public with sharing class GitSnapshotScheduler implements Schedulable {
    public String gitSnapshotId = '';
    public GitSnapshotScheduler(String gitSnapshotId) {
        this.gitSnapshotId = gitSnapshotId;
    }

    public void execute(SchedulableContext scheduleContext) {
        Actions.TakeGitSnapshotRequest request = new Actions.TakeGitSnapshotRequest();
        request.snapshotId = gitSnapshotId;
        request.message = Label.GitSnapshotScheduleCommitMessage;

        Actions.GitSnapshotService.takeSnapshot(request);
    }
}