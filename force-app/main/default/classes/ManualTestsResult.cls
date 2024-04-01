public with sharing class ManualTestsResult {
    private Id testId;
    private Result__c result;
    private Map<Id, String> statusPerTestRun;

    private static final String MANUAL_TESTS = 'Manual Tests';
    private static final String RESULT_IN_PROGRESS = 'In Progress';
    private static final String FAILED = 'Failed';

    //CTOR

    public ManualTestsResult(Id testId, Result__c result) {
        this.testId = testId;
        this.result = result;
    }

    //PUBLIC

    public ManualTestsResult statusPerTestRun(Map<Id, String> statusPerTestRun) {
        this.statusPerTestRun = statusPerTestRun;
        return this;
    }

    public Result__c upsertResult(String status) {
        result = result == null ? new ResultsSelector().getLatestResultByTestId(testId) : result;

        if (String.isBlank(status)) {
            prepareResult();
        } else {
            prepareResultWith(status);
        }
        result = upsertResult();
        return result;
    }

    //PRIVATE

    private void prepareResult() {
        if (result != null && result.Status__c == RESULT_IN_PROGRESS) {
            if (statusPerTestRun.values().contains(FAILED)) {
                result = asResult(result.Id, FAILED);
            }
        } else {
            if (statusPerTestRun.values().contains(FAILED)) {
                result = asResult(null, FAILED);
            } else {
                result = asResult(null, RESULT_IN_PROGRESS);
            }
        }
    }

    private Result__c upsertResult() {
        if (result != null) {
            Utilities.Secure_DML(result, Utilities.DML_Action.UPS, Schema.SObjectType.Result__c);
        }
        return result;
    }

    private Result__c asResult(Id resultId, String status) {
        return new Result__c(id = resultId, Status__c = status, Progress_Status__c = status, Job_Type__c = MANUAL_TESTS, Test__c = testId);
    }

    private void prepareResultWith(String status) {
        result.Status__c = status;
        result.Progress_Status__c = status;
    }
}