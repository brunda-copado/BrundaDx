@SuppressWarnings('PMD.AvoidGlobalModifier')
global with sharing class PackageImportAction implements JobExecutionCallback {
    private Request request;
    private final static String PACKAGE_VERSION_DETAILS_FILENAME = 'PackageAndVersions.json';

    // CTOR

    // Note: needed for JobExecutionCallback instantiation
    @SuppressWarnings('PMD.EmptyStatementBlock')
    public PackageImportAction() {
    }

    public PackageImportAction(Request request) {
        verifyUser();
        validateRequest(request);
        this.request = request;
    }

    // GLOBAL

    @InvocableMethod(label='Package Import Action' category='Copado Action')
    global static List<Response> import(List<Request> requests) {
        if (requests?.size() != 1) {
            throw new ApplicationException(Label.OnlyOneRequestAvailable);
        }

        Response response = new PackageImportAction(requests[0]).import();

        return new List<Response>{ response };
    }

    // PUBLIC

    public Response import() {
        Deployment_Flow__c pipeline = getPipeline(request.pipelineId);

        JobExecution__c job = startJobExecution(pipeline);

        return new Response(job);
    }

    public void execute(JobExecution__c job, String status) {
        Artifact__c packageRecord;
        try {
            ResultPayload resultData = parseResultData(getResultData(job.Id));
            packageRecord = resultData.packageRecord;
            List<Artifact_Version__c> packageVersions = resultData.packageVersions;

            DML.safeUpsert(
                packageRecord,
                'Could not upsert the Package record from the Result payload on Package Import Action ( PackageImportAction.execute class )'
            );
            if (packageVersions != null) {
                upsertPackageVersions(packageVersions, packageRecord?.Id);
            }

            Request requestData = (Request) JSON.deserialize(job.DataJson__c, Request.class);
            new ActionCallback(requestData.actionCallback, job, status).run();
        } catch (Exception ex) {
            job.Status__c = JobExecutionConstants.STATUS_ERROR;
            throw new ApplicationException(ex.getMessage());
        } finally {
            sendNotification(job, packageRecord);
            publishAutomationEvent(job);
        }
    }

    // PRIVATE

    private void sendNotification(JobExecution__c job, Artifact__c packageRecord) {
        Set<Id> recipientIds = new Set<Id>{ UserInfo.getUserId() };
        String jobExecutionLink = URL.getSalesforceBaseUrl().toExternalForm() + '/' + job.Id;
        String packageLink = URL.getSalesforceBaseUrl().toExternalForm() + '/' + packageRecord?.Id;
        String notificationName = job.Status__c == 'Successful' ? 'Import_Package_Success' : 'Import_Package_Failure';

        Map<String, String> contextJson = new Map<String, String>{
            'PackageName' => packageRecord?.Name,
            'UserName' => UserInfo.getName(),
            'PackageLink' => packageLink,
            'JobExecutionLink' => jobExecutionLink
        };

        new Notification(notificationName, recipientIds, contextJson).send();
    }

    private Deployment_Flow__c getPipeline(Id pipelineId) {
        List<Deployment_Flow__c> pipeline = new PipelineSelector().byId(new Set<Id>{ pipelineId });

        if (pipeline.isEmpty()) {
            throw new ApplicationException(Label.InvalidPipelineId);
        }

        if (String.isBlank(pipeline[0].Git_Repository__c)) {
            throw new ApplicationException(Label.NoGitRepoLinked);
        }

        return pipeline.get(0);
    }

    private JobExecution__c startJobExecution(Deployment_Flow__c pipeline) {
        CreateExecution.Request executionRequest = new CreateExecution.Request();

        executionRequest.templateName = new ActionTemplate('ImportPackage').pipeline(pipeline).getApiName();
        executionRequest.dataJson = JSON.serialize(request);
        executionRequest.pipelineId = request.pipelineId;
        executionRequest.runAfterInstantiation = true;
        executionRequest.callback = PackageImportAction.class.getName();

        return CreateExecution.execute(new List<CreateExecution.Request>{ executionRequest })[0];
    }

    private void verifyUser() {
        if (!Copado_License__c.getInstance().Enable_Copado__c) {
            throw new ApplicationException(Label.LicensesNotAssigned);
        }

        if (!Test.isRunningTest() && !FeatureManagement.checkPermission('Enable_Package_Import')) {
            throw new ApplicationException(Label.InsufficientPermissions);
        }
    }

    private void validateRequest(Request request) {
        if (String.isNotBlank(request.jsonInformation)) {
            try {
                JSON.deserializeUntyped(request.jsonInformation);
            } catch (JSONException ex) {
                throw new ApplicationException(Label.ERROR_PARSING_JSON + ' ' + ex.getMessage());
            }
        }
    }

    private String getResultData(Id jobExecutionId) {
        // Note: this assumes that the last JobStep of the JobExecution contains the Result with the expected data. This may vary according to the JobTemplate used (and therefore according to the implementation of each MC extension)
        Result__c jobResult = new ResultsSelector().byJobExecutionId(jobExecutionId);

        // Note: Checking if we've any content document linked to last step result record. If we've, read package and version details from that linked document(named as PackageAndVersions.json) else read from result data.
        List<ContentDocumentLink> packageVersionFileDetails = getContentDocumentLink(jobResult.Id);
        String data = jobResult.Result_Data__c;

        if (!packageVersionFileDetails.isEmpty()) {
            List<ContentVersion> contentVersions = new ContentVersionsSelector()
                .byContentDocumentIdWithLatest(new Set<Id>{ packageVersionFileDetails[0].ContentDocumentId });
            if (!contentVersions.isEmpty()) {
                // We can only read file of size upto 4.3 MB in Apex
                data = contentVersions[0]?.VersionData?.toString();
            }
        }

        return data;
    }

    @SuppressWarnings('PMD.EmptyCatchBlock')
    private ResultPayload parseResultData(String resultDataRaw) {
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

    private static List<ContentDocumentLink> getContentDocumentLink(Id recordId) {
        return new ContentDocumentLinksSelector()
            .byLinkedEntityIdAndTitles(new Set<Id>{ recordId }, new Set<String>{ PACKAGE_VERSION_DETAILS_FILENAME });
    }

    private void upsertPackageVersions(List<Artifact_Version__c> packageVersions, Id packageId) {
        // Note: can not use DML.safeUpsert directly as Artifact__c is master-detail of Artifact_Version__c and access type is not upsertable
        List<Artifact_Version__c> versionsToInsert = new List<Artifact_Version__c>();
        List<Artifact_Version__c> versionsToUpdate = new List<Artifact_Version__c>();
        for (Artifact_Version__c packageVersion : packageVersions) {
            if (packageVersion.Id != null) {
                versionsToUpdate.add(packageVersion);
            } else {
                packageVersion.Artifact__c = packageId;
                versionsToInsert.add(packageVersion);
            }
        }
        DML.safeInsert(
            versionsToInsert,
            'Could not insert the Package Version records from the Result payload on Package Import Action ( PackageImportAction.execute class )'
        );
        DML.safeUpdate(
            versionsToUpdate,
            'Could not update the Package Version records from the Result payload on Package Import Action ( PackageImportAction.execute class )'
        );
    }

    private void publishAutomationEvent(JobExecution__c job) {
        Response response = new Response(job);
        new GenerateAutomationEvent(ActionConstants.IMPORT_PACKAGE, job, JSON.serialize(response)).execute();
    }

    // INNER

    global class Request {
        @InvocableVariable(required=true label='Package Name or Id')
        global String packageNameOrId;

        @InvocableVariable(required=true label='Pipeline Id')
        global Id pipelineId;

        @InvocableVariable(label='Platform related arguments in JSON format')
        global String jsonInformation;

        @InvocableVariable(label='Action Callback' description='Apex Callback Class that implements JobExecutionCallback')
        global String actionCallback;

        global Request(String packageNameOrId, String pipelineId, String jsonInformation) {
            this.packageNameOrId = packageNameOrId;
            this.pipelineId = pipelineId;
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

    @TestVisible
    private with sharing class ResultPayload {
        @TestVisible
        private Artifact__c packageRecord;
        @TestVisible
        private List<Artifact_Version__c> packageVersions;
    }
}