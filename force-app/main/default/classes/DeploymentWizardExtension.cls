@SuppressWarnings('PMD')
public with sharing class DeploymentWizardExtension {
    public Deployment__c deployment { get; set; }
    public List<Step__c> steps { get; set; }
    public List<Destination_Org__c> destinationOrgs { get; set; }
    public List<Deployment_Job__c> deploymentJobs { get; set; }
    public Map<String, List<Object>> pageMessagesByMessageSeverity { get; set; }
    public Boolean showDateField { get; set; }
    public Boolean canDeployThis { get; set; }
    public Boolean goToDeployment { get; set; }
    public Boolean stepsHaveMixedTypes { get; set; }
    public List<Estimation> estimations;
    public Integer totalEstimations { get; set; }
    public Integer orgCount { get; set; }
    public Integer totalOutstandingEstimations { get; set; }
    private String deploymentScheduleValue { get; set; }
    private Promotion__c promotion { get; set; }
    private Set<String> stepTypesForMetadataCount = new Set<String>{
        'MetaData',
        'Full Profiles',
        'Full Permission Sets',
        'Users',
        'Translations',
        'Delete MetaData',
        'Custom Settings',
        'Git MetaData'
    };
    private Set<String> stepTypesForZeroCredit = new Set<String>{
        'Manual Task',
        'Git Promotion',
        'Salesforce Flow',
        'Function',
        'Automation',
        'Test'
    };
    private Set<String> applicationStepTypes = new Set<String>{ 'Manual Task', 'Salesforce Flow', 'Function', 'Automation', 'Test' };
    private List<String> attacnmentNames = new List<String>{
        'MetaData',
        'Delete MetaData',
        'Full Profiles',
        'Full Permission Sets',
        'Translations',
        'Users',
        'Custom Settings'
    };

    private final String DEPLOYMENT_SCHEDULE_VALUE = 'deployNow';
    private final String PENDING = 'Pending';
    private final String IN_PROGRESS = 'In Progress';
    private final String SUCCESS = 'Success';
    private final String NOT_STARTED = 'Not started';
    private final String SCHEDULED = 'Scheduled';
    private final String DEPLOY_NOW = 'Deploy now';
    private final String DEPLOY_LATER = 'Deploy later';
    private final String ERROR = 'error';
    private final String WARNING = 'warning';
    private boolean isOutstandingDeployment = false;

    public DeploymentWizardExtension(ApexPages.StandardController stdController) {
        if (!Test.isRunningTest()) {
            stdController.addFields(Utilities.getAllFields('Deployment__c').get(Label.FIELDS).split(','));
        }
        deployment = (Deployment__c) stdController.getRecord();
        initializeVariables();
        if (deploymentScheduleValue.toLowerCase() == DEPLOYMENT_SCHEDULE_VALUE.toLowerCase()) {
            getDestinationOrgs();
            getSteps();
            getDeploymentJobs();
            stepsHaveMixedTypes = checkDeploymentJobStepTypes();
            canDeployThis = validateDeployment();
        }
    }

    private void initializeVariables() {
        steps = new List<Step__c>();
        destinationOrgs = new List<Destination_Org__c>();
        deploymentJobs = new List<Deployment_Job__c>();
        pageMessagesByMessageSeverity = new Map<String, List<Object>>();
        deploymentScheduleValue = ApexPages.currentPage().getParameters().get('gotoStep');
        goToDeployment = false;
        showDateField = false;
        stepsHaveMixedTypes = false;
    }

    public Boolean validateDeployment() {
        Deployment__c deployment = returnDeploymentRecord();
        Boolean isSalesforcePlatform = deployment.From_Org__r.Platform__c == null || deployment.From_Org__r.Platform__c == 'Salesforce';
        Boolean isLicensesExceeded = false;
        Boolean isCopadoEnabled = false;
        Boolean isCCMEnabled = false;

        if (isSalesforcePlatform) {
            isLicensesExceeded = LicenseHelper.isLicensesExceeded();
            isCopadoEnabled = LicenseHelper.isCopadoEnabled();
            isCCMEnabled = LicenseHelper.isCCMEnabled();
        }

        if (isSalesforcePlatform && isLicensesExceeded) {
            pageMessagesByMessageSeverity.put(WARNING, new List<Object>{ Label.LICENSES_EXCEEDED });
            return false;
        }
        if (!isSalesforcePlatform || (isSalesforcePlatform && deployment.Promotion__c != null && (isCopadoEnabled || isCCMEnabled))) {
            Boolean isSandboxDestinations = destinationCredentialIsValidToDeploy(isCopadoEnabled, isCCMEnabled);
            if (!isSandboxDestinations) {
                pageMessagesByMessageSeverity.put(WARNING, new List<Object>{ Label.CCM_DESTINATION_ORG_INVALID });
                return false;
            }

            Boolean deploymentHasPromotionLinked = deployment.Promotion__c != null;
            return deploymentHasPromotionLinked ? pipelineValidations(deployment, isCopadoEnabled, isSalesforcePlatform) : true;
        } else if (isSalesforcePlatform && isCopadoEnabled) {
            return true;
        } else {
            pageMessagesByMessageSeverity.put(WARNING, new List<Object>{ Label.COPADO_DEPLOYER_LICENSE_NOT_ENABLED });
        }
        return false;
    }

    private Deployment__c returnDeploymentRecord() {
        Deployment__c deployment = [
            SELECT
                From_Org__r.Platform__c,
                Promotion__c,
                Promotion__r.Project__r.Deployment_Flow__c,
                Promotion__r.Project__r.Deployment_Flow__r.Active__c,
                Promotion__r.Project__r.Deployment_Flow__r.Git_Repository__c,
                Promotion__r.Project__r.Deployment_Flow__r.Main_Branch__c,
                Promotion__r.Release__r.Project__r.Deployment_Flow__c,
                Promotion__r.Release__r.Project__r.Deployment_Flow__r.Active__c,
                Promotion__r.Release__r.Project__r.Deployment_Flow__r.Git_Repository__c,
                Promotion__r.Release__r.Project__r.Deployment_Flow__r.Main_Branch__c
            FROM Deployment__c
            WHERE Id = :deployment.Id
            WITH SECURITY_ENFORCED
        ];
        return deployment;
    }

    private Boolean destinationCredentialIsValidToDeploy(Boolean isCopadoEnabled, Boolean isCCMEnabled) {
        Boolean isSandboxDestinations = true;
        if (!isCopadoEnabled && isCCMEnabled) {
            for (Destination_Org__c destinationOrgRecord : destinationOrgs) {
                if (destinationOrgRecord.To_Org__r.Environment__r.Type__c == 'Sandbox') {
                    isSandboxDestinations = true;
                } else {
                    isSandboxDestinations = false;
                    break;
                }
            }
        }
        return isSandboxDestinations;
    }

    private Boolean pipelineValidations(Deployment__c deployment, Boolean isCopadoEnabled, Boolean isSalesforcePlatform) {
        Deployment_Flow__c pipeline = returnPipelineRecord(deployment);
        Boolean isActiveFlow = isActivePipeline(pipeline);
        Boolean isCCMFlow = isCCMPipeline(pipeline);
        Boolean isValidCBMFlow = isValidCBMPipeline(pipeline);
        if (!isActiveFlow) {
            pageMessagesByMessageSeverity.put(WARNING, new List<Object>{ Label.PROMOTION_FLOW_INACTIVE });
            return false;
        }

        if (isSalesforcePlatform && isCopadoEnabled && isCCMFlow) {
            return true;
        } else if (isSalesforcePlatform && isValidCBMFlow) {
            return true;
        } else if (!isSalesforcePlatform) {
            return true;
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.CBM_FLOW_INVALID));
            return false;
        }
    }

    private Deployment_Flow__c returnPipelineRecord(Deployment__c deployment) {
        Deployment_Flow__c pipeline = [
            SELECT Active__c, Git_Repository__c, Main_Branch__c
            FROM Deployment_Flow__c
            WHERE
                Id = :deployment.Promotion__r.Project__r.Deployment_Flow__c
                OR Id = :deployment.Promotion__r.Release__r.Project__r.Deployment_Flow__c
            WITH SECURITY_ENFORCED
        ];
        return pipeline;
    }

    private Boolean isActivePipeline(Deployment_Flow__c pipeline) {
        Boolean isActiveFlow = false;
        if (pipeline != null) {
            if (pipeline.Active__c) {
                isActiveFlow = true;
            }
        }
        return isActiveFlow;
    }

    private Boolean isCCMPipeline(Deployment_Flow__c pipeline) {
        Boolean isCCMFlow = false;
        if (pipeline != null) {
            if (pipeline.Git_Repository__c == null && pipeline.Main_Branch__c == null) {
                isCCMFlow = true;
            }
        }
        return isCCMFlow;
    }

    private Boolean isValidCBMPipeline(Deployment_Flow__c pipeline) {
        Boolean isValidCBMFlow = false;
        if (pipeline != null) {
            if (pipeline.Git_Repository__c != null && pipeline.Main_Branch__c != null) {
                isValidCBMFlow = true;
            }
        }
        return isValidCBMFlow;
    }

    private void getDestinationOrgs() {
        destinationOrgs = Utilities.getDestinationOrgsByDeploymentId(deployment.Id);
    }

    private void getSteps() {
        steps = Utilities.getStepsByDeploymentId(deployment.Id);
    }

    private void getDeploymentJobs() {
        deploymentJobs = [
            SELECT Id, Status__c, Step__r.Deployment__c, Deployed__c, Step__r.Type__c, Step__r.Order__c, Last_Result__c 
            FROM Deployment_Job__c
            WHERE Step__r.Deployment__c = :deployment.Id
            WITH SECURITY_ENFORCED
            ORDER BY Step__r.Order__c
            LIMIT 10000
        ];
    }

    private Boolean checkDeploymentJobStepTypes() {
        Boolean stepsHaveMixedTypes = false;
        for (Deployment_Job__c deploymentJob : deploymentJobs) {
            if (!applicationStepTypes.contains(deploymentJob.Step__r.Type__c)) {
                stepsHaveMixedTypes = true;
                break;
            }
        }
        return stepsHaveMixedTypes;
    }

    public List<SelectOption> getScheduleOptions() {
        List<SelectOption> options = new List<SelectOption>();
        Schema.DescribeFieldResult fieldResult = Deployment__c.Schedule__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry f : ple) {
            options.add(new SelectOption(f.getLabel(), f.getValue()));
        }
        return options;
    }

    public PageReference scheduleShowDate() {
        showDateField = false;
        if (deployment.Schedule__c == DEPLOY_LATER) {
            Org__c customerOrg = DeployAPI.getCustomerOrg();
            if (customerOrg == null) {
                deployment.Schedule__c = '';
                deployment.Schedule__c.addError(Label.CUSTOMER_ORG_NOT_EXISTS);
                return null;
            }
            if (!DeployAPI.validateOrg(customerOrg.Id)) {
                deployment.Schedule__c = '';
                deployment.Schedule__c.addError(Label.CUSTOMER_ORG_NOT_VALIDATED);
                return null;
            }
            showDateField = true;
        }
        return null;
    }

    public PageReference creditCheckAndValidations() {
        try {
            Integer credits = DeployAPI.getCredits();
            if ((deployment.Date__c == null || deployment.Date__c < System.now()) && deployment.Schedule__c == DEPLOY_LATER) {
                pageMessagesByMessageSeverity.put(ERROR, new List<Object>{ Label.DEPLOYLATER_DT_MUST_BE_FUTURE });
                return null;
            }
            if (totalEstimations > credits && DeployAPI.orgMap.get('autoRecharge') == 'false') {
                pageMessagesByMessageSeverity.put(ERROR, new List<Object>{ Label.NOT_ENOUGH_CREDITS });
            }
        } catch (Exception ex) {
            pageMessagesByMessageSeverity.put(ERROR, new List<Object>{ ex.getMessage() });
        }
        return null;
    }

    public PageReference confirmAll() {
        if (pageMessagesByMessageSeverity.isEmpty()) {
            resetStatusOfDeploymentJobsAndDestinations(true);
        }
        return null;
    }

    public PageReference confirmOutstanding() {
        this.isOutstandingDeployment = true;
        if (pageMessagesByMessageSeverity.isEmpty()) {
            resetStatusOfDeploymentJobsAndDestinations(false);
        }
        return null;
    }

    private void resetStatusOfDeploymentJobsAndDestinations(Boolean deployAll) {
        try {
            updateDestinationCredentialsStatus();
            updateDeploymentJobStatus(deployAll);
        } catch (Exception ex) {
            pageMessagesByMessageSeverity.put(ERROR, new List<Object>{ ex.getMessage() });
        }
    }

    private void updateDestinationCredentialsStatus() {
        for (Destination_Org__c destinationOrg : destinationOrgs) {
            destinationOrg.Status__c = NOT_STARTED;
        }

        SObjectAccessDecision destinationCredentialDecision = Security.stripInaccessible(AccessType.UPDATABLE, destinationOrgs);
        update destinationCredentialDecision.getRecords();
    }

    private void updateDeploymentJobStatus(Boolean deployAll) {
        Boolean firstJob = false;
        Boolean firstJobStatusInProgress = false;
        for (Deployment_Job__c deploymentJob : deploymentJobs) {
            if ((deployAll || deploymentJob.Status__c != SUCCESS)) {
                Integer stepOrder = (Integer) deploymentJob.Step__r.Order__c;
                firstJob = (stepOrder == 1) || (!deployAll && !firstJob && !firstJobStatusInProgress);
                String newStatus = stepsHaveMixedTypes ? PENDING : firstJob ? IN_PROGRESS : PENDING;
                deploymentJob.Status__c = newStatus;
                if (newStatus == IN_PROGRESS) {
                    firstJobStatusInProgress = true;
                }

                if (deployAll) {
                    deploymentJob.Early_Completion_Status__c = newStatus;
                }
                deploymentJob.Deployed__c = 0;
                // set values to null to restart the deployment jobs.
                if(deploymentJob.Last_Result__c != null) {
                    deploymentJob.Last_Result__c = null;
                }
            }
        }

        SObjectAccessDecision deploymentJobDecision = Security.stripInaccessible(AccessType.UPDATABLE, deploymentJobs);
        update deploymentJobDecision.getRecords();
    }

    public PageReference confirm() {
        try {
            if (pageMessagesByMessageSeverity.isEmpty()) {
                updateDeployment();
                Integer pendingJobs = 0;
                pendingJobs = returnPendingDeploymentJobCount();
                if (stepsHaveMixedTypes && pendingJobs == 0) {
                    pageMessagesByMessageSeverity.put(ERROR, new List<Object>{ 'Nothing to deploy. Try "Deploy All" button' });
                    return null;
                }
            }
        } catch (Exception ex) {
            pageMessagesByMessageSeverity.put(ERROR, new List<Object>{ ex.getMessage() });
        }
        return null;
    }

    private void updateDeployment() {
        List<Deployment__c> deploymentsToCheckStatuesOfChild = [
            SELECT Id, (SELECT Status__c FROM Steps__r WHERE Status__c IN ('Not started', 'In progress', 'Completed with Errors'))
            FROM Deployment__c
            WHERE Id = :deployment.Id
            WITH SECURITY_ENFORCED
        ];
        Boolean failedSteps = false;
        Boolean inProgressSteps = false;

        for (Step__c stepRecord : deploymentsToCheckStatuesOfChild[0].Steps__r) {
            if (stepRecord.Status__c == 'Not started' || stepRecord.Status__c == 'In progress') {
                inProgressSteps = true;
            } else if (stepRecord.Status__c == 'Completed with Errors') {
                failedSteps = true;
            }
        }
        // if there is failed steps before this method runs, we do not need to update deployment again with in progress. In function execution, the job might start immediately, so we execute this method 3 seconds later in order to get statues of the child steps.
        Boolean allStepsCompleted = failedSteps || !failedSteps && !inProgressSteps;
        if (!allStepsCompleted) {
            deployment.Deployment_Completed_email_sent__c = false;
            deployment.Status__c = stepsHaveMixedTypes ? SCHEDULED : IN_PROGRESS;
            deployment.Deployment_command_sent__c = null;
            if (deployment.Schedule__c == DEPLOY_NOW) {
                deployment.Date__c = System.now();
            }
            SObjectAccessDecision deploymentDecision = Security.stripInaccessible(AccessType.UPSERTABLE, new List<Deployment__c>{ deployment });
            upsert deploymentDecision.getRecords();
            deployment = (Deployment__c) deploymentDecision.getRecords()[0];
        }
    }

    private Integer returnPendingDeploymentJobCount() {
        return [SELECT COUNT() FROM Deployment_Job__c WHERE Step__r.Deployment__c = :deployment.Id AND Status__c = :PENDING WITH SECURITY_ENFORCED];
    }

    public PageReference deployCall() {
        try {
            if (pageMessagesByMessageSeverity.isEmpty()) {
                if (deployment.Schedule__c == DEPLOY_NOW) {
                    if (stepsHaveMixedTypes) {
                        if (!this.isOutstandingDeployment) {
                            DeployAPI.deploy(deployment.Id, UserInfo.getSessionId());
                        } else {
                            DeployAPI.deployNowOutstanding(deployment.Id, UserInfo.getSessionId());
                        }
                    }
                } else if (deployment.Schedule__c == DEPLOY_LATER) {
                    String cronExpression = GetCRONExpression(deployment.Date__c);
                    DeployLater scheduledJob = new DeployLater(deployment.Id);
                    System.schedule(deployment.Name + ' ' + DEPLOY_LATER + ' ' + cronExpression, cronExpression, scheduledJob);
                }
                goToDeployment = true;
            }
        } catch (Exception ex) {
            pageMessagesByMessageSeverity.put(ERROR, new List<Object>{ ex.getMessage() });
        }
        return null;
    }

    private String GetCRONExpression(Datetime dt) {
        return ('' + dt.second() + ' ' + dt.minute() + ' ' + dt.hour() + ' ' + dt.day() + ' ' + dt.month() + ' ? ' + dt.year());
    }

    public List<Estimation> getEstimations() {
        estimations = new List<Estimation>();
        if (steps.isEmpty()) {
            return estimations;
        }
        orgCount = destinationOrgs.size();
        totalEstimations = 0;
        totalOutstandingEstimations = 0;

        Map<String, Object> creditsValueByStepId = estimateDeploy(deployment.Id);
        Map<Id, Integer> outstandings = new Map<Id, Integer>();
        for (Deployment_Job__c deploymentJobRecord : deploymentJobs) {
            if (outstandings.get(deploymentJobRecord.Step__c) == null) {
                outstandings.put(deploymentJobRecord.Step__c, 0);
            }
            if (deploymentJobRecord.Status__c != SUCCESS) {
                outstandings.put(deploymentJobRecord.Step__c, outstandings.get(deploymentJobRecord.Step__c) + 1);
            }
        }
        for (Step__c stepRecord : steps) {
            Estimation estimationRecord = new Estimation();
            estimationRecord.step = stepRecord;
            estimationRecord.stepId = stepRecord.Id;
            try {
                estimationRecord.credits = Integer.valueOf((String) creditsValueByStepId.get(stepRecord.Id)) * orgCount;
                estimationRecord.outstandingCredits =
                    Integer.valueOf((String) creditsValueByStepId.get(stepRecord.Id)) * outstandings.get(stepRecord.Id);
                totalEstimations += estimationRecord.credits;
                totalOutstandingEstimations += estimationRecord.outstandingCredits;
                estimationRecord.Status = 'Estimation Done';
            } catch (Exception exx) {
                estimationRecord.Status = (String) creditsValueByStepId.get(stepRecord.Id);
            }
            estimations.add(estimationRecord);
        }
        return estimations;
    }

    private Map<String, Object> estimateDeploy(String deploymentId) {
        Map<String, Object> creditsValueByStepId = new Map<String, Object>();
        Set<String> metadataCountStepIds = new Set<String>();
        Set<String> gitStepsIds = new Set<String>();
        for (Step__c stepRecord : steps) {
            creditsValueByStepId.put(stepRecord.Id, '1');
            if (stepTypesForMetadataCount.contains(stepRecord.Type__c)) {
                if (stepRecord.Type__c == 'Git MetaData') {
                    gitStepsIds.add(stepRecord.Id);
                }
                // The credits are based on the number of items in the step's attachment
                metadataCountStepIds.add(stepRecord.id);
            } else if (stepTypesForZeroCredit.contains(stepRecord.Type__c)) {
                creditsValueByStepId.put(stepRecord.Id, '0');
            } else {
                // 1 credit per execution of all other step types (Data, Bulk Data, Apex, URL Callout and any other)
                creditsValueByStepId.put(stepRecord.Id, '1');
            }
        }

        for (Attachment attachmentRecord : [
            SELECT Name, ParentId, Body
            FROM Attachment
            WHERE ParentId IN :metadataCountStepIds AND Name IN :attacnmentNames
        ]) {
            String attachmentBody = EncodingUtil.base64Decode(EncodingUtil.base64Encode(attachmentRecord.Body)).toString();
            // Attachments of 'Users' and 'Custom Settings' have irregular json structures
            if (attachmentRecord.Name == 'Users') {
                if (String.isNotBlank(attachmentBody)) {
                    UserWrapper usWrapper = (UserWrapper) System.JSON.deserialize(attachmentBody, UserWrapper.class);
                    if (usWrapper.userIds != null) {
                        creditsValueByStepId.put(attachmentRecord.ParentId, String.valueOf(usWrapper.userIds.size()));
                    } else {
                        creditsValueByStepId.put(attachmentRecord.ParentId, '1');
                    }
                } else {
                    creditsValueByStepId.put(attachmentRecord.ParentId, '1');
                }
            } else if (attachmentRecord.Name == 'Custom Settings') {
                if (String.isNotBlank(attachmentBody)) {
                    CustomSettingWrapper rItems = (CustomSettingWrapper) JSON.deserialize(attachmentBody, CustomSettingWrapper.class);
                    if (rItems.prevRes != null) {
                        Integer totalSelected = 0;
                        for (CustomSettingValues csv : rItems.prevRes) {
                            if (csv.s) {
                                totalSelected++;
                            }
                        }
                        creditsValueByStepId.put(attachmentRecord.ParentId, String.valueOf(totalSelected));
                    } else {
                        creditsValueByStepId.put(attachmentRecord.ParentId, '1');
                    }
                } else {
                    creditsValueByStepId.put(attachmentRecord.ParentId, '1');
                }
            } else {
                // All other attachments have regular json structures
                List<Object> mItems = (List<Object>) JSON.deserializeUntyped(attachmentBody);
                if (
                    attachmentRecord.Name == 'Translations' ||
                    attachmentRecord.Name == 'Full Profiles' ||
                    attachmentRecord.Name == 'Full Permission Sets'
                ) {
                    // 5 credits per translation, full profile and full permission set
                    creditsValueByStepId.put(attachmentRecord.ParentId, String.valueOf(mItems.size() * 5));
                } else if (gitStepsIds.contains(attachmentRecord.ParentId) && mItems.size() > 50) {
                    // 50 max credits for 'Git MetaData'
                    creditsValueByStepId.put(attachmentRecord.ParentId, String.valueOf(50));
                } else if (mItems.size() > 0) {
                    // 1 credit per metadata item
                    creditsValueByStepId.put(attachmentRecord.ParentId, String.valueOf(mItems.size()));
                } else {
                    creditsValueByStepId.put(attachmentRecord.ParentId, '1');
                }
            }
        }
        return creditsValueByStepId;
    }

    public Integer getPageMessageSize() {
        return messagesSize(pageMessagesByMessageSeverity);
    }

    private Integer messagesSize(Map<String, List<Object>> pageMessagesByMessageSeverity) {
        Integer listSize = 0;
        if (pageMessagesByMessageSeverity != null) {
            for (String severity : pageMessagesByMessageSeverity.keySet()) {
                listSize += pageMessagesByMessageSeverity.get(severity).size();
            }
        }
        return listSize;
    }

    public class UserWrapper {
        public String fromSuffix { get; set; }
        public String toSuffix { get; set; }
        public Boolean active { get; set; }
        public String userTerritories { get; set; }
        public List<String> userIds { get; set; }
    }

    public class CustomSettingWrapper {
        public String fromSuffix { get; set; }
        public String toSuffix { get; set; }
        public List<String> settings { get; set; }
        public String sco { get; set; }
        public String csName { get; set; }
        public List<CustomSettingValues> prevRes { get; set; }
    }

    public class CustomSettingValues {
        public Boolean s { get; set; }
        public String Name { get; set; }
        public String type { get; set; }
    }

    public class Estimation {
        public Step__c step { get; set; }
        public String stepId { get; set; }
        public Integer credits { get; set; }
        public String Status { get; set; }
        public Integer outstandingCredits { get; set; }
    }
}