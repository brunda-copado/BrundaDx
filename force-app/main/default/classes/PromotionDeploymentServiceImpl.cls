@SuppressWarnings('PMD.CyclomaticComplexity, PMD.ExcessivePublicCount, PMD.CognitiveComplexity')
public inherited sharing class PromotionDeploymentServiceImpl implements JobExecutionCallback {
    // PUBLIC

    public static Actions.PromotionDeploymentResult execute(Actions.PromotionDeploymentRequest request) {
        CreateExecutionRequestData requestData = populateDefaultContractParameters(request);

        getPromotionDetails(requestData);
        if (requestData.promotion.Status__c != PromotionConstants.STATUS_IN_PROGRESS) {
            updatePromotion(requestData.promotionId, PromotionConstants.STATUS_IN_PROGRESS);
        }

        insertDeploymentWithDestinations(requestData);
        populateChangeableContractParameters(requestData);
        List<User_Story_Metadata__c> userStoryMetadata = getUserStoryMetadata(requestData.userStoryIds);
        populateMetadataParameters(userStoryMetadata, requestData);

        JobExecution__c jobExecution = executePromotionDeployJob(userStoryMetadata, requestData);

        Actions.PromotionDeploymentResult result = new Actions.PromotionDeploymentResult();
        result.jobExecution = jobExecution;
        return result;
    }

    public void execute(JobExecution__c job, String status) {
        String deploymentStatus;
        Destination_Org__c destinationOrg;
        try {
            CreateExecutionRequestData requestData = (CreateExecutionRequestData) JSON.deserialize(job.DataJson__c, CreateExecutionRequestData.class);
            String promotionStatus = promotionStatus(status, requestData.deploymentDryRun);
            deploymentStatus = deploymentStatus(status);
            destinationOrg = getDestinationOrgDetails(job.ParentId__c);
            Id promotionId = destinationOrg.Deployment__r.Promotion__c;
            List<SObject> records = new List<SObject>{
                populatePromotionStatus(promotionId, promotionStatus, requestData.deploymentDryRun),
                populateDestinationOrgStatus(destinationOrg.Id, deploymentStatus),
                populateDeploymentStatus(job.ParentId__c, deploymentStatus),
                populateEnvironmentLastDeploymentStatus(job.Destination__c, job.ParentId__c, deploymentStatus)
            };

            fflib_SObjectDomain.getTriggerEvent(DeploymentTriggerHandler.class).disableAll();
            fflib_SObjectDomain.getTriggerEvent(DestinationOrgTriggerHandler.class).disableAll();
            fflib_SObjectDomain.getTriggerEvent(EnvironmentTriggerHandler.class).disableAll();
            UserStories.bypassTrigger = true;
            if (requestData.deploymentDryRun) {
                PromotionTriggerHelper.resetUserStories = false;
            }

            records.addAll(updatedUserStories(job.ParentId__c, promotionId, promotionStatus, requestData.deploymentDryRun));

            update Security.stripInaccessible(AccessType.UPDATABLE, records).getRecords();

            UserStories.bypassTrigger = false;
            fflib_SObjectDomain.getTriggerEvent(DestinationOrgTriggerHandler.class).enableAll();
            fflib_SObjectDomain.getTriggerEvent(DeploymentTriggerHandler.class).enableAll();
            fflib_SObjectDomain.getTriggerEvent(EnvironmentTriggerHandler.class).enableAll();

            if (!destinationOrg.Deployment__r.Promotion__r.Back_Promotion__c) {
                UpdateUserStoryStatusAction.Request request = new UpdateUserStoryStatusAction.Request();
                request.jobExecution = job;

                UpdateUserStoryStatusAction.execute(new List<UpdateUserStoryStatusAction.Request>{ request });
            }

            new ActionCallback(requestData.actionCallback, job, status).run();
        } catch (Exception ex) {
            job.Status__c = JobExecutionConstants.STATUS_ERROR;
            throw new ApplicationException(ex.getMessage());
        } finally {
            Boolean jobIsSuccess = deploymentStatus == PromotionConstants.STATUS_COMPLETED_SUCCESSFULLY;
            sendNotification(jobIsSuccess, job, destinationOrg);
            publishAutomationEvent(job);
        }
    }

    // PRIVATE

    private static CreateExecutionRequestData populateDefaultContractParameters(Actions.PromotionDeploymentRequest request) {
        CreateExecutionRequestData requestData = new CreateExecutionRequestData();
        requestData.promotionId = request.promotionId != null ? request.promotionId : null;
        requestData.deploymentDryRun = request.deploymentDryRun != null ? request.deploymentDryRun : false;
        requestData.otherInformation = request.otherInformation != null ? request.otherInformation : null;
        requestData.actionCallback = request.actionCallback;
        requestData.transactionId = request.transactionId;
        return requestData;
    }

    private static void getPromotionDetails(CreateExecutionRequestData requestData) {
        List<Promotion__c> promotions = new PromotionsSelector().promotionsDetailsForPromoteAndDeployActions(new Set<Id>{ requestData.promotionId });
        requestData.promotion = promotions.isEmpty() ? new Promotion__c() : promotions[0];
    }

    public static void updatePromotion(Id promotionId, String status) {
        updatePromotion(promotionId, status, false);
    }

    public static void updatePromotion(Id promotionId, String status, Boolean hasConflict) {
        List<SObject> records = new List<SObject>{ new Promotion__c(Id = promotionId, Status__c = status, Merge_Conflict__c = hasConflict) };
        PromotionTriggerHelper.bypassPromotionTrigger = true;
        update Security.stripInaccessible(AccessType.UPDATABLE, records).getRecords();
        if (status == PromotionConstants.STATUS_COMPLETED_WITH_ERRORS) {
            new UpdatePromoteAndDeployOnUserStories(new Set<Id>{ promotionId }).execute();
        }
    }

    private static void insertDeploymentWithDestinations(CreateExecutionRequestData requestData) {
        fflib_SObjectDomain.getTriggerEvent(DestinationOrgTriggerHandler.class).disableAll();
        SObjectAccessDecision decision = Security.stripInaccessible(AccessType.CREATABLE, new List<Destination_Org__c>{ destination(requestData) });
        insert decision.getRecords();
        fflib_SObjectDomain.getTriggerEvent(DestinationOrgTriggerHandler.class).enableAll();
    }

    private static Destination_Org__c destination(CreateExecutionRequestData requestData) {
        insertDeployment(requestData);
        return new Destination_Org__c(
            Deployment__c = requestData.deployment.Id,
            To_Org__c = requestData.promotion.Destination_Org_Credential__c,
            Status__c = PromotionConstants.STATUS_IN_PROGRESS
        );
    }

    private static void insertDeployment(CreateExecutionRequestData requestData) {
        fflib_SObjectDomain.getTriggerEvent(DeploymentTriggerHandler.class).disableAll();
        SObjectAccessDecision decision = Security.stripInaccessible(AccessType.CREATABLE, new List<Deployment__c>{ deployment(requestData) });
        insert decision.getRecords();
        fflib_SObjectDomain.getTriggerEvent(DeploymentTriggerHandler.class).enableAll();

        requestData.deployment = (Deployment__c) (decision.getRecords().get(0));
        requestData.deploymentId = requestData.deployment.Id;

        updateEnvironment(requestData);
    }

    private static void updateEnvironment(CreateExecutionRequestData requestData) {
        Environment__c environment = populateEnvironmentLastDeploymentStatus(
            requestData.promotion.Destination_Environment__c,
            requestData.deploymentId,
            PromotionConstants.STATUS_IN_PROGRESS_FOR_DEPLOYMENT
        );

        fflib_SObjectDomain.getTriggerEvent(EnvironmentTriggerHandler.class).disableAll();
        SObjectAccessDecision edecision = Security.stripInaccessible(AccessType.UPDATABLE, new List<Environment__c>{ environment });
        update edecision.getRecords();
        fflib_SObjectDomain.getTriggerEvent(EnvironmentTriggerHandler.class).enableAll();
    }

    private static Deployment__c deployment(CreateExecutionRequestData requestData) {
        String advancedDeploymentRecordId = Schema.Sobjecttype.Deployment__c.getRecordTypeInfosByDeveloperName()
            .get('Advanced_multi_step')
            .getRecordTypeId();

        return new Deployment__c(
            RecordTypeId = advancedDeploymentRecordId,
            Name = requestData.promotion.Name,
            Status__c = PromotionConstants.STATUS_IN_PROGRESS_FOR_DEPLOYMENT,
            Promotion__c = requestData.promotion.Id,
            From_Org__c = requestData.promotion.Source_Org_Credential__c
        );
    }

    private static void populateChangeableContractParameters(CreateExecutionRequestData requestData) {
        populateUserStoryParameters(requestData, requestData.promotion);

        requestData.promotionBranchName = 'promotion/' + requestData.promotion.Name;
        requestData.destinationBranchName = destinationBranchName(requestData.promotion);
    }

    public static void populateUserStoryParameters(CreateExecutionRequestData requestData, Promotion__c promotion) {
        List<Id> userStoryIds = new List<Id>();
        List<String> userStoryBranches = new List<String>();
        for (User_Story__c userStory : getUserStoriesInOrder(promotion)) {
            userStoryIds.add(userStory.Id);
            userStoryBranches.add('feature/' + userStory.Name);
        }
        requestData.userStoryIds = userStoryIds;
        requestData.userStoryBranches = userStoryBranches;
    }

    @SuppressWarnings('PMD.UnusedLocalVariable, PMD.ApexSOQLInjection')
    private static List<User_Story__c> getUserStoriesInOrder(Promotion__c promotion) {
        List<User_Story__c> result = new List<User_Story__c>();

        Id promotionId = promotion.Id;
        String orderBy = getUserStoriesOrder(promotion);
        // Note: False Positive. The validity of the order field is checked in the Promotion/Pipeline trigger on saving
        List<Promoted_User_Story__c> promotesUserStories = Database.query(
            'SELECT User_Story__r.Id, User_Story__r.Name FROM Promoted_User_Story__c WHERE Promoted_User_Story__c.Promotion__c = :promotionId WITH SECURITY_ENFORCED ORDER BY User_Story__r.' +
            orderBy
        );

        for (Promoted_User_Story__c promotedUserStory : promotesUserStories) {
            result.add(promotedUserStory.User_Story__r);
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

    public static String destinationBranchName(Promotion__c promotion) {
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

    public static List<User_Story_Metadata__c> getUserStoryMetadata(List<Id> userStoryIds) {
        List<User_Story_Metadata__c> result = new UserStoryMetadataSelector().byUserStoryIds(new Set<Id>(userStoryIds));
        if (result.size() > 8000) {
            throw new ApplicationException(Label.Can_Not_Promote_More_Than_8000_Metadata);
        }
        return result;
    }

    private static void populateMetadataParameters(List<User_Story_Metadata__c> userStoryMetadata, CreateExecutionRequestData requestData) {
        populateChangeParameters(requestData, userStoryMetadata);
        populateFileParameters(requestData, requestData.deployment.Id, PromotionConstants.DEPLOY_FILE_NAME);
    }

    public static void populateChangeParameters(CreateExecutionRequestData requestData, List<User_Story_Metadata__c> userStoryMetadata) {
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

    public static void populateFileParameters(CreateExecutionRequestData requestData, Id parentId, String fileName) {
        // THIS is the File that the  Job will read if/when executed, avoiding the need of any Flow to gather the information
        String changesJson = Json.serialize(requestData.changes, true);
        requestData.changes = null; // remove the changes from the request

        if (requestData.userStoryIds != null && !requestData.userStoryIds.isEmpty()) {
            requestData.fileWithSelectedChanges = new Files().upsertFile(parentId, fileName, changesJson);
        }
    }

    private static JobExecution__c executePromotionDeployJob(List<User_Story_Metadata__c> userStoryMetadata, CreateExecutionRequestData requestData) {
        String templateName = userStoryMetadata.isEmpty()
            ? null
            : new ActionTemplate(ActionConstants.PROMOTION_DEPLOYMENT).promotion(requestData.promotion).getApiName();

        Quality.StepsResult qualitySteps;
        Map<String, List<JobStep__c>> filteredQualitySteps;
        if (!requestData.promotion.Back_Promotion__c && !requestData.deploymentDryRun) {
            qualitySteps = getQualitySteps(templateName, userStoryMetadata, requestData);
        }
        filteredQualitySteps = reOrderSteps(qualitySteps, requestData);

        JobExecution__c jobExecution = templateName != null
            ? createJobForTemplate(templateName, requestData, filteredQualitySteps)
            : createJobForQualityGates(requestData, filteredQualitySteps);

        if (!doNotRunJob(requestData)) {
            Id transactionId = requestData.transactionId != null ? requestData.transactionId : requestData.promotionId;
            Jobs.Execution.execute(new Jobs.ExecutionRequest(jobExecution.Id, transactionId));
        }

        updateLastDeploymentJobExecutionId(requestData, jobExecution.Id);

        return jobExecution;
    }

    private static Quality.StepsResult getQualitySteps(
        String templateName,
        List<User_Story_Metadata__c> userStoryMetadata,
        CreateExecutionRequestData requestData
    ) {
        Quality.StepsRequest qualityRequest = new Quality.StepsRequest();
        qualityRequest.action = ActionConstants.PROMOTION_DEPLOYMENT;
        qualityRequest.pipeline = new FindPipeline().fromObject(requestData.promotion);
        qualityRequest.platform = requestData.promotion.Platform__c;
        qualityRequest.templateName = templateName;
        qualityRequest.environment = requestData.promotion.Destination_Environment__c;
        qualityRequest.contextIds = requestData.userStoryIds;
        qualityRequest.metadataChanges = userStoryMetadata;

        return Quality.steps(qualityRequest);
    }

    private static JobExecution__c createJobForQualityGates(
        CreateExecutionRequestData requestData,
        Map<String, List<JobStep__c>> filteredQualitySteps
    ) {
        Jobs.ExecutionCreateRequest request = new Jobs.ExecutionCreateRequest();
        request.parentId = requestData.deployment.Id;
        request.pipelineId = new FindPipeline().fromObject(requestData.promotion);
        request.sourceId = requestData.promotion.Source_Environment__c;
        request.destinationId = requestData.promotion.Destination_Environment__c;
        request.callback = PromotionDeploymentServiceImpl.class.getName();
        // we do not need to put promotion and deployment information in the payload and make the json huge
        requestData.promotion = null;
        requestData.deployment = null;
        request.dataJson = JSON.serializePretty(requestData, true);
        request.steps = filteredQualitySteps != null ? getAllJobSteps(filteredQualitySteps) : new List<JobStep__c>();

        return Jobs.Execution.create(request).jobExecution;
    }

    private static JobExecution__c createJobForTemplate(
        String templateName,
        CreateExecutionRequestData requestData,
        Map<String, List<JobStep__c>> filteredQualitySteps
    ) {
        String parentId = requestData.deployment.Id;

        Jobs.ExecutionCreateFromTemplateRequest request = new Jobs.ExecutionCreateFromTemplateRequest();
        request.templateAPIName = templateName;
        request.parentId = parentId;
        request.pipelineId = new FindPipeline().fromObject(requestData.promotion);
        request.sourceId = requestData.promotion.Source_Environment__c;
        request.destinationId = requestData.promotion.Destination_Environment__c;
        request.callback = PromotionDeploymentServiceImpl.class.getName();
        // we do not need to put promotion and deployment information in the payload and make the json huge
        requestData.promotion = null;
        requestData.deployment = null;
        request.dataJson = JSON.serializePretty(requestData, true);
        request.steps = filteredQualitySteps != null ? getExecutionSteps(filteredQualitySteps) : new List<Jobs.ExecutionStep>();

        return Jobs.Execution.createFromTemplate(request).jobExecution;
    }

    private static Map<String, List<JobStep__c>> reOrderSteps(Quality.StepsResult qualitySteps, CreateExecutionRequestData requestData) {
        // TODO: the order of the user stories in the promotion needs to be configurable
        List<JobStep__c> filteredDeploymentTaskSteps = new DeploymentTaskStepChecker(getDeploymentStepsInOrder(requestData))
            .pipelineId(new FindPipeline().fromObject(requestData.promotion))
            .destinationId(requestData.promotion.Destination_Environment__c)
            .backPromotion(requestData.promotion.Back_Promotion__c)
            .isValidation(requestData.deploymentDryRun)
            .run();
        Map<String, List<JobStep__c>> filteredDeploymentTaskStepsBySequence = filterBySequence(filteredDeploymentTaskSteps);
        filteredDeploymentTaskSteps.clear();
        Map<String, List<JobStep__c>> filteredQualitySteps = filterBySequence(qualitySteps);

        List<JobStep__c> jobSteps = new List<JobStep__c>();
        if (filteredQualitySteps.containsKey(PromotionConstants.BEFORE_VALUE)) {
            jobSteps.addAll(filteredQualitySteps.get(PromotionConstants.BEFORE_VALUE));
        }
        if (filteredDeploymentTaskStepsBySequence.containsKey(PromotionConstants.BEFORE_VALUE)) {
            jobSteps.addAll(filteredDeploymentTaskStepsBySequence.get(PromotionConstants.BEFORE_VALUE));
        }
        filteredQualitySteps.put(PromotionConstants.BEFORE_VALUE, jobSteps);

        jobSteps = new List<JobStep__c>();
        if (filteredDeploymentTaskStepsBySequence.containsKey(PromotionConstants.AFTER_VALUE)) {
            jobSteps.addAll(filteredDeploymentTaskStepsBySequence.get(PromotionConstants.AFTER_VALUE));
        }
        if (filteredQualitySteps.containsKey(PromotionConstants.AFTER_VALUE)) {
            jobSteps.addAll(filteredQualitySteps.get(PromotionConstants.AFTER_VALUE));
        }
        filteredQualitySteps.put(PromotionConstants.AFTER_VALUE, jobSteps);

        return filteredQualitySteps;
    }

    private static List<JobStep__c> getDeploymentStepsInOrder(CreateExecutionRequestData requestData) {
        List<JobStep__c> result = new JobStepsSelector().byUserStoryId(new Set<Id>(requestData.userStoryIds));

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

    private static List<Jobs.ExecutionStep> getExecutionSteps(Map<String, List<JobStep__c>> filteredQualitySteps) {
        List<Jobs.ExecutionStep> executionSteps = new List<Jobs.ExecutionStep>();
        for (String sequence : filteredQualitySteps.keySet()) {
            Jobs.ExecutionStep executionStep = new Jobs.ExecutionStep();
            if (sequence == PromotionConstants.AFTER_VALUE || sequence == PromotionConstants.BEFORE_VALUE) {
                executionStep.sequence = sequence;
            } else {
                executionStep.resourceObservation = sequence;
            }
            executionStep.steps = filteredQualitySteps.get(sequence);
            executionSteps.add(executionStep);
        }
        return executionSteps;
    }

    private static List<JobStep__c> getAllJobSteps(Map<String, List<JobStep__c>> filteredQualitySteps) {
        List<JobStep__c> jobSteps = new List<JobStep__c>();
        jobSteps.addAll(filteredQualitySteps.get(PromotionConstants.BEFORE_VALUE));
        jobSteps.addAll(filteredQualitySteps.get(PromotionConstants.AFTER_VALUE));
        return jobSteps;
    }

    private static Map<String, List<JobStep__c>> filterBySequence(Quality.StepsResult qualitySteps) {
        Map<String, List<JobStep__c>> result = new Map<String, List<JobStep__c>>();

        if (qualitySteps != null) {
            filterBySequence(qualitySteps.steps, result);
        }

        return result;
    }

    private static void filterBySequence(List<Jobs.ExecutionStep> steps, Map<String, List<JobStep__c>> result) {
        for (Jobs.ExecutionStep executionStep : steps) {
            if (executionStep.sequence != null) {
                if (!result.containsKey(executionStep.sequence.toLowerCase())) {
                    result.put(executionStep.sequence.toLowerCase(), executionStep.steps);
                } else {
                    result.get(executionStep.sequence.toLowerCase()).addAll(executionStep.steps);
                }
            }

            if (executionStep.resourceObservation != null) {
                if (!result.containsKey(executionStep.resourceObservation.toLowerCase())) {
                    result.put(executionStep.resourceObservation.toLowerCase(), executionStep.steps);
                } else {
                    result.get(executionStep.resourceObservation.toLowerCase()).addAll(executionStep.steps);
                }
            }
        }
    }

    private static Map<String, List<JobStep__c>> filterBySequence(List<JobStep__c> steps) {
        Map<String, List<JobStep__c>> result = new Map<String, List<JobStep__c>>();

        for (JobStep__c executionStep : steps) {
            if (executionStep.ExecutionSequence__c != null) {
                if (!result.containsKey(executionStep.ExecutionSequence__c.toLowerCase())) {
                    result.put(executionStep.ExecutionSequence__c.toLowerCase(), new List<JobStep__c>{ executionStep });
                } else {
                    result.get(executionStep.ExecutionSequence__c.toLowerCase()).add(executionStep);
                }
            }
        }

        return result;
    }

    private static Boolean doNotRunJob(CreateExecutionRequestData requestData) {
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

    private static void updateLastDeploymentJobExecutionId(CreateExecutionRequestData requestData, Id deploymentJobExecutionId) {
        List<SObject> records = new List<SObject>{
            new Promotion__c(Id = requestData.promotionId, Last_Deployment_Execution_Id__c = deploymentJobExecutionId)
        };

        PromotionTriggerHelper.bypassPromotionTrigger = true;
        update Security.stripInaccessible(AccessType.UPDATABLE, records).getRecords();
    }

    private static String promotionStatus(String jobStatus, Boolean deploymentDryRun) {
        return (jobStatus == PromotionConstants.STATUS_SUCCESSFUL)
            ? (deploymentDryRun ? PromotionConstants.STATUS_VALIDATED : PromotionConstants.STATUS_COMPLETED)
            : (deploymentDryRun ? PromotionConstants.STATUS_VALIDATION_FAILED : PromotionConstants.STATUS_COMPLETED_WITH_ERRORS);
    }

    private static String deploymentStatus(String jobStatus) {
        return (jobStatus == PromotionConstants.STATUS_SUCCESSFUL)
            ? PromotionConstants.STATUS_COMPLETED_SUCCESSFULLY
            : PromotionConstants.STATUS_COMPLETED_WITH_ERRORS;
    }

    private Destination_Org__c getDestinationOrgDetails(Id deploymentId) {
        return [
            SELECT
                Id,
                Status__c,
                Deployment__c,
                Deployment__r.Promotion__c,
                Deployment__r.Promotion__r.Destination_Environment__r.Name,
                Deployment__r.Promotion__r.Source_Environment__r.Name,
                Deployment__r.Promotion__r.Back_Promotion__c
            FROM Destination_Org__c
            WHERE Deployment__c = :deploymentId
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];
    }

    private Promotion__c populatePromotionStatus(Id promotionId, String status, Boolean deploymentDryRun) {
        Boolean promotionMergedAndDeployed = status == PromotionConstants.STATUS_COMPLETED && !deploymentDryRun;
        return new Promotion__c(Id = promotionId, Status__c = status, Completed__c = promotionMergedAndDeployed);
    }

    private Destination_Org__c populateDestinationOrgStatus(Id destinationId, String status) {
        return new Destination_Org__c(Id = destinationId, Status__c = status);
    }

    private Deployment__c populateDeploymentStatus(Id deploymentId, String status) {
        return new Deployment__c(Id = deploymentId, Status__c = status);
    }

    private static Environment__c populateEnvironmentLastDeploymentStatus(Id environmentId, Id deploymentId, String status) {
        return new Environment__c(Id = environmentId, Latest_Deployment__c = deploymentId, Latest_Deployment_Status__c = status);
    }

    // PMD False positive, as WITH USER_MODE is not supported yet
    @SuppressWarnings('PMD.ExcessiveParameterList, PMD.ApexCRUDViolation')
    private static List<SObject> updatedUserStories(Id deploymentId, Id promotionId, String promotionStatus, Boolean deploymentDryRun) {
        List<User_Story__c> result = new List<User_Story__c>();
        for (Promoted_User_Story__c promotedUserStory : [
            SELECT User_Story__c
            FROM Promoted_User_Story__c
            WHERE Promotion__c = :promotionId
            WITH USER_MODE
        ]) {
            User_Story__c updatedStory = new User_Story__c(Id = promotedUserStory.User_Story__c);
            Boolean needsUpdate = false;
            if (promotionStatus == PromotionConstants.STATUS_COMPLETED_WITH_ERRORS) {
                updatedStory.Promote_and_Deploy__c = false;
                needsUpdate = true;
            }
            if (deploymentDryRun) {
                updatedStory.Last_Validation_Deployment__c = deploymentId;
                updatedStory.Last_Validation_Promotion__c = promotionId;
                needsUpdate = true;
            }
            if (needsUpdate) {
                result.add(updatedStory);
            }
        }
        return result;
    }

    private static void sendNotification(Boolean jobIsSuccess, JobExecution__c jobExecution, Destination_Org__c destinationOrg) {
        String jobExecutionLink = URL.getOrgDomainURL().toExternalForm() + '/' + jobExecution.Id;

        Map<String, String> contextJson = new Map<String, String>{
            'UserName' => UserInfo.getName(),
            'DeployJobExecutionName' => jobExecution.Name,
            'JobExecutionLink' => jobExecutionLink,
            'SourceEnv' => destinationOrg.Deployment__r.Promotion__r.Source_Environment__r.Name,
            'TargetEnv' => destinationOrg.Deployment__r.Promotion__r.Destination_Environment__r.Name
        };

        CopadoNotifications.SendRequest request = new CopadoNotifications.SendRequest();
        request.name = jobIsSuccess ? PromotionConstants.DEPLOY_SUCCESS : PromotionConstants.DEPLOY_FAILED;
        request.recipientIds = new Set<Id>{ UserInfo.getUserId() };
        request.mergeData = contextJson;

        CopadoNotifications.send(request);
    }

    private void publishAutomationEvent(JobExecution__c job) {
        Actions.PromotionDeploymentResult response = new Actions.PromotionDeploymentResult();
        response.jobExecution = job;
        new GenerateAutomationEvent(ActionConstants.PROMOTION_DEPLOYMENT, job, JSON.serialize(response)).execute();
    }

    // INNER

    @SuppressWarnings('PMD.TooManyFields, PMD.ExcessivePublicCount') // note: data contract variables. Cannot be changed.
    public with sharing class CreateExecutionRequestData {
        // Common variables for both Promote and Deploy action
        public Id promotionId;
        public Boolean deploymentDryRun;
        public String otherInformation;

        // Only used by the Job execution for both action
        public List<Change> changes; // list of all changes of each user story
        public Promotion__c promotion;
        public String destinationBranchName;
        public String promotionBranchName;
        public Id fileWithSelectedChanges;
        public Id transactionId;
        public List<Id> userStoryIds;

        // Only used by the Job execution for Deploy Action
        public Id deploymentId;
        public Deployment__c deployment;
        public List<String> userStoryBranches = new List<String>();

        // Generic parameters for all actions
        public String actionCallback;
    }

    // NOTE: names are short to reduce memory/heap/transmission sizes
    public with sharing class Change {
        @InvocableVariable(required=true)
        public String n; // "name"

        @InvocableVariable
        public String t; // "type"

        @InvocableVariable
        public String m; // "module directory"

        @InvocableVariable(required=true)
        public String a; // "action" add, delete, retrieve-only, full pps, "deleteCascade"

        @InvocableVariable
        public String c; // optional, not used right now, "category" of this item: copadodx, vlocity, cpq, ...

        @InvocableVariable
        public String j; // "json additional information"... other values associated with this File

        @InvocableVariable
        public String u; // "user story name"... optional, user story name

        public Boolean equals(Object obj) {
            Change other = (Change) obj;
            return other != null && this.n == other.n && this.t == other.t && this.a == other.a && this.u == other.u;
        }

        public Integer hashCode() {
            return 17 + (31 * n.hashCode()) + (31 * t.hashCode()) + (31 * a.hashCode()) + (31 * u.hashCode());
        }
    }
}