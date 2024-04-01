@SuppressWarnings('PMD.AvoidGlobalModifier, PMD.EmptyStatementBlock')
global with sharing class PackageVersionPublishAction implements JobExecutionCallback {
    private Request request;

    // CTOR

    public PackageVersionPublishAction(Request request) {
        verifyUser();
        this.request = request;
    }

    public PackageVersionPublishAction() {
        // Empty constructor needed so callback function can be called.
    }

    // GLOBAL

    @InvocableMethod(label='Package Version Publish Action' category='Copado Action')
    global static List<Response> publish(List<Request> requests) {
        if (requests.size() != 1) {
            throw new ApplicationException(Label.OnlyOneRequestAvailable);
        }

        return new List<Response>{ new PackageVersionPublishAction(requests[0]).publish() };
    }

    // Job Callback, called only after the job finishes
    global void execute(JobExecution__c job, String status) {
        Artifact_Version__c version;
        try {
            Request requestData = (Request) JSON.deserialize(job.DataJson__c, Request.class);
            List<Artifact_Version__c> versions = new ArtifactVersionsSelector()
                .byIds(new Set<Id>{ requestData.packageVersionId });

            versions[0].Is_released__c = status == JobExecutionConstants.STATUS_SUCCESSFUL;
            update Security.stripInaccessible(AccessType.UPDATABLE, versions).getRecords();
            version = versions[0];
            
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

    private void sendNotification(JobExecution__c job, Artifact_Version__c version) {
        Set<Id> recipientIds = new Set<Id>{ UserInfo.getUserId() };
        String versionLink = URL.getSalesforceBaseUrl().toExternalForm() + '/' + version?.Id;
        String jobExecutionLink = URL.getSalesforceBaseUrl().toExternalForm() + '/' + job.Id;
        Id artifactId = version?.Artifact__c;
        Artifact__c packageRecord;

        if(artifactId != null) {
            packageRecord = [SELECT Name FROM Artifact__c WHERE Id = :artifactId WITH SECURITY_ENFORCED];
        }
        String packageLink = URL.getSalesforceBaseUrl().toExternalForm() + '/' + packageRecord?.Id;
        String notificationName = job.Status__c == 'Successful' ? 'Publish_Package_Success' : 'Publish_Package_Failure';

        Map<String, String> contextJson = new Map<String, String>{
            'PackageLink' => packageLink,
            'UserName' => UserInfo.getName(),
            'PackageVersionLink' => versionLink,
            'PackageName' => packageRecord?.Name,
            'PackageVersionName' => version?.Name,
            'JobExecutionLink' => jobExecutionLink
        };

        new Notification(notificationName, recipientIds, contextJson).send();
    }

    public Response publish() {
        JobExecution__c job = startJobExecution(getPackageVersion());

        return new Response(job);
    }

    // PRIVATE

    private Artifact_Version__c getPackageVersion() {
        List<Artifact_Version__c> version = new ArtifactVersionsSelector()
            .byIds(new Set<Id>{ request.packageVersionId });

        if (version.isEmpty()) {
            throw new ApplicationException(Label.InvalidPackageVersionId);
        }

        if (String.isBlank(version.get(0).Artifact__r.Pipeline__c)) {
            throw new ApplicationException(Label.NoPipelineLinkedToPackage);
        }

        return version.get(0);
    }

    private JobExecution__c startJobExecution(Artifact_Version__c version) {
        CreateExecution.Request executionRequest = new CreateExecution.Request();

        executionRequest.templateName = new ActionTemplate('PublishPackageVersion').package(version.Artifact__r).getApiName();
        executionRequest.dataJson = JSON.serialize(request);
        executionRequest.pipelineId = version.Artifact__r.Pipeline__c;
        executionRequest.runAfterInstantiation = true;
        executionRequest.callback = PackageVersionPublishAction.class.getName();

        return CreateExecution.execute(new List<CreateExecution.Request> { executionRequest })[0];
    }

    private void verifyUser() {
        if (!Copado_License__c.getInstance().Enable_Copado__c) {
            throw new ApplicationException(Label.LicensesNotAssigned);
        }

        if (!Test.isRunningTest() && !FeatureManagement.checkPermission('Enable_Package_Publish')) {
            throw new ApplicationException(Label.InsufficientPermissions);
        }
    }

    private void publishAutomationEvent(JobExecution__c job) {
        Response response = new Response(job);
        new GenerateAutomationEvent(ActionConstants.PUBLISH_PACKAGE_VERSION, job, JSON.serialize(response)).execute();
    }

    // INNER

    global with sharing class Request {
        @InvocableVariable(required=true label='Package Version Id')
        global Id packageVersionId;

        @InvocableVariable(label='Action Callback' description='Apex Callback Class that implements JobExecutionCallback')
        global String actionCallback;

        global Request(Id packageVersionId) {
            this.packageVersionId = packageVersionId;
        }
    }

    global with sharing class Response {
        @InvocableVariable
        global JobExecution__c job;

        public Response(JobExecution__c job) {
            this.job = job;
        }
    }
}