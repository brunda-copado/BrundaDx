@SuppressWarnings('PMD')
public with sharing class DeploymentTriggerHelper {
    private List<Deployment__c> deploymentRecords = new List<Deployment__c>();
    public Map<Id, Deployment__c> oldDeploymentsRecordsByDeploymentIds;
    public Map<Id, Deployment__c> newDeploymentsByDeploymentIds;
    public Map<Id, Deployment__c> oldDeploymentsByDeploymentIds;
    private List<Promotion__c> promotionsToBeUpdated = new List<Promotion__c>();
    private List<Build_Task__c> buildTasks = new List<Build_Task__c>();
    private Set<Id> validationDeploymentIds = new Set<Id>();
    private Set<String> deploymentSourceCredentialIds = new Set<String>();
    private Set<Id> promotionUserStoryIds = new Set<Id>();
    private List<Deployment_History__c> history = new List<Deployment_History__c>();
    public Map<Id, Id> deploymentIdsByPromotiondIds;
    public Map<Id, Promotion__c> deploymentPromotionsByDeploymentIds;

    public Map<Id, Id> deploymentFlowIdsByPromotionIds;
    public Map<Id, Deployment_Flow__c> deploymentFlowsByDeploymentFlowIds;
    private Map<Id, Set<Step__c>> stepsPerDeployment = new Map<Id, Set<Step__c>>();
    private Set<Step__c> stepsToUpdate = new Set<Step__c>();
    private Boolean promotionsUpdated { get; set; }
    private Map<Id, User_Story__c> userStoryByIds = new Map<Id, User_Story__c>();
    private Map<Id, Environment__c> environmentByIds = new Map<Id, Environment__c>();
    private final String SALESFORCE = 'Salesforce';
    private final String IN_PROGRESS = 'In Progress';
    private final String IN_PROGRESS_DEPLOYMENT = 'In progress';
    private final String MERGE_CONFLICT = 'Merge Conflict';
    private final String DRAFT = 'Draft';
    private final String COMPLETED_SUCCESSFULLY = 'Completed Successfully';
    private final String COMPLETED_WITH_ERRORS = 'Completed with Errors';
    private final String DW_SUMMARY = 'DW_Summary';
    private final String ROLL_BACK = 'Rollback';

    // CONSTRUCTOR

    public DeploymentTriggerHelper(List<Deployment__c> deployments, Boolean isAfter) {
        deploymentRecords = deployments;
        getPromotionAndPipeline();

        if (isAfter) {
            newDeploymentsByDeploymentIds = new DeploymentsSelector().deploymentByIds(deployments);
            populateSourceCredentialIds();
        }
    }

    public DeploymentTriggerHelper(List<Deployment__c> deployments, Map<Id, Deployment__c> oldDeploymentsByIds, Boolean isAfter) {
        deploymentRecords = deployments;
        getPromotionAndPipeline();
        oldDeploymentsRecordsByDeploymentIds = oldDeploymentsByIds;
        if (isAfter) {
            newDeploymentsByDeploymentIds = new DeploymentsSelector().deploymentByIds(deployments);
            populateSourceCredentialIds();
            oldDeploymentsByDeploymentIds = new DeploymentsSelector().deploymentByIds(oldDeploymentsByIds.values());
            populateStepsPerDeployment();
        }
    }

    // PUBLIC

    public void beforeInsert() {
        updateDeploymentPausedStatus();
        canDeployThis();
        updateDeploymentStatusToDraft();
    }

    public void beforeUpdate() {
        updateDeploymentPausedStatus();
        updateDeploymentLastStepRollback();
    }

    public void beforeDelete() {
        Boolean isCopadoEnabled = LicenseHelper.isCopadoEnabled();
        for (Deployment__c deployment : deploymentRecords) {
            if (!isCopadoEnabled) {
                deployment.addError(Label.COPADO_DEPLOYER_LICENSE_NOT_ENABLED);
            }
        }
    }

    public void afterInsert() {
        addHistory('created');
    }

    public void afterUpdate() {
        addHistory();
        getValidateOnlyDeployments();
        updatePromotionStatus();
        updateBuildTaskStatus();
        updateEnvironmentStatus();
        cleanManualTaskNotifications();
        deploy();
    }

    public void afterDelete() {
        addHistory('deleted');
    }

    // PRIVATE

    private void getPromotionAndPipeline() {
        Set<Id> promotionIds = new Set<Id>();
        deploymentIdsByPromotiondIds = new Map<Id, Id>();
        deploymentFlowIdsByPromotionIds = new Map<Id, Id>();
        deploymentPromotionsByDeploymentIds = new Map<Id, Promotion__c>();
        deploymentFlowsByDeploymentFlowIds = new Map<Id, Deployment_Flow__c>();
        for (Deployment__c deployment : deploymentRecords) {
            if (deployment.Promotion__c != null) {
                promotionIds.add(deployment.Promotion__c);
                deploymentIdsByPromotiondIds.put(deployment.Promotion__c, deployment.Id);
            }
        }

        if (!promotionIds.isEmpty()) {
            for (Promotion__c promotion : new PromotionsSelector(false, false).promotionsByIds(promotionIds)) {
                if (promotion.Release__r.Project__r.Deployment_Flow__c != null) {
                    deploymentFlowIdsByPromotionIds.put(promotion.Id, promotion.Release__r.Project__r.Deployment_Flow__c);

                    Deployment_Flow__c pipeline = new Deployment_Flow__c(
                        Id = promotion.Release__r.Project__r.Deployment_Flow__c,
                        Active__c = promotion.Release__r.Project__r.Deployment_Flow__r.Active__c,
                        Git_Repository__c = promotion.Release__r.Project__r.Deployment_Flow__r.Git_Repository__c,
                        Main_Branch__c = promotion.Release__r.Project__r.Deployment_Flow__r.Main_Branch__c,
                        Platform__c = promotion.Release__r.Project__r.Deployment_Flow__r.Platform__c
                    );
                    deploymentFlowsByDeploymentFlowIds.put(pipeline.Id, pipeline);
                }
                if (promotion.Project__r.Deployment_Flow__c != null) {
                    deploymentFlowIdsByPromotionIds.put(promotion.Id, promotion.Project__r.Deployment_Flow__c);

                    Deployment_Flow__c pipeline = new Deployment_Flow__c(
                        Id = promotion.Project__r.Deployment_Flow__c,
                        Active__c = promotion.Project__r.Deployment_Flow__r.Active__c,
                        Git_Repository__c = promotion.Project__r.Deployment_Flow__r.Git_Repository__c,
                        Main_Branch__c = promotion.Project__r.Deployment_Flow__r.Main_Branch__c,
                        Platform__c = promotion.Project__r.Deployment_Flow__r.Platform__c
                    );
                    deploymentFlowsByDeploymentFlowIds.put(pipeline.Id, pipeline);
                }
                if (promotion.Project__r.Deployment_Flow__c != null || promotion.Release__r.Project__r.Deployment_Flow__c != null) {
                    deploymentPromotionsByDeploymentIds.put(deploymentIdsByPromotiondIds.get(promotion.Id), promotion);
                }

                for (Promoted_User_Story__c promotedUserStory : promotion.Promoted_User_Stories__r) {
                    promotionUserStoryIds.add(promotedUserStory.User_Story__c);
                }
            }
        }
    }

    private void populateSourceCredentialIds() {
        for (Deployment__c deploymentRecord : newDeploymentsByDeploymentIds.values()) {
            deploymentSourceCredentialIds.add(deploymentRecord.From_Org__c);
        }
    }

    private void populateStepsPerDeployment() {
        for (Deployment__c deploymentRecord : oldDeploymentsByDeploymentIds.values()) {
            deploymentSourceCredentialIds.add(deploymentRecord.From_Org__c);
            for (Step__c step : deploymentRecord.Steps__r) {
                if (stepsPerDeployment.containsKey(step.Deployment__c)) {
                    Set<Step__c> steps = stepsPerDeployment.get(step.Deployment__c);
                    steps.add(step);
                    stepsPerDeployment.put(step.Deployment__c, steps);
                } else {
                    Set<Step__c> steps = new Set<Step__c>();
                    steps.add(step);
                    stepsPerDeployment.put(step.Deployment__c, steps);
                }
            }
        }
    }

    private void updateDeploymentPausedStatus() {
        for (Deployment__c deployment : deploymentRecords) {
            if (deployment.Paused__c && deployment.Status__c != IN_PROGRESS_DEPLOYMENT) {
                deployment.Paused__c = false;
            }
        }
    }

    private void updateDeploymentStatusToDraft() {
        for (Deployment__c deployment : deploymentRecords) {
            deployment.Status__c = DRAFT;
        }
    }

    private void updateDeploymentLastStepRollback() {
        for (Deployment__c deployment : deploymentRecords) {
            if (
                deployment.Deployment_Last_Step__c != DW_SUMMARY &&
                deployment.Status__c == COMPLETED_SUCCESSFULLY &&
                deployment.Name.contains(ROLL_BACK)
            ) {
                deployment.Deployment_Last_Step__c = DW_SUMMARY;
            }
        }
    }

    private void canDeployThis() {
        String userContextType = UserInfo.getUserType();
        Boolean isStandardContext = userContextType != 'AutomatedProcess';
        Boolean isLicensesExceeded = LicenseHelper.isLicensesExceeded();
        Boolean isCopadoEnabled = LicenseHelper.isCopadoEnabled();
        Boolean isCCMEnabled = LicenseHelper.isCCMEnabled();

        for (Deployment__c deployment : deploymentRecords) {
            if (isStandardContext && isLicensesExceeded) {
                deployment.addError(Label.LICENSES_EXCEEDED);
            }

            if (isStandardContext && deployment.Promotion__c != null && (isCopadoEnabled || isCCMEnabled)) {
                Boolean isActiveFlow = false;
                Boolean isCCMFlow = false;
                Boolean isValidCBMFlow = false;
                if (
                    deploymentFlowIdsByPromotionIds.containsKey(deployment.Promotion__c) &&
                    deploymentFlowsByDeploymentFlowIds.containsKey(deploymentFlowIdsByPromotionIds.get(deployment.Promotion__c)) &&
                    deploymentFlowsByDeploymentFlowIds.get(deploymentFlowIdsByPromotionIds.get(deployment.Promotion__c)) != null &&
                    deploymentFlowsByDeploymentFlowIds.get(deploymentFlowIdsByPromotionIds.get(deployment.Promotion__c)).Active__c
                ) {
                    isActiveFlow = true;
                }

                if (isActiveFlow) {
                    Deployment_Flow__c pipeline = deploymentFlowsByDeploymentFlowIds.get(
                        deploymentFlowIdsByPromotionIds.get(deployment.Promotion__c)
                    );
                    Boolean isSalesforcePlatform = pipeline.Platform__c == SALESFORCE || pipeline.Platform__c == null;
                    if (
                        (isSalesforcePlatform && pipeline.Git_Repository__c == null && pipeline.Main_Branch__c == null) ||
                        pipeline.Platform__c != SALESFORCE
                    ) {
                        isCCMFlow = true;
                    } else if (
                        (isSalesforcePlatform && pipeline.Git_Repository__c != null && pipeline.Main_Branch__c != null) ||
                        pipeline.Platform__c != SALESFORCE
                    ) {
                        isValidCBMFlow = true;
                    }

                    if (isCopadoEnabled && !isCCMFlow && !isValidCBMFLow) {
                        deployment.addError(Label.CBM_FLOW_INVALID);
                    }
                    if (!isCopadoEnabled && isCCMFlow) {
                        deployment.addError(Label.CBM_FLOW_INVALID);
                    }
                } else {
                    deployment.addError(Label.PROMOTION_FLOW_INACTIVE);
                }
            } else if (isStandardContext && !isCopadoEnabled && deployment.Template__c == null) {
                deployment.addError(Label.COPADO_DEPLOYER_LICENSE_NOT_ENABLED);
            }
        }
    }

    private void getValidateOnlyDeployments() {
        if (newDeploymentsByDeploymentIds != null) {
            for (Deployment__c deploymentRecord : newDeploymentsByDeploymentIds.values()) {
                Integer validateTypeStepsCount = 0;
                Integer manualTaskStepCount = 0;
                for (Step__c stepRecord : deploymentRecord.Steps__r) {
                    if (stepRecord.CheckOnly__c) {
                        validateTypeStepsCount++;
                    }

                    if (stepRecord.Type__c == 'Manual Task') {
                        manualTaskStepCount++;
                    }
                }

                Integer stepSizeWithoutManualTask = deploymentRecord.Steps__r.size() - manualTaskStepCount;

                if (
                    deploymentRecord.Steps__r.size() > 0 &&
                    deploymentRecord.Steps__r.size() != manualTaskStepCount &&
                    validateTypeStepsCount == stepSizeWithoutManualTask
                ) {
                    validationDeploymentIds.add(deploymentRecord.Id);
                }
            }

            updateDeploymentLookupOnUserStory();
        }
    }

    private void updateDeploymentLookupOnUserStory() {
        for (Deployment__c deployment : deploymentRecords) {
            for (Id usId : promotionUserStoryIds) {
                if (validationDeploymentIds.contains(deployment.Id)) {
                    User_Story__c us = new User_Story__c(
                        Id = usId,
                        Last_Validation_Deployment__c = deployment.Id,
                        Last_Validation_Promotion__c = deployment.Promotion__c
                    );
                    userStoryByIds.put(us.Id, us);
                }
            }
        }

        if (!userStoryByIds.isEmpty()) {
            Utilities.Secure_DML(userStoryByIds.values(), Utilities.DML_Action.UPD, schema.Sobjecttype.User_Story__c);
        }
    }

    private void updatePromotionStatus() {
        for (Deployment__c newDeploymentRecord : deploymentRecords) {
            Deployment__c oldDeploymentRecord = oldDeploymentsRecordsByDeploymentIds.get(newDeploymentRecord.Id);
            Promotion__c promotion = deploymentPromotionsByDeploymentIds.get(newDeploymentRecord.Id);
            if (promotion != null) {
                String promotionStatus = promotion.Status__c;
                //below condition is added to seperate ccd deployments from user story validations
                Boolean isRegularDeployment = (validationDeploymentIds.isEmpty() || !validationDeploymentIds.contains(newDeploymentRecord.Id));
                Boolean isSuccess =
                    oldDeploymentRecord.Status__c != COMPLETED_SUCCESSFULLY &&
                    newDeploymentRecord.Status__c == COMPLETED_SUCCESSFULLY;
                Boolean isError = oldDeploymentRecord.Status__c != COMPLETED_WITH_ERRORS && newDeploymentRecord.Status__c == COMPLETED_WITH_ERRORS;
                Boolean isInProgress = oldDeploymentRecord.Status__c != IN_PROGRESS_DEPLOYMENT && newDeploymentRecord.Status__c == IN_PROGRESS_DEPLOYMENT;

                if (
                    String.isNotBlank(newDeploymentRecord.Rolled_back_Deployment__c) &&
                    String.isNotBlank(newDeploymentRecord.Promotion__c) &&
                    newDeploymentRecord.Status__c == COMPLETED_SUCCESSFULLY
                ) {
                    //promotion.Status__c = 'Completed';
                    promotion.Is_Rolled_Back__c = true;
                    promotionsToBeUpdated.add(promotion);
                } else if(String.isBlank(newDeploymentRecord.Rolled_back_Deployment__c)){
                    if (
                        isRegularDeployment &&
                        !String.isBlank(newDeploymentRecord.Promotion__c) &&
                        isSuccess &&
                        !newDeploymentRecord.Do_Not_Update_Promotion__c
                    ) {
                        promotion.Status__c = 'Completed';
                    } else if (isRegularDeployment && !String.isBlank(newDeploymentRecord.Promotion__c) && isError) {
                        promotion.Status__c = COMPLETED_WITH_ERRORS;
                    } else if (
                        !isRegularDeployment &&
                        !String.isBlank(newDeploymentRecord.Promotion__c) &&
                        isSuccess &&
                        !newDeploymentRecord.Do_Not_Update_Promotion__c
                    ) {
                        promotion.Status__c = 'Validated';
                    } else if (!isRegularDeployment && !String.isBlank(newDeploymentRecord.Promotion__c) && isError) {
                        promotion.Status__c = 'Validation failed';
                    } else if (!String.isBlank(newDeploymentRecord.Promotion__c) && isInProgress) {
                        promotion.Status__c = IN_PROGRESS;
                    }
                    if (promotionStatus != promotion.Status__c) {
                        promotionsToBeUpdated.add(promotion);
                    }
                }
            }
        }

        if (promotionsUpdated == null) {
            promotionsUpdated = false;
        }
        if (!promotionsUpdated && !promotionsToBeUpdated.isEmpty()) {
            promotionsUpdated = true;
            Utilities.Secure_DML(promotionsToBeUpdated, Utilities.DML_Action.UPD, schema.Sobjecttype.Promotion__c);
        }
    }

    private void updateBuildTaskStatus() {
        for (Deployment__c newDeploymentRecord : deploymentRecords) {
            Deployment__c oldDeploymentRecord = (Deployment__c) Trigger.oldMap.get(newDeploymentRecord.Id);
            if (!String.isBlank(newDeploymentRecord.Build_Task__c)) {
                for (Deployment__c deploymentRecord : newDeploymentsByDeploymentIds.values()) {
                    Boolean isError = oldDeploymentRecord.Status__c != COMPLETED_WITH_ERRORS && deploymentRecord.Status__c == COMPLETED_WITH_ERRORS;
                    Boolean isSuccess =
                        oldDeploymentRecord.Status__c != COMPLETED_SUCCESSFULLY &&
                        deploymentRecord.Status__c == COMPLETED_SUCCESSFULLY;
                    Boolean isRecordNull = deploymentRecord.Build_Task__r.Continuous_Integration__r.Post_Success_Deployment_Jobs__c == null;
                    if ((isSuccess || isError) && isRecordNull) {
                        Build_Task__c buildTask = new Build_Task__c();
                        buildTask.Id = deploymentRecord.Build_Task__c;
                        buildTask.Status__c = isSuccess ? 'Success' : 'Failed';
                        buildTasks.add(buildTask);
                    }
                }
            }
        }

        if (!buildTasks.isEmpty()) {
            Utilities.Secure_DML(buildTasks, Utilities.DML_Action.UPD, schema.Sobjecttype.Build_Task__c);
        }
    }

    private void updateEnvironmentStatus() {
        if (oldDeploymentsRecordsByDeploymentIds == null) {
            return;
        }
        //merge conflict added for showing it on the deployment activity screen
        List<String> desiredStatuses = new List<String>{ MERGE_CONFLICT, IN_PROGRESS_DEPLOYMENT, COMPLETED_WITH_ERRORS, COMPLETED_SUCCESSFULLY };
        Set<Id> depIds = new Set<Id>();
        for (Deployment__c thisDeployment : deploymentRecords) {
            Deployment__c oldDeploymentRecord = oldDeploymentsRecordsByDeploymentIds.get(thisDeployment.Id);
            Boolean isStatusChanged = thisDeployment.Status__c != oldDeploymentRecord.Status__c;
            Boolean isPausedChanged = thisDeployment.Paused__c != oldDeploymentRecord.Paused__c;
            if (desiredStatuses.contains(thisDeployment.Status__c) && (isStatusChanged || isPausedChanged)) {
                depIds.add(thisDeployment.Id);
            }
        }

        if (depIds.isEmpty()) {
            return;
        }

        Boolean isPausedValueExist = false;
        Schema.DescribeFieldResult fieldResult = Environment__c.Latest_Deployment_Status__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry key : ple) {
            if (key.getValue() == 'Paused') {
                isPausedValueExist = true;
                break;
            }
        }

        for (Deployment__c deploymentRecord : newDeploymentsByDeploymentIds.values()) {
            for (Destination_Org__c destinationOrgRecord : deploymentRecord.Destination_Orgs__r) {
                if (depIds.contains(destinationOrgRecord.Deployment__c)) {
                    String status = deploymentRecord.Paused__c && isPausedValueExist ? 'Paused' : deploymentRecord.Status__c;
                    Environment__c environment = new Environment__c(
                        Id = destinationOrgRecord.To_Org__r.Environment__c,
                        Latest_Deployment__c = deploymentRecord.Id,
                        Latest_Deployment_Status__c = status
                    );
                    environmentByIds.put(destinationOrgRecord.To_Org__r.Environment__c, environment);
                }
            }
        }

        if (!environmentByIds.isEmpty()) {
            Utilities.Secure_DML(environmentByIds.values(), Utilities.DML_Action.UPD, Schema.SObjectType.Environment__c);
        }
    }

    private void addHistory(String event) {
        for (Deployment__c deployment : deploymentRecords) {
            history.add(
                new Deployment_History__c(
                    Deployment_Id__c = deployment.Id,
                    Deployment__c = (event == 'Deleted' ? null : deployment.Id),
                    Date__c = System.now(),
                    Event__c = event,
                    Object__c = 'Deployment',
                    User__c = UserInfo.getUserId()
                )
            );
        }
        insertHistory();
    }

    private void addHistory() {
        Map<String, Schema.SObjectField> fieldMap = Schema.SObjectType.Deployment__c.fields.getMap();
        for (String field : fieldMap.keyset()) {
            DescribeFieldResult dfr = fieldMap.get(field).getDescribe();
            if (dfr.isUpdateable()) {
                for (Deployment__c newDeploymentRecord : deploymentRecords) {
                    Deployment__c oldDeploymentRecord = (Deployment__c) Trigger.oldMap.get(newDeploymentRecord.Id);
                    if (oldDeploymentRecord.get(field) != newDeploymentRecord.get(field)) {
                        Deployment_History__c deploymentHistoryRecord = new Deployment_History__c(
                            Deployment__c = oldDeploymentRecord.Id,
                            Deployment_Id__c = oldDeploymentRecord.Id,
                            Date__c = System.now(),
                            Event__c = 'Updated',
                            Object__c = 'Deployment',
                            Field__c = dfr.getLabel(),
                            User__c = UserInfo.getUserId(),
                            New_Value__c = (newDeploymentRecord.get(field) != null ? String.valueOf(newDeploymentRecord.get(field)) : null),
                            Old_Value__c = (oldDeploymentRecord.get(field) != null ? String.valueOf(oldDeploymentRecord.get(field)) : null)
                        );
                        String orgName = '';
                        String environmentOrgId = '';
                        if (
                            String.isNotBlank(deploymentHistoryRecord.New_Value__c) &&
                            deploymentSourceCredentialIds.contains(deploymentHistoryRecord.New_Value__c)
                        ) {
                            orgName = newDeploymentsByDeploymentIds.get(newDeploymentRecord.Id).From_Org__r.Name;
                            environmentOrgId = newDeploymentsByDeploymentIds.get(newDeploymentRecord.Id).From_Org__r.Environment__r.Org_ID__c;
                            Boolean isOtherPlatform =
                                newDeploymentsByDeploymentIds.get(newDeploymentRecord.Id).From_Org__r.Environment__r.Platform__c != null &&
                                newDeploymentsByDeploymentIds.get(newDeploymentRecord.Id).From_Org__r.Environment__r.Platform__c != 'Salesforce';
                            deploymentHistoryRecord.New_Value__c = orgName;
                            if (!isOtherPlatform) {
                                deploymentHistoryRecord.New_Value__c += ' (' + environmentOrgId + ')';
                            }
                        }
                        if (
                            String.isNotBlank(deploymentHistoryRecord.Old_Value__c) &&
                            deploymentSourceCredentialIds.contains(deploymentHistoryRecord.Old_Value__c)
                        ) {
                            orgName = oldDeploymentsByDeploymentIds.get(oldDeploymentRecord.Id).From_Org__r.Name;
                            environmentOrgId = oldDeploymentsByDeploymentIds.get(oldDeploymentRecord.Id).From_Org__r.Environment__r.Org_ID__c;
                            Boolean isOtherPlatform =
                                oldDeploymentsByDeploymentIds.get(oldDeploymentRecord.Id).From_Org__r.Environment__r.Platform__c != null &&
                                oldDeploymentsByDeploymentIds.get(oldDeploymentRecord.Id).From_Org__r.Environment__r.Platform__c != 'Salesforce';
                            deploymentHistoryRecord.Old_Value__c = orgName;
                            if (!isOtherPlatform) {
                                deploymentHistoryRecord.Old_Value__c += ' (' + environmentOrgId + ')';
                            }
                        }
                        history.add(deploymentHistoryRecord);
                    }
                }
            }
        }
        insertHistory();
    }

    private void insertHistory() {
        if (!history.isEmpty()) {
            Utilities.Secure_DML(history, Utilities.DML_Action.INS, schema.Sobjecttype.Deployment_History__c);
            history.clear();
        }
    }

    private void cleanManualTaskNotifications() {
        for (Deployment__c newDeployment : deploymentRecords) {
            for (Deployment__c oldDeployment : oldDeploymentsRecordsByDeploymentIds.values()) {
                if (oldDeployment.Status__c != IN_PROGRESS_DEPLOYMENT && newDeployment.Status__c == IN_PROGRESS_DEPLOYMENT) {
                    if (stepsPerDeployment.containsKey(oldDeployment.Id)) {
                        stepsToUpdate.addAll(stepsPerDeployment.get(oldDeployment.Id));
                    }
                }
            }
        }
        updateSteps();
    }

    private void updateSteps() {
        if (!stepsToUpdate.isEmpty() && !StepTriggerHelper.isManualTaskNotified) {
            for (Step__c step : stepsToUpdate) {
                step.Manual_Task_Notified__c = false;
            }
            Utilities.Secure_DML(new List<Step__c>(stepsToUpdate), Utilities.DML_Action.UPD, schema.Sobjecttype.Step__c);
        }
    }

    private void deploy() {
        List<Id> deploymentIds = new List<Id>();
        for (Deployment__c newDeploymentRecord : deploymentRecords) {
            Deployment__c oldDeploymentRecord = (Deployment__c) Trigger.oldMap.get(newDeploymentRecord.Id);
            if (newDeploymentRecord.Deployment_command_sent__c != null && oldDeploymentRecord.Deployment_command_sent__c == null) {
                deploymentIds.add(oldDeploymentRecord.id);
            }
        }
        if (!deploymentIds.isEmpty()) {
            DeployAPI.deploy(deploymentIds, UserInfo.getSessionId());
        }
    }
}