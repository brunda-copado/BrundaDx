@SuppressWarnings('PMD.CyclomaticComplexity, PMD.CognitiveComplexity')
public with sharing class CommitServiceImpl implements JobExecutionCallback {
    // PUBLIC

    public static Actions.CommitResult execute(Actions.CommitRequest request) {
        // No need of bulkification right now, so keep it simple
        setDefaultValues(request);
        validateRequest(request);
        User_Story__c userStory = getUserStory(request);
        validateCommitRequirements(userStory);

        Boolean isCLICommit = !request.executeCommit;

        List<ExtensionKeyValueSetting__mdt> forceCommitExecutionSettings = new ExtensionKeyValueSettingsSelector()
            .byPlatformAndKey(userStory.Platform__c, 'forceCommitTemplateExecution');
        Boolean forceExecution = !forceCommitExecutionSettings.isEmpty() ? Boolean.valueOf(forceCommitExecutionSettings[0].Value__c) : false;

        CreateExecutionRequestData data = new CreateExecutionRequestData(userStory, request);
        data.createCommitRecords();
        Id userStoryCommitId = data.userStoryCommitId();

        Actions.CommitResult result = new Actions.CommitResult();
        result.userStorycommit = new User_Story_Commit__c(Id = userStorycommitId);

        Id contentVersionId = createChangesFile(userStory, request.changes);
        data.fileWithSelectedChanges(contentVersionId);

        Boolean needsJobExecution = !isCLICommit || (isCLICommit && forceExecution);

        CommitExecutionVariables commitVariables = new CommitExecutionVariables();
        // we need to check if customer wants to use different commit template request in the otherinformation json
        if (String.isNotBlank(request.otherInformation) && request.otherInformation.contains('"overrideJobTemplate"')) {
            try {
                Map<String, Object> otherInformations = (Map<String, Object>) JSON.deserializeUntyped(request.otherInformation);
                commitVariables.templateName = (String) otherInformations.get('overrideJobTemplate');
            } catch (Exception ex) {
                throw new ApplicationException(ex.getMessage());
            }
        }
        if (String.isBlank(commitVariables.templateName)) {
            commitVariables.templateName = new ActionTemplate(ActionConstants.COMMIT_ACTION)
                .userStory(userStory)
                .templateRequired(needsJobExecution)
                .getApiName();
        }

        commitVariables.userStory = userStory;
        commitVariables.pipelineId = new FindPipeline().fromObject(userStory);
        commitVariables.changes = request.changes;
        commitVariables.data = data;
        commitVariables.needsJobExecution = needsJobExecution;

        JobExecution__c jobExecution = createJobExecution(commitVariables);

        if (jobExecution != null) {
            result.jobExecution = Jobs.Execution.execute(new Jobs.ExecutionRequest(jobExecution.Id, userStoryCommitId)).jobExecution;
            result.jobExecution.UserStoryCommit__c = userStoryCommitId;

            // Note: False positive, checked permissions before in this method
            UserStoryCommitTriggerHandler.bypassTrigger = true;
            update new User_Story_Commit__c(Id = userStoryCommitId, LastJobExecutionId__c = jobExecution.Id); // NOPMD
            UserStoryCommitTriggerHandler.bypassTrigger = false;
        } else {
            CallbackRequest callbackRequest = new CallbackRequest(request, data, result);
            commitCallback(callbackRequest);
        }

        return result;
    }

    public void execute(JobExecution__c job, String status) {
        CallbackRequest callbackRequest = new CallbackRequest(job, status);
        commitCallback(callbackRequest);
    }

    // PRIVATE

    @SuppressWarnings('PMD.ApexCRUDViolation')
    private static void commitCallback(CallbackRequest callbackRequest) {
        User_Story__c userStory = getUserStory(callbackRequest.userStory);
        try {
            if (
                callbackRequest.commitStatus == CommitConstants.STATUS_COMPLETE ||
                callbackRequest.commitStatus == CommitConstants.STATUS_NO_CHANGES
            ) {
                List<Actions.CommitChange> changes = readChangesFile(callbackRequest.fileWithSelectedChanges);
                handleUserStoryMetadataRecords(userStory, changes, callbackRequest.recreateFeatureBranch);
                if (callbackRequest.recreateFeatureBranch) {
                    updateCommitsNotInBranch(userStory, callbackRequest.userStoryCommit);
                }
            }

            // Note: False positive, checked permissions before in this method
            UserStories.bypassTrigger = true;
            update new User_Story__c(
                Id = callbackRequest.userStory,
                Latest_Commit_Date__c = System.now(),
                Base_Branch__c = callbackRequest.baseBranch
            );
            UserStories.bypassTrigger = false;

            // Note: False positive, checked permissions before in this method
            UserStoryCommitTriggerHandler.bypassTrigger = true;
            update new User_Story_Commit__c(
                Id = callbackRequest.userStoryCommit,
                External_Id__c = String.isNotBlank(callbackRequest.commitId) ? callbackRequest.userStory + '_' + callbackRequest.commitId : null
            );
            UserStoryCommitTriggerHandler.bypassTrigger = false;

            // Note: False positive, checked permissions before in this method
            GitOrgCommitTriggerHandler.bypassTrigger = true;
            update new Git_Org_Commit__c(
                Id = callbackRequest.snapsthoCommit,
                Status__c = callbackRequest.commitStatus,
                Commit_Id__c = callbackRequest.commitId
            );
            GitOrgCommitTriggerHandler.bypassTrigger = false;

            // TODO: maybe delete file used by job execution? not for now, but likely later

            new ActionCallback(callbackRequest.actionCallback, callbackRequest.job, callbackRequest.job?.Status__c).run();
        } catch (Exception ex) {
            throw new ApplicationException(ex.getMessage());
        } finally {
            // Note: it is not possible that CLI commit fails, so we will only send notifications when working with a Job Execution
            if (callbackRequest.job != null) {
                // I can't reuse the same job as in callback, as we need the status from previous
                sendNotification(callbackRequest.job);
                publishAutomationEvent(callbackRequest.job, callbackRequest.userStoryCommit, userStory);
            } else if (callbackRequest.response != null) {
                publishAutomationEvent(callbackRequest.pipeline, callbackRequest.response, userStory);
            }
        }
    }

    private static void setDefaultValues(Actions.CommitRequest request) {
        request.executeCommit = request.executeCommit != null ? request.executeCommit : true;
        request.recreateFeatureBranch = request.recreateFeatureBranch != null ? request.recreateFeatureBranch : false;
    }

    private static void validateRequest(Actions.CommitRequest request) {
        if (request.changes.isEmpty()) {
            throw new ApplicationException(Label.ThereShouldBeAtLeastOneChangeToCommit);
        }
        request = removeDuplicatedChanges(request);
        if (request.changes.size() > 8000) {
            throw new ApplicationException(Label.Can_Not_Commit_More_Than_8000_Metadata);
        }
    }

    private static Actions.CommitRequest removeDuplicatedChanges(Actions.CommitRequest request) {
        Id userStoryId = request.userStoryId;

        Map<String, Actions.CommitChange> changeByUniqueId = new Map<String, Actions.CommitChange>();
        for (Actions.CommitChange change : request.changes) {
            String uniqueId = uniqueId(change, userStoryId);
            if (changeByUniqueId.containsKey(uniqueId) && changeByUniqueId.get(uniqueId).a != change.a) {
                throw new ApplicationException(Label.Can_Not_Commit_Same_Metadata_With_Different_Operation);
            }
            changeByUniqueId.put(uniqueId, change);
        }
        request.changes = changeByUniqueId.values();
        return request;
    }

    private static User_Story__c getUserStory(Actions.CommitRequest request) {
        return getUserStory(request.userStoryId);
    }

    private static User_Story__c getUserStory(Id userStoryId) {
        return new UserStoriesSelector().byIdsForMulticloud(new Set<Id>{ userStoryId })[0];
    }

    private static void validateCommitRequirements(User_Story__c userStory) {
        List<String> commitUnavailabilityReasons = new ValidateCommitRequirements(userStory).execute();

        if (!commitUnavailabilityReasons.isEmpty()) {
            throw new ApplicationException(
                String.format(Label.CanNotPerformThisAction, new List<Object>{ String.join(commitUnavailabilityReasons, ', ') })
            );
        }
    }

    private static void deletePreviousUserStoryMetadata(User_Story__c userStory) {
        delete new UserStoriesMetadataSelector().byUserStoryId(new Set<Id>{ userStory.Id });
    }

    private static void saveChangesAsUserStoryMetadata(List<Actions.CommitChange> changes, User_Story__c userStory) {
        List<User_Story_Metadata__c> metadatas = new List<User_Story_Metadata__c>();
        for (Actions.CommitChange change : changes) {
            metadatas.add(changeToUserStoryMetadata(change, userStory));
        }

        // Note: False positive, checked permissions before
        upsert metadatas Unique_ID__c; // NOPMD
    }

    private static void checkPotentialConflicts(User_Story__c userStory) {
        IndexMetadataJobMC indexMetadataJob = new IndexMetadataJobMC().userStories(new Set<Id>{ userStory.Id });
        if (userStory.Stop_Indexing_Metadata__c) {
            indexMetadataJob.stopIndexing();
        } else {
            indexMetadataJob.startIndexing();
        }
        Database.executebatch(indexMetadataJob);
    }

    private static Id createChangesFile(User_Story__c userStory, List<Actions.CommitChange> changes) {
        // Note: this is the File that the Job will read if/when executed, avoiding the need of any Flow to gather the information
        return new Files().upsertFile(userStory.Id, 'Copado Commit changes.json', JSON.serialize(changes, true));
    }

    private static JobExecution__c createJobExecution(CommitExecutionVariables commitVariables) {
        JobExecution__c result;

        Quality.StepsResult qualitySteps = getQualitySteps(commitVariables);

        List<JobStep__c> afterSteps = getAfterQualitySteps(qualitySteps);

        if (commitVariables.needsJobExecution) {
            result = createJobForTemplate(commitVariables, qualitySteps);
        } else if (!commitVariables.needsJobExecution && !afterSteps.isEmpty()) {
            result = createJobForQualityGates(commitVariables, afterSteps);
        } else {
            result = null;
        }

        return result;
    }

    private static Quality.StepsResult getQualitySteps(CommitExecutionVariables commitVariables) {
        Quality.StepsRequest qualityRequest = new Quality.StepsRequest();
        qualityRequest.action = ActionConstants.COMMIT_ACTION;
        qualityRequest.pipeline = commitVariables.pipelineId;
        qualityRequest.platform = commitVariables.userStory.Platform__c;
        qualityRequest.templateName = commitVariables.templateName;
        qualityRequest.environment = commitVariables.userStory.Environment__c;
        qualityRequest.contextIds = new List<Id>{ commitVariables.userStory.Id };
        qualityRequest.metadataChanges = getMetadataRecords(commitVariables.changes);
        Quality.StepsResult qualitySteps = Quality.steps(qualityRequest);
        return qualitySteps;
    }

    private static JobExecution__c createJobForQualityGates(CommitExecutionVariables commitVariables, List<JobStep__c> afterSteps) {
        Jobs.ExecutionCreateRequest request = new Jobs.ExecutionCreateRequest();
        request.parentId = commitVariables.data.userStoryCommitId();
        request.pipelineId = commitVariables.pipelineId;
        request.callback = CommitServiceImpl.class.getName();
        request.dataJson = JSON.serializePretty(commitVariables.data, true);
        request.sourceId = commitVariables.userStory.Environment__c;
        request.steps = afterSteps;
        return Jobs.Execution.create(request).jobExecution;
    }

    private static JobExecution__c createJobForTemplate(CommitExecutionVariables commitVariables, Quality.StepsResult qualitySteps) {
        Jobs.ExecutionCreateFromTemplateRequest request = new Jobs.ExecutionCreateFromTemplateRequest();
        request.parentId = commitVariables.data.userStoryCommitId();
        request.pipelineId = commitVariables.pipelineId;
        request.templateAPIName = commitVariables.templateName;
        request.callback = CommitServiceImpl.class.getName();
        request.dataJson = JSON.serializePretty(commitVariables.data, true);
        request.sourceId = commitVariables.userStory.Environment__c;
        request.steps = qualitySteps.steps;
        return Jobs.Execution.createFromTemplate(request).jobExecution;
    }

    private static List<JobStep__c> getAfterQualitySteps(Quality.StepsResult qualitySteps) {
        List<JobStep__c> result = new List<JobStep__c>();

        for (Jobs.ExecutionStep executionStep : qualitySteps.steps) {
            if (executionStep.sequence == 'After' && String.isBlank(executionStep.resourceObservation)) {
                result.addAll(executionStep.steps);
            }
        }

        return result;
    }

    private static void handleUserStoryMetadataRecords(User_Story__c userStory, List<Actions.CommitChange> changes, Boolean recreateFeatureBranch) {
        if (recreateFeatureBranch) {
            deletePreviousUserStoryMetadata(userStory);
        }
        saveChangesAsUserStoryMetadata(changes, userStory);
        checkPotentialConflicts(userStory);
    }

    private static ResultPayload getResultPayload(Id jobExecutionId) {
        return parseResultData(getResultData(jobExecutionId));
    }

    private static String getResultData(Id jobExecutionId) {
        Result__c jobResult = new ActionResult(jobExecutionId).getRecord();
        return jobResult?.Result_Data__c;
    }

    @SuppressWarnings('PMD.EmptyCatchBlock')
    private static ResultPayload parseResultData(String resultDataRaw) {
        ResultPayload result = new ResultPayload();
        if (String.isNotBlank(resultDataRaw)) {
            try {
                result = (ResultPayload) JSON.deserialize(resultDataRaw, ResultPayload.class);
            } catch (JSONException e) {
                // Note: ignore parse errors, as the result format may vary
            }
        }
        return result;
    }

    private static List<Actions.CommitChange> readChangesFile(Id contentVersionId) {
        ContentVersion contentVersion = new ContentVersionsSelector().byId(new Set<Id>{ contentVersionId })[0];
        return (List<Actions.CommitChange>) JSON.deserialize(contentVersion.VersionData.toString(), List<Actions.CommitChange>.class);
    }

    private static void updateCommitsNotInBranch(User_Story__c userStory, Id currentUserStoryCommit) {
        List<Git_Org_Commit__c> commits = new List<Git_Org_Commit__c>();
        for (User_Story_Commit__c userStoryCommit : new UserStoryCommitsSelector().byUserStory(new Set<Id>{ userStory.Id })) {
            if (userStoryCommit.Id != currentUserStoryCommit) {
                commits.add(new Git_Org_Commit__c(Id = userStoryCommit.Snapshot_Commit__c, Status__c = CommitConstants.STATUS_COMMIT_NOT_IN_BRANCH));
            }
        }
        GitOrgCommitTriggerHandler.bypassTrigger = true;
        update commits; // NOPMD
        GitOrgCommitTriggerHandler.bypassTrigger = false;
    }

    private static void sendNotification(JobExecution__c job) {
        if (job.Status__c != JobExecutionConstants.STATUS_ERROR) {
            return;
        }

        CopadoNotifications.SendRequest request = new CopadoNotifications.SendRequest();
        request.name = 'Commit_Failed';
        request.recipientIds = new Set<Id>{ UserInfo.getUserId() };
        request.mergeData = new Map<String, String>{
            'UserName' => UserInfo.getName(),
            'UserStoryName' => job.UserStoryCommit__r.User_Story__r.Name,
            'UserStoryCommitLink' => URL.getSalesforceBaseUrl().toExternalForm() +
            '/' +
            job.UserStoryCommit__c,
            'UserStoryCommitName' => job.UserStoryCommit__r.Name
        };
        CopadoNotifications.send(request);
    }

    private static void publishAutomationEvent(JobExecution__c job, String userStoryCommitId, User_Story__c userStory) {
        Actions.CommitResult response = new Actions.CommitResult();
        response.jobExecution = job;
        response.userStorycommit = new User_Story_Commit__c(Id = userStorycommitId);
        new GenerateAutomationEvent(ActionConstants.COMMIT_ACTION, job, JSON.serialize(response)).setEnvironment(userStory.Environment__c).execute();
    }

    private static void publishAutomationEvent(String pipelineId, Actions.CommitResult response, User_Story__c userStory) {
        new GenerateAutomationEvent(
                ActionConstants.COMMIT_ACTION,
                AutomationRuleConstants.SOURCE_ACTION_STATUS_SUCCESSFUL,
                pipelineId,
                JSON.serialize(response)
            )
            .setEnvironment(userStory.Environment__c)
            .execute();
    }

    private static User_Story_Metadata__c changeToUserStoryMetadata(Actions.CommitChange change, User_Story__c userStory) {
        String metadataApiName = change.t + '.' + change.n;
        String uniqueId = uniqueId(change, userStory.Id);

        return new User_Story_Metadata__c(
            Action__c = change.a,
            Category__c = change.c,
            ModuleDirectory__c = change.m,
            Type__c = change.t,
            JsonInformation__c = change.j,
            User_Story__c = userStory.Id,
            Metadata_API_Name__c = change.n, // Create Name__c later if needed
            Name = (userStory.Name + ' ' + change.a + ' ' + metadataApiName).left(80),
            Last_Commit_Date__c = System.now(), // needed?
            Unique_ID__c = uniqueId
        );
    }

    private static String uniqueId(Actions.CommitChange change, String userStoryId) {
        String result = userStoryId + ';' + change.m + ';' + change.t + ';' + change.n;
        return getEncodedUniqueIdWhenNeeded(result);
    }

    // Note: Encoding is skipped when not needed due to CPU performance and readability purposes
    private static String getEncodedUniqueIdWhenNeeded(String uniqueId) {
        if (uniqueId.length() > 255) {
            uniqueId = EncodingUtil.convertToHex(Crypto.generateDigest('MD5', Blob.valueOf(uniqueId)));
        }
        return uniqueId;
    }

    private static List<User_Story_Metadata__c> getMetadataRecords(List<Actions.CommitChange> changes) {
        List<User_Story_Metadata__c> result = new List<User_Story_Metadata__c>();
        for (Actions.CommitChange change : changes) {
            result.add(new User_Story_Metadata__c(ModuleDirectory__c = change.m, Type__c = change.t, Metadata_API_Name__c = change.n));
        }
        return result;
    }

    private with sharing class CreateExecutionRequestData {
        // Shared variables with Request
        private Id userStoryId;
        private Boolean recreateFeatureBranch;
        private String baseBranch;
        private String message;
        private String jsonInformation;
        private String commitId;
        private String actionCallback;

        // Only used by the Job execution
        private String featureBranchName;
        private Id sourceCredentialId;
        private Id orgCommitId;
        private Id userStoryCommitId;
        private Id fileWithSelectedChanges;

        // CTOR OUTTER

        private CreateExecutionRequestData(User_Story__c userStory, Actions.CommitRequest request) {
            recreateFeatureBranch = request.recreateFeatureBranch;
            userStoryId = userStory.Id;
            featureBranchName = 'feature/' + userStory.Name;
            sourceCredentialId = userStory.Org_Credential__c;
            setMessage(request.message, userStory);
            setBaseBranch(request.baseBranch, userStory);
            actionCallback = request.actionCallback;
            jsonInformation = request.otherInformation;
            commitId = request.commitId;
        }

        // PRIVATE OUTTER

        private CreateExecutionRequestData createCommitRecords() {
            Git_Org_Commit__c orgCommit = new Git_Org_Commit__c(
                Commit_Date__c = datetime.now(),
                Commit_Message__c = message.left(255),
                Org__c = sourceCredentialId,
                Status__c = CommitConstants.STATUS_IN_PROGRESS
            );
            // Note: False positive, checked permissions before
            GitOrgCommitTriggerHandler.bypassTrigger = true;
            insert orgCommit; // NOPMD
            GitOrgCommitTriggerHandler.bypassTrigger = false;
            orgCommitId = orgCommit.Id;

            User_Story_Commit__c userStoryCommit = new User_Story_Commit__c(
                Snapshot_Commit__c = orgCommit.Id,
                User_Story__c = userStoryId,
                Name = message.left(80)
            );
            // Note: False positive, checked permissions before
            UserStoryCommitTriggerHandler.bypassTrigger = true;
            insert userStoryCommit; // NOPMD
            UserStoryCommitTriggerHandler.bypassTrigger = false;
            userStoryCommitId = userStoryCommit.Id;

            return this;
        }

        private void fileWithSelectedChanges(Id contentVersionId) {
            fileWithSelectedChanges = contentVersionId;
        }

        private Id userStoryCommitId() {
            return userStoryCommitId;
        }

        // PRIVATE INNER

        private void setMessage(String message, User_Story__c userStory) {
            if (String.isNotBlank(message)) {
                this.message = message;
            } else {
                this.message = String.format('[{0}] {1}', new List<Object>{ userStory.Name, userStory.User_Story_Title__c });
            }
        }

        private void setBaseBranch(String branchName, User_Story__c userStory) {
            if (String.isNotBlank(branchName)) {
                baseBranch = branchName;
            } else if (String.isNotBlank(userStory.Base_Branch__c)) {
                baseBranch = userStory.Base_Branch__c;
            } else if (String.isNotBlank(userStory.Release__r.Base_Branch__c)) {
                baseBranch = userStory.Release__r.Base_Branch__c;
            } else if (String.isNotBlank(userStory.Release__r.Project__r.Deployment_Flow__r.Main_Branch__c)) {
                baseBranch = userStory.Release__r.Project__r.Deployment_Flow__r.Main_Branch__c;
            } else if (String.isNotBlank(userStory.Project__r.Deployment_Flow__r.Main_Branch__c)) {
                baseBranch = userStory.Project__r.Deployment_Flow__r.Main_Branch__c;
            } else {
                baseBranch = '';
            }
        }
    }

    private with sharing class CommitExecutionVariables {
        private String templateName;
        private User_Story__c userStory;
        private Id pipelineId;
        private List<Actions.CommitChange> changes;
        private CreateExecutionRequestData data;
        private Boolean needsJobExecution;
    }

    private with sharing class ResultPayload {
        private String commitId;
        private String status;
    }

    private with sharing class CallbackRequest {
        private Id userStory;
        private Id userStoryCommit;
        private Id snapsthoCommit;
        private Id fileWithSelectedChanges;
        private Boolean recreateFeatureBranch;
        private String baseBranch;
        private String commitId;
        private String commitStatus;
        private String actionCallback;
        private JobExecution__c job;
        private Id pipeline;
        private Actions.CommitResult response;

        private CallbackRequest(Actions.CommitRequest request, CreateExecutionRequestData data, Actions.CommitResult response) {
            this.userStory = request.userStoryId;
            this.userStoryCommit = data.userStoryCommitId;
            this.snapsthoCommit = data.orgCommitId;
            this.fileWithSelectedChanges = data.fileWithSelectedChanges;
            this.recreateFeatureBranch = request.recreateFeatureBranch;
            this.baseBranch = data.baseBranch;
            this.commitId = request.commitId;
            this.commitStatus = CommitConstants.STATUS_COMPLETE;
            this.actionCallback = request.actionCallback;
            this.pipeline = new FindPipeline().fromObject(getUserStory(request));
            this.response = response;
        }

        private CallbackRequest(JobExecution__c job, String status) {
            CreateExecutionRequestData requestData = (CreateExecutionRequestData) JSON.deserialize(job.DataJson__c, CreateExecutionRequestData.class);

            Map<String, String> snapshotStatusByJobStatus = new Map<String, String>{
                JobExecutionConstants.STATUS_NOT_STARTED => CommitConstants.STATUS_PENDING,
                JobExecutionConstants.STATUS_IN_PROGRESS => CommitConstants.STATUS_IN_PROGRESS,
                JobExecutionConstants.STATUS_SUCCESSFUL => CommitConstants.STATUS_COMPLETE,
                JobExecutionConstants.STATUS_CANCELLED => CommitConstants.STATUS_FAILED,
                JobExecutionConstants.STATUS_ERROR => CommitConstants.STATUS_FAILED
            };

            // Note: this is replacing the Status__c and Error_Message__c set by the JobEngine, so we need to set them manually
            JobExecution__c jobWithCommitData = new JobExecutionsSelector().byIdForCommit(new Set<Id>{ job.Id })[0];
            jobWithCommitData.Status__c = job.Status__c;
            jobWithCommitData.ErrorMessage__c = job.ErrorMessage__c;

            ResultPayload resultData = getResultPayload(job.Id);
            String commitId = String.isNotBlank(requestData.commitId) ? requestData.commitId : resultData.commitId;
            String commitStatus = String.isNotBlank(resultData.status) ? resultData.status : snapshotStatusByJobStatus.get(status);

            this.userStory = requestData.userStoryId;
            this.userStoryCommit = jobWithCommitData.UserStoryCommit__c;
            this.snapsthoCommit = jobWithCommitData.UserStoryCommit__r.Snapshot_Commit__c;
            this.fileWithSelectedChanges = requestData.fileWithSelectedChanges;
            this.recreateFeatureBranch = requestData.recreateFeatureBranch;
            this.baseBranch = requestData.baseBranch;
            this.commitId = commitId;
            this.commitStatus = commitStatus;
            this.actionCallback = requestData.actionCallback;
            this.job = jobWithCommitData;
        }
    }
}