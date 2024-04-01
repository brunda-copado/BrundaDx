public inherited sharing class TakeGitSnapshotServiceImpl implements JobExecutionCallback {
    // PUBLIC

    public static Actions.TakeGitSnapshotResult execute(Actions.TakeGitSnapshotRequest request) {
        Git_Backup__c gitSnapshot = getGitSnapshot(request.snapshotId);

        List<String> errorMessages = new ValidateGitSnapshot().execute(gitSnapshot);
        if (!errorMessages.isEmpty()) {
            sendNotification(gitSnapshot, JobExecutionConstants.STATUS_ERROR);
            throw new ApplicationException(String.join(errorMessages, '\n'));
        }

        Git_Org_Commit__c gitSnapshotCommit = insertGitSnapshotCommit(gitSnapshot, request.message);

        JobExecution__c jobExecution = createJob(gitSnapshot, gitSnapshotCommit, request);
        Jobs.Execution.execute(new Jobs.ExecutionRequest(jobExecution.Id, gitSnapshotCommit.Id));

        Actions.TakeGitSnapshotResult result = new Actions.TakeGitSnapshotResult();
        result.jobExecution = jobExecution;
        result.snapshotCommit = gitSnapshotCommit;
        return result;
    }

    public void execute(JobExecution__c job, String status) {
        Map<String, String> snapshotStatusByJobStatus = new Map<String, String>{
            JobExecutionConstants.STATUS_NOT_STARTED => CommitConstants.STATUS_PENDING,
            JobExecutionConstants.STATUS_IN_PROGRESS => CommitConstants.STATUS_IN_PROGRESS,
            JobExecutionConstants.STATUS_SUCCESSFUL => CommitConstants.STATUS_COMPLETE,
            JobExecutionConstants.STATUS_CANCELLED => CommitConstants.STATUS_FAILED,
            JobExecutionConstants.STATUS_ERROR => CommitConstants.STATUS_FAILED
        };

        ExecutionData executionData = (ExecutionData) JSON.deserialize(job.DataJson__c, ExecutionData.class);
        Git_Backup__c gitSnapshot = getGitSnapshot(executionData.gitSnapshotId);
        Git_Org_Commit__c gitSnapshotCommit = getGitSnapshotCommit(executionData.gitSnapshotCommitId);
        try {
            ResultPayload resultData = getResultPayload(job.Id);
            String commitId = resultData.commitId;
            String commitStatus = String.isNotBlank(resultData.status) ? resultData.status : snapshotStatusByJobStatus.get(status);
            DML.safeUpdate(
                new Git_Org_Commit__c(Id = gitSnapshotCommit.Id, Commit_Id__c = commitId, Status__c = commitStatus),
                String.format(
                    Label.ErrorWhileUpdating,
                    new List<String>{
                        Git_Org_Commit__c.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).getLabel(),
                        'TakeGitSnapshotServiceImpl.execute'
                    }
                )
            );

            DML.safeUpdate(
                new Git_Backup__c(Id = gitSnapshot.Id, Last_Backup__c = System.now()),
                String.format(
                    Label.ErrorWhileUpdating,
                    new List<String>{
                        Git_Backup__c.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).getLabel(),
                        'TakeGitSnapshotServiceImpl.execute'
                    }
                )
            );
            new ActionCallback(executionData.actionCallback, job, status).run();
        } catch (Exception ex) {
            job.Status__c = JobExecutionConstants.STATUS_ERROR;
            throw new ApplicationException(ex.getMessage());
        } finally {
            sendNotification(gitSnapshot, status);
            publishAutomationEvent(gitSnapshot, gitSnapshotCommit, job);
        }
    }

    // PRIVATE

    private static Git_Backup__c getGitSnapshot(String snapshotId) {
        List<Git_Backup__c> gitSnapshots = [
            SELECT Name, CreatedById, Org__c, Org__r.Environment__c, Pipeline__c
            FROM Git_Backup__c
            WHERE Id = :snapshotId OR External_Id__c = :snapshotId
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];
        if (gitSnapshots.isEmpty()) {
            throw new ApplicationException(Label.Git_Snapshot_Not_Found);
        }
        return gitSnapshots[0];
    }

    private static Git_Org_Commit__c getGitSnapshotCommit(String snapshotCommitId) {
        List<Git_Org_Commit__c> gitSnapshotCommits = [
            SELECT Name, Commit_Date__c, Commit_Id__c, Commit_Message__c, Org__c, Git_Backup__c, Status__c
            FROM Git_Org_Commit__c
            WHERE Id = :snapshotCommitId
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];
        if (gitSnapshotCommits.isEmpty()) {
            throw new ApplicationException(Label.Git_Snapshot_Commit_Record_Not_Found);
        }
        return gitSnapshotCommits[0];
    }

    private static Git_Org_Commit__c insertGitSnapshotCommit(Git_Backup__c gitSnapshot, String commitMessage) {
        Git_Org_Commit__c gitSnapshotCommit = new Git_Org_Commit__c(
            Commit_Date__c = System.now(),
            Commit_Message__c = commitMessage.left(255),
            Git_Backup__c = gitSnapshot.Id,
            Git_Operation__c = 'Commit Files',
            Org__c = gitSnapshot.Org__c,
            Status__c = CommitConstants.STATUS_PENDING
        );
        DML.safeInsert(
            gitSnapshotCommit,
            String.format(
                Label.ErrorWhileInserting,
                new List<String>{
                    Git_Org_Commit__c.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).getLabel(),
                    'TakeGitSnapshotServiceImpl.insertGitSnapshotCommit'
                }
            )
        );
        return gitSnapshotCommit;
    }

    private static JobExecution__c createJob(Git_Backup__c gitSnapshot, Git_Org_Commit__c gitSnapshotCommit, Actions.TakeGitSnapshotRequest request) {
        ExecutionData executionData = new ExecutionData();
        executionData.gitSnapshotId = gitSnapshot.Id;
        executionData.gitSnapshotCommitId = gitSnapshotCommit.Id;
        executionData.actionCallback = request.actionCallback;
        executionData.message = request.message;
        executionData.otherInformation = request.otherInformation;

        Jobs.ExecutionCreateFromTemplateRequest jobRequest = new Jobs.ExecutionCreateFromTemplateRequest();
        jobRequest.parentId = gitSnapshot.Id;
        jobRequest.pipelineId = gitSnapshot.Pipeline__c;
        jobRequest.templateAPIName = new ActionTemplate(ActionConstants.TAKE_SNAPSHOT).gitSnapshot(gitSnapshot).getApiName();
        jobRequest.callback = TakeGitSnapshotServiceImpl.class.getName();
        jobRequest.dataJson = JSON.serializePretty(executionData, true);
        jobRequest.sourceId = gitSnapshot.Org__r.Environment__c;
        JobExecution__c job = Jobs.Execution.createFromTemplate(jobRequest).jobExecution;
        // Note: temporary solution until we decide how to relate Job Execution with snapshot commit using service methods
        job.ParentRecord_Id__c = gitSnapshotCommit.Id;
        DML.safeUpdate(
            job,
            String.format(
                Label.ErrorWhileUpdating,
                new List<String>{
                    JobExecution__c.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).getLabel(),
                    'TakeGitSnapshotServiceImpl.createJob'
                }
            )
        );
        return job;
    }

    private static ResultPayload getResultPayload(Id jobExecutionId) {
        return parseResultData(getResultData(jobExecutionId));
    }

    private static String getResultData(Id jobExecutionId) {
        Result__c jobResult = new ActionResult(jobExecutionId).getRecord();
        return jobResult?.Result_Data__c;
    }

    private static ResultPayload parseResultData(String resultDataRaw) {
        ResultPayload result = new ResultPayload();
        if (String.isNotBlank(resultDataRaw)) {
            try {
                result = (ResultPayload) JSON.deserialize(resultDataRaw, ResultPayload.class);
            } catch (JSONException e) {
                Logger.error(null, 'parseResultData fail', '', null, e);
            }
        }
        return result;
    }

    private static void sendNotification(Git_Backup__c gitSnapshot, String status) {
        CopadoNotifications.SendRequest request = new CopadoNotifications.SendRequest();
        request.name = status == JobExecutionConstants.STATUS_SUCCESSFUL ? 'Successful_Snapshot' : 'Failed_Snapshot';
        request.recipientIds = new Set<Id>{ UserInfo.getUserId() };
        request.mergeData = new Map<String, String>{
            'UserName' => UserInfo.getName(),
            'GitSnapshotName' => gitSnapshot.Name,
            'GitSnapshotLink' => URL.getSalesforceBaseUrl().toExternalForm() +
            '/' +
            gitSnapshot.Id
        };

        CopadoNotifications.send(request);
    }

    private static void publishAutomationEvent(Git_Backup__c gitSnapshot, Git_Org_Commit__c gitSnapshotCommit, JobExecution__c job) {
        Actions.TakeGitSnapshotResult response = new Actions.TakeGitSnapshotResult();
        response.jobExecution = job;
        response.snapshotCommit = gitSnapshotCommit;
        new GenerateAutomationEvent(ActionConstants.TAKE_SNAPSHOT, job, JSON.serialize(response))
            .setEnvironment(gitSnapshot.Org__r.Environment__c)
            .execute();
    }

    // INNER

    private with sharing class ExecutionData {
        private String gitSnapshotId;
        private String gitSnapshotCommitId;
        private String actionCallback;
        private String message;
        private String otherInformation;
    }

    private with sharing class ResultPayload {
        private String commitId;
        private String status;
    }
}