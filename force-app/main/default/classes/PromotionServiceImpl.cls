@SuppressWarnings('PMD.CognitiveComplexity,PMD.CyclomaticComplexity')
public inherited sharing class PromotionServiceImpl implements JobExecutionCallback {
    private static CreateExecutionRequestData requestData;

    // PUBLIC

    public static Actions.PromotionResult execute(Actions.PromotionRequest request) {
        // Note: No need of bulkification, so keep it simple
        setDefaultValues(request);
        requestData = populateDefaultContractParameters(request);

        // Validate Request
        PromotionValidator.ReturnData data = new PromotionValidator(request).execute();

        if (String.isEmpty(request.promotionId)) {
            Promotion__c promotion = createPromotionRecord(request, data.userStories);
            requestData.promotion = insertPromotions(new List<Promotion__c>{ promotion })[0];
            requestData.promotionId = requestData.promotion.Id;
            insertPromotedUserStories(promotedUserStories(data.userStories));
            getPromotionDetails(requestData);
        } else {
            requestData.promotionId = request.promotionId;
            requestData.promotion = data.promotion;
        }
        populateChangeableContractParameters();
        List<User_Story_Metadata__c> userStoryMetadata = getUserStoryMetadata();
        if (!userStoryMetadata.isEmpty()) {
            populateMetadataParameters(userStoryMetadata);
        }

        // promotion needs to be populated before job execution process because we are emptying promotion details to not deliver unnecessary information in the request
        Actions.PromotionResult response = new Actions.PromotionResult();
        response.promotion = requestData.promotion;

        response.jobExecution = getPromotionJobExecution(userStoryMetadata);
        return response;
    }

    // Callback after the job finishes
    public void execute(JobExecution__c job, String status) {
        Boolean hasConflict;
        try {
            requestData = (CreateExecutionRequestData) JSON.deserialize(job.DataJson__c, CreateExecutionRequestData.class);
            getPromotionDetails(requestData);
            Boolean jobIsSuccess = status == PromotionConstants.STATUS_SUCCESSFUL;
            hasConflict = checkLatestResultForConflict(job.Id);

            if (jobIsSuccess && !hasConflict && requestData.executeDeployment) {
                invokePromotionDeployAction(getTransactionId(job.VolumeOptions__c, requestData));
            } else {
                PromotionTriggerHelper.resetUserStories = false;
                String promotionStatus = hasConflict
                    ? PromotionConstants.STATUS_MERGE_CONFLICT
                    : jobIsSuccess ? PromotionConstants.STATUS_COMPLETED : PromotionConstants.STATUS_COMPLETED_WITH_ERRORS;
                updatePromotion(job.ParentId__c, promotionStatus, hasConflict);
            }

            if (requestData.executeDeployment != null && !requestData.executeDeployment) {
                new ActionCallback(requestData.actionCallback, job, status).run();
            }
        } catch (Exception ex) {
            job.Status__c = JobExecutionConstants.STATUS_ERROR;
            throw new ApplicationException(ex.getMessage());
        } finally {
            Boolean jobIsSuccess = job.Status__c == PromotionConstants.STATUS_SUCCESSFUL;
            String templateName = hasConflict
                ? PromotionConstants.PROMOTION_CONFLICT
                : jobIsSuccess ? PromotionConstants.PROMOTION_SUCCESS : PromotionConstants.PROMOTION_FAILED;
            sendNotification(templateName);
            publishAutomationEvent(job);
        }
    }

    // PRIVATE

    private Id getTransactionId(String volumeOption, CreateExecutionRequestData requestData) {
        Id transactionIdFromVolumeOption = volumeOption != null ? getTransactionIdFromVolumeOption(volumeOption) : null;

        return requestData.transactionId != null
            ? requestData.transactionId
            : transactionIdFromVolumeOption != null ? transactionIdFromVolumeOption : requestData.promotionId;
    }

    private Id getTransactionIdFromVolumeOption(String volumeOption) {
        Id result;

        List<Object> volumeOptionValues = (List<Object>) JSON.deserializeUntyped(volumeOption);
        for (Object obj : volumeOptionValues) {
            Map<String, Object> volumeOptionMap = (Map<String, Object>) obj;

            if (volumeOptionMap.get(PromotionConstants.VOLUME_OPTION_NAME) == PromotionConstants.TRANSACTION_ID) {
                result = (Id) volumeOptionMap.get(PromotionConstants.VOLUME_OPTION_VALUE);
                break;
            }
        }

        return result;
    }

    private static JobExecution__c getPromotionJobExecution(List<User_Story_Metadata__c> userStoryMetadata) {
        JobExecution__c jobExecution;

        if (!userStoryMetadata.isEmpty()) {
            jobExecution = processPromotionJobExecution(userStoryMetadata);
        } else {
            if (requestData.deploymentDryRun) {
                throw new ApplicationException(Label.Can_Not_Validate_Without_Metadata);
            }
            List<JobStep__c> originalDeploymentTaskSteps = getDeploymentStepsInOrder(requestData);
            List<JobStep__c> filteredDeploymentTaskSteps = new DeploymentTaskStepChecker(originalDeploymentTaskSteps)
                .pipelineId(new FindPipeline().fromObject(requestData.promotion))
                .destinationId(requestData.promotion.Destination_Environment__c)
                .backPromotion(requestData.isBackPromotion)
                .isValidation(requestData.deploymentDryRun)
                .run();
            if (!filteredDeploymentTaskSteps.isEmpty() && requestData.executeDeployment) {
                invokePromotionDeployAction(requestData.transactionId);
            } else if (filteredDeploymentTaskSteps.isEmpty() && !originalDeploymentTaskSteps.isEmpty() && requestData.executeDeployment) {
                updatePromotion(requestData.promotionId, PromotionConstants.STATUS_COMPLETED, false, true);
                updateUserStories(requestData.promotionId);
            } else if (filteredDeploymentTaskSteps.isEmpty() && requestData.executePromotion && !requestData.executeDeployment) {
                throw new ApplicationException(Label.Can_Not_Promote_If_Either_No_Deployment_Steps_or_Metadata_Commits);
            }
        }

        return jobExecution;
    }

    private static List<Promotion__c> insertPromotions(List<Promotion__c> promotions) {
        SObjectAccessDecision decision = Security.stripInaccessible(AccessType.CREATABLE, promotions);
        insert decision.getRecords();
        return (List<Promotion__c>) decision.getRecords();
    }

    private static Promotion__c createPromotionRecord(Actions.PromotionRequest request, List<User_Story__c> userStories) {
        Promotion__c promotion = new Promotion__c();
        promotion.Project__c = projectId(request, userStories[0]);
        promotion.Release__c = releaseId(userStories[0]);
        promotion.Back_Promotion__c = request.isBackPromotion;

        // PromotionTriggerHelper.setDestinationOrgFromFlow will populate necessary fields
        // TODO: move the logic in a helper class
        if (request.isBackPromotion) {
            promotion.Destination_Environment__c = request.sourceEnvironmentId;
        } else {
            promotion.Source_Environment__c = request.sourceEnvironmentId;
        }
        return promotion;
    }

    private static Promoted_User_Story__c createPromotedUserStoryRecord(Promotion__c promotion, User_Story__c userStory) {
        Promoted_User_Story__c promotedUserStory = new Promoted_User_Story__c();
        promotedUserStory.Name = promotedUserStoryName(promotion, userStory.Name);
        promotedUserStory.Promotion__c = promotion.Id;
        promotedUserStory.User_Story__c = userStory.Id;
        return promotedUserStory;
    }

    private static void insertPromotedUserStories(List<Promoted_User_Story__c> promotedUserStories) {
        insert Security.stripInaccessible(AccessType.CREATABLE, promotedUserStories).getRecords();
    }

    private static void setDefaultValues(Actions.PromotionRequest request) {
        request.executePromotion = request.executePromotion != null ? request.executePromotion : true;
        request.isBackPromotion = request.isBackPromotion != null ? request.isBackPromotion : false;
        request.executeDeployment = request.executeDeployment != null ? request.executeDeployment : false;
        request.deploymentDryRun = request.deploymentDryRun != null ? request.deploymentDryRun : false;
    }

    private static CreateExecutionRequestData populateDefaultContractParameters(Actions.PromotionRequest request) {
        CreateExecutionRequestData requestData = new CreateExecutionRequestData();
        requestData.promotionId = request.promotionId;
        requestData.executePromotion = request.executePromotion;
        requestData.executeDeployment = request.executeDeployment;
        requestData.deploymentDryRun = request.deploymentDryRun;
        requestData.otherInformation = request.otherInformation;
        requestData.isBackPromotion = request.isBackPromotion;
        requestData.userStoryIds = request.userStoryIds;
        requestData.actionCallback = request.actionCallback;
        requestData.transactionId = request.transactionId;
        return requestData;
    }

    private static String promotedUserStoryName(Promotion__c promotion, String userStoryName) {
        return promotion.Back_Promotion__c
            ? PromotionConstants.BACK_PROMOTED_USER_STORY + ' ' + userStoryName
            : PromotionConstants.PROMOTED_USER_STORY + ' ' + userStoryName;
    }

    private static void populateChangeableContractParameters() {
        requestData.isBackPromotion = requestData.promotion.Back_Promotion__c;
        requestData.sourceCredentialId = requestData.promotion.Source_Org_Credential__c;
        requestData.destinationCredentialId = requestData.promotion.Destination_Org_Credential__c;
        requestData.gitTag = requestData.promotion.Release__r.Version__c;

        requestData.promotionBranchName = 'promotion/' + requestData.promotion.Name;
        requestData.destinationBranchName = destinationBranchName(requestData.promotion);
    }

    private static void populateMetadataParameters(List<User_Story_Metadata__c> userStoryMetadata) {
        populateUserStoryParameters(requestData, userStoryMetadata);
        populateChangeParameters(requestData, userStoryMetadata);
        populateFileParameters(requestData, requestData.promotionId, PromotionConstants.PROMOTE_FILE_NAME);
    }

    private static JobExecution__c executePromoteJobTemplate(List<User_Story_Metadata__c> userStoryMetadata) {
        String templateName = new ActionTemplate(ActionConstants.PROMOTION).promotion(requestData.promotion).getApiName();

        Quality.StepsResult qualitySteps;
        if (!requestData.promotion.Back_Promotion__c) {
            qualitySteps = getQualitySteps(templateName, userStoryMetadata);
        }

        JobExecution__c jobExecution = createJobForTemplate(templateName, qualitySteps);

        if (!doNotRunJob()) {
            Id transactionId = requestData.transactionId != null ? requestData.transactionId : requestData.promotionId;
            Jobs.Execution.execute(new Jobs.ExecutionRequest(jobExecution.Id, transactionId));
        }

        return jobExecution;
    }

    private static Boolean doNotRunJob() {
        Boolean result = false;
        if (requestData.otherInformation != null) {
            PromotionOtherInformation otherInformation = (PromotionOtherInformation) JSON.deserialize(
                requestData.otherInformation,
                PromotionOtherInformation.class
            );
            result = otherInformation.doNotRunJob != null && otherInformation.doNotRunJob == true;
        }
        return result;
    }

    private static Quality.StepsResult getQualitySteps(String templateName, List<User_Story_Metadata__c> userStoryMetadata) {
        Quality.StepsRequest qualityRequest = new Quality.StepsRequest();
        qualityRequest.action = ActionConstants.PROMOTION;
        qualityRequest.pipeline = new FindPipeline().fromObject(requestData.promotion);
        qualityRequest.platform = requestData.promotion.Platform__c;
        qualityRequest.templateName = templateName;
        qualityRequest.environment = requestData.promotion.Destination_Environment__c;
        qualityRequest.contextIds = requestData.userStoryIds;
        qualityRequest.metadataChanges = userStoryMetadata;

        return Quality.steps(qualityRequest);
    }

    private static JobExecution__c createJobForTemplate(String templateName, Quality.StepsResult qualitySteps) {
        String parentId = requestData.promotionId;

        Jobs.ExecutionCreateFromTemplateRequest request = new Jobs.ExecutionCreateFromTemplateRequest();
        request.templateAPIName = templateName;
        request.parentId = parentId;
        request.pipelineId = new FindPipeline().fromObject(requestData.promotion);
        request.sourceId = requestData.promotion.Source_Environment__c;
        request.destinationId = requestData.promotion.Destination_Environment__c;
        request.callback = PromotionServiceImpl.class.getName();
        // we do not need to put promotion and deployment information in the payload and make the json huge
        requestData.promotion = null;
        requestData.allUserStoryIds = null;
        requestData.blockQueueForTransaction = blockQueueForTransaction(request.pipelineId, requestData.executeDeployment);
        request.dataJson = JSON.serializePretty(requestData, true);
        request.steps = qualitySteps != null ? qualitySteps.steps : new List<Jobs.ExecutionStep>();

        return Jobs.Execution.createFromTemplate(request).jobExecution;
    }

    private static void invokePromotionDeployAction(Id transactionId) {
        Actions.PromotionDeploymentRequest request = new Actions.PromotionDeploymentRequest();
        request.promotionId = requestData.promotionId;
        request.deploymentDryRun = requestData.deploymentDryRun;
        request.otherInformation = requestData.otherInformation;
        request.transactionId = transactionId;
        request.actionCallback = requestData.actionCallback;

        Actions.PromotionDeploymentService.execute(request);
    }

    private static JobExecution__c processPromotionJobExecution(List<User_Story_Metadata__c> userStoryMetadata) {
        JobExecution__c promotionJobExecution;

        if (!requestData.executePromotion) {
            return null;
        }

        promotionJobExecution = executePromoteJobTemplate(userStoryMetadata);

        List<SObject> records = new List<SObject>{
            new Promotion__c(
                Id = requestData.promotionId,
                Last_Promotion_Execution_Id__c = promotionJobExecution.Id,
                Last_Deployment_Execution_Id__c = null
            )
        };

        PromotionTriggerHelper.bypassPromotionTrigger = true;
        update Security.stripInaccessible(AccessType.UPDATABLE, records).getRecords();
        PromotionTriggerHelper.bypassPromotionTrigger = false;

        return promotionJobExecution;
    }

    @SuppressWarnings('PMD.AvoidDebugStatements')
    private static Boolean checkLatestResultForConflict(Id jobExecutionId) {
        Result__c latestResult = new ActionResult(jobExecutionId).getRecord();

        String statusText = '';

        if (String.isNotBlank(latestResult?.Result_Data__c)) {
            try {
                Map<String, Object> valuesByParamaters = (Map<String, Object>) JSON.deserializeUntyped(latestResult.Result_Data__c);
                statusText = (String) valuesByParamaters.get('status');
            } catch (Exception error) {
                // for internal troubleshooting purposes
                System.debug(LoggingLevel.ERROR, error.getMessage() + ': ' + error.getStackTraceString());
            }
        }

        return String.isNotBlank(statusText) && statusText == 'conflicts';
    }

    private static List<Promoted_User_Story__c> promotedUserStories(List<User_Story__c> userStories) {
        List<Promoted_User_Story__c> result = new List<Promoted_User_Story__c>();
        for (User_Story__c userStory : userStories) {
            result.add(createPromotedUserStoryRecord(requestData.promotion, userStory));
        }

        return result;
    }

    private static void sendNotification(String notificationName) {
        String promotionRecordLink = URL.getOrgDomainUrl().toExternalForm() + '/' + requestData.promotion.Id;

        Map<String, String> contextJson = new Map<String, String>{
            'UserName' => UserInfo.getName(),
            'PromotionName' => requestData.promotion.Name,
            'PromotionLink' => promotionRecordLink,
            'SourceEnv' => requestData.promotion.Source_Environment__r.Name,
            'TargetEnv' => requestData.promotion.Destination_Environment__r.Name
        };

        CopadoNotifications.SendRequest request = new CopadoNotifications.SendRequest();
        request.name = notificationName;
        request.recipientIds = new Set<Id>{ UserInfo.getUserId() };
        request.mergeData = contextJson;

        CopadoNotifications.send(request);
    }

    private void publishAutomationEvent(JobExecution__c job) {
        Actions.PromotionResult response = new Actions.PromotionResult();
        response.jobExecution = job;
        new GenerateAutomationEvent(ActionConstants.PROMOTION, job, JSON.serialize(response)).execute();
    }

    private static void populateChangeParameters(CreateExecutionRequestData requestData, List<User_Story_Metadata__c> userStoryMetadata) {
        // read all the User_Story_Metadata objects of all the user stories, make it a unique list
        // and save it into requestData.changes

        // Make sure to update change parameters in promotionUserStoryMetadatasRemovalModal LWC if format of the ignored change file is changed.
        requestData.changes = new List<Change>();

        List<Change> ignoredChanges = getIgnoredChanges(requestData.promotionId);
        for (User_Story_Metadata__c record : userStoryMetadata) {
            Change metadataChange = change(record);
            if (!ignoredChanges.contains(metadataChange)) {
                requestData.changes.add(metadataChange);
            }
        }
    }

    // PMD False positive, as WITH USER_MODE is not supported yet
    @SuppressWarnings('PMD.ApexCRUDViolation')
    private static List<Change> getIgnoredChanges(Id promotionId) {
        List<Change> result = new List<Change>();
        for (ContentDocumentLink documentLink : [
            SELECT ContentDocument.LatestPublishedVersion.VersionData
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :promotionId AND ContentDocument.Title = :PromotionConstants.IGNORED_CHANGES_FILE_NAME.substringBefore('.')
            WITH USER_MODE
            LIMIT 1
        ]) {
            result.addAll(
                (List<Change>) JSON.deserialize(documentLink.ContentDocument.LatestPublishedVersion.VersionData.toString(), List<Change>.class)
            );
        }
        return result;
    }

    // PMD False positive, as WITH USER_MODE is not supported yet
    @SuppressWarnings('PMD.ApexCRUDViolation')
    private static List<User_Story__c> getUserStories() {
        List<User_Story__c> result = new List<User_Story__c>();

        // Note: False Positive. The validity of the order field is checked in the Promotion/Pipeline trigger on saving
        List<Promoted_User_Story__c> promotesUserStories = [
            SELECT User_Story__r.Id, User_Story__r.Name
            FROM Promoted_User_Story__c
            WHERE Promoted_User_Story__c.Promotion__c = :requestData.promotionId
            WITH USER_MODE
        ];

        for (Promoted_User_Story__c promotedUserStory : promotesUserStories) {
            result.add(promotedUserStory.User_Story__r);
        }

        requestData.allUserStoryIds = new List<Id>(new Map<Id, User_Story__c>(result).keySet());

        return result;
    }

    // PMD False positive, as WITH USER_MODE is not supported yet
    @SuppressWarnings('PMD.ApexCRUDViolation')
    private static List<User_Story_Metadata__c> getUserStoryMetadata() {
        String orderBy = getUserStoriesOrder(requestData.promotion);
        List<User_Story__c> userStories = getUserStories(); // NOPMD
        String query =
            'SELECT Id, Metadata_API_Name__c, Type__c, ModuleDirectory__c, Action__c, Category__c, JsonInformation__c, User_Story__c, User_Story__r.Name FROM User_Story_Metadata__c WHERE User_Story__c IN :userStories WITH USER_MODE ORDER BY User_Story__r.' +
            orderBy +
            ' LIMIT 41000';

        List<User_Story_Metadata__c> result = Database.query(String.escapeSingleQuotes(query));
        if (result.size() > 8000) {
            throw new ApplicationException(Label.Can_Not_Promote_More_Than_8000_Metadata);
        }
        return result;
    }

    private static String getUserStoriesOrder(Promotion__c promotion) {
        String result = promotion.Order_By__c;

        if (String.isBlank(result)) {
            result = String.isNotBlank(promotion.Project__c)
                ? promotion.Project__r.Deployment_Flow__r.Order_by__c
                : promotion.Release__r.Project__r.Deployment_Flow__r.Order_by__c;
        }

        if (String.isBlank(result)) {
            result = 'Name ASC';
        }

        return result;
    }

    private static void populateUserStoryParameters(CreateExecutionRequestData requestData, List<User_Story_Metadata__c> userStoryMetadata) {
        List<Id> userStoryIds = new List<Id>();
        List<String> userStoryBranches = new List<String>();
        for (User_Story_Metadata__c metadata : userStoryMetadata) {
            if (!userStoryIds.contains(metadata.User_Story__c)) {
                userStoryIds.add(metadata.User_Story__c);
                userStoryBranches.add('feature/' + metadata.User_Story__r.Name);
            }
        }
        requestData.userStoryIds = userStoryIds;
        requestData.userStoryBranches = userStoryBranches;
    }

    private static void populateFileParameters(CreateExecutionRequestData requestData, Id parentId, String fileName) {
        // THIS is the File that the  Job will read if/when executed, avoiding the need of any Flow to gather the information
        String changesJson = Json.serialize(requestData.changes, true);
        requestData.changes = null; // remove the changes from the request

        Boolean executePromotion = requestData.executePromotion != null && requestData.executePromotion;
        Boolean executeDeployment = requestData.executeDeployment != null && requestData.executeDeployment;
        if (requestData.userStoryIds != null && !requestData.userStoryIds.isEmpty() && (executePromotion || executeDeployment)) {
            requestData.fileWithSelectedChanges = new Files().upsertFile(parentId, fileName, changesJson);
        }
    }

    private static void updatePromotion(Id promotionId, String status, Boolean hasConflict) {
        updatePromotion(promotionId, status, hasConflict, false);
    }

    @SuppressWarnings('PMD.ExcessiveParameterList')
    private static void updatePromotion(Id promotionId, String status, Boolean hasConflict, Boolean promotionIsCompleted) {
        List<SObject> records = new List<SObject>{
            new Promotion__c(Id = promotionId, Status__c = status, Merge_Conflict__c = hasConflict, Completed__c = promotionIsCompleted)
        };
        PromotionTriggerHelper.bypassPromotionTrigger = true;
        update Security.stripInaccessible(AccessType.UPDATABLE, records).getRecords();
        if (status == PromotionConstants.STATUS_COMPLETED_WITH_ERRORS) {
            new UpdatePromoteAndDeployOnUserStories(new Set<Id>{ promotionId }).execute();
        }
        PromotionTriggerHelper.bypassPromotionTrigger = false;
    }

    // PMD False positive, as WITH USER_MODE is not supported yet
    @SuppressWarnings('PMD.ApexCRUDViolation')
    private static void updateUserStories(Id promotionId) {
        List<User_Story__c> userStoriestoBeUpdated = new List<User_Story__c>();
        for (Promoted_User_Story__c pus : [
            SELECT
                User_Story__c,
                User_Story__r.Promote_Change__c,
                User_Story__r.Promote_and_Deploy__c,
                User_Story__r.Environment__c,
                User_Story__r.Org_Credential__c,
                Promotion__r.Destination_Environment__c,
                Promotion__r.Destination_Org_Credential__c
            FROM Promoted_User_Story__c
            WHERE Promotion__c = :promotionId AND Promotion__r.Back_Promotion__c = FALSE
            WITH USER_MODE
        ]) {
            User_Story__c userStory = new User_Story__c(
                Id = pus.User_Story__c,
                Promote_Change__c = false,
                Promote_and_Deploy__c = false,
                Environment__c = pus.Promotion__r.Destination_Environment__c,
                Org_Credential__c = pus.Promotion__r.Destination_Org_Credential__c
            );
            userStoriestoBeUpdated.add(userStory);
        }

        if (!userStoriestoBeUpdated.isEmpty()) {
            UserStories.bypassTrigger = true;
            update Security.stripInaccessible(AccessType.UPDATABLE, userStoriestoBeUpdated).getRecords();
            UserStories.bypassTrigger = false;
        }
    }

    private static void getPromotionDetails(CreateExecutionRequestData requestData) {
        List<Promotion__c> promotions = new PromotionsSelector().promotionsDetailsForPromoteAndDeployActions(new Set<Id>{ requestData.promotionId });
        requestData.promotion = promotions.isEmpty() ? new Promotion__c() : promotions[0];
    }

    private static String destinationBranchName(Promotion__c promotion) {
        String pipelineId = new FindPipeline().fromObject(promotion);
        Deployment_Flow__c pipeline = [
            SELECT
                Id,
                Main_Branch__c,
                (SELECT Branch__c FROM Deployment_Flow_Steps__r WHERE Source_Environment__c = :promotion.Destination_Environment__c)
            FROM Deployment_Flow__c
            WHERE Id = :pipelineId
            WITH SECURITY_ENFORCED
        ];
        return pipeline.Deployment_Flow_Steps__r.isEmpty() ? pipeline.Main_Branch__c : pipeline.Deployment_Flow_Steps__r[0].Branch__c;
    }

    private static Change change(User_Story_Metadata__c record) {
        Change result = new Change();

        result.n = record.Metadata_API_Name__c;
        result.t = record.Type__c;
        result.m = record.ModuleDirectory__c;
        result.a = record.Action__c;
        result.c = record.Category__c;
        result.j = record.JsonInformation__c;
        result.u = record.User_Story__r.Name;

        return result;
    }

    private static Boolean blockQueueForTransaction(Id pipelineId, Boolean promoteAndDeploy) {
        Boolean result = promoteAndDeploy;
        if (promoteAndDeploy) {
            List<System_Property__c> properties = [
                SELECT Id, Value__c
                FROM System_Property__c
                WHERE Pipeline__c = :pipelineId AND Name = :'enforceUniquePromotionDeploymentByEnvironment'
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];
            result = (!properties.isEmpty() && properties[0].Value__c?.toLowerCase() == 'false') ? false : true;
        }
        return result;
    }

    private static List<JobStep__c> getDeploymentStepsInOrder(CreateExecutionRequestData requestData) {
        List<JobStep__c> result = new JobStepsSelector().byUserStoryId(new Set<Id>(requestData.allUserStoryIds));

        if (requestData.otherInformation != null) {
            PromotionOtherInformation otherInformation = (PromotionOtherInformation) JSON.deserialize(
                requestData.otherInformation,
                PromotionOtherInformation.class
            );

            if (otherInformation.deploymentSteps != null) {
                result = reorderSteps(result, otherInformation.deploymentSteps);
            }
        }

        return result;
    }

    private static List<JobStep__c> reorderSteps(List<JobStep__c> deploymentSteps, List<Id> newOrder) {
        Map<Id, JobStep__c> deploymentStepsById = new Map<Id, JobStep__c>(deploymentSteps);

        List<JobStep__c> result = new List<JobStep__c>();
        for (Id deploymentStepId : newOrder) {
            result.add(deploymentStepsById.get(deploymentStepId));
        }

        return result;
    }

    private static Id projectId(Actions.PromotionRequest request, User_Story__c userStory) {
        return String.isNotBlank(request.projectId)
            ? request.projectId
            : userStory.Project__c != null ? userStory.Project__c : userStory.Release__c != null ? userStory.Release__r.Project__c : null;
    }

    private static Id releaseId(User_Story__c userStory) {
        return userStory.Release__c != null ? userStory.Release__c : null;
    }

    private class ApplicationException extends Exception {
    }

    // WRAPPER

    @SuppressWarnings('PMD.TooManyFields') // note: data contract variables. Cannot be changed.
    private with sharing class CreateExecutionRequestData {
        // Common variables for both Promote and Deploy action
        private Id promotionId;
        private Boolean deploymentDryRun;
        private Boolean executeDeployment;
        private String otherInformation;

        // Variables for Promote action
        private Id sourceEnvironmentId;
        private Boolean isBackPromotion;
        private Id projectId;
        private Boolean executePromotion;
        private Id transactionId;
        private Boolean blockQueueForTransaction;

        // Only used by the Job execution for both action
        private List<Change> changes; // list of all changes of each user story
        private Promotion__c promotion;
        private String destinationBranchName;
        private String promotionBranchName;
        private Id fileWithSelectedChanges;
        private List<Id> userStoryIds;
        private List<Id> allUserStoryIds;
        private String gitTag;

        // Only used by the Job execution for Promote Action
        private Id sourceCredentialId;
        private Id destinationCredentialId;
        private List<String> userStoryBranches = new List<String>();
        private List<Promotion__c> promotions;

        // Generic parameters for all actions
        private String actionCallback;
    }

    // NOTE: names are short to reduce memory/heap/transmission sizes
    @TestVisible
    private with sharing class Change {
        public String n; // "name"
        public String t; // "type"
        public String m; // "module directory"
        public String a; // "action" add, delete, retrieve-only, full pps, "deleteCascade"
        public String c; // optional, not used right now, "category" of this item: copadodx, vlocity, cpq, ...
        public String j; // "json additional information"... other values associated with this File
        public String u; // "user story name"... optional, user story name

        private Boolean equals(Object obj) {
            Change other = (Change) obj;
            return other != null && this.n == other.n && this.t == other.t && this.a == other.a && this.u == other.u;
        }

        private Integer hashCode() {
            return 17 + (31 * n.hashCode()) + (31 * t.hashCode()) + (31 * a.hashCode()) + (31 * u.hashCode());
        }
    }
}