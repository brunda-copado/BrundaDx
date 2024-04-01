@IsTest
private class RunJobTest {
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
            Exception expectedException = null;
            RunJob.Request request = new RunJob.Request();

            // Exercise
            try {
                RunJob.execute(new List<RunJob.Request>{ request });
            } catch (Exception ex) {
                expectedException = ex;
            }

            // Verify
            System.assertNotEquals(null, expectedException, 'There is an exception.');
            System.assertEquals(Label.InvalidExecutionId, expectedException.getMessage(), 'The exception messages match.');
        }
    }


    @IsTest
    private static void executeWithMultipleRequests() {
        System.runAs(getUser()) {

            // Setup
            Exception expectedException = null;
            RunJob.Request request1 = new RunJob.Request();
            RunJob.Request request2 = new RunJob.Request();

            // Exercise
            try {
                RunJob.execute(new List<RunJob.Request>{ request1, request2 });
            } catch (Exception ex) {
                expectedException = ex;
            }

            // Verify
            System.assertNotEquals(null, expectedException, 'There is an exception');
            System.assertEquals(Label.InvalidRequestError, expectedException.getMessage(), 'The exception messages match');
        }
    }


    @IsTest
    private static void shouldNotStartNextStepIfJobIsAlreadyInProgress() {
        System.runAs(getUser()) {

            // Setup
            Exception expectedException;
            JobTemplate__c template = (JobTemplate__c) new JobTemplate()
                                                            .name('Sample').persist();
            JobExecution__c job = (JobExecution__c) new JobExecution()
                                                        .status('In Progress')
                                                        .template(template.Id)
                                                        .add(new JobStep()
                                                        .name('step1')
                                                        .type('Manual')
                                                        .order(1)
                                                        .configJson('')).persist();

            RunJob.Request request = new RunJob.Request();
            request.jobId = job.Id;

            // Exercise
            try {
                RunJob.execute(new List<RunJob.Request>{ request });
            } catch(Exception ex) {
                expectedException = ex;
            }

            // Verify
            System.assertEquals(0, [SELECT COUNT() FROM Result__c], 'No new result record is created');
            System.assertNotEquals(null, expectedException, 'An exception should be thrown');
            System.assertEquals(Label.JobInProgress, expectedException.getMessage(), 'Exception message should match.');
        }
    }

    @IsTest
    private static void shouldResetResultOnExistingStepsOnRerun() {
        System.runAs(getUser()) {

            // Setup
            JobTemplate__c template = (JobTemplate__c) new JobTemplate()
                                                            .name('Sample').persist();
            JobExecution__c job = (JobExecution__c) new JobExecution()
                                                        .status('Cancelled')
                                                        .template(template.Id)
                                                        .add(new JobStep()
                                                            .name('step1')
                                                            .type('Manual')
                                                            .order(1)
                                                            .configJson('')
                                                            .result(new Result()
                                                                .jobType('Manual')
                                                                .status('Success')))
                                                        .add(new JobStep()
                                                            .name('step2')
                                                            .type('Manual')
                                                            .order(2)
                                                            .configJson('')
                                                            .result(new Result()
                                                                .jobType('Manual')
                                                                .status('Failed')))
                                                        .add(new JobStep()
                                                            .name('step3')
                                                            .type('Manual')
                                                            .order(3)
                                                            .configJson('')
                                                            .result(new Result()
                                                                .jobType('Manual')
                                                                .status('Cancelled'))).persist();

            RunJob.Request request = new RunJob.Request();
            request.jobId = job.Id;
            request.allSteps = false;

            // Exercise
            Test.startTest();
            RunJob.execute(new List<RunJob.Request>{ request });
            Test.stopTest();
            Test.getEventBus().deliver();

            // Verify
            System.assertEquals(4, [SELECT COUNT() FROM Result__c], 'The count matches');
            System.assertEquals('In Progress', [SELECT Status__c FROM JobExecution__c].Status__c, 'The job is in progress');
            System.assertEquals(null, [SELECT Result__c FROM JobStep__c WHERE Name = 'step3'].Result__c, 'The result has been reset');
            System.assertNotEquals(null, [SELECT Result__c FROM JobStep__c WHERE Name = 'step2'].Result__c, 'The result has been reset');
            System.assertNotEquals(null, [SELECT Result__c FROM JobStep__c WHERE Name = 'step1'].Result__c, 'The result has been reset');
        }
    }

    @IsTest
    private static void shouldFailExecutionForInvalidFlow() {
        System.runAs(getUser()) {

            // Setup
            JobTemplate__c template = (JobTemplate__c) new JobTemplate()
                                                            .name('Sample').persist();
            JobExecution__c job = (JobExecution__c) new JobExecution()
                                                        .status('Not Started')
                                                        .template(template.Id)
                                                        .add(new JobStep()
                                                            .name('step1')
                                                            .type('Flow')
                                                            .order(1)
                                                            .configJson('{"flowName" : "Invalid Flow"}')).persist();

            RunJob.Request request = new RunJob.Request();
            request.jobId = job.Id;
            Flow.mockResponse = flowCompletionEvent(false, 'Invalid Flow', '');

            // Exercise
            Test.startTest();
            RunJob.execute(new List<RunJob.Request>{ request });
            Test.getEventBus().deliver();
            Test.stopTest();

            // Verify
            JobStep__c step1 = [SELECT Status__c, JobExecution__r.Status__c, JobExecution__r.ErrorMessage__c FROM JobStep__c WHERE Name = :'step1'];

            System.assertEquals(1, [SELECT COUNT() FROM Result__c], 'The result count matches');

            System.assertEquals('Failed', step1.Status__c, 'Step1 has failed');
            System.assertEquals('Error', step1.JobExecution__r.Status__c, 'Job Execution status matches');
            System.assertEquals('Invalid Flow', step1.JobExecution__r.ErrorMessage__c, 'The error message matches');
        }
    }

    @IsTest
    private static void shouldFailExecutionForInvalidFunctionName() {
        User user = getUser();
        System.runAs(user) {

            // Setup
            insert new Personal_Settings__c(SetupOwnerId = user.Id, API_Key__c = DeployAPI.encryptAPIKey('000111222333'));

            JobTemplate__c template = (JobTemplate__c) new JobTemplate()
                                                            .name('Sample').persist();
            JobExecution__c job = (JobExecution__c) new JobExecution()
                                                        .status('Not Started')
                                                        .template(template.Id)
                                                        .add(new JobStep()
                                                        .name('step1')
                                                        .type('Function')
                                                        .order(1)
                                                        .configJson('{"functionName" : "Invalid Function"}')).persist();

            credential();
            RunJob.Request request = new RunJob.Request();
            request.jobId = job.Id;

            // Exercise
            Test.startTest();
            RunJob.execute(new List<RunJob.Request>{ request });
            Test.stopTest();

            // Verify
            String errorMessage = Label.Function_not_Found + ' Invalid Function';
            List<Result__c> results = [SELECT Error_Message__c, JobStep__r.JobExecution__r.ErrorMessage__c FROM Result__c];

            System.assertEquals(1, results.size(), 'The count matches');
            System.assertEquals('Error', [SELECT Status__c FROM JobExecution__c].Status__c, 'Job execution status matches');
            System.assert(results[0].Error_Message__c.contains(errorMessage), 'Result contains the error message');
            System.assertEquals(results[0].Error_Message__c, results[0].JobStep__r.JobExecution__r.ErrorMessage__c, 'Error message matches');
        }
    }

    @IsTest
    private static void shouldCompleteIfAllStepsSucceed() {
        User user = getUser();
        System.runAs(user) {

            // Setup
            insert new Personal_Settings__c(SetupOwnerId = user.Id, API_Key__c = DeployAPI.encryptAPIKey('000111222333'));

            new Function()
                .apiName('MockedFunction')
                .script('echo hi');
            JobTemplate__c template = (JobTemplate__c) new JobTemplate()
                                                            .name('Sample').persist();
            JobExecution__c job = (JobExecution__c) new JobExecution()
                                                        .status('Not Started')
                                                        .template(template.Id)
                                                        .add(new JobStep()
                                                            .name('step1')
                                                            .type('Function')
                                                            .order(1)
                                                            .configJson('{"functionName" : "MockedFunction"}'))
                                                        .add(new JobStep()
                                                        .name('step2')
                                                        .type('Function')
                                                        .order(2)
                                                        .configJson('{"functionName" : "MockedFunction"}')).persist();

            RunJob.Request request = new RunJob.Request();
            request.jobId = job.Id;
            request.allSteps = true;

            FunctionEngine.mockResponse = functionCompletionEvent(true, '', 'Success data 2');

            // Exercise
            Test.startTest();
            RunJob.execute(new List<RunJob.Request>{ request });
            Test.getEventBus().deliver();
            Test.stopTest();
            Test.getEventBus().deliver();

            // Verify
            JobStep__c step1 = [SELECT Status__c, Result__r.Result_Data__c FROM JobStep__c WHERE Name = 'step1'];
            JobStep__c step2 = [SELECT Status__c, Result__r.Result_Data__c FROM JobStep__c WHERE Name = 'step2'];

            System.assertEquals(2, [SELECT COUNT() FROM Result__c], 'The count matches');
            System.assertEquals('Successful', [SELECT Status__c FROM JobExecution__c].Status__c, 'The job status matches');

            System.assertEquals('Success', step1.Status__c, 'The step status matches');
            System.assertEquals('Success', step2.Status__c, 'The step status matches');

            System.assertEquals('Success data 2', step1.Result__r.Result_Data__c, 'The step result data matches');
            System.assertEquals('Success data 2', step2.Result__r.Result_Data__c, 'The step result data matches');
        }
    }

    @IsTest
    private static void shouldFailIfFunctionStepFails() {
        User user = getUser();
        System.runAs(user) {

            // Setup
            insert new Personal_Settings__c(SetupOwnerId = user.Id, API_Key__c = DeployAPI.encryptAPIKey('000111222333'));

            new Function()
                .apiName('MockedFunction')
                .script('echo hi');
            JobTemplate__c template = (JobTemplate__c) new JobTemplate()
                                                            .name('Sample').persist();
            JobExecution__c job = (JobExecution__c) new JobExecution()
                                                        .status('Not Started')
                                                        .template(template.Id)
                                                        .add(new JobStep()
                                                            .name('step1')
                                                            .type('Function')
                                                            .order(1)
                                                            .configJson('{"functionName" : "MockedFunction"}'))
                                                        .add(new JobStep()
                                                            .name('step2')
                                                            .type('Function')
                                                            .order(2)
                                                            .configJson('{"functionName" : "MockedFunction"}')).persist();

            RunJob.Request request = new RunJob.Request();
            request.jobId = job.Id;
            request.allSteps = true;

            FunctionEngine.mockResponse = functionCompletionEvent(false, 'Custom error', '');

            // Exercise
            Test.startTest();
            RunJob.execute(new List<RunJob.Request>{ request });
            Test.stopTest();

            // Verify
            JobStep__c step1 = [
                SELECT Status__c, Result__r.Result_Data__c, Result__r.Error_Message__c, JobExecution__r.ErrorMessage__c
                FROM JobStep__c
                WHERE Name = 'step1'
            ];

            System.assertEquals(1, [SELECT COUNT() FROM Result__c], 'The result count matches');
            System.assertEquals('Error', [SELECT Status__c FROM JobExecution__c].Status__c, 'The job status matches');
            System.assertEquals('Failed', step1.Status__c, 'The step status matches');
            System.assertEquals('Custom error', step1.Result__r.Error_Message__c, 'Result\'s error message matches');
            System.assertEquals('Custom error', step1.JobExecution__r.ErrorMessage__c, 'Job\' error message matches');
        }
    }

    @IsTest
    private static void shouldFailIfFlowStepFails() {
        User user = getUser();
        System.runAs(user) {

            // Setup
            insert new Personal_Settings__c(SetupOwnerId = user.Id, API_Key__c = DeployAPI.encryptAPIKey('000111222333'));

            new Function().
                apiName('MockedFunction')
                .script('echo hi');
            JobTemplate__c template = (JobTemplate__c) new JobTemplate()
                                                            .name('Sample').persist();
            JobExecution__c job = (JobExecution__c) new JobExecution()
                                                        .status('Not Started')
                                                        .template(template.Id)
                                                        .add(new JobStep()
                                                            .name('step1')
                                                            .type('Flow')
                                                            .order(1)
                                                            .configJson('{"flowName" : "MockedFlow"}'))
                                                        .add(new JobStep()
                                                            .name('step2')
                                                            .type('Function')
                                                            .order(2)
                                                            .configJson('{"functionName" : "MockedFunction"}')).persist();

            RunJob.Request request = new RunJob.Request();
            request.jobId = job.Id;
            request.allSteps = true;

            Flow.mockResponse = flowCompletionEvent(false, 'Custom error', '');

            // Exercise
            Test.startTest();
            RunJob.execute(new List<RunJob.Request>{ request });
            Test.stopTest();

            // Verify
            JobStep__c step1 = [
                SELECT Status__c, Result__r.Result_Data__c, Result__r.Error_Message__c, JobExecution__r.ErrorMessage__c
                FROM JobStep__c
                WHERE Name = 'step1'
            ];

            System.assertEquals(1, [SELECT COUNT() FROM Result__c], 'The count of results match');
            System.assertEquals('Error', [SELECT Status__c FROM JobExecution__c].Status__c, 'Job status matches');
            System.assertEquals('Failed', step1.Status__c, 'The step status matches');
            System.assertEquals('Custom error', step1.Result__r.Error_Message__c, 'Result\' error message matches');
            System.assertEquals('Custom error', step1.JobExecution__r.ErrorMessage__c, 'Job\' error message matches');
        }
    }

    @IsTest
    private static void shouldReRunFailedStepsIfAnyStepFails() {
        User user = getUser();
        System.runAs(user) {

            // Setup
            insert new Personal_Settings__c(SetupOwnerId = user.Id, API_Key__c = DeployAPI.encryptAPIKey('000111222333'));

            new Function()
                .apiName('MockedFunction')
                .script('echo hi');
            JobTemplate__c template = (JobTemplate__c) new JobTemplate()
                                                            .name('Sample').persist();
            JobExecution__c job = (JobExecution__c) new JobExecution()
                                                        .status('Failed')
                                                        .template(template.Id)
                                                        .add(new JobStep()
                                                            .name('step1')
                                                            .type('Flow')
                                                            .order(1)
                                                            .configJson('{"flowName" : "MockedFlow"}')
                                                            .result(new Result()
                                                                .jobType('Flow')
                                                                .status('Success')))
                                                        .add(new JobStep()
                                                            .name('step2')
                                                            .type('Function')
                                                            .order(2)
                                                            .configJson('{"functionName" : "MockedFunction"}')
                                                            .result(new Result()
                                                                .jobType('Function')
                                                                .status('Failed'))).persist();

            RunJob.Request request = new RunJob.Request();
            request.jobId = job.Id;
            request.allSteps = false;

            credential();

            Flow.mockResponse = flowCompletionEvent(true, '', 'Success data');
            FunctionEngine.mockResponse = functionCompletionEvent(true, '', 'Sample Data');

            // Exercise
            Test.startTest();
            RunJob.execute(new List<RunJob.Request>{ request });
            Test.stopTest();

            // Verify
            JobStep__c step2 = [SELECT Result__r.Result_Data__c, Status__c, JobExecution__r.Status__c FROM JobStep__c WHERE Name = 'step2'];

            System.assertEquals(3, [SELECT COUNT() FROM Result__c], 'The count matches');

            System.assertEquals('Success', step2.Status__c, 'Step status matches');
            System.assertEquals('Sample Data', step2.Result__r.Result_Data__c, 'Result Data matches');
            System.assertEquals('Successful', step2.JobExecution__r.Status__c, 'Job status matches');
        }
    }

    @IsTest
    private static void executeOutstanding() {
        User user = getUser();
        System.runAs(user) {

            // Setup
            insert new Personal_Settings__c(SetupOwnerId = user.Id, API_Key__c = DeployAPI.encryptAPIKey('000111222333'));

            new Function()
                .apiName('MockedFunction')
                .script('echo hi');
            JobTemplate__c template = (JobTemplate__c) new JobTemplate()
                                                            .name('Sample').persist();
            JobExecution__c job = (JobExecution__c) new JobExecution()
                                                        .status('Failed')
                                                        .template(template.Id)
                                                        .add(new JobStep()
                                                            .name('step1')
                                                            .type('Flow')
                                                            .order(1)
                                                            .configJson('{"flowName" : "MockedFlow"}')
                                                            .result(new Result()
                                                                .jobType('Flow')
                                                                .status('Success')))
                                                        .add(new JobStep()
                                                            .name('step2')
                                                            .type('Function')
                                                            .order(2)
                                                            .configJson('{"functionName" : "MockedFunction"}')
                                                            .result(new Result()
                                                                .jobType('Function')
                                                                .status('Failed'))).persist();

            credential();

            Flow.mockResponse = flowCompletionEvent(true, '', 'Success data');
            FunctionEngine.mockResponse = functionCompletionEvent(true, '', 'Sample Data');

            // Exercise
            Test.startTest();
            RunJobController.execute(job.Id, false);
            Test.stopTest();

            // Verify
            JobStep__c step2 = [SELECT Result__r.Result_Data__c, Status__c, JobExecution__r.Status__c FROM JobStep__c WHERE Name = 'step2'];

            System.assertEquals(3, [SELECT COUNT() FROM Result__c], 'The count matches');

            System.assertEquals('Success', step2.Status__c, 'Step status matches');
            System.assertEquals('Sample Data', step2.Result__r.Result_Data__c, 'Result data matches');
            System.assertEquals('Successful', step2.JobExecution__r.Status__c, 'Job status matches');
        }
    }

    @IsTest
    private static void executeTestStep() {
        User user = getUser();
        System.runAs(user) {

            // Setup
            insert new Personal_Settings__c(SetupOwnerId = user.Id, API_Key__c = DeployAPI.encryptAPIKey('000111222333'));

            JobTemplate__c template = (JobTemplate__c) new JobTemplate()
                                                            .name('Sample').persist();
            JobExecution__c job = (JobExecution__c) new JobExecution()
                                                        .status('Failed')
                                                        .template(template.Id)
                                                        .volumeOptions('[{"name": "transactionId", "value": "000111222333"} ]')
                                                        .add(new JobStep()
                                                            .name('step1')
                                                            .type('Test')
                                                            .order(1)
                                                            .configJson('{"type" : "QRT"}')).persist();

            credential();
            TestJobStep.mockResponseStatus = 'Success';

            // Exercise
            Test.startTest();
            RunJobController.execute(job.Id, true);
            Test.getEventBus().deliver();
            Test.stopTest();

            // Verify
            JobStep__c step1 = [SELECT Result__r.Result_Data__c, Status__c, JobExecution__r.Status__c FROM JobStep__c WHERE Name = 'step1'];

            System.assertEquals(1, [SELECT COUNT() FROM Result__c], 'The result count matches');
            System.assertEquals('Success', step1.Status__c, 'The step status is success');
        }
    }

    @IsTest
    private static void executeTestStepCancelled() {
        User user = getUser();
        System.runAs(user) {

            // Setup
            insert new Personal_Settings__c(SetupOwnerId = user.Id, API_Key__c = DeployAPI.encryptAPIKey('000111222333'));

            JobTemplate__c template = (JobTemplate__c) new JobTemplate()
                                                            .name('Sample').persist();
            JobExecution__c job = (JobExecution__c) new JobExecution()
                                                        .status('Failed')
                                                        .template(template.Id)
                                                        .add(new JobStep()
                                                            .name('step1')
                                                            .type('Test')
                                                            .order(1)
                                                            .configJson('{"type" : "QRT"}')).persist();

            credential();
            TestJobStep.mockResponseStatus = 'Cancelled';

            // Exercise
            Test.startTest();
            RunJobController.execute(job.Id, true);
            Test.getEventBus().deliver();
            Test.stopTest();

            // Verify
            JobStep__c step1 = [SELECT Result__r.Result_Data__c, Status__c, JobExecution__r.Status__c FROM JobStep__c WHERE Name = 'step1'];

            System.assertEquals(1, [SELECT COUNT() FROM Result__c], 'The result count matches');
            System.assertEquals('Cancelled', step1.Status__c, 'The step status matches');
        }
    }

    @IsTest
    private static void restartExecution() {
        User user = getUser();
        System.runAs(user) {

            // Setup
            insert new Personal_Settings__c(SetupOwnerId = user.Id, API_Key__c = DeployAPI.encryptAPIKey('000111222333'));

            new Function()
                .apiName('MockedFunction')
                .script('echo hi');
            JobTemplate__c template = (JobTemplate__c) new JobTemplate()
                                                            .name('Sample')
                                                            .persist();
            JobExecution__c job = (JobExecution__c) new JobExecution()
                                                        .status('Failed')
                                                        .template(template.Id)
                                                        .add(new JobStep()
                                                            .name('step1')
                                                            .type('Flow')
                                                            .order(1)
                                                            .configJson('{"flowName" : "MockedFlow"}')
                                                            .result(new Result()
                                                                .jobType('Flow')
                                                                .status('Success')))
                                                        .add(new JobStep()
                                                            .name('step2')
                                                            .type('Function')
                                                            .order(2)
                                                            .configJson('{"functionName" : "MockedFunction"}')
                                                            .result(new Result()
                                                                .jobType('Function')
                                                                .status('Success'))).persist();

            Flow.mockResponse = flowCompletionEvent(true, '', 'Success data');
            FunctionEngine.mockResponse = functionCompletionEvent(true, '', 'Sample Data');

            // Exercise
            Test.startTest();
            RunJobController.execute(job.Id, true);
            Test.getEventBus().deliver();
            Test.stopTest();

            Test.getEventBus().deliver();

            // Verify
            JobStep__c step2 = [SELECT Result__r.Result_Data__c, Status__c, JobExecution__r.Status__c FROM JobStep__c WHERE Name = 'step2'];

            System.assertEquals(4, [SELECT COUNT() FROM Result__c], 'The result count matches');

            System.assertEquals('Success', step2.Status__c, 'Step status matches');
            System.assertEquals('Sample Data', step2.Result__r.Result_Data__c, 'Step result data matches');
            System.assertEquals('Successful', step2.JobExecution__r.Status__c, 'Job status matches');
        }
    }

    @IsTest
    private static void testKillVolumeOption() {
        User user = getUser();
        System.runAs(user) {

            // Setup
            insert new Personal_Settings__c(SetupOwnerId = user.Id, API_Key__c = DeployAPI.encryptAPIKey('000111222333'));

            credential();

            new Function()
                .apiName('MockedFunction')
                .script('echo hi');
            JobTemplate__c template = (JobTemplate__c) new JobTemplate()
                                                            .name('Sample').persist();
            JobExecution__c job = (JobExecution__c) new JobExecution()
                                                        .status('Not Started')
                                                        .template(template.Id)
                                                        .volumeOptions('[{"name": "volumeEnabled", "value": "true"} ]')
                                                        .add(new JobStep()
                                                            .name('step1')
                                                            .type('Function')
                                                            .order(1)
                                                            .configJson('{"functionName" : "MockedFunction"}'))
                                                        .add(new JobStep()
                                                            .name('step2')
                                                            .type('Function')
                                                            .order(2)
                                                            .configJson('{"functionName" : "MockedFunction"}')).persist();

            FunctionEngine.mockResponse = functionCompletionEvent(true, '', '');

            // Exercise
            Test.startTest();
            RunJobController.execute(job.Id, true);
            Test.stopTest();

            // Verify
            JobStep__c step1 = [SELECT Result__r.Result_Data__c FROM JobStep__c WHERE Name = 'step1'];
            JobStep__c step2 = [SELECT Result__r.Result_Data__c FROM JobStep__c WHERE Name = 'step2'];

            System.assertEquals(2, [SELECT COUNT() FROM Result__c], 'The result count matches');

            System.assert(!step1.Result__r?.Result_Data__c?.contains('killVolume'), 'Result matches');
            System.assert(step2.Result__r?.Result_Data__c?.contains('killVolume'), 'Result matches');
        }
    }

    @IsTest
    private static void getNextStepOutstanding() {
        User user = getUser();
        System.runAs(user) {

            // Setup
            insert new Personal_Settings__c(SetupOwnerId = user.Id, API_Key__c = DeployAPI.encryptAPIKey('000111222333'));

            new Function()
                .apiName('MockedFunction')
                .script('echo hi');
            JobTemplate__c template = (JobTemplate__c) new JobTemplate()
                                                            .name('Sample').persist();
            JobExecution__c job = (JobExecution__c) new JobExecution()
                                                        .status('Failed')
                                                        .template(template.Id)
                                                        .add(new JobStep()
                                                            .name('step1')
                                                            .type('Flow')
                                                            .order(1)
                                                            .configJson('{"flowName" : "MockedFlow"}')
                                                            .result(new Result()
                                                                .jobType('Flow')
                                                                .status('Success')))
                                                        .add(new JobStep()
                                                            .name('step2')
                                                            .type('Function')
                                                            .order(2)
                                                            .configJson('{"functionName" : "MockedFunction"}')
                                                            .result(new Result()
                                                                .jobType('Function')
                                                                .status('Failed'))).persist();

            // Exercise
            Test.startTest();
            JobStep__c nextStep = RunJobController.getNextStep(job.Id, false);
            Test.stopTest();

            //Verify
            System.assertEquals('step2', nextStep.Name, 'The step name matches');
        }
    }

    @IsTest
    private static void getNextStepRestartExecution() {
        User user = getUser();
        System.runAs(user) {

            // Setup
            insert new Personal_Settings__c(SetupOwnerId = user.Id, API_Key__c = DeployAPI.encryptAPIKey('000111222333'));

            new Function()
                .apiName('MockedFunction')
                .script('echo hi');
            JobTemplate__c template = (JobTemplate__c) new JobTemplate()
                                                            .name('Sample').persist();
            JobExecution__c job = (JobExecution__c) new JobExecution()
                                                        .status('Failed')
                                                        .template(template.Id)
                                                        .add(new JobStep()
                                                            .name('step1')
                                                            .type('Flow')
                                                            .order(1)
                                                            .configJson('{"flowName" : "MockedFlow"}')
                                                            .result(new Result()
                                                                .jobType('Flow')
                                                                .status('Success')))
                                                        .add(new JobStep()
                                                            .name('step2')
                                                            .type('Function')
                                                            .order(2)
                                                            .configJson('{"functionName" : "MockedFunction"}')
                                                            .result(new Result()
                                                                .jobType('Function')
                                                                .status('Failed'))).persist();

            // Exercise
            Test.startTest();
            JobStep__c nextStep = RunJobController.getNextStep(job.Id, true);
            Test.stopTest();

            //Verify
            System.assertEquals('step1', nextStep.Name, 'The step name matches');
        }
    }

    // HELPER

    private static User getUser() {
        return [SELECT Id, Email FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1];
    }

    private static Event__e flowCompletionEvent(Boolean isSuccess, String errorMessage, String data) {
        Event__e result = new Event__e();
        result.Topic_Uri__c = OnJobStepComplete.STEP_ENDPOINT;
        result.Payload__c = Json.serialize(new OnJobStepComplete.EventPayload(isSuccess, errorMessage, data));

        return result;
    }

    private static MC_Result__e functionCompletionEvent(Boolean isSuccess, String errorMessage, String data) {
        MC_Result__e result = new MC_Result__e();
        result.IsFinished__c = true;
        result.Result_Data__c = data;
        result.IsSuccess__c = isSuccess;
        result.Error_Message__c = errorMessage;

        return result;
    }

    private static void credential() {
        Org__c org = new Org__c();
        org.Validated_Date__c = System.today();
        org.SFDC_Org_ID__c = UserInfo.getOrganizationId() + '_' + UserInfo.getUserId();
        org.Username__c = UserInfo.getUserName();
        org.Oauth_Signature__c = 'Valid';
        insert org;
    }
}