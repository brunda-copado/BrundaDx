@SuppressWarnings('PMD.CyclomaticComplexity,PMD.ExcessivePublicCount')
public with sharing class StepTriggerHelper {
    private static final String SPECIFIC_ENVIRONMENTS_IN_PIPELINE = 'Specific Environments in Pipeline';
    private static final String ALL_ENVIRONMENTS_IN_PIPELINE = 'All Environments in Pipeline';
    private static final String NAMESPACE = Settings.ns;
    private static final Set<String> DEPLOYMENT_TASK_TYPES = new Set<String> {
        'Manual Task',
        'Data',
        'Bulk Data',
        'Data Template',
        'Delete Metadata',
        'Custom Settings',
        'Apex',
        'URL Callout',
        'Salesforce Flow'
    };
    public static Boolean isManualTaskNotified = false;
    public static ManualTaskSkipDecisionVariables manualTaskVars;
    private List<Step__c> steps;
    private static Deployment_Job__c depJobItem;
    static Map<Id, Set<Id>> pipelineEnvironments;

    public static void getPipelineEnvironmentMap(Set<Id> pipelineIds){ 
        Map<Id, Set<Id>> pipelineEnvironmentMap = new Map<Id, Set<Id>>();
        Map<Id, List<Deployment_Flow_Step__c>> pipelineMapById = new DeploymentFlowStepsSelector().byPipeline(pipelineIds);
        for (Id pipeline : pipelineIds) {
            pipelineEnvironmentMap = prepareMap(pipelineMapById, pipelineEnvironmentMap, pipeline);
        }
        pipelineEnvironments = pipelineEnvironmentMap;
    }

    private static Map<Id, Set<Id>> prepareMap(Map<Id, List<Deployment_Flow_Step__c>> pipelineMapById, Map<Id, Set<Id>> pipelineEnvironmentMap, Id pipeline) {
        Map<Id, Set<Id>> result = pipelineEnvironmentMap;
        if (pipelineMapById.get(pipeline) != null) {
            for (Deployment_Flow_Step__c pipelineConnection : pipelineMapById.get(pipeline)) {
                if (!result.containsKey(pipeline)) {
                    result.put(pipeline, new Set<Id>());
                }
                result.get(pipeline).add(pipelineConnection.Source_Environment__c);
                result.get(pipeline).add(pipelineConnection.Destination_Environment__c);
            }
        }
        return result;
    }

    // CONSTRUCTOR

    public StepTriggerHelper(List<Step__c> steps) {
        this.steps = steps;
    }

    // PUBLIC

    public void notifyManualStepOwner() {
        for(Step__c step : steps) {
            if (isManualTaskInProgress(step)) {
                notifyTaskOwner(step);
            }
        }
    }

    public void validate() {
        checkFeature();
        // Note: Skip license check for Automated process
        if (UserInfo.getUserType() != 'AutomatedProcess') {
            checkLicense();
        }
    }

    public void afterInsert() {
        DeployJobHelper.upsertDeployJobs( getDeployments() );
        commitSteps(
            arrangeOrders(
                getAllSteps()
            )
        );
    }

    private List<Step__c> getAllSteps() {
        Set<Id> deploymentIds = new Set<Id>();
        for (Step__c step : steps) {
            if(DEPLOYMENT_TASK_TYPES.contains(step.Type__c)){
                deploymentIds.add(step.Deployment__c);
            }
        }
        return [SELECT Id, Order__c, Deployment__c FROM Step__c WHERE Deployment__c IN : deploymentIds WITH SECURITY_ENFORCED ORDER BY Order__c ASC];
    }

    private List<Step__c> arrangeOrders(List<Step__c> stepsParam){
        Map<Id, List<Step__c>> orderedStepsByDeploymentIds = new Map<Id, List<Step__c>>();
        for(Step__c step : stepsParam){
            if(orderedStepsByDeploymentIds.containsKey(step.Deployment__c)){
                step.Order__c = orderedStepsByDeploymentIds.get(step.Deployment__c).size() + 1;
            } else {
                step.Order__c = 1;
                orderedStepsByDeploymentIds.put(step.Deployment__c, new List<Step__c>());
            }
            orderedStepsByDeploymentIds.get(step.Deployment__c).add(step); 
        }
        return convertListOfListToList(
            orderedStepsByDeploymentIds.values()
        );
    }

    private List<Step__c> convertListOfListToList(List<List<Step__c>> stepsList){
        List<Step__c> returnList = new List<Step__c>();
        for(List<Step__c> steps : stepsList){
            returnList.addAll(steps);
        }
        return returnList;
    }

    private void commitSteps(List<Step__c> stepsParam){
        Utilities.Secure_DML(stepsParam, Utilities.DML_Action.UPD, schema.SObjectType.Step__c);
    }

    // PRIVATE

    private Boolean isManualTaskInProgress(Step__c step) {
        return (
            step.Status__c == 'In Progress' &&
            step.Type__c == 'Manual Task' &&
            !step.Manual_Task_Notified__c
        );
    }

    private List<Deployment__c> getDeployments() {
        List<Deployment__c> result = new List<Deployment__c>();

        for (Step__c step : steps) {
            result.add(new Deployment__c(Id = step.Deployment__c));
        }
        return result;
    }


    private void checkFeature() {
        for (Step__c step : steps) {
            String feature = step.Type__c + ' step';
            Feature__c featureRecord = Feature__c.getValues(feature);

            if (featureRecord != null && !featureRecord.Enabled__c) {
                step.addError(Label.STEP_NOT_SUPPORTED);
            }
        }
    }

    private void checkLicense() {
        Boolean isLicensesExceeded = LicenseHelper.isLicensesExceeded();
        Boolean isCopadoEnabled = LicenseHelper.isCopadoEnabled();
        Boolean isCCMEnabled = LicenseHelper.isCCMEnabled();

        for (Step__c step : steps) {
            if (isLicensesExceeded) {
                step.addError(Label.LICENSES_EXCEEDED);
            }
            else if (!isCopadoEnabled && !isCCMEnabled) {
                step.addError(Label.COPADO_DEPLOYER_LICENSE_NOT_ENABLED);
            }
        }
    }

    private static void getDeploymentJob(Id stepId){
        List<Deployment_Job__c> jobs = [SELECT Id, Status__c, Step__r.dataJson__c, Pipeline_Id__c, Destination_Org__r.To_Org__r.Environment__c, Step__r.Deployment__r.Promotion__r.Back_Promotion__c FROM Deployment_Job__c WHERE Step__c = : stepId WITH SECURITY_ENFORCED ORDER BY CreatedDate DESC LIMIT 1];
        if(!jobs.isEmpty()){
            depJobItem = jobs[0];
            getPipelineEnvironmentMap(new Set<Id>{depJobItem.Pipeline_Id__c});
        }
    }

    private static void notifyTaskOwner(Step__c step) {
        getDeploymentJob(step.Id);
        if(null != depJobItem){
            manualTaskVars = new ManualTaskSkipDecisionVariables(depJobItem);
            if(!manualTaskVars.shouldAutocloseTask){
                step.Manual_Task_Notified__c = true;
                isManualTaskNotified = true;
                notificationDecider(step);
            }
        }
    }

    private static void notificationDecider(Step__c step){
        ManualTaskJSONdata taskData = (ManualTaskJSONdata) JSON.deserialize(step.dataJson__c, ManualTaskJSONdata.class);
        String chatterMessage = ' ' + System.Label.MANUAL_TASK_WAITING + ' ' + step.Name;

        // TODO: Bulkify send email part
        if (String.isEmpty(taskData.Task_Owner)) {
            return;
        }

        if ((taskData.Notify_Task_Owner == 'Chatter' || taskData.Notify_Task_Owner == 'Chatter and Email') &&
            Utilities.isChatterEnabled(NAMESPACE + 'Deployment__c')) {
            Utilities.notifyUsingChatterWithAtMention(taskData.Task_Owner, chatterMessage, step.Deployment__c);
        }

        if (taskData.Notify_Task_Owner == 'Email' || taskData.Notify_Task_Owner == 'Chatter and Email') {
            notifyUsingEmail(taskData.Task_Owner, step.Name, step.Deployment__c);
        }
    }

    // Note: User is a special object and non-admin users will not have access to it
    @SuppressWarnings('PMD.ApexCRUDViolation')
    private static void notifyUsingEmail(String userId, String stepName, Id deploymentId) {
        User ownerOfTask = [SELECT Email FROM User WHERE Id = :userId LIMIT 1];

        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        message.toAddresses = new List<String>{ ownerOfTask.Email };
        String htmlBody = System.Label.MANUAL_TASK_WAITING + ' ' + stepName + '<br/>';
        htmlBody += 'Deployment link: ' + Url.getSalesforceBaseUrl().toExternalForm() + '/' + deploymentId;
        message.setHtmlBody(htmlBody);
        message.setSubject(System.Label.MANUAL_TASK_WAITING + ' ' + stepName);
        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ message });
    }

    // INNER

    // Note: needs to look exactly like the API JSON
    @SuppressWarnings('PMD.PropertyNamingConventions')
    private class ManualTaskJSONdata {
        public Boolean Perform_in_Destination_Org { get; set; }
        public Boolean Perform_in_Source_Org { get; set; }
        public String Task_Description { get; set; }
        public String Task_Owner { get; set; }
        public String Notify_Task_Owner { get; set; }
        //public String[] Selected_Environments { get; set; }
    }

    public class ManualTaskSkipDecisionVariables {
        public Boolean shouldAutocloseTask = false;
        public ManualTaskSkipDecisionVariables(Deployment_Job__c depJobItem){
            Map<String, Object> valuesByParameters = (Map<String, Object>) JSON.deserializeUntyped(depJobItem.step__r.dataJson__c);
            if (valuesByParameters.containsKey('Apply_to') && null != pipelineEnvironments) {
                String applyTo = (String) valuesByParameters.get('Apply_to');
                Boolean isSpecificEnvironment = String.isNotBlank(applyTo) && applyTo == SPECIFIC_ENVIRONMENTS_IN_PIPELINE;
                List<Object> selectedEnvironmentIds = (List<Object>) valuesByParameters.get('Selected_Environments');
                Boolean isJobDestinationSelected = isSpecificEnvironment
                    ? selectedEnvironmentIds.contains(depJobItem.Destination_Org__r.To_Org__r.Environment__c)
                    : (pipelineEnvironments.get(depJobItem.Pipeline_Id__c) != null &&
                    pipelineEnvironments.get(depJobItem.Pipeline_Id__c).contains(depJobItem.Destination_Org__r.To_Org__r.Environment__c));
                Boolean isBackPromotionDisabled = (Boolean) valuesByParameters.get('Disable_Task_for_Back_Promotions');
                Boolean isBackPromotionDeployment = depJobItem.Step__r.Deployment__r.Promotion__r.Back_Promotion__c;
                this.shouldAutocloseTask = (!isJobDestinationSelected || (isBackPromotionDeployment && isBackPromotionDisabled));
            }
        }
    }
}