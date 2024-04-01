@IsTest
private class CancelExecutionServiceImplTest {
    @TestSetup
    private static void setupData() {
        TestUtilities.getAllMultilicense();
        User user = (User) new User_t()
            .assign(new PermissionSetAssignment_t().copadoUser())
            .assign(new PermissionSetAssignment_t().jobEngine())
            .assign(new PermissionSetAssignment_t().functions())
            .persist();

        System.runAs(user) {
            new CopadoLicense().user(user).enableAll().persist();
        }
    }

    @IsTest
    private static void executeWithInvalidExecutionId() {
        System.runAs(getUser()) {
            // Setup
            Exception expectedException;
            Jobs.ExecutionResult expectedResult;

            // Exercise
            Test.startTest();
            try {
                expectedResult = Jobs.Execution.cancel(null);
            } catch (Exception ex) {
                expectedException = ex;
            }
            Test.stopTest();

            // Verify
            System.assertEquals(null, expectedResult, 'Response should be null');
            System.assertEquals('Missing required parameters : Job Id', expectedException.getMessage(), 'Exception message should match.');
        }
    }

    @IsTest
    private static void cancelFunction() {
        User user = getUser();
        setHttpMock(201);
        System.runAs(user) {
            // Setup
            fflib_SObjectUnitOfWork.disableRollback = true;
            insert new Personal_Settings__c(SetupOwnerId = user.Id, API_Key__c = DeployAPI.encryptAPIKey('000111222333'));

            new Function();
            JobTemplate__c template = (JobTemplate__c) new JobTemplate().name('Sample').persist();

            JobExecution__c job = (JobExecution__c) new JobExecution()
                .status('In Progress')
                .template(template.Id)
                .add(new JobStep().name('step1').type('Function').order(1).configJson('{"functionName" : "Function_1"}'))
                .persist();

            JobStep__c step = [SELECT Id, Result__c FROM JobStep__c];
            Function__c function = [SELECT Id FROM Function__c];

            Result__c stepResult = (Result__c) new Result().jobType('Function').status('In Progress').function(function.Id).step(step.Id).persist();
            step.Result__c = stepResult.Id;
            update step;

            // Exercise
            Test.startTest();
            Jobs.Execution.cancel(job.Id);
            Test.stopTest();

            //Verify
            Result__c result = [SELECT Status__c, Progress_Status__c FROM Result__c];
            System.assertEquals('Cancelling', result.Progress_Status__c, 'Incorrect Progress Status.');
        }
    }

    @IsTest
    private static void cancelFunctionWithErrorServerResponse() {
        User user = getUser();
        setHttpMock(400);
        System.runAs(user) {
            // Setup
            fflib_SObjectUnitOfWork.disableRollback = true;
            Exception resultException;
            insert new Personal_Settings__c(SetupOwnerId = user.Id, API_Key__c = DeployAPI.encryptAPIKey('000111222333'));

            new Function();
            JobTemplate__c template = (JobTemplate__c) new JobTemplate().name('Sample').persist();

            JobExecution__c job = (JobExecution__c) new JobExecution()
                .status('In Progress')
                .template(template.Id)
                .add(new JobStep().name('step1').type('Function').order(1).configJson('{"functionName" : "Function_1"}'))
                .persist();

            JobStep__c step = [SELECT Id, Result__c FROM JobStep__c];
            Function__c function = [SELECT Id FROM Function__c];

            Result__c stepResult = (Result__c) new Result().jobType('Function').status('In Progress').function(function.Id).step(step.Id).persist();
            step.Result__c = stepResult.Id;
            update step;

            // Exercise
            Test.startTest();
            try {
                Jobs.Execution.cancel(job.Id);
            } catch (Exception ex) {
                resultException = ex;
            }
            Test.stopTest();

            // Verify
            System.assertNotEquals(null, resultException, 'Exception should not be null');
            System.assertEquals(Label.Stop_Execution_Error_Connecting, resultException.getMessage(), 'Error message matches.');
        }
    }

    @IsTest
    private static void cancelManual() {
        User user = getUser();
        System.runAs(user) {
            // Setup
            JobTemplate__c template = (JobTemplate__c) new JobTemplate().name('Sample').persist();
            JobExecution__c job = (JobExecution__c) new JobExecution()
                .status('In Progress')
                .template(template.Id)
                .add(new JobStep().name('step1').type('Manual').configJson('').order(1))
                .persist();

            JobStep__c step = [SELECT Id, Result__c FROM JobStep__c];
            Result__c stepResult = (Result__c) new Result().jobType('Manual').status('In Progress').step(step.Id).persist();
            step.Result__c = stepResult.Id;
            update step;

            // Exercise
            Test.startTest();
            Jobs.ExecutionResult response = Jobs.Execution.cancel(job.Id);
            Test.stopTest();

            //Verify
            Result__c result = [SELECT Status__c, Progress_Status__c FROM Result__c];
            System.assertEquals('Cancelled', result.Progress_Status__c, 'Progress Status is cancelled');
            System.assertEquals('Cancelled', result.Status__c, 'Status is cancelled.');
            System.assertEquals('Canceled', response.jobExecution.Status__c, 'Status is canceled');
        }
    }

    @IsTest
    private static void cancelFlow() {
        User user = getUser();
        System.runAs(user) {
            // Setup
            JobTemplate__c template = (JobTemplate__c) new JobTemplate().name('Sample').persist();
            JobExecution__c job = (JobExecution__c) new JobExecution()
                .status('In Progress')
                .template(template.Id)
                .add(
                    new JobStep()
                        .name('step1')
                        .type('Flow')
                        .order(1)
                        .configJson('{"flowName" : "MockedFlow"}')
                        .result(new Result().jobType('Flow').status('In Progress'))
                )
                .persist();

            // Exercise
            Test.startTest();
            Jobs.ExecutionResult response = Jobs.Execution.cancel(job.Id);
            Test.stopTest();

            //Verify
            System.assertEquals('Canceled', response.jobExecution.Status__c, 'Status is canceled');
        }
    }

    @IsTest
    private static void cancelTestJobStepWithManualSubStep() {
        User user = getUser();
        System.runAs(user) {
            // Setup
            JobTemplate__c template = (JobTemplate__c) new JobTemplate().name('Sample').persist();

            new JobExecution()
                .status('In Progress')
                .template(template.Id)
                .add(new JobStep().name('step1').type('Test').order(1).configJson('{"type" : "QRT"}'));
            JobExecution__c subJob = (JobExecution__c) new JobExecution()
                .status('In Progress')
                .add(new JobStep().name('Sub Step').type('Manual').order(1).configJson('{"type" : "Manual"}'))
                .persist();

            List<JobStep__c> jobSteps = [SELECT Id, Result__c, Sub_Job_Execution__c, Type__c FROM JobStep__c];

            new Result().jobType(jobSteps[0].Type__c).status('In Progress').step(jobSteps[0].Id);
            new Result().jobType(jobSteps[1].Type__c).status('In Progress').step(jobSteps[1].Id).persist();

            List<Result__c> results = [SELECT Id, Job_Type__c, JobStep__c FROM Result__c];

            for (JobStep__c jobStep : jobSteps) {
                for (Result__c result : results) {
                    if (result.JobStep__c == jobStep.Id) {
                        jobStep.Result__c = result.Id;
                    }
                }
                if (jobStep.Type__c == 'Test') {
                    jobStep.Sub_Job_Execution__c = subJob.Id;
                }
            }

            update jobSteps;
            JobExecution__c parentJob = [SELECT Id FROM JobExecution__c WHERE Template__c != NULL];

            // Exercise
            Test.startTest();
            Jobs.ExecutionResult response = Jobs.Execution.cancel(parentJob.Id);
            Test.stopTest();

            //Verify
            Result__c result = [SELECT Status__c, Progress_Status__c FROM Result__c WHERE JobStep__r.Name = 'step1'];
            System.assertEquals('Cancelled', result.Status__c, 'Consolidated result is cancelled.');
            System.assertEquals('Canceled', response.jobExecution.Status__c, 'Main Job Execution Status is canceled');
        }
    }

    @IsTest
    private static void cancelTestJobStepWithFunctionSubStep() {
        User user = getUser();
        setHttpMock(201);
        System.runAs(user) {
            // Setup
            fflib_SObjectUnitOfWork.disableRollback = true;
            insert new Personal_Settings__c(SetupOwnerId = user.Id, API_Key__c = DeployAPI.encryptAPIKey('000111222333'));

            new Function();
            JobTemplate__c template = (JobTemplate__c) new JobTemplate().name('Sample').persist();

            new JobExecution()
                .status('In Progress')
                .template(template.Id)
                .add(new JobStep().name('step1').type('Test').order(1).configJson('{"type" : "QRT"}'));
            JobExecution__c subJob = (JobExecution__c) new JobExecution()
                .status('In Progress')
                .add(new JobStep().name('Sub Step').type('Function').order(1).configJson('{"functionName" : "Function_1"}'))
                .persist();

            List<JobStep__c> jobSteps = [SELECT Id, Result__c, Sub_Job_Execution__c, Type__c FROM JobStep__c];
            Function__c function = [SELECT Id FROM Function__c];

            new Result().jobType(jobSteps[0].Type__c).function(function.Id).status('In Progress').step(jobSteps[0].Id);
            new Result().jobType(jobSteps[1].Type__c).function(function.Id).status('In Progress').step(jobSteps[1].Id).persist();

            List<Result__c> results = [SELECT Id, Job_Type__c, JobStep__c FROM Result__c];

            for (JobStep__c jobStep : jobSteps) {
                for (Result__c result : results) {
                    if (result.JobStep__c == jobStep.Id) {
                        jobStep.Result__c = result.Id;
                    }
                }
                if (jobStep.Type__c == 'Test') {
                    jobStep.Sub_Job_Execution__c = subJob.Id;
                }
            }

            update jobSteps;
            JobExecution__c parentJob = [SELECT Id FROM JobExecution__c WHERE Template__c != NULL];

            // Exercise
            Test.startTest();
            Jobs.ExecutionResult response = Jobs.Execution.cancel(parentJob.Id);
            Test.stopTest();

            //Verify
            Result__c result = [SELECT Status__c, Progress_Status__c FROM Result__c WHERE JobStep__r.Name = 'step1'];
            System.assertEquals('Cancelled', result.Status__c, 'Consolidated result is cancelled.');
            System.assertEquals('Canceled', response.jobExecution.Status__c, 'Main Job Execution Status is canceled');
        }
    }

    @IsTest
    private static void cancelCompletedFlow() {
        User user = getUser();
        System.runAs(user) {
            // Setup
            JobTemplate__c template = (JobTemplate__c) new JobTemplate().name('Sample').persist();

            JobExecution__c job = (JobExecution__c) new JobExecution()
                .status('In Progress')
                .template(template.Id)
                .add(
                    new JobStep()
                        .name('step1')
                        .type('Flow')
                        .order(1)
                        .configJson('{"flowName" : "MockedFlow"}')
                        .result(new Result().jobType('Flow').status('Success'))
                )
                .persist();

            // Exercise
            Test.startTest();
            Jobs.ExecutionResult response = Jobs.Execution.cancel(job.Id);
            Test.stopTest();

            //Verify
            Result__c result = [SELECT Status__c, Progress_Status__c FROM Result__c];
            System.assertEquals('Success', result.Status__c, 'Status does not update to cancelled.');
            System.assertEquals(
                'In Progress',
                response.jobExecution.Status__c,
                'Status does not change as there were no in progress steps to cancel.'
            );
        }
    }

    @IsTest
    private static void cancelCompletedExecution() {
        User user = getUser();
        System.runAs(user) {
            // Setup
            JobTemplate__c template = (JobTemplate__c) new JobTemplate().name('Sample').persist();

            JobExecution__c job = (JobExecution__c) new JobExecution()
                .status('Successful')
                .template(template.Id)
                .add(
                    new JobStep()
                        .name('step1')
                        .type('Flow')
                        .order(1)
                        .configJson('{"flowName" : "MockedFlow"}')
                        .result(new Result().jobType('Flow').status('Success'))
                )
                .persist();

            // Exercise
            Test.startTest();
            Jobs.ExecutionResult response = Jobs.Execution.cancel(job.Id);
            Test.stopTest();

            //Verify
            Result__c result = [SELECT Status__c, Progress_Status__c FROM Result__c];
            System.assertEquals('Success', result.Status__c, 'Status does not update to cancelled.');
            System.assertEquals(
                'Successful',
                response.jobExecution.Status__c,
                'Status does not change as there were no in progress steps to cancel.'
            );
        }
    }

    @IsTest
    private static void cancelExecutionWithNoSteps() {
        User user = getUser();
        System.runAs(user) {
            // Setup
            Exception expectedException;
            Jobs.ExecutionResult expectedResult;
            JobTemplate__c template = (JobTemplate__c) new JobTemplate().name('Sample').persist();

            JobExecution__c job = (JobExecution__c) new JobExecution().status('Not Started').template(template.Id).persist();

            // Exercise
            Test.startTest();
            try {
                expectedResult = Jobs.Execution.cancel(job.Id);
            } catch (Exception ex) {
                expectedException = ex;
            }
            Test.stopTest();

            //Verify
            System.assertEquals(null, expectedResult, 'Response should be null');
            System.assertEquals(
                String.format(Label.JobHasNoStep, new List<String>{ 'cancel' }),
                expectedException.getMessage(),
                'Exception message should match.'
            );
        }
    }

    //HELPER

    private static User getUser() {
        return [SELECT Id, Email FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1];
    }

    private static void setHttpMock(Integer status) {
        MockHttpResponseGenerator mockResponse = new MockHttpResponseGenerator(status, 'Complete', '{}', null);

        Test.setMock(HttpCalloutMock.class, mockResponse);
    }
}