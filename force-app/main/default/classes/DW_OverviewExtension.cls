/**
 * It is main controller for DW_Overview page
 */
@SuppressWarnings('PMD')
public with sharing class DW_OverviewExtension extends DeploymentHelper {
    // Non constants
    public String stepTestLevel { get; set; }
    public List<Quality_Gate__c> qualityGateList { get; set; }
    public Id stepId { get; set; }
    public Boolean isRollback { get; set; }

    // Constants
    public final String namespace = Settings.ns;
    private final String NO_TEST_RUN = 'No Test Run';
    private final String RUN_SPECIFIED_TESTS = 'Run Specified Tests';
    private final String RUN_LOCAL_TESTS = 'Run Local Tests';
    private final String RUN_ALL_TESTS_IN_ORG = 'Run All Tests In Org';

    /**
     * The extension constructor initializes the public deployment member
     *
     * @param stdController
     */
    public DW_OverviewExtension(ApexPages.StandardController stdController) {
        // Add ALL the fields of the sobject to the list of queried fields, to avoid " SObject row was retrieved via SOQL without querying..."
        if (!Test.isRunningTest()) {
            stdController.addFields(new List<String>(Schema.SObjectType.Deployment__c.fields.getMap().keySet()));
            stdController.addFields(new List<String>{ 'From_Org__r.Environment__c' });
        }
        this.deployment = (Deployment__c) stdController.getRecord();
        isRollback = deployment.Name.startsWith(ROLL_BACK);
        if (isTestClassFilePresent()) {
            stepTestLevel = RUN_SPECIFIED_TESTS.replaceAll(' ', '');
        } else {
            stepTestLevel = NO_TEST_RUN.replaceAll(' ', '');
        }
        initializeServiceClasses();
        populateStepsList();
        populatePagesList();
        checkValidation();
        qualityGateList = new List<Quality_Gate__c>();
        connectionBehaviorsCheck();
        if (deploymentInterface.getStepGeneralHeader() != Label.New_Data_Deployment) {
            initializeMetadataUrl();
        } else {
            getDataTemplateDetails();
        }

        List<Step__c> steps = new StepsSelector().byDeploymentIdFilteringTypes(new List<Id>{ this.deployment.Id }, new List<String>{ ROLL_BACK });
        if (!steps.isEmpty()) {
            this.stepId = steps[0].Id;
        }
    }

    /**
     * It is used to parse the data template attachment and find the total size of relation
     *
     * @return
     */
    public Integer getTotalRelationCount() {
        try {
            List<Attachment> attachmentList;
            if (Schema.SObjectType.Attachment.isQueryable() && Schema.SObjectType.Attachment.isAccessible()) {
                if (String.isNotBlank(dataTemplate.Id)) {
                    attachmentList = [SELECT Id, Body FROM Attachment WHERE ParentId = :dataTemplate.Id AND Name = 'Template Detail' LIMIT 1];
                }
            } else {
                pageMessagesMap.put(
                    C_WARNING,
                    new List<Object>{ Label.Insufficient_Access_Rights, Label.Related_Object + ' ' + Schema.SObjectType.Attachment.getLabel() }
                );
            }
            if (!attachmentList.isEmpty()) {
                DataTemplateSetupExtension.TemplateObjectWrapper dummyWrapper = (DataTemplateSetupExtension.TemplateObjectWrapper) JSON.deserialize(
                    attachmentList[0].Body.toString(),
                    DataTemplateSetupExtension.TemplateObjectWrapper.class
                );
                return dummyWrapper.parentObjectsReferenceList.size() + dummyWrapper.childrenObjectsReferenceList.size();
            }
        } catch (Exception excp) {
            pageMessagesMap.put(C_ERROR, new List<Object>{ excp.getMessage() });
        }
        return 0;
    }

    /**
     * It is used to check if source and destination orgs are validated
     */
    private void checkValidation() {
        List<Object> pmList = new List<Object>();
        String destOrgId = getDestinationOrg().To_Org__c;
        List<Org__c> orgList;
        if (Schema.SObjectType.Org__c.isQueryable() && Schema.SObjectType.Org__c.isAccessible()) {
            orgList = [
                SELECT Id, Name, Validated_Date__c, Validated_Status__c, Disable_Validation__c
                FROM Org__c
                WHERE Id = :deployment.From_Org__c OR Id = :destOrgId
            ];
        } else {
            pageMessagesMap.put(
                C_WARNING,
                new List<Object>{ Label.Insufficient_Access_Rights, Label.Related_Object + ' ' + Schema.SObjectType.Org__c.getLabel() }
            );
        }

        for (Org__c org : orgList) {
            if (!org.Disable_Validation__c && org.Validated_Status__c != C_OK) {
                if (String.isNotBlank(deployment.From_Org__c) && org.Id == deployment.From_Org__c) {
                    pmList.add(Label.WRONG_CREDENTIALS + ' - ' + org.Name);
                }

                if (null != destOrgId && org.Id == destOrgId) {
                    pmList.add(Label.DESTINATION_ORG_NOT_VALIDATED);
                }
            }
        }

        if (!pmList.isEmpty()) {
            pageMessagesMap.put(C_ERROR, pmList);
        }
    }

    /**
     * It is used to populate test level options for step record
     *
     * @return
     */
    public List<SelectOption> getTestLevels() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption(NO_TEST_RUN.replaceAll(' ', ''), NO_TEST_RUN));
        options.add(new SelectOption(RUN_SPECIFIED_TESTS.replaceAll(' ', ''), RUN_SPECIFIED_TESTS));
        options.add(new SelectOption(RUN_LOCAL_TESTS.replaceAll(' ', ''), RUN_LOCAL_TESTS));
        options.add(new SelectOption(RUN_ALL_TESTS_IN_ORG.replaceAll(' ', ''), RUN_ALL_TESTS_IN_ORG));
        return options;
    }

    /**
     * It is used to render validate and deployment buttons
     *
     * @return
     */
    public Boolean getEnableButtons() {
        if (LicenseHelper.isLicensesExceeded()) {
            pageMessagesMap.put(C_WARNING, new List<Object>{ Label.LICENSES_EXCEEDED });
            return false;
        }
        if(isRollback){
            return true;
        }
        if (LicenseHelper.isCopadoEnabled()) {
            return true;
        } else {
            pageMessagesMap.put(C_WARNING, new List<Object>{ Label.COPADO_DEPLOYER_LICENSE_NOT_ENABLED });
        }
        return false;
    }

    /**
     * It is used to check if user has enough credit to deploy
     */
    public void confirmDeployment() {
        try {
            pageMessagesMap.clear();
            deploymentActionName = ApexPages.currentPage().getParameters().get('actionName');
            Integer creditsAvailable = DeployAPI.getCredits();
            Integer creditsToBeUsed = getCalculatedCredit();
            Boolean autoRechargeIsNotActive = DeployAPI.orgMap.get('autoRecharge') == 'false';
            if (creditsToBeUsed > creditsAvailable && autoRechargeIsNotActive) {
                pageMessagesMap.put(C_WARNING, new List<Object>{ Label.NOT_ENOUGH_CREDITS });
                return;
            }
        } catch (Exception excp) {
            pageMessagesMap.put(C_ERROR, new List<Object>{ excp.getMessage() });
        }
    }

    public void validateDataTemplateDeployment() {
        try {
            pageMessagesMap.clear();

            Step__c step = getDeploymentStepRecord();
            DataStepValidator validator = new DataStepValidator(step.Id);
            validator.validate();
        } catch (Exception e) {
            pageMessagesMap.put(C_ERROR, new List<Object>{ e.getMessage() });
        }
    }

    /**
     * It is used to callout deployment job
     *
     * @return
     */
    public PageReference deploymentCallout() {
        try {
            if (pageMessagesMap.isEmpty()) {
                DeployAPI.deploy(deployment.Id, UserInfo.getSessionId());
            }
        } catch (Exception excp) {
            pageMessagesMap.put(C_ERROR, new List<Object>{ excp.getMessage() });
        }
        return null;
    }

    /**
     * It is used to update datajson field of step
     *
     * @see StepDataJson
     */
    public void updateStep() {
        List<Step__c> stepList = new List<Step__c>();
        try {
            for (Step__c step : new StepsSelector().byDeploymentIdFilteringTypes(new List<Id>{ deployment.Id }, new List<String>())) {
                if (step.Type__c != null && step.Type__c != DATA_TEMPLATE && step.Type__c != ROLL_BACK) {
                    StepDataJson stepJson = new StepDataJson(stepTestLevel, new List<String>());
                    step.dataJson__c = JSON.serialize(stepJson);
                    stepList.add(step);
                } else if (step.Type__c == ROLL_BACK) {
                    // getRollbackJson will be called only once when the step is Rollback
                    step.dataJson__c = getRollbackJson(step.Id, deployment.Id, stepTestLevel);
                    stepList.add(step);
                    break;
                }
            }

            if (!stepList.isEmpty()) {
                Utilities.Secure_DML(stepList, Utilities.DML_Action.UPD, schema.SObjectType.Step__c);
            }
        } catch (Exception e) {
            pageMessagesMap.put(
                C_WARNING,
                new List<Object>{ Label.Insufficient_Access_Rights, Label.Related_Object + ' ' + Schema.SObjectType.Step__c.getLabel() }
            );
            return;
        }
    }

    private List<Step__c> getOriginalSteps(String deploymentId) {
        List<Deployment__c> rollbackDeployment = new DeploymentsSelector().byId(new Set<Id>{ Id.valueOf(deploymentId) });
        return new StepsSelector().byDeploymentIdFilteringTypes(new List<Id>{ rollbackDeployment[0].Rolled_Back_Deployment__c }, eligibleSteps);
    }

    private String getRollbackJson(Id stepId, String deploymentId, String stepTestLevel) {
        Set<Id> stepIds = new Set<Id>();
        RollbackStepJson wrapper = new RollbackStepJson();
        wrapper.testLevel = stepTestLevel;
        wrapper.replacements = new List<String>();
        wrapper.steps = new List<RollbackStepJson.step>();
        List<Deployment__c> rollbackDeployment = new DeploymentsSelector().byId(new Set<Id>{ Id.valueOf(deploymentId) });
        wrapper.gitBranch = getDestinationEnvironmentBranch(rollbackDeployment[0].Rolled_Back_Deployment__c);
        stepIds.add(stepId);
        List<Step__c> originalSteps = getOriginalSteps(deploymentId);

        for (Step__c step : originalSteps) {
            stepIds.add(step.Id);
        }
        Map<Id, List<ContentVersion>> contentVersionsByStepId = getContentVersionsByStepId(stepIds);
        for (Step__c step : originalSteps) {
            RollbackStepJson.Step stepData = new RollbackStepJson.Step();
            stepData.promotion = true;
            stepData.metadataFileId = getContentVersionId(step.Id, ROLLBACK_METADATA_FILENAME, contentVersionsByStepId);
            stepData.vlocityFileId = getContentVersionId(step.Id, ROLLBACK_VLOCITY_FILENAME, contentVersionsByStepId);
            Id indexFileId = getContentVersionId(stepId, SELECTED_ROLLBACK_FILENAME + '_' + step.Type__c, contentVersionsByStepId);
            if (indexFileId != null) {
                stepData.indexFileId = getContentVersionId(stepId, SELECTED_ROLLBACK_FILENAME + '_' + step.Type__c, contentVersionsByStepId);
                wrapper.steps.add(stepData);
            }
        }
        return JSON.serialize(wrapper);
    }

    private Map<Id, List<ContentVersion>> getContentVersionsByStepId(Set<Id> stepIds) {
        Set<Id> contentDocumentIds = new Set<Id>();
        Map<Id, List<ContentVersion>> contentVersionsByStepId = new Map<Id, List<ContentVersion>>();
        Map<Id, Set<Id>> stepIdCdMap = new Map<Id, Set<Id>>();
        Map<Id, ContentVersion> cvCdMap = new Map<Id, ContentVersion>();

        for (ContentDocumentLink cdl : new ContentDocumentLinksSelector().byLinkedEntityId(stepIds)) {
            contentDocumentIds.add(cdl.ContentDocumentId);
            if (!stepIdCdMap.containsKey(cdl.LinkedEntityId)) {
                stepIdCdMap.put(cdl.LinkedEntityId, new Set<Id>{ cdl.ContentDocumentId });
            } else {
                stepIdCdMap.get(cdl.LinkedEntityId).add(cdl.ContentDocumentId);
            }
        }
        if (!contentDocumentIds.isEmpty()) {
            for (ContentVersion cvs : new ContentVersionsSelector().byContentDocumentIdWithLatest(contentDocumentIds)) {
                cvCdMap.put(cvs.ContentDocumentId, cvs);
            }
        }

        for (Id stepId : stepIdCdMap.keySet()) {
            for (Id cdId : stepIdCdMap.get(stepId)) {
                if (!contentVersionsByStepId.containsKey(stepId)) {
                    contentVersionsByStepId.put(stepId, new List<ContentVersion>{ cvCdMap.get(cdId) });
                } else {
                    contentVersionsByStepId.get(stepId).add(cvCdMap.get(cdId));
                }
            }
        }

        return contentVersionsByStepId;
    }

    private Id getContentVersionId(Id stepId, String title, Map<Id, List<ContentVersion>> contentVersionsByStepId) {
        if (contentVersionsByStepId != null && contentVersionsByStepId.containsKey(stepId)) {
            for (ContentVersion cv : contentVersionsByStepId.get(stepId)) {
                if (cv.Title == title) {
                    return cv.Id;
                }
            }
        }
        return null;
    }

    private String getDestinationEnvironmentBranch(String deploymentId) {
        List<Deployment__c> deployment = new DeploymentsSelector().byId(new Set<Id>{ Id.valueOf(deploymentId) });

        List<Promotion__c> promotion = [
            SELECT
                Project__c,
                Project__r.Deployment_Flow__c,
                Release__c,
                Release__r.Project__r.Deployment_Flow__c,
                Destination_Org_Credential__r.Environment__c
            FROM Promotion__c
            WHERE Id IN :new Set<Id>{ deployment[0].Promotion__c }
        ];

        if (!promotion.isEmpty()) {
            String flowid;
            if (promotion[0].Project__c != null) {
                flowid = promotion[0].Project__r.Deployment_Flow__c;
            } else if (promotion[0].Release__c != null) {
                flowid = promotion[0].Release__r.Project__r.Deployment_Flow__c;
            }
            Map<Id, String> branchePerEnvironment = Utilities.getEnvsAndBranchesOfDeploymentFlow(flowid);

            if (branchePerEnvironment != null && branchePerEnvironment.containsKey(promotion[0].Destination_Org_Credential__r.Environment__c)) {
                return branchePerEnvironment.get(promotion[0].Destination_Org_Credential__r.Environment__c);
            }
        }
        return null;
    }

    /**
     * It is used when user click on "Save & Close" button
     * First of all, we will try to upsert destination org record
     * Deployment_Last_Step__c should be populated.
     *
     * @return
     */
    public PageReference saveAndCloseStep() {
        upsertDeployment(false);
        updateStep();
        return goToDeploymentTab();
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
        if (pageMessagesMap.isEmpty()) {
            upsertDeployment(true, true);
            updateStep();
        }
        return pageMessagesMap.isEmpty() ? goToNextStep() : null;
    }

    /**
     * It is used to find connection behaviors based on selected destnation org environment.
     * If there are connection behaviors and quality gates, user will be redirected to the regular deployment page and deployment type should be updated to the "other"
     *
     * @return
     */
    private void connectionBehaviorsCheck() {
        String connectionBehaviorId = getDestinationOrg().To_Org__r.Environment__r.Connection_Behavior__c;
        if (String.isNotBlank(connectionBehaviorId) && deployment.RecordTypeId != dataDeploymentRecordTypeId) {
            if (Schema.SObjectType.Quality_Gate__c.isAccessible() && Schema.SObjectType.Quality_Gate__c.isQueryable()) {
                qualityGateList = [SELECT Id FROM Quality_Gate__c WHERE Connection_Behavior__c = :connectionBehaviorId];
                if (!qualityGateList.isEmpty()) {
                    pageMessagesMap.put(C_INFO, new List<Object>{ Label.Connection_Behavior_Detected });
                }
            } else {
                pageMessagesMap.put(
                    C_WARNING,
                    new List<Object>{ Label.Insufficient_Access_Rights, Label.Related_Object + ' ' + Schema.SObjectType.Quality_Gate__c.getLabel() }
                );
            }
        }
    }

    /**
     * It is used to redirect user to advanced deployment page if there are connection behavior and quality gates,
     *
     * @return
     */
    public PageReference goToAdvanceDeployment() {
        try {
            updateStep();
            deployment.RecordTypeId = advancedDeploymentRecordTypeId;
            Utilities.Secure_DML(deployment, Utilities.DML_Action.UPS, schema.SObjectType.Deployment__c);
            return goToDeployment();
        } catch (Exception excp) {
            pageMessagesMap.put(C_ERROR, new List<Object>{ excp.getMessage() });
        }
        return null;
    }

    /**
     * It is used to populate override filter text values
     * Parse dataJson__c field of step and get the value from filterOverride parameter
     */
    public String getOverrideFilterText() {
        List<Step__c> steps = returnDateTemplateStep('');
        StepAttachmentDetails existingJson = new StepAttachmentDetails();
        if (!steps.isEmpty()) {
            existingJson = returnParsedValueOfDataJSONField(steps[0]);
        }
        return existingJson.filterOverride != null && existingJson.filterOverride ? Label.Yes : Label.No;
    }

    public PageReference redirectToAddTestClassRollbackPage() {
        Step__c step = getDeploymentStepRecord();
        PageReference ref = Page.AddTestClassesForRollback;
        ref.getParameters().put('Id', step.Id);
        ref.setRedirect(true);
        return ref;
    }

    private Boolean isTestClassFilePresent() {
        Step__c step = getDeploymentStepRecord();
        Map<Id, List<ContentVersion>> contentVersionsByStepId = getContentVersionsByStepId(new Set<Id>{ step.Id });
        return String.isNotBlank(getContentVersionId(step.Id, TEST_CLASSES, contentVersionsByStepId));
    }

    public PageReference redirectToDeploymentPage() {
        updateStep();
        PageReference pageRef = new PageReference('/' + deployment.id);
        return pageRef;
    }

    /**
     * It is used to populate data json field of step record
     */
    public class StepDataJson {
        public String testLevel { get; set; }
        public String[] replacements { get; set; }

        public StepDataJson(String tLevel, String[] rArray) {
            this.testLevel = tLevel;
            this.replacements = rArray;
        }
    }
}