@SuppressWarnings('PMD.AvoidGlobalModifier, PMD.EmptyStatementBlock')
global with sharing class PackageVersionCreateAction implements JobExecutionCallback {
    private Request request;

    // CONSTRUCTOR

    public PackageVersionCreateAction(Request request) {
        PackageHelper helper = new PackageHelper();
        helper.verifyUser();

        if (String.isNotBlank(request.jsonInformation)) {
            helper.assertRequest(request.jsonInformation);
        }
        this.request = request;
    }

    public PackageVersionCreateAction() {
        // Empty constructor needed so callback function can be called.
    }

    // GLOBAL

    @InvocableMethod(label='Package Version Create Action' category='Copado Action')
    global static List<Response> create(List<Request> requests) {
        if (requests.size() != 1) {
            throw new ApplicationException(Label.OnlyOneRequestAvailable);
        }

        return new List<Response>{ new PackageVersionCreateAction(requests[0]).create() };
    }

    // Job Callback, called only after the job finishes
    global void execute(JobExecution__c job, String status) {
        Artifact_Version__c version;

        try {
            Result__c result = new ResultsSelector().byJobExecutionId(job.Id);
            version = upsertVersion(result.Result_Data__c);
            updateLatestVersionOnPackage(version);

            Request requestData = (Request) JSON.deserialize(job.DataJson__c, Request.class);
            new ActionCallback(requestData.actionCallback, job, status).run();
        } catch (Exception ex) {
            job.Status__c = JobExecutionConstants.STATUS_ERROR;
            throw new ApplicationException(ex.getMessage());
        } finally {
            sendNotification(job, version);
            publishAutomationEvent(job);
        }
    }

    // PUBLIC

    public Response create() {
        Artifact__c pkg = new PackageHelper().getPackage(request.packageId);

        return new Response(startJobExecution(pkg));
    }

    // PRIVATE

    private JobExecution__c startJobExecution(Artifact__c pkg) {
        CreateExecution.Request result = new CreateExecution.Request();

        result.templateName = new ActionTemplate('CreatePackageVersion').package(pkg).getApiName();
        result.dataJson = JSON.serialize(request);
        result.pipelineId = pkg.Pipeline__c;
        result.parentId = pkg.Id;
        result.runAfterInstantiation = true;
        result.callback = PackageVersionCreateAction.class.getName();

        return CreateExecution.execute(new List<CreateExecution.Request> { result })[0];
    }

    private Artifact_Version__c upsertVersion(String resultDataRaw){
        Artifact_Version__c version = (Artifact_Version__c) JSON.deserialize(
            resultDataRaw,
            Artifact_Version__c.class
        );

        Utilities.Secure_DML(version, Utilities.DML_Action.UPS, Schema.SObjectType.Artifact_Version__c);
        return version;
    }

    private void updateLatestVersionOnPackage(Artifact_Version__c version) {
        List<Artifact_Version__c> versions = new ArtifactVersionsSelector().byIds(new Set<Id>{ version.Id });

        update Security.stripInaccessible(
                AccessType.UPDATABLE,
                new List<Artifact__c>{ new Artifact__c(Id = versions[0]?.Artifact__c, Artifact_Version__c = version.Id) }
            )
            .getRecords();
    }

    private void publishAutomationEvent(JobExecution__c job) {
        Response response = new Response(job);
        new GenerateAutomationEvent(ActionConstants.CREATE_PACKAGE_VERSION, job, JSON.serialize(response)).execute();
    }

    private void sendNotification(JobExecution__c job, Artifact_Version__c version) {
        Set<Id> recipientIds = new Set<Id>{ UserInfo.getUserId() };
        Artifact__c pkg = new PackageHelper().getPackage(job.parentId__c);
        String jobExecutionLink = URL.getSalesforceBaseUrl().toExternalForm() + '/' + job.Id;
        String packageVersionLink = URL.getSalesforceBaseUrl().toExternalForm() + '/' + version?.Id;
        String notificationName = job.Status__c == 'Successful' ? 'Generate_Package_Version_Success' : 'Generate_Package_Version_Failure';

        Map<String, String> contextJson = new Map<String, String>{
            'PackageName' => pkg.Name,
            'UserName' => UserInfo.getName(),
            'PackageVersionName' => version?.Name,
            'JobExecutionLink' => jobExecutionLink,
            'PackageVersionLink' => packageVersionLink
        };

        new Notification(notificationName, recipientIds, contextJson).send();
    }

    // INNER

    global class Request {
        @InvocableVariable(label='Package Id')
        global Id packageId;

        @InvocableVariable(label='Version Name')
        global String versionName;

        @InvocableVariable(label='Version Number')
        global String versionNumber;

        @InvocableVariable(label='Description')
        global String description;

        @InvocableVariable(label='Platform related Version data JSON format')
        global String jsonInformation;

        @InvocableVariable(label='Action Callback' description='Apex Callback Class that implements JobExecutionCallback')
        global String actionCallback;

        global Request(Id packageId, String jsonInformation) {
            this.packageId = packageId;
            this.jsonInformation = jsonInformation;
        }
    }

    global class Response {
        @InvocableVariable
        global JobExecution__c job;

        public Response(JobExecution__c job) {
            this.job = job;
        }
    }
}