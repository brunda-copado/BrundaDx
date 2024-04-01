public with sharing class CreateManualTestsRuns {
    private Id testId;
    private List<RunManualTestsController.StepExecutionWrapper> executionWrapper;

    private static final String PASSED = 'Passed';
    private static final String PASSED_WITH_COMMENTS = 'Passed with comments';
    private static final String FAILED = 'Failed';
    private static final String IN_PROGRESS = 'In progress';

    //CTOR

    public CreateManualTestsRuns(Id testId, List<RunManualTestsController.StepExecutionWrapper> executionWrapper) {
        this.testId = testId;
        this.executionWrapper = executionWrapper;
    }

    //PUBLIC

    public void execute() {
        Set<Id> testRunIds = createTestRuns();
        List<Test_Run_Step__c> updatedRunSteps = updateTestRunSteps(testRunIds);
        updateTestRunStatusWith(updatedRunSteps);
    }

    //PRIVATE

    private Set<Id> createTestRuns() {
        Set<Id> result = new Set<Id>();

        List<Test_Run__c> testRunsToInsert = new List<Test_Run__c>();
        Set<Id> processedScriptId = new Set<Id>();

        for (RunManualTestsController.StepExecutionWrapper executionRow : executionWrapper) {
            if (executionRow.testRunId != null) {
                result.add(executionRow.testRunId);
            }

            if (executionRow.testRunId == null && !processedScriptId.contains(executionRow.scriptId)) {
                processedScriptId.add(executionRow.scriptId);

                testRunsToInsert.add(asTestRun(executionRow));
            }
        }

        if (!testRunsToInsert.isEmpty()) {
            Utilities.Secure_DML(testRunsToInsert, Utilities.DML_Action.INS, Schema.SObjectType.Test_Run__c);
            result.addAll((new Map<Id, Test_Run__c>(testRunsToInsert).keySet()));
        }

        return result;
    }

    private Test_Run__c asTestRun(RunManualTestsController.StepExecutionWrapper executionRow) {
        return new Test_Run__c(Test_Script__c = executionRow.scriptId, Test__c = testId, Tester__c = UserInfo.getUserId(), Status__c = IN_PROGRESS);
    }

    private List<Test_Run_Step__c> updateTestRunSteps(Set<Id> testRunIds) {
        List<Test_Run_Step__c> runStepsToUpdate = getRunSteps(testRunIds);

        if (!runStepsToUpdate.isEmpty()) {
            runStepsToUpdate = asTestRunStep(runStepsToUpdate);
        }

        if (!runStepsToUpdate.isEmpty()) {
            Utilities.Secure_DML(runStepsToUpdate, Utilities.DML_Action.UPD, schema.SObjectType.Test_Run_Step__c);
        }

        return runStepsToUpdate;
    }

    private List<Test_Run_Step__c> getRunSteps(Set<Id> testRunIds) {
        return [
            SELECT Id, Actual_Result__c, Status__c, Script_Step__c, Test_Run__c
            FROM Test_Run_Step__c
            WHERE Test_Run__c IN :testRunIds
            WITH SECURITY_ENFORCED
        ];
    }

    private List<Test_Run_Step__c> asTestRunStep(List<Test_Run_Step__c> runSteps) {
        for (Test_Run_Step__c runStep : runSteps) {
            for (RunManualTestsController.StepExecutionWrapper executionRow : executionWrapper) {
                if (runStep.Script_Step__c == executionRow.scriptStepId) {
                    runStep.Actual_Result__c = executionRow.actualResult;
                    runStep.Status__c = executionRow.status == PASSED && String.isNotBlank(executionRow.actualResult)
                        ? PASSED_WITH_COMMENTS
                        : executionRow.status;
                }
            }
        }
        return runSteps;
    }

    private Map<Id, String> getStatusPerTestRun(List<Test_Run_Step__c> testRunSteps) {
        Map<Id, String> result = new Map<Id, String>();

        for (Test_Run_Step__c testRunStep : testRunSteps) {
            String status = getProcessStatus(testRunStep.Status__c);

            if (!result.containsKey(testRunStep.Test_Run__c)) {
                result.put(testRunStep.Test_Run__c, status);
            } else if (result.get(testRunStep.Test_Run__c) != FAILED) {
                result = populateMap(status, testRunStep, result);
            }
        }

        return result;
    }

    private Map<Id, String> populateMap(String status, Test_Run_Step__c testRunStep, Map<Id, String> result) {
        Boolean failed = status == FAILED;
        Boolean inProgress = String.isBlank(testRunStep.Status__c);
        Boolean passedWithComments = status == PASSED_WITH_COMMENTS && result.get(testRunStep.Test_Run__c) != IN_PROGRESS;
        Boolean passed = status == PASSED && result.get(testRunStep.Test_Run__c) == PASSED;
        if (failed || inProgress || passedWithComments || passed) {
            result.put(testRunStep.Test_Run__c, status);
        }
        return result;
    }

    private String getProcessStatus(String status) {
        return String.isBlank(status) ? IN_PROGRESS : status;
    }

    private void updateTestRunStatusWith(List<Test_Run_Step__c> updatedRunSteps) {
        Map<Id, String> statusPerTestRun = getStatusPerTestRun(updatedRunSteps);
        List<Test_Run__c> testRunsToUpdate = new List<Test_Run__c>();

        for (Id testRunId : statusPerTestRun.keySet()) {
            testRunsToUpdate.add(new Test_Run__c(Id = testRunId, Status__c = statusPerTestRun.get(testRunId)));
        }

        if (!testRunsToUpdate.isEmpty()) {
            Utilities.Secure_DML(testRunsToUpdate, Utilities.DML_Action.UPD, schema.SObjectType.Test_Run__c);
        }

        Result__c result = new ManualTestsResult(testId, null).statusPerTestRun(statusPerTestRun).upsertResult('');

        if (result != null) {
            new EvaluateManualTestsCriteria(testId).execute();
        }
    }
}