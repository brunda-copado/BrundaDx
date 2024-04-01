@SuppressWarnings('PMD.AvoidGlobalModifier')
global with sharing class RunTestsAction implements JobExecutionCallback {
    // GLOBAL

    @InvocableMethod(
        label='Run a List of Copado Tests'
        description='Extracts and Runs a list of Copado Tests of a specific type'
        category='Copado Test'
    )
    global static List<Response> execute(List<Request> requests) {
        Actions.RunTestRequest runTestRequest = convertRequests(requests);
        Actions.RunTestResult runTestResult = Actions.RunTestService.execute(runTestRequest);
        return convertResult(runTestResult);
    }

    // Note: Job Execution Callback, called only after the job finishes
    global void execute(JobExecution__c execution, String status) {
        new RunTestServiceImpl().execute(execution, status);
    }

    // PRIVATE

    private static Actions.RunTestRequest convertRequests(List<Request> requests) {
        if (requests.size() != 1) {
            throw new ApplicationException(Label.OnlyOneRequestAvailable);
        }
        Request request = requests[0];

        Actions.RunTestRequest result = new Actions.RunTestRequest();
        result.tool = request.tool;
        result.contextIds = request.contextIds;
        result.extensionConfigurationId = request.extensionConfigurationId;
        result.resultId = request.resultId;
        result.acceptanceCriteria = request.acceptanceCriteria;
        result.environmentId = request.environmentId;
        result.transactionId = request.transactionId;
        result.actionCallback = request.actionCallback;
        return result;
    }

    private static List<Response> convertResult(Actions.RunTestResult runTestResult) {
        return new List<Response>{ new Response(runTestResult.jobExecution) };
    }

    // GLOBAL INNER CLASSES

    global with sharing class Request {
        // MANDATORY PARAMETERS

        @InvocableVariable(
            label='Test Tool'
            description='Master label of the Test Tool custom metadata type record that applies to all Test\'s Tool Configurations.'
            required=true
        )
        global String tool;

        @InvocableVariable(
            label='Context Ids'
            description='List of Salesforce Record Ids that contain Tests. It might be multiple test records, user stories, features or applications.'
            required=true
        )
        global List<Id> contextIds;

        // OPTIONAL PARAMETERS

        @InvocableVariable(
            label='Extension Configuration'
            description='By providing a Extension Configuration, it will override the Extension Configuration related to the tests in contexts for its execution.'
            required=false
        )
        global String extensionConfigurationId;

        @InvocableVariable(
            label='Action Callback'
            description='Apex Callback Class that implements TestsStepCallback, invoked after job execution completion. Its functional purpose is to inject post-execution logic needed by the action consumer.'
            required=false
        )
        global String actionCallback;

        @InvocableVariable(
            label='Consolidated Result Id'
            description='Id of an existing consolidated result, to be updated with the overall test execution status. If provided, test independent results will not be generated.'
            required=false
        )
        global String resultId;

        @InvocableVariable(
            label='Acceptance Criteria'
            description='JSON formatted properties that will be applied to compute each test result. If provided, will override the acceptance criteria defined at the test record level.'
            required=false
        )
        global String acceptanceCriteria;

        @InvocableVariable(
            label='Environment Id'
            description='The Identifier (Salesforce Record Id, URL, URI, ApiName, Git branch, etc) of the “Environment” to run the tests in.'
            required=false
        )
        global String environmentId;

        @InvocableVariable(
            label='Transaction Id'
            description='Contains the transaction Id to be used in case the volume needs to be preserved across job executions.'
            required=false
        )
        public String transactionId;

        // DEPRECATED PARAMETERS

        @InvocableVariable(
            label='Deprecated - Test Type'
            description='Deprecated - Master label of the Test Type custom metadata type record that applies to all Tests contained in contextIds.'
            required=false
        )
        global String type;

        @InvocableVariable(
            label='Deprecated - Properties Override'
            description='Deprecated - JSON String overriding properties with different values. For instance, allows Quality Gates to use stricter values e.g. Code Coverage on Unit Test runs.'
            required=false
        )
        global String propertiesOverride;

        @InvocableVariable(
            label='Deprecated - Create Consolidated Result'
            description='Specifies if consolidated result has to be created for Job Execution, by default it is true'
            required=false
        )
        global Boolean createConsolidatedResult = true;

        // BUILDER METHODS

        global Request extensionConfigurationId(String id) {
            extensionConfigurationId = id;
            return this;
        }

        global Request tool(String testTool) {
            tool = testTool;
            return this;
        }

        global Request context(List<Id> ids) {
            contextIds = ids;
            return this;
        }

        global Request environment(String id) {
            environmentId = id;
            return this;
        }

        global Request actionCallback(String className) {
            actionCallback = className;
            return this;
        }

        global Request result(Id resultId) {
            this.resultId = resultId;
            return this;
        }

        global Request acceptanceCriteria(String json) {
            this.acceptanceCriteria = json;
            return this;
        }

        global Request type(String testType) {
            type = testType;
            return this;
        }

        global Request propertiesOverride(String json) {
            propertiesOverride = json;
            return this;
        }

        global Request createConsolidatedResult(Boolean createConsolidatedResult) {
            this.createConsolidatedResult = createConsolidatedResult;
            return this;
        }
    }

    global with sharing class Response {
        @InvocableVariable(label='Job Execution' description='Job Execution record for the Run Test Action')
        global JobExecution__c jobExecution;

        // CTOR

        public Response(JobExecution__c jobExecution) {
            this.jobExecution = jobExecution;
        }
    }
}