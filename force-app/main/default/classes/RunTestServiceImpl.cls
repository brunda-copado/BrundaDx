@SuppressWarnings('PMD.CyclomaticComplexity, PMD.CognitiveComplexity')
public with sharing class RunTestServiceImpl implements JobExecutionCallback {
    private static final String TEST_NOTIFICATION_PREFIX = 'Test_';
    private static final String QUALITY_GATE_NOTIFICATION_PREFIX = 'Quality_Gate_';
    private static final String BASE_URL = URL.getOrgDomainUrl().toExternalForm();

    private static final Map<String, String> RESULT_STATUS_BY_EXECUTION_STATUS = new Map<String, String>{
        JobExecutionConstants.STATUS_NOT_STARTED => ResultConstants.STATUS_NOT_STARTED,
        JobExecutionConstants.STATUS_IN_PROGRESS => ResultConstants.STATUS_IN_PROGRESS,
        JobExecutionConstants.STATUS_SUCCESSFUL => ResultConstants.STATUS_SUCCESS,
        JobExecutionConstants.STATUS_ERROR => ResultConstants.STATUS_FAILED,
        JobExecutionConstants.STATUS_CANCELLED => ResultConstants.STATUS_CANCELLED
    };

    // PUBLIC

    public static Actions.RunTestResult execute(Actions.RunTestRequest request) {
        Map<String, TestTool__mdt> testToolByLabel = initTestToolsAvailable();
        Map<String, JobTemplate__c> jobTemplateByName = getTemplatesByName(testToolByLabel.values());

        Jobs.ExecutionCreateFromTemplateRequest jobRequest;
        List<JobExecution__c> failedJobExecutions = new List<JobExecution__c>();
        List<Result__c> consolidatedResults = new List<Result__c>();

        Boolean isQgContext = isQualityGateContext(request.resultId);
        CategorizeTests.TestsWrapper testsWrapper = new CategorizeTests(request, isQgContext, testToolByLabel).execute();
        RunTestsExecutionPayload payload = payload(request, testsWrapper);
        JobExecution__c jobExecution = validateRequest(request, isQgContext, testsWrapper, testToolByLabel, jobTemplateByName, payload);

        if (validRequest(jobExecution)) {
            initConsolidatedResultStatus(request, isQgContext, consolidatedResults);
            jobRequest = prepareJobRequest(request, testToolByLabel, payload);
        } else {
            failedJobExecutions.add(jobExecution);
        }

        updateConsolidatedResults(consolidatedResults);
        return prepareResponse(jobRequest, failedJobExecutions);
    }

    public void execute(JobExecution__c execution, String status) {
        RunTestsExecutionPayload payload = (RunTestsExecutionPayload) JSON.deserialize(execution.DataJson__c, RunTestsExecutionPayload.class);

        Boolean qgContext = isQualityGateContext(payload.resultId);
        List<Result__c> results = new List<Result__c>();
        try {
            Set<Id> resultIds = qgContext
                ? new Set<Id>{ payload.resultId }
                : (payload.resultIds != null) ? new Set<Id>(payload.resultIds) : new Set<Id>();
            updateResults(resultIds, execution, status);
            results = new ResultsSelector().byIds(resultIds);
            if (qgContext && !results.isEmpty()) {
                Result__c consolidatedResult = results[0];
                // Note: this callback is set in TestJobStep.cls and it is not like any other callback that we are allowing for other actions. This is only to notify parent job execution about the completion of the sub-job execution. We should change this in the future.
                runTestStepCallback(payload.actionCallback, consolidatedResult);
            }
        } catch (Exception ex) {
            throw new ApplicationException(ex.getMessage());
        } finally {
            // Note: getting only one result record to compose email template
            if (!results.isEmpty()) {
                Result__c testResult = results[0];
                sendNotification(qgContext, testResult);
            }
        }
    }

    // PRIVATE

    private static Map<String, TestTool__mdt> initTestToolsAvailable() {
        Map<String, TestTool__mdt> testToolsAvailable = new Map<String, TestTool__mdt>();

        List<TestTool__mdt> testTools = new TestToolsSelector().getAll();
        for (TestTool__mdt testTool : testTools) {
            testToolsAvailable.put(testTool.MasterLabel, testTool);
        }
        return testToolsAvailable;
    }

    private static Map<String, JobTemplate__c> getTemplatesByName(List<TestTool__mdt> testTools) {
        Map<String, JobTemplate__c> result = new Map<String, JobTemplate__c>();
        Set<String> templateNames = new Set<String>();
        for (TestTool__mdt testTool : testTools) {
            templateNames.add(testTool.JobTemplate__c);
        }

        for (JobTemplate__c template : new JobTemplatesSelector().byApiName(templateNames)) {
            result.put(template.ApiName__c, template);
        }

        return result;
    }

    @SuppressWarnings('PMD.ExcessiveParameterList')
    private static JobExecution__c validateRequest(
        Actions.RunTestRequest request,
        Boolean isQgContext,
        CategorizeTests.TestsWrapper testsWrapper,
        Map<String, TestTool__mdt> testToolByLabel,
        Map<String, JobTemplate__c> jobTemplateByName,
        RunTestsExecutionPayload payload
    ) {
        return new ValidateRunTestsRequest(request)
            .testTool(testToolByLabel.get(request.tool))
            .testsWrapper(testsWrapper)
            .setQgContext(isQgContext)
            .payload(payload)
            .jobTemplateByName(jobTemplateByName)
            .execute();
    }

    private static Boolean isQualityGateContext(String consolidatedResultId) {
        return String.isNotBlank(consolidatedResultId);
    }

    private static Boolean validRequest(JobExecution__c result) {
        return result == null;
    }

    private static void initConsolidatedResultStatus(Actions.RunTestRequest request, Boolean isQgContext, List<Result__c> consolidatedResults) {
        if (isQgContext) {
            consolidatedResults.add(updateStatus(new Result__c(Id = request.resultId), 'In Progress'));
        }
    }

    private void updateConsolidatedResult(Id resultId, String status) {
        Result__c resultToUpdate = new Result__c(Id = resultId, Status__c = RESULT_STATUS_BY_EXECUTION_STATUS.get(status));
        DML.safeUpdate(
            resultToUpdate,
            'Could not update the Consolidated Result after executing QG Step ( RunTestServiceImpl.updateConsolidatedResult class )'
        );
    }

    private static Result__c updateStatus(Result__c result, String status) {
        result.Status__c = status;
        result.Progress_Status__c = status;
        return result;
    }

    private static void updateConsolidatedResults(List<Result__c> consolidatedResults) {
        if (!consolidatedResults.isEmpty()) {
            Utilities.Secure_DML(consolidatedResults, Utilities.DML_Action.UPS, schema.SObjectType.Result__c);
        }
    }

    private static Jobs.ExecutionCreateFromTemplateRequest prepareJobRequest(
        Actions.RunTestRequest request,
        Map<String, TestTool__mdt> testToolByLabel,
        RunTestsExecutionPayload payload
    ) {
        return asJobRequest(template(request, testToolByLabel), payload, request.transactionId);
    }

    private static String template(Actions.RunTestRequest request, Map<String, TestTool__mdt> testToolByLabel) {
        return testToolByLabel.get(request.tool)?.JobTemplate__c;
    }

    private static RunTestsExecutionPayload payload(Actions.RunTestRequest request, CategorizeTests.TestsWrapper testWrap) {
        Id qualityCheck;
        Id parentContextId;
        Id parentJobExecutionId;
        List<Id> resultIds = String.isNotBlank(request.resultId) ? new List<Id>() : new TestsResultGenerator(testWrap.validTests).execute();

        // After QG Automation Scenario
        if (String.isNotBlank(request.otherInformation)) {
            RunTestOtherInformation otherInformation = getOtherInformation(request);
            qualityCheck = otherInformation.qualityCheck;
            parentContextId = otherInformation.parentContextId;
            parentJobExecutionId = otherInformation.parentJobExecutionId;
        }

        return new RunTestsExecutionPayload()
            .tests(testWrap.validTests)
            .ignoredTests(testWrap.ignoredTests)
            .environment(request.environmentId)
            .callback(request.actionCallback)
            .result(request.resultId)
            .results(resultIds)
            .acceptanceCriteria(request.acceptanceCriteria)
            .extensionConfigurationId(request.extensionConfigurationId)
            .qualityCheck(qualityCheck)
            .parentContextId(parentContextId)
            .parentJobExecutionId(parentJobExecutionId);
    }

    private static RunTestOtherInformation getOtherInformation(Actions.RunTestRequest request) {
        return (RunTestOtherInformation) JSON.deserialize(request.otherInformation, RunTestOtherInformation.class);
    }

    private static Jobs.ExecutionCreateFromTemplateRequest asJobRequest(
        String jobTemplateName,
        RunTestsExecutionPayload payload,
        String transactionId
    ) {
        Jobs.ExecutionCreateFromTemplateRequest request = new Jobs.ExecutionCreateFromTemplateRequest();

        request.templateAPIName = jobTemplateName;
        request.callback = RunTestServiceImpl.class.getName();
        request.transactionId = transactionId;
        setParametersForNonQgContext(request, payload);
        setParametersForQgContext(request, payload);

        return request;
    }

    private static Jobs.ExecutionCreateFromTemplateRequest setParametersForQgContext(
        Jobs.ExecutionCreateFromTemplateRequest request,
        RunTestsExecutionPayload payload
    ) {
        if (payload.resultId != null) {
            Result__c jobResult = new ResultsSelector().byId(payload.resultId);
            request.sourceId = jobResult.JobStep__r.Source_Id__c;
            request.destinationId = jobResult.JobStep__r.Destination_Id__c;
            request.pipelineId = jobResult.JobStep__r.Pipeline_Id__c;
            request.dataJson = prepareCompositeJson(JSON.serialize(payload), jobResult.JobStep__r.JobExecution__r.DataJson__c);
            request.parentId = jobResult.JobStep__r.JobExecution__r.ParentId__c;
            request.steps = new List<Jobs.ExecutionStep>();
            request.parentStepId = jobResult.JobStep__c;
        }
        return request;
    }

    private static Jobs.ExecutionCreateFromTemplateRequest setParametersForNonQgContext(
        Jobs.ExecutionCreateFromTemplateRequest request,
        RunTestsExecutionPayload payload
    ) {
        if (payload.resultId == null && !payload.testIds.isEmpty()) {
            Test__c test = new TestsSelector().byIds(new Set<Id>{ payload.testIds[0] })[0];
            request.sourceId = test.User_Story__r?.Environment__c;
            request.pipelineId = getPipelineIdFrom(test);
            request.dataJson = JSON.serializePretty(payload, true);
            request.parentId = String.isNotBlank(payload.parentContextId) ? payload.parentContextId : test.Id;
            if (String.isNotBlank(payload.parentJobExecutionId)) {
                setQualityCheckParameters(request, payload);
            }
            request.steps = new List<Jobs.ExecutionStep>();
        }
        return request;
    }

    // PMD False positive, as WITH USER_MODE is not supported yet
    private static List<JobExecution__c> getParentJobExecution(String parentJobExecutionId) {
        return [
            SELECT Id, DataJson__c, Source__c, Destination__c, Pipeline__c
            FROM JobExecution__c
            WHERE Id = :parentJobExecutionId
            WITH USER_MODE
            LIMIT 1
        ];
    }

    private static void setQualityCheckParameters(Jobs.ExecutionCreateFromTemplateRequest request, RunTestsExecutionPayload payload) {
        for (JobExecution__c parentJobExecution : getParentJobExecution(payload.parentJobExecutionId)) {
            request.dataJson = prepareCompositeJson(JSON.serialize(payload), parentJobExecution.DataJson__c);
            request.sourceId = parentJobExecution.Source__c;
            request.destinationId = parentJobExecution.Destination__c;
            request.pipelineId = parentJobExecution.Pipeline__c;
        }
    }

    private static String prepareCompositeJson(String childDataJson, String parentDataJson) {
        Map<String, Object> finalPayload = (Map<String, Object>) Json.deserializeUntyped(parentDataJson);
        finalPayload.putAll((Map<String, Object>) Json.deserializeUntyped(childDataJson));

        return JSON.serializePretty(finalPayload, true);
    }

    private static String getPipelineIdFrom(Test__c test) {
        return test.User_Story__r?.Project__r?.Deployment_Flow__c != null
            ? test.User_Story__r?.Project__r?.Deployment_Flow__c
            : test.User_Story__r?.Release__r?.Project__r?.Deployment_Flow__c;
    }

    private static Actions.RunTestResult prepareResponse(
        Jobs.ExecutionCreateFromTemplateRequest jobRequest,
        List<JobExecution__c> failedJobExecutions
    ) {
        Actions.RunTestResult result = new Actions.RunTestResult();
        Map<String, List<Id>> testsByJobExecution = new Map<String, List<Id>>();

        List<JobExecution__c> jobExecutions = new List<JobExecution__c>();
        if (jobRequest != null) {
            JobExecution__c jobExecution = Jobs.Execution.createFromTemplate(jobRequest).jobExecution;
            Jobs.Execution.execute(new Jobs.ExecutionRequest(jobExecution.Id));
            jobExecutions.add(jobExecution);
        }

        failedJobExecutions = !failedJobExecutions.isEmpty() ? createJobExecutions(failedJobExecutions) : failedJobExecutions;
        jobExecutions.addAll(failedJobExecutions);

        for (JobExecution__c jobExecution : jobExecutions) {
            result.jobExecution = jobExecution;
            RunTestsExecutionPayload extractedPayload = (RunTestsExecutionPayload) JSON.deserialize(
                jobExecution.DataJson__c,
                RunTestsExecutionPayload.class
            );
            testsByJobExecution.put(jobExecution.Id, extractedPayload.testIds);
        }

        Tests.updateWithExecution(testsByJobExecution);
        if (!failedJobExecutions.isEmpty()) {
            executeQGFailedCallback(failedJobExecutions[0]);
        }
        return result;
    }

    private static void executeQGFailedCallback(JobExecution__c jobExecution) {
        RunTestsExecutionPayload extractedPayload = (RunTestsExecutionPayload) JSON.deserialize(
            jobExecution.DataJson__c,
            RunTestsExecutionPayload.class
        );
        if (String.isNotBlank(extractedPayload.resultId)) {
            new RunTestServiceImpl().execute(jobExecution, jobExecution.Status__c);
        }
    }

    private static List<JobExecution__c> createJobExecutions(List<JobExecution__c> jobExecutions) {
        DML.safeInsert(
            jobExecutions,
            'Could not create a Job Execution object on the Create Execution process ( RunTestServiceImpl.createJobExecutions class )'
        );
        return jobExecutions;
    }

    private static void updateResults(Set<Id> resultIds, JobExecution__c execution, String status) {
        List<Result__c> resultsToUpdate = new List<Result__c>();

        for (Id resultId : resultIds) {
            Result__c result = new Result__c();
            result.Id = resultId;
            result.Status__c = RESULT_STATUS_BY_EXECUTION_STATUS.get(status);
            result.Progress_Status__c = status == JobExecutionConstants.STATUS_SUCCESSFUL ? 'Completed' : 'Error';
            result.Error_Message__c = execution.ErrorMessage__c;
            resultsToUpdate.add(result);
        }

        if (!resultsToUpdate.isEmpty()) {
            DML.safeUpdate(resultsToUpdate, 'Could not update the Result after executing test ( RunTestServiceImpl.updateResult class )');
        }
    }

    private static void runTestStepCallback(String callback, Result__c consolidatedResult) {
        if (String.isNotBlank(callback)) {
            Type callbackClass = typeByName(callback);
            ((TestsStepCallback) callbackClass.newInstance()).execute(consolidatedResult.Id, consolidatedResult.Status__c);
        }
    }

    private static Type typeByName(String callback) {
        String namespace = callback.contains('.') ? callback.substringBefore('.') : '';
        String className = callback.contains('.') ? callback.substringAfter('.') : callback;

        Type result = Type.forName(namespace, className);
        if (result == null) {
            throw new ApplicationException(Label.InvalidCallback + ' ' + callback);
        }

        return result;
    }

    private static void sendNotification(Boolean qgContext, Result__c result) {
        String resultStatus = result.Status__c;
        if (resultStatus != ResultConstants.STATUS_IN_PROGRESS) {
            sendNotification(
                (qgContext ? QUALITY_GATE_NOTIFICATION_PREFIX : TEST_NOTIFICATION_PREFIX) + resultStatus,
                qgContext ? getQgContextJson(result) : getNonQgContextJson(result)
            );
        }
    }

    private static void sendNotification(String notificationName, Map<String, String> contextJson) {
        CopadoNotifications.SendRequest request = new CopadoNotifications.SendRequest();

        request.name = notificationName;
        request.recipientIds = new Set<Id>{ UserInfo.getUserId() };
        request.mergeData = contextJson;

        CopadoNotifications.send(request);
    }

    private static Map<String, String> getNonQgContextJson(Result__c result) {
        Map<String, String> contextJson = new Map<String, String>{
            'UserName' => UserInfo.getName(),
            'TestName' => result.Test__r.Name,
            'TestNameLink' => BASE_URL +
            '/' +
            result.Test__c,
            'TestResultName' => result.Name,
            'TestResultLink' => BASE_URL +
            '/' +
            result.Id
        };

        return contextJson;
    }

    private static Map<String, String> getQgContextJson(Result__c result) {
        Map<String, String> contextJson = new Map<String, String>{
            'UserName' => UserInfo.getName(),
            'QualityGateRuleName' => result.JobStep__r.Quality_Gate_Rule__r.Name,
            'QualityGateRuleJobStepLink' => BASE_URL +
            '/' +
            result.JobStep__c,
            'ParentContextName' => getParentContextName(result),
            'ParentContextLink' => BASE_URL +
            '/' +
            result.JobStep__r.JobExecution__r.ParentId__c,
            'ConsolidatedResultName' => result.Name,
            'ConsolidatedResultLink' => BASE_URL +
            '/' +
            result.Id
        };

        return contextJson;
    }

    private static String getParentContextName(Result__c result) {
        String parentContextName = '';

        if (result.JobStep__r.JobExecution__r.context__c != null) {
            parentContextName = result.JobStep__r.JobExecution__r.context__c.substringAfter('>');
            parentContextName = parentContextName.substringBefore('<');
        }

        return parentContextName;
    }
}