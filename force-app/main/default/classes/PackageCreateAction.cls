@SuppressWarnings('PMD.AvoidGlobalModifier, PMD.EmptyStatementBlock')
global with sharing class PackageCreateAction implements JobExecutionCallback {
    private Request request;

    // CONSTRUCTOR

    public PackageCreateAction(Request request) {
        PackageHelper helper = new PackageHelper();
        helper.verifyUser();

        if (String.isNotBlank(request?.jsonInformation)) {
            helper.assertRequest(request.jsonInformation);
        }
        this.request = request;
    }

    public PackageCreateAction() {
        // Empty constructor needed so callback function can be called.
    }
    // GLOBAL

    @InvocableMethod(label='Package Create Action' category='Copado Action')
    global static List<Response> create(List<Request> requests) {
        if (requests.size() != 1) {
            throw new ApplicationException(Label.OnlyOneRequestAvailable);
        }

        return new List<Response>{ new PackageCreateAction(requests[0]).create() };
    }

    // This method will be executed after Package Creation.
    global void execute(JobExecution__c job, String status) {
        try {
            Request requestData = (Request) JSON.deserialize(job.DataJson__c, Request.class);
            new ActionCallback(requestData.actionCallback, job, status).run();
        } catch(Exception ex) {
            job.Status__c = JobExecutionConstants.STATUS_ERROR;
            throw new ApplicationException(ex.getMessage());
        } finally {
            sendNotification(job);
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

        result.templateName = new ActionTemplate('CreatePackage').package(pkg).getApiName();
        result.dataJson = JSON.serialize(request);
        result.pipelineId = pkg.Pipeline__c;
        result.runAfterInstantiation = true;
        result.parentId = request.packageId;
        result.callback = PackageCreateAction.class.getName();

        return CreateExecution.execute(new List<CreateExecution.Request> { result })[0];
    }

    private void publishAutomationEvent(JobExecution__c job) {
        Response response = new Response(job);
        new GenerateAutomationEvent(ActionConstants.CREATE_PACKAGE, job, JSON.serialize(response)).execute();
    }

    private void sendNotification(JobExecution__c job) {
        Set<Id> recipientIds = new Set<Id>{ UserInfo.getUserId() };
        Artifact__c pkg = new PackageHelper().getPackage(job.parentId__c);
        String packageLink = URL.getSalesforceBaseUrl().toExternalForm() + '/' + pkg.Id;
        String jobExecutionLink = URL.getSalesforceBaseUrl().toExternalForm() + '/' + job.Id;
        String notificationName = job.Status__c == 'Successful' ? 'Create_Package_Success' : 'Create_Package_Failure';

        Map<String, String> contextJson = new Map<String, String>{
            'PackageName' => pkg.Name,
            'PackageLink' => packageLink,
            'UserName' => UserInfo.getName(),
            'JobExecutionLink' => jobExecutionLink
        };

        new Notification(notificationName, recipientIds, contextJson).send();
    }

    // INNER

    global class Request {
        @InvocableVariable(label='Package Id' required='true')
        global Id packageId;

        @InvocableVariable(label='Platform related package data in JSON format')
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