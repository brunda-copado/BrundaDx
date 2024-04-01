public with sharing class ValidateRunTestsRequest {
    private RunTestsAction.Request request;
    private TestTool__mdt testTool;
    private Boolean isQgContext;
    private CategorizeTests.TestsWrapper testsWrapper;
    private Map<String, JobTemplate__c> jobTemplateByName;
    private RunTestsExecutionPayload payload;

    // CTOR

    public ValidateRunTestsRequest(RunTestsAction.Request request) {
        this.request = request;
    }

    // Note: temporary constructor for services
    public ValidateRunTestsRequest(Actions.RunTestRequest request) {
        this(getRequest(request));
    }

    // PUBLIC

    public ValidateRunTestsRequest testTool(TestTool__mdt testTool) {
        this.testTool = testTool;
        return this;
    }

    public ValidateRunTestsRequest testsWrapper(CategorizeTests.TestsWrapper testsWrapper) {
        this.testsWrapper = testsWrapper;
        return this;
    }

    public ValidateRunTestsRequest payload(RunTestsExecutionPayload payload) {
        this.payload = payload;
        return this;
    }

    public ValidateRunTestsRequest setQgContext(Boolean isQgContext) {
        this.isQgContext = isQgContext;
        return this;
    }

    public ValidateRunTestsRequest jobTemplateByName(Map<String, JobTemplate__c> jobTemplateByName) {
        this.jobTemplateByName = jobTemplateByName;
        return this;
    }

    public JobExecution__c execute() {
        JobExecution__c result = validateRequest();
        return result;
    }

    // PRIVATE

    private JobExecution__c validateRequest() {
        JobExecution__c result = validateTestTool();
        if (continueValidation(result)) {
            result = validateJobTemplate();
        }
        if (continueValidation(result)) {
            result = validateContextIds();
        }
        return prepareDataJson(result);
    }

    private JobExecution__c prepareDataJson(JobExecution__c result) {
        if (result != null) {
            result.DataJson__c = JSON.serializePretty(
                new RunTestsExecutionPayload()
                    .tests(!testsWrapper.validTests.isEmpty() ? testsWrapper.validTests : testsWrapper.ignoredTests)
                    .ignoredTests(testsWrapper.ignoredTests)
                    .callback(request.actionCallback)
                    .result(request.resultId),
                true
            );
        }

        return result;
    }

    private Boolean continueValidation(sObject result) {
        return result == null;
    }

    private JobExecution__c validateTestTool() {
        JobExecution__c result;

        if (testTool == null || (!isQgContext && !testsWrapper.ignoredTests.isEmpty() && testsWrapper.validTests.isEmpty())) {
            result = asJobExecution(null, 'Error', Label.MissingTestTool);
        }

        if (isQgContext && testTool == null) {
            updateConsolidatedResult('Failed', Label.MissingTestTool);
        }

        return result;
    }

    private JobExecution__c validateJobTemplate() {
        JobExecution__c result;
        String errorMessage = jobTemplateErrorMessage();

        if (errorMessage != null) {
            if (isQgContext) {
                updateConsolidatedResult(asConsolidatedResult(request.resultId, 'Failed', errorMessage));
            }
            result = asJobExecution(null, 'Error', errorMessage);
        }

        return result;
    }

    private String jobTemplateErrorMessage() {
        String errorMessage;

        if (String.isBlank(testTool.jobTemplate__c)) {
            errorMessage = Label.InvalidTemplateIdEmpty;
        } else if (!jobTemplateByName.containsKey(testTool.jobTemplate__c)) {
            errorMessage = String.format(Label.InvalidTemplateId, new List<String>{ testTool.jobTemplate__c });
        }

        return errorMessage;
    }

    private JobExecution__c validateContextIds() {
        JobExecution__c result;

        if (testsWrapper.validTests.isEmpty()) {
            if (isQgContext) {
                updateConsolidatedResult('Failed', Label.NoTestsFound);
            }
            String jobTemplateId = getJobTemplateId();
            result = asJobExecution(jobTemplateId, 'Error', Label.NoTestsFound);
        } else {
            if (isQgContext) {
                updateConsolidatedResult('In Progress', null);
            }
        }

        return result;
    }

    private String getJobTemplateId() {
        return jobTemplateByName.get(testTool?.jobTemplate__c)?.Id;
    }

    private JobExecution__c asJobExecution(String templateId, String status, String errorMessage) {
        JobExecution__c result = new JobExecution__c();
        result.Status__c = status;
        result.ErrorMessage__c = errorMessage;
        result.Template__c = templateId;
        result.DataJson__c = JSON.serialize(payload);
        return result;
    }

    private Result__c asConsolidatedResult(String resultId, String status, String errorMessage) {
        Result__c result = new Result__c(Id = resultId);
        result.Status__c = status;
        result.Progress_Status__c = status;
        result.Error_Message__c = errorMessage;
        return result;
    }

    private void updateConsolidatedResult(String status, String message) {
        Result__c consolidatedResult = asConsolidatedResult(request.resultId, status, message);
        consolidatedResult.Result_Data__c = JSON.serializepretty(new ResultJson(testsWrapper.ignoredTests, message), true);
        updateConsolidatedResult(consolidatedResult);
    }

    private void updateConsolidatedResult(Result__c consolidatedResult) {
        Utilities.Secure_DML(consolidatedResult, Utilities.DML_Action.UPS, schema.SObjectType.Result__c);
    }

    // Note: converting service request to existing request
    private static RunTestsAction.Request getRequest(Actions.RunTestRequest request) {
        RunTestsAction.Request result = new RunTestsAction.Request();
        result.tool = request.tool;
        result.contextIds = request.contextIds;
        result.extensionConfigurationId = request.extensionConfigurationId;
        result.actionCallback = request.actionCallback;
        result.resultId = request.resultId;
        result.acceptanceCriteria = request.acceptanceCriteria;
        result.environmentId = request.environmentId;
        return result;
    }

    private class ResultJson {
        public List<Id> ignoredTestIds;
        public String details;

        public ResultJson(List<Id> ignoredTestIds, String details) {
            this.ignoredTestIds = ignoredTestIds;
            this.details = details;
        }
    }
}