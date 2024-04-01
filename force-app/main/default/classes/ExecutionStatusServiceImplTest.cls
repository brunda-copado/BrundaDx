@IsTest
private class ExecutionStatusServiceImplTest {

    @TestSetup
    private static void setupData() {
        TestUtilities.getAllMultilicense();
        User user = (User) new User_t()
            .assign(new PermissionSetAssignment_t().copadoUser())
            .assign(new PermissionSetAssignment_t().jobEngine())
            .assign(new PermissionSetAssignment_t().qualityGatesAdmin())
            .persist();

        System.runAs(user) {
            new CopadoLicense().user(user).enableAll().persist();
        }
    }


    @isTest
    private static void exceptionWithNoJobId() {
        System.runAs(getUser()) {
            //Setup
            Exception expectedException;
            Jobs.StatusResult expectedResult;

            // Exercise
            Test.startTest();
            try {
                expectedResult = Jobs.Execution.status(null);
            } catch(Exception ex) {
                expectedException = ex;
            }
            Test.stopTest();

            // Verify
            System.assertEquals(null, expectedResult, 'Response should be null');
            System.assertNotEquals(null, expectedException, 'An exception should be thrown');
            System.assertEquals('Missing required parameters : Job Id', expectedException.getMessage(), 'Exception message should match.');
        }
    }


    @IsTest
    private static void successfulExecutionWithSuccessfulSteps() {
        System.runAs(getUser()) {
            // Setup
            JobExecution__c jobExecution = (JobExecution__c) new JobExecution()
                .status(JobExecutionConstants.STATUS_SUCCESSFUL)
                .add(new JobStep().result(new Result().status(JobExecutionConstants.STATUS_SUCCESSFUL)))
                .persist();

            // Exercise
            Test.startTest();
            Jobs.StatusResult expectedResult = Jobs.Execution.status(jobExecution.Id);
            Test.stopTest();

            // Verify
            System.assertNotEquals(null, expectedResult, 'Result is not null');
            System.assertEquals(JobExecutionConstants.STATUS_SUCCESSFUL, expectedResult.jobStatus, 'Job Execution Status should match');
            System.assertEquals(1, expectedResult.steps.size(), 'Should be one execution step');
            System.assertEquals(JobExecutionConstants.STATUS_SUCCESSFUL, expectedResult.steps[0].Status__c, 'Job Execution Step Status should match');
        }
    }


    @IsTest
    private static void erroredExecutionWithDifferentSteps() {
        System.runAs(getUser()) {
            // Setup
            JobExecution__c jobExecution = (JobExecution__c) new JobExecution()
                .status(JobExecutionConstants.STATUS_ERROR)
                .add(new JobStep().order(1).result(new Result().status(JobExecutionConstants.STATUS_SUCCESSFUL)))
                .add(new JobStep().order(2).result(new Result().status(JobExecutionConstants.STATUS_SUCCESSFUL)))
                .add(new JobStep().order(3).result(new Result().status(JobExecutionConstants.STATUS_ERROR)))
                .persist();

            // Exercise
            Test.startTest();
            Jobs.StatusResult expectedResult = Jobs.Execution.status(jobExecution.Id);
            Test.stopTest();

            // Verify
            System.assertNotEquals(null, expectedResult, 'Result is not null');
            System.assertEquals(JobExecutionConstants.STATUS_ERROR, expectedResult.jobStatus, 'Job Execution Status should match');
            System.assertEquals(3, expectedResult.steps.size(), 'Should be 3 execution steps');
            System.assertEquals(JobExecutionConstants.STATUS_SUCCESSFUL, expectedResult.steps[0].Status__c, 'Job Execution Step Status should match');
            System.assertEquals(JobExecutionConstants.STATUS_SUCCESSFUL, expectedResult.steps[1].Status__c, 'Job Execution Step Status should match');
            System.assertEquals(JobExecutionConstants.STATUS_ERROR, expectedResult.steps[2].Status__c, 'Job Execution Step Status should match');
        }
    }


    // HELPER

    private static User getUser() {
        return [SELECT Id, Email FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1];
    }
}