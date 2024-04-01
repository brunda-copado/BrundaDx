@isTest
private with sharing class ApexTestRunResultTest {
    @isTest
    private static void getNumberOfFailures() {
        System.runAs(getTestUser()) {
            // Setup
            ApexTestRunResult mockRunResult = new ApexTestRunResult();
            mockRunResult.records = new List<ApexTestRunResult.TestMethodResult>{
                createMockMethodResult('Pass', 1),
                createMockMethodResult('Fail', 1),
                createMockMethodResult('Fail', 1),
                createMockMethodResult('Pass', 1)
            };

            // Exercise
            Integer numberOfFailures = mockRunResult.getNumberOfFailures();

            // Verify
            System.assertEquals(2, numberOfFailures, 'There must be 2 failures found');
        }
    }

    @isTest
    private static void getTotalExecutionTime() {
        System.runAs(getTestUser()) {
            // Setup
            ApexTestRunResult mockRunResult = new ApexTestRunResult();
            mockRunResult.records = new List<ApexTestRunResult.TestMethodResult>{
                createMockMethodResult('Pass', 1),
                createMockMethodResult('Fail', 1),
                createMockMethodResult('Fail', 1),
                createMockMethodResult('Pass', 1)
            };

            // Exercise
            Integer executionTime = mockRunResult.getTotalExecutionTime();

            // Verify
            System.assertEquals(4, executionTime, 'Execution time must sum 4');
        }
    }

    private static ApexTestRunResult.TestMethodResult createMockMethodResult(String outcome, Integer executionTime) {
        ApexTestRunResult.TestMethodResult result = new ApexTestRunResult.TestMethodResult();

        result.Outcome = outcome;
        result.RunTime = executionTime;

        return result;
    }

    @TestSetup
    private static void setupUser() {
        new CopadoSetupTestDefaults.UserDefaults().createRunAsUsers().executeDML();
    }

    private static User getTestUser() {
        return [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test@test.org' LIMIT 1].get(0);
    }
}