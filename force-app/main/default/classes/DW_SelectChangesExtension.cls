/**
 * It is main controller for DW_SelectChanges page
 */
@SuppressWarnings('PMD')
public with sharing class DW_SelectChangesExtension extends DeploymentHelper {
    // Non Constants
    @TestVisible
    private String copadoNotificationId;
    @TestVisible
    private List<Copado_Notification__c> copadoNotificationList;
    public String jqxGridConfig { get; set; }
    public String zipBytesSource { get; set; }
    public String zipBytesTarget { get; set; }
    public String stepId { get; set; }
    public String deleteStepId { get; set; }
    public Boolean isRollback { get; set; }
    public Boolean isRefreshCacheSucceeded {
        get {
            if (null == isRefreshCacheSucceeded) {
                isRefreshCacheSucceeded = false;
            }
            return isRefreshCacheSucceeded;
        }
        set;
    }
    public Boolean startActionPoller {
        get {
            if (null == startActionPoller) {
                startActionPoller = false;
            }
            return startActionPoller;
        }
        set;
    }
    public Map<String, Set<Object>> componentMessagesMap {
        get {
            if (null == componentMessagesMap) {
                componentMessagesMap = new Map<String, Set<Object>>();
            }
            return componentMessagesMap;
        }
        set;
    }
    @TestVisible
    private String operationName {
        get {
            if (null == operationName) {
                operationName = '';
            }
            return operationName;
        }
        set;
    }
    public Boolean showRefreshCachePromtButton {
        get {
            if (null == showRefreshCachePromtButton) {
                showRefreshCachePromtButton = false;
            }
            return showRefreshCachePromtButton;
        }
        set;
    }

    /**
     * The extension constructor initializes the public deployment member
     *
     * @param stdController
     */
    public DW_SelectChangesExtension(ApexPages.StandardController stdController) {
        // Add ALL the fields of the sobject to the list of queried fields, to avoid " SObject row was retrieved via SOQL without querying..."
        if (!Test.isRunningTest()) {
            stdController.addFields(new List<String>(Schema.SObjectType.Deployment__c.fields.getMap().keySet()));
            stdController.addFields(new List<String>{ 'From_Org__r.Environment__r.Name', 'Rolled_back_Deployment__r.Name' });
        }
        this.deployment = (Deployment__c) stdController.getRecord();
        isRollback = deployment.Name.startsWith(ROLL_BACK);
        initializeServiceClasses();
        populateStepsList();
        populatePagesList();
        if (String.isNotBlank(deployment.From_Org__c)) {
            initializeMetadataUrl();
        }
        List<Step__c> steps = new StepsSelector()
            .byDeploymentIdFilteringTypes(new List<Id>{ this.deployment.rolled_back_deployment__c }, eligibleSteps);
        for (Step__c step : steps) {
            if (step.Type__c == GIT_PROMOTION) {
                this.stepId = step.Id;
            } else if (step.Type__c == DELETE_METADATA) {
                this.deleteStepId = step.Id;
            }
        }
    }

    /**
     * It is used to insert step to deployment
     */
    @RemoteAction
    public static String insertStep(String deploymentId, Boolean isRollback) {
        List<Step__c> steps = new List<Step__c>();
        try {
            List<String> typesToCheck = new List<String>();
            if (isRollback) {
                typesToCheck.add('Rollback');
            } else {
                typesToCheck.add('MetaData');
                typesToCheck.add('Git MetaData');
            }
            steps = new StepsSelector().byDeploymentIdFilteringTypes(new List<Id>{ deploymentId }, typesToCheck);
            if (!steps.isEmpty()) {
                return steps[0].Id;
            }
        } catch (System.QueryException exceptions) {
            UIDesignHelper.genericWarningMessage('info', new List<String>{ exceptions.getMessage() });
            return null;
        }

        Step__c step = new Step__c();
        if (
            Schema.SObjectType.Step__c.fields.Deployment__c.isCreateable() &&
            Schema.SObjectType.Step__c.fields.Type__c.isCreateable() &&
            Schema.SObjectType.Step__c.fields.Status__c.isCreateable() &&
            Schema.SObjectType.Step__c.fields.Order__c.isCreateable() &&
            Schema.SObjectType.Step__c.fields.Commit_Name__c.isCreateable()
        ) {
            step.Deployment__c = deploymentId;
            step.Name = 'Step 1';
            if (isRollback) {
                List<Deployment__c> originalDeployment = new DeploymentsSelector().byId(new Set<Id>{ Id.valueOf(deploymentId) });
                List<Step__c> gitPromotionStep = new StepsSelector()
                    .byDeploymentIdFilteringTypes(
                        new List<Id>{ originalDeployment[0].Rolled_Back_Deployment__c },
                        new List<String>{ 'Git Promotion' }
                    );
                step.Type__c = 'Rollback';
                if (!gitPromotionStep.isEmpty()) {
                    step.Name = originalDeployment[0].Name;
                    step.Git_Repository__c = gitPromotionStep[0].Git_Repository__c;
                }
            } else {
                step.Type__c = 'MetaData';
            }
            step.Status__c = 'Not Started';
            step.Order__c = 1;
            Utilities.Secure_DML(step, Utilities.DML_Action.INS, schema.SObjectType.Step__c);
            return step.Id;
        } else {
            return null;
        }
    }

    /**
     * It is used when user click on "Save & Close" button
     * First of all, we will try to upsert destination org record
     * Deployment_Last_Step__c should be populated.
     *
     * @return
     */
    public PageReference saveAndCloseStep() {
        upsertDeployment(false, true);
        return pageMessagesMap.isEmpty() ? goToDeploymentTab() : null;
    }

    /**
     * It is used when user click on "Confirm Target"
     * First of all, we will try to upsert destination org record
     * Deployment_Last_Step__c should be populated.
     *
     * @see DeploymentHelper
     * @return
     */
    public PageReference confirmAndGoNextStep() {
        upsertDeployment(true , true);
        return pageMessagesMap.isEmpty() ? goToNextStep() : null;
    }

    /**
     * It is used to initialize correct poller for showing the message until the job is done
     */
    public void initPoller() {
        operationName = ApexPages.currentPage().getParameters().get('operation');
        startActionPoller = true;
        if (String.isNotBlank(operationName) && operationName == REFRESH_CACHE) {
            isRefreshCacheSucceeded = false;
        }
        String message = Label.Initializing;
        componentMessagesMap = UIDesignHelper.accumulativeGenericWarningMessage(C_INFO, new List<String>{ message }, componentMessagesMap);
    }

    /**
     * It is used to check the copado notification record each time when action poller is enabled on the page. Interval is 5 second.
     *
     * @return
     */
    public PageReference pollerHandler() {
        if (String.isNotBlank(operationName) && operationName == REFRESH_CACHE) {
            isRefreshCacheSucceeded = copadoNotificationProcesses();
        }
        return null;
    }

    /**
     * This is used to find latest copado notification record to populate necessary information to the user.
     * @return
     */
    public Boolean copadoNotificationProcesses() {
        String parentId = deployment.From_Org__c;
        String failMessageLabel = Label.Refresh_Metadata_Job_Fail;
        String notificationType = 'MetadataRetriever';
        String copadoNotificationName = CopadoNotificationHelper.PROGRESS_STATUS_COPADO;

        try {
            if (copadoNotificationList == null || copadoNotificationList.isEmpty()) {
                copadoNotificationList = [
                    SELECT Id, status__c, isSuccess__c, isFinished__c
                    FROM Copado_Notification__c
                    WHERE
                        Type__c = :notificationType
                        AND isSuccess__c = FALSE
                        AND isFinished__c = FALSE
                        AND Name = :copadoNotificationName
                        AND ParentId__c = :parentId
                        AND CreatedById = :UserInfo.getUserId()
                    WITH SECURITY_ENFORCED
                    ORDER BY CreatedDate DESC
                    LIMIT 1
                ];
                if (!copadoNotificationList.isEmpty()) {
                    copadoNotificationId = copadoNotificationList[0].Id;
                }
            } else {
                if (String.isNotBlank(copadoNotificationId)) {
                    copadoNotificationList = [
                        SELECT status__c, isSuccess__c, isFinished__c
                        FROM Copado_Notification__c
                        WHERE Id = :copadoNotificationId
                        LIMIT 1
                    ];
                }
            }
            if (!copadoNotificationList.isEmpty() && !copadoNotificationList[0].isFinished__c) {
                componentMessagesMap = UIDesignHelper.accumulativeGenericWarningMessage(
                    C_INFO,
                    new List<String>{ copadoNotificationList[0].status__c },
                    componentMessagesMap
                );
                return false;
            }
        } catch (System.QueryException exceptions) {
            componentMessagesMap = UIDesignHelper.accumulativeGenericWarningMessage(
                C_WARNING,
                new List<String>{ exceptions.getMessage() },
                componentMessagesMap
            );
            return false;
        }
        if (
            !copadoNotificationList.isEmpty() &&
            copadoNotificationList[0].status__c != null &&
            copadoNotificationList[0].status__c.contains(C_DONE) &&
            copadoNotificationList[0].isFinished__c
        ) {
            if (copadoNotificationList[0].isSuccess__c) {
                return true;
            } else {
                componentMessagesMap = UIDesignHelper.accumulativeGenericWarningMessage(
                    C_WARNING,
                    new List<String>{ failMessageLabel },
                    componentMessagesMap
                );
                showRefreshCachePromtButton = true;
                return false;
            }
        } else {
            String message = Label.Initializing;
            componentMessagesMap = UIDesignHelper.accumulativeGenericWarningMessage(C_INFO, new List<String>{ message }, componentMessagesMap);
            return false;
        }
    }

    /**
     * It is used to count messages size in the list, so at the component it will be used to render icons and spinner
     *
     * @return
     */
    public Integer getComponentMessageSize() {
        Integer listSize = 0;
        for (String severity : componentMessagesMap.keySet()) {
            listSize += componentMessagesMap.get(severity).size();
        }
        return listSize;
    }

    /**
     * It is used to clear componentMessagesMap to use again in other action
     */
    public void clearMessagesMap() {
        componentMessagesMap = new Map<String, Set<Object>>();
        copadoNotificationList = new List<Copado_Notification__c>();
        copadoNotificationId = '';
        showRefreshCachePromtButton = false;
        startActionPoller = false;
    }

    public void assignZipBytes() {
        zipBytesSource = ApexPages.currentPage().getParameters().get('sourceFile');
        zipBytesTarget = ApexPages.currentPage().getParameters().get('targetFile');
    }

    public void assignJqxGridConfig() {
        jqxGridConfig = ApexPages.currentPage().getParameters().get('config');
    }
}