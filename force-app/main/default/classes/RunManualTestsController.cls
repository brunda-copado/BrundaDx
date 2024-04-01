public with sharing class RunManualTestsController {
    private static final String IN_PROGRESS = 'In progress';

    @AuraEnabled
    public static List<TestRunRow> retrieveTestRuns(Id recordId) {
        List<TestRunRow> testRunRows = new List<TestRunRow>();

        List<Test__c> tests = new TestsSelector().byIds(new Set<Id>{ recordId });
        if (!tests.isEmpty()) {
            List<Test_Script__c> testScripts = fetchTestScripts(recordId);
            List<Test_Run__c> testRuns = fetchLatestTestRuns(getTestScriptIdsFrom(testScripts), recordId);
            Map<Id, Test_Run_Step__c> testRunStepPerScriptStep = fetchRunStepPerScriptStep(testRuns);

            for (Test_Script__c testScript : testScripts) {
                testRunRows.add(new TestRunRow(testScript, testRunStepPerScriptStep));
            }
        }

        return testRunRows;
    }

    @AuraEnabled
    public static void saveTestRuns(String testRunRows, Id recordId) {
        try {
            List<StepExecutionWrapper> executionWrapper = parseJson(testRunRows);

            new CreateManualTestsRuns(recordId, executionWrapper).execute();
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }
    }

    // PRIVATE

    private static List<Test_Script__c> fetchTestScripts(Id testId) {
        List<Test_Script__c> result = new List<Test_Script__c>();

        String whereClause = 'IN (SELECT Test_Script__c FROM Test_Suite_Script__c WHERE Test__c = :testId)';
        result = Database.query(getQuery(whereClause));

        return result;
    }

    private static String getQuery(String whereClause) {
        String result =
            'SELECT Id, Name, Test_Title__c, Prerequisites__c, Expected_Result__c, Project__c,' +
            ' (SELECT Id, Order__c, Test_Script__c FROM Test_Suite_Scripts__r WHERE Test__c = :testId LIMIT 1),' +
            ' (SELECT Id, Test_Script__c, Name, Action_Description__c, Expected_Result__c, Guidance_notes__c, Order__c FROM Script_Steps__r)' +
            ' FROM Test_Script__c WHERE ID ' +
            whereClause +
            ' WITH SECURITY_ENFORCED';

        return result;
    }

    private static List<Id> getTestScriptIdsFrom(List<Test_Script__c> testScripts) {
        return new List<Id>(new Map<Id, Test_Script__c>(testScripts).keySet());
    }

    private static List<Test_Run__c> fetchLatestTestRuns(List<Id> testScriptIds, Id testId) {
        List<Test_Run__c> result = [
            SELECT Id, Test_Script__c, Status__c
            FROM Test_Run__c
            WHERE Test_Script__c IN :testScriptIds AND Tester__c = :UserInfo.getUserId() AND Test__c = :testId AND Status__c = :IN_PROGRESS
            WITH SECURITY_ENFORCED
            ORDER BY CreatedDate DESC
        ];

        return result;
    }

    private static Map<Id, Test_Run_Step__c> fetchRunStepPerScriptStep(List<Test_Run__c> testRuns) {
        Map<Id, Test_Run_Step__c> result = new Map<Id, Test_Run_Step__c>();

        if (!testRuns.isEmpty()) {
            for (Test_Run_Step__c step : [
                SELECT Id, Name, Actual_Result__c, Script_Step__c, Status__c, Test_Run__c, Test_Run__r.Status__c
                FROM Test_Run_Step__c
                WHERE Test_Run__c IN :testRuns
                WITH SECURITY_ENFORCED
            ]) {
                result.put(step.Script_Step__c, step);
            }
        }

        return result;
    }

    private static List<StepExecutionWrapper> parseJson(String body) {
        return (List<StepExecutionWrapper>) System.JSON.deserialize(body, List<StepExecutionWrapper>.class);
    }

    // INNER

    public class TestRunRow {
        @AuraEnabled
        public Test_Script__c testScript { get; set; }
        @AuraEnabled
        public List<Test_Run_Step__c> testRunSteps { get; set; }
        @AuraEnabled
        public Id testRunId { get; set; }

        public TestRunRow(Test_Script__c testScript, Map<Id, Test_Run_Step__c> testRunStepPerScriptStep) {
            this.testScript = testScript;
            this.testRunSteps = new List<Test_Run_Step__c>();

            for (Test_Script_Step__c scriptStep : testScript.Script_Steps__r) {
                this.testRunId = testRunStepPerScriptStep.get(scriptStep.Id)?.Test_Run__c;
                Test_Run_Step__c testRunStep = new Test_Run_Step__c();

                testRunStep.Script_Step__c = scriptStep.Id;

                if (testRunStepPerScriptStep.containsKey(scriptStep.Id)) {
                    testRunStep.Id = testRunStepPerScriptStep.get(scriptStep.Id).Id;
                    testRunStep.Status__c = testRunStepPerScriptStep.get(scriptStep.Id).Status__c;
                    testRunStep.Actual_Result__c = testRunStepPerScriptStep.get(scriptStep.Id).Actual_Result__c;
                }

                testRunSteps.add(testRunStep);
            }
        }
    }

    public class StepExecutionWrapper {
        public Id scriptId;
        public Id scriptStepId;
        public Id testRunId;
        public Id testRunStepId;
        public String status;
        public String actualResult;
    }
}