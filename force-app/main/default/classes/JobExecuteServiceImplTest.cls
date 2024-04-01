@IsTest
private class JobExecuteServiceImplTest {
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
            //Setup
            Exception expectedException;
            Jobs.ExecutionResult expectedResult;
            Jobs.ExecutionRequest request = new Jobs.ExecutionRequest(null, 'test');

            // Exercise
            Test.startTest();
            try {
                expectedResult = Jobs.Execution.execute(request);
            } catch (Exception ex) {
                expectedException = ex;
            }
            Test.stopTest();

            // Verify
            System.assertEquals(null, expectedResult, 'Response should be null');
            System.assertNotEquals(null, expectedException, 'An exception should be thrown');
            System.assertEquals(Label.InvalidExecutionId, expectedException.getMessage(), 'Exception message should match.');
        }
    }

    @IsTest
    private static void executeWithEmptyJob() {
        System.runAs(getUser()) {
            //Setup
            Exception expectedException;
            Jobs.ExecutionResult expectedResult;

            JobTemplate__c template = (JobTemplate__c) new JobTemplate().name('Sample').persist();
            JobExecution__c job = (JobExecution__c) new JobExecution().status('Failed').template(template.Id).persist();

            Jobs.ExecutionRequest request = new Jobs.ExecutionRequest(job.Id, 'test');

            // Exercise
            Test.startTest();
            try {
                expectedResult = Jobs.Execution.execute(request);
            } catch (Exception ex) {
                expectedException = ex;
            }
            Test.stopTest();

            // Verify
            System.assertEquals(null, expectedResult, 'Response should be null');
            System.assertNotEquals(null, expectedException, 'An exception should be thrown');
            System.assertEquals(
                String.format(Label.JobHasNoStep, new List<String>{ 'execute' }),
                expectedException.getMessage(),
                'Exception message should match.'
            );
        }
    }

    @IsTest
    private static void testKillVolumeOption() {
        User user = getUser();
        System.runAs(user) {
            // Setup
            insert new Personal_Settings__c(SetupOwnerId = user.Id, API_Key__c = DeployAPI.encryptAPIKey('000111222333'));
            insert credential();

            ApexExpression.mockValue = 'ParameterValue';

            new Function().apiName('MockedFunction').script('echo hi');
            JobTemplate__c template = (JobTemplate__c) new JobTemplate().name('Sample').persist();
            JobExecution__c job = (JobExecution__c) new JobExecution()
                .status('Not Started')
                .template(template.Id)
                .volumeOptions('[{"name": "volumeEnabled", "value": "true"} ]')
                .add(
                    new JobStep()
                        .name('step1')
                        .type('Function')
                        .order(1)
                        .configJson('{"functionName" : "MockedFunction"}')
                        .skipCondition('{$Context.Apex.ApexExpression}')
                )
                .add(new JobStep().name('step2').type('Function').order(2).configJson('{"functionName" : "MockedFunction"}'))
                .persist();

            FunctionEngine.mockResponse = functionCompletionEvent(true, '', '');
            Jobs.ExecutionRequest request = new Jobs.ExecutionRequest(job.Id, '');

            // Exercise
            Test.startTest();
            Jobs.ExecutionResult expectedResult = Jobs.Execution.execute(request);
            Test.stopTest();

            // Verify
            List<JobStep__c> jobSteps = [
                SELECT Result__c, Result__r.Result_Data__c, IsSkipped__c, SkipCondition__c, Status__c
                FROM JobStep__c
                WHERE JobExecution__c = :expectedResult.jobExecution.Id
                ORDER BY Order__c
            ];

            System.assertEquals('Successful', expectedResult.jobExecution.Status__c, 'Job Execution is successful.');
            System.assertEquals(1, [SELECT COUNT() FROM Result__c], 'There is 1 result record.');
            System.assertEquals(null, jobSteps[0].Result__c, 'The step1 does not have an associated result.');
            System.assert(jobSteps[1].Result__r?.Result_Data__c?.contains('killVolume'), 'It contains killVolume');
            System.assertEquals(true, jobSteps[0].IsSkipped__c, 'The step1 is skipped during execution');
            System.assertEquals(false, jobSteps[1].IsSkipped__c, 'The step2 is not skipped during execution');
            System.assertEquals('{$Context.Apex.ApexExpression}', jobSteps[0].SkipCondition__c, 'The step1 has skip condition populated');
            System.assertEquals(null, jobSteps[1].SkipCondition__c, 'The step2 doesn\'t have any skip condition');
            System.assertEquals('Skipped', jobSteps[0].Status__c, 'The step1\'s status is skipped.');
            System.assertEquals('Success', jobSteps[1].Status__c, 'The step2\'s status is success.');
        }
    }

    @IsTest
    private static void shouldNotStartNextStepIfJobIsAlreadyInProgress() {
        System.runAs(getUser()) {
            // Setup
            Exception expectedException;
            Jobs.ExecutionResult expectedResult;
            JobTemplate__c template = (JobTemplate__c) new JobTemplate().name('Sample').persist();
            JobExecution__c job = (JobExecution__c) new JobExecution()
                .status('In Progress')
                .template(template.Id)
                .add(new JobStep().name('step1').type('Manual').order(1))
                .persist();

            Jobs.ExecutionRequest request = new Jobs.ExecutionRequest(job.Id, '');

            // Exercise
            Test.startTest();
            try {
                expectedResult = Jobs.Execution.execute(request);
            } catch (Exception ex) {
                expectedException = ex;
            }
            Test.stopTest();

            // Verify
            System.assertEquals(null, expectedResult, 'Response should be null');
            System.assertNotEquals(null, expectedException, 'An exception should be thrown');
            System.assertEquals(Label.JobInProgress, expectedException.getMessage(), 'Exception message should match.');
        }
    }

    @IsTest
    private static void shouldFailExecutionForInvalidFlow() {
        System.runAs(getUser()) {
            // Setup
            JobTemplate__c template = (JobTemplate__c) new JobTemplate().name('Sample').persist();
            JobExecution__c job = (JobExecution__c) new JobExecution()
                .status('Not Started')
                .template(template.Id)
                .add(new JobStep().name('step1').type('Flow').order(1).configJson('{"flowName" : "Invalid Flow"}'))
                .persist();

            Flow.mockResponse = flowCompletionEvent(false, 'Invalid Flow', '');

            Jobs.ExecutionRequest request = new Jobs.ExecutionRequest(job.Id, '');

            // Exercise
            Test.startTest();
            Jobs.ExecutionResult response = Jobs.Execution.execute(request);
            Test.getEventBus().deliver();
            Test.stopTest();

            // Verify
            JobStep__c step1 = [SELECT Status__c FROM JobStep__c WHERE Name = 'step1'];

            System.assertEquals(1, [SELECT COUNT() FROM Result__c], 'Job execution result is created.');
            System.assertEquals('Failed', step1.Status__c, 'The step status is Failed');
            System.assertEquals('Error', response.jobExecution.Status__c, 'The job execution errors out.');
            System.assertEquals('Invalid Flow', response.jobExecution.ErrorMessage__c, 'Error message matches.');
        }
    }

    @IsTest
    private static void executionForValidFlowAndInvalidSkipCondition() {
        System.runAs(getUser()) {
            // Setup
            JobTemplate__c template = (JobTemplate__c) new JobTemplate().name('Sample').persist();
            JobExecution__c job = (JobExecution__c) new JobExecution()
                .status('Not Started')
                .template(template.Id)
                .add(
                    new JobStep()
                        .name('step1')
                        .type('Flow')
                        .order(1)
                        .configJson('{"flowName":"MockedFlow","parameters":[{"name":"finalResultStatus","value":"Success"}]}')
                )
                .add(
                    new JobStep()
                        .name('Another Step')
                        .type('Flow')
                        .order(2)
                        .configJson('{"flowName":"MockedFlow"}')
                        .skipCondition('{$Invalid.Expression}')
                )
                .persist();

            Flow.mockResponse = flowCompletionEvent(true, '', 'Success data');

            Jobs.ExecutionRequest request = new Jobs.ExecutionRequest(job.Id, '');

            // Exercise
            Test.startTest();
            Jobs.ExecutionResult response = Jobs.Execution.execute(request);
            Test.getEventBus().deliver();
            Test.stopTest();

            // Verify
            List<JobStep__c> jobSteps = [
                SELECT Name, Result__c, IsSkipped__c, SkipCondition__c, Status__c
                FROM JobStep__c
                WHERE JobExecution__c = :response.jobExecution.Id
                ORDER BY Order__c
            ];

            System.assertEquals(1, [SELECT COUNT() FROM Result__c], 'There is only 1 result created for job step 1');
            System.assertEquals('Error', response.jobExecution.Status__c, 'The job execution errored out.');
            System.assertEquals(
                String.format(Label.Skip_Condition_Error, new List<String>{ jobSteps[1].Name, 'Invalid expression:' + jobSteps[1].SkipCondition__c }),
                response.jobExecution.ErrorMessage__c,
                'The error message matches.'
            );

            System.assertEquals('Success', jobSteps[0].Status__c, 'The step 1 status is success');
            System.assertEquals('Pending', jobSteps[1].Status__c, 'The step 2 status is pending');

            System.assertNotEquals(null, jobSteps[0].Result__c, 'The step 1 has a related result');
            System.assertEquals(null, jobSteps[1].Result__c, 'The step 2 has no related result');

            System.assertEquals(false, jobSteps[0].IsSkipped__c, 'The step 1 is not skipped during execution');
            System.assertEquals(false, jobSteps[1].IsSkipped__c, 'The step 2 is not skipped during execution');

            System.assertEquals(null, jobSteps[0].SkipCondition__c, 'The step 1 does not have any skip condition');
            System.assertEquals(
                '{$Invalid.Expression}',
                jobSteps[1].SkipCondition__c,
                'The step 2 has a skip condition which evaluated to a falsy value'
            );
        }
    }

    @IsTest
    private static void shouldCompleteIfAllStepsSucceed() {
        User user = getUser();
        System.runAs(user) {
            // Setup
            insert new Personal_Settings__c(SetupOwnerId = user.Id, API_Key__c = DeployAPI.encryptAPIKey('000111222333'));

            new SystemProperty().value('sql server').apiName('DB').sensitive(false).globalProperty(true);

            new Function().apiName('MockedFunction').script('echo hi');
            JobTemplate__c template = (JobTemplate__c) new JobTemplate().name('Sample').persist();

            JobExecution__c job = (JobExecution__c) new JobExecution()
                .status('Not Started')
                .template(template.Id)
                .volumeOptions('[{"name": "transactionId", "value": "000111222333"} ]')
                .add(new JobStep().name('step1').type('Function').order(1).configJson('{"functionName" : "MockedFunction"}'))
                .add(
                    new JobStep()
                        .name('step2')
                        .type('Function')
                        .order(2)
                        .configJson('{"functionName" : "MockedFunction"}')
                        .skipCondition('{$Global.Property.DB.matches(sql*)}')
                )
                .add(
                    new JobStep()
                        .name('check')
                        .type('Function')
                        .order(3)
                        .configJson('{"functionName" : "MockedFunction"}')
                        .skipCondition('{$Global.Property.DB.matches(testsql*)}')
                )
                .add(new JobStep().name('function step').type('Function').order(4).configJson('{"functionName" : "MockedFunction"}'))
                .persist();

            FunctionEngine.mockResponse = functionCompletionEvent(true, '', 'Success data 2');
            Jobs.ExecutionRequest request = new Jobs.ExecutionRequest(job.Id, '');

            // Exercise
            Test.startTest();
            Jobs.ExecutionResult response = Jobs.Execution.execute(request);
            Test.getEventBus().deliver();
            Test.stopTest();
            Test.getEventBus().deliver();

            // Verify
            List<JobStep__c> jobSteps = [
                SELECT Result__c, Result__r.Result_Data__c, IsSkipped__c, SkipCondition__c, Status__c
                FROM JobStep__c
                WHERE JobExecution__c = :response.jobExecution.Id
                ORDER BY Order__c
            ];

            System.assertEquals(3, [SELECT COUNT() FROM Result__c], 'Result record for three steps (out of four) are created.');
            System.assertEquals('Successful', response.jobExecution.Status__c, 'Job Execution is successful.');

            System.assertEquals('Success', jobSteps[0].Status__c, 'First step is successful.');
            System.assertEquals('Skipped', jobSteps[1].Status__c, 'Second step is skipped.');
            System.assertEquals('Success', jobSteps[2].Status__c, 'Third step is successful.');
            System.assertEquals('Success', jobSteps[3].Status__c, 'Fourth step is successful.');

            System.assertEquals(false, jobSteps[0].IsSkipped__c, 'First step is not skipped.');
            System.assertEquals(true, jobSteps[1].IsSkipped__c, 'Second step is skipped.');
            System.assertEquals(false, jobSteps[2].IsSkipped__c, 'Third step is not skipped.');
            System.assertEquals(false, jobSteps[3].IsSkipped__c, 'Fourth step is not skipped.');

            System.assertEquals(null, jobSteps[0].SkipCondition__c, 'First step has no skip condition.');
            System.assertEquals('{$Global.Property.DB.matches(sql*)}', jobSteps[1].SkipCondition__c, 'Second step has a truthy skip condition.');
            System.assertEquals('{$Global.Property.DB.matches(testsql*)}', jobSteps[2].SkipCondition__c, 'Third step has a falsy skip condition.');
            System.assertEquals(null, jobSteps[3].SkipCondition__c, 'Fourth step has no skip condition.');

            System.assertEquals('Success data 2', jobSteps[0].Result__r.Result_Data__c, 'The Result Data matches.');
            System.assertEquals(null, jobSteps[1].Result__c, 'Second step has no result.');
            System.assertEquals('Success data 2', jobSteps[2].Result__r.Result_Data__c, 'The Result Data matches.');
            System.assertEquals('Success data 2', jobSteps[3].Result__r.Result_Data__c, 'The Result Data matches.');
        }
    }

    @IsTest
    private static void shouldFailIfFunctionStepFails() {
        User user = getUser();
        System.runAs(user) {
            // Setup
            insert new Personal_Settings__c(SetupOwnerId = user.Id, API_Key__c = DeployAPI.encryptAPIKey('000111222333'));

            new Function().apiName('MockedFunction').script('echo hi');
            JobTemplate__c template = (JobTemplate__c) new JobTemplate().name('Sample').persist();

            JobExecution__c job = (JobExecution__c) new JobExecution()
                .status('Not Started')
                .template(template.Id)
                .add(new JobStep().name('step1').type('Function').order(1).configJson('{"functionName" : "MockedFunction"}'))
                .add(new JobStep().name('step2').type('Function').order(2).configJson('{"functionName" : "MockedFunction"}'))
                .persist();

            FunctionEngine.mockResponse = functionCompletionEvent(false, 'Custom error', '');
            Jobs.ExecutionRequest request = new Jobs.ExecutionRequest(job.Id, '');

            // Exercise
            Test.startTest();
            Jobs.ExecutionResult response = Jobs.Execution.execute(request);
            Test.stopTest();

            // Verify
            JobStep__c step1 = [SELECT Status__c, Result__r.Result_Data__c, Result__r.Error_Message__c FROM JobStep__c WHERE Name = 'step1'];

            System.assertEquals(1, [SELECT COUNT() FROM Result__c], 'Result record is created.');
            System.assertEquals('Error', response.jobExecution.Status__c, 'Job execution errors out.');
            System.assertEquals('Failed', step1.Status__c, 'Step 1 fails.');
            System.assertEquals('Custom error', step1.Result__r.Error_Message__c, 'The error message matches.');
            System.assertEquals('Custom error', response.jobExecution.ErrorMessage__c, 'The error message matches.');
        }
    }

    @IsTest
    private static void testSkipConditions() {
        User user = getUser();
        System.runAs(user) {
            // Setup
            insert new Personal_Settings__c(SetupOwnerId = user.Id, API_Key__c = DeployAPI.encryptAPIKey('000111222333'));

            ApexExpression.mockValue = '0';

            new Function().apiName('MockedFunction').script('echo hi');
            JobTemplate__c template = (JobTemplate__c) new JobTemplate().name('Sample').persist();
            JobExecution__c job = (JobExecution__c) new JobExecution()
                .status('Not Started')
                .template(template.Id)
                .volumeOptions('[{"name": "volumeEnabled", "value": "true"} ]')
                .add(
                    new JobStep()
                        .name('step1')
                        .type('Function')
                        .order(1)
                        .configJson('{"functionName" : "MockedFunction"}')
                        .skipCondition('{$CONTEXT.APEX.ApexExpression.matches("0")}')
                )
                .add(
                    new JobStep()
                        .name('step2')
                        .type('Function')
                        .order(2)
                        .configJson('{"functionName" : "MockedFunction"}')
                        .skipCondition('Test with hardcoded string')
                )
                .add(
                    new JobStep()
                        .name('step3')
                        .type('Function')
                        .order(3)
                        .configJson('{"functionName" : "MockedFunction"}')
                        .skipCondition('{$Context.Apex.ApexExpression}')
                )
                .add(
                    new JobStep()
                        .name('step4')
                        .type('Function')
                        .order(4)
                        .configJson('{"functionName" : "MockedFunction"}')
                        .skipCondition('{$Source.Branch.matches(dev*)}')
                )
                .add(
                    new JobStep()
                        .name('step5')
                        .type('Function')
                        .order(5)
                        .configJson('{"functionName" : "MockedFunction"}')
                        .skipCondition('{$User.invalid.matches(dev*)}')
                )
                .persist();

            FunctionEngine.mockResponse = functionCompletionEvent(true, '', 'Success data');
            Jobs.ExecutionRequest request = new Jobs.ExecutionRequest(job.Id, '');

            // Exercise
            Test.startTest();
            Jobs.ExecutionResult expectedResult = Jobs.Execution.execute(request);
            Test.stopTest();

            // Verify
            List<JobStep__c> jobSteps = [
                SELECT Name, Result__c, Result__r.Result_Data__c, IsSkipped__c, SkipCondition__c, Status__c
                FROM JobStep__c
                WHERE JobExecution__c = :expectedResult.jobExecution.Id
                ORDER BY Order__c
            ];
            String message = 'No such column \'invalid\' on entity \'User\'. If you are attempting to use a custom field, be sure to append the \'__c\' after the custom field name. Please reference your WSDL or the describe call for the appropriate names.';

            System.assertEquals('Error', expectedResult.jobExecution.Status__c, 'Job Execution errors out.');
            System.assert(expectedResult.jobExecution.ErrorMessage__c.contains(message), 'The error message matches.');
            System.assertEquals(2, [SELECT COUNT() FROM Result__c], 'There are 2 result records created for 5 job steps.');

            System.assertEquals(null, jobSteps[0].Result__c, 'The step1 does not have an associated result.');
            System.assertEquals(null, jobSteps[1].Result__c, 'The step2 does not have an associated result.');
            System.assertEquals('Success data', jobSteps[2].Result__r.Result_Data__c, 'The Result Data matches.');
            System.assertEquals('Success data', jobSteps[3].Result__r.Result_Data__c, 'The Result Data matches.');
            System.assertEquals(null, jobSteps[4].Result__c, 'The step5 does not have an associated result.');

            System.assertEquals(true, jobSteps[0].IsSkipped__c, 'The step1 is skipped during execution as the skip condition is a truthy');
            System.assertEquals(true, jobSteps[1].IsSkipped__c, 'The step2 is skipped during execution as the skip condition is a truthy');
            System.assertEquals(false, jobSteps[2].IsSkipped__c, 'The step3 is not skipped during execution as the skip condition is a falsy');
            System.assertEquals(false, jobSteps[3].IsSkipped__c, 'The step4 is not skipped during execution as the skip condition is a falsy');
            System.assertEquals(
                false,
                jobSteps[4].IsSkipped__c,
                'The step5 is not skipped during execution as it encountered an error during exp evaluation'
            );

            System.assertEquals(
                '{$CONTEXT.APEX.ApexExpression.matches("0")}',
                jobSteps[0].SkipCondition__c,
                'The step1 has skip condition populated'
            );
            System.assertEquals('Test with hardcoded string', jobSteps[1].SkipCondition__c, 'The step2 has skip condition populated');
            System.assertEquals('{$Context.Apex.ApexExpression}', jobSteps[2].SkipCondition__c, 'The step3 has skip condition populated');
            System.assertEquals('{$Source.Branch.matches(dev*)}', jobSteps[3].SkipCondition__c, 'The step4 has skip condition populated');
            System.assertEquals('{$User.invalid.matches(dev*)}', jobSteps[4].SkipCondition__c, 'The step5 has skip condition populated');

            System.assertEquals('Skipped', jobSteps[0].Status__c, 'The step1\'s status is skipped.');
            System.assertEquals('Skipped', jobSteps[1].Status__c, 'The step2\'s status is skipped.');
            System.assertEquals('Success', jobSteps[2].Status__c, 'The step3\'s status is success.');
            System.assertEquals('Success', jobSteps[3].Status__c, 'The step4\'s status is success.');
            System.assertEquals('Pending', jobSteps[4].Status__c, 'The step5\'s status is pending.');
        }
    }

    @IsTest
    private static void testStepExpressionSkipConditions() {
        User user = getUser();
        System.runAs(user) {
            // Setup
            insert new Personal_Settings__c(SetupOwnerId = user.Id, API_Key__c = DeployAPI.encryptAPIKey('000111222333'));

            new Function().apiName('MockedFunction').script('echo hi');
            JobTemplate__c template = (JobTemplate__c) new JobTemplate().name('Sample').persist();
            JobExecution__c job = (JobExecution__c) new JobExecution()
                .status('Not Started')
                .template(template.Id)
                .volumeOptions('[{"name": "volumeEnabled", "value": "true"} ]')
                .add(
                    new JobStep()
                        .name('step1')
                        .type('Function')
                        .order(1)
                        .configJson('{"functionName" : "MockedFunction"}')
                        .skipCondition('{$User.Name.matches("*")}')
                )
                .add(
                    new JobStep()
                        .name('step2')
                        .type('Function')
                        .order(2)
                        .configJson('{"functionName" : "MockedFunction"}')
                        .skipCondition('{$Job.PrevStep.Status__c.matches("Skipped")}')
                )
                .add(new JobStep().name('step3').type('Function').order(3).configJson('{"functionName" : "MockedFunction"}'))
                .persist();

            FunctionEngine.mockResponse = functionCompletionEvent(true, '', 'Success data');
            Jobs.ExecutionRequest request = new Jobs.ExecutionRequest(job.Id, '');

            // Exercise
            Test.startTest();
            Jobs.ExecutionResult expectedResult = Jobs.Execution.execute(request);
            Test.stopTest();

            // Verify
            List<JobStep__c> jobSteps = [
                SELECT Name, Result__c, Result__r.Result_Data__c, IsSkipped__c, SkipCondition__c, Status__c
                FROM JobStep__c
                WHERE JobExecution__c = :expectedResult.jobExecution.Id
                ORDER BY Order__c
            ];

            System.assertEquals('Successful', expectedResult.jobExecution.Status__c, 'Job Execution is successful.');
            System.assertEquals(2, [SELECT COUNT() FROM Result__c], 'There are 2 result records created for 3 job steps.');

            System.assertEquals(null, jobSteps[0].Result__c, 'The step1 does not have an associated result.');
            System.assertEquals('Success data', jobSteps[1].Result__r.Result_Data__c, 'The Result Data matches.');
            System.assertEquals('Success data', jobSteps[2].Result__r.Result_Data__c, 'The Result Data matches.');

            System.assertEquals(true, jobSteps[0].IsSkipped__c, 'The step1 is skipped during execution as the skip condition is a truthy');
            System.assertEquals(
                false,
                jobSteps[1].IsSkipped__c,
                'The step2 is not skipped during execution as the prev step status has not updated in the db yet'
            );
            System.assertEquals(false, jobSteps[2].IsSkipped__c, 'The step3 is not skipped during execution as the skip condition is a falsy');

            System.assertEquals('{$User.Name.matches("*")}', jobSteps[0].SkipCondition__c, 'The step1 has skip condition populated');
            System.assertEquals(
                '{$Job.PrevStep.Status__c.matches("Skipped")}',
                jobSteps[1].SkipCondition__c,
                'The step2 has skip condition populated'
            );
            System.assertEquals(null, jobSteps[2].SkipCondition__c, 'The step3 has no skip condition populated');

            System.assertEquals('Skipped', jobSteps[0].Status__c, 'The step1\'s status is skipped.');
            System.assertEquals('Success', jobSteps[1].Status__c, 'The step2\'s status is success.');
            System.assertEquals('Success', jobSteps[2].Status__c, 'The step3\'s status is success.');
        }
    }

    @IsTest
    private static void blockQueueOnStepError() {
        User user = getUser();
        System.runAs(user) {
            // Setup
            insert new Personal_Settings__c(SetupOwnerId = user.Id, API_Key__c = DeployAPI.encryptAPIKey('000111222333'));

            new Function().apiName('MockedFunction').script('echo hi');
            JobTemplate__c template = (JobTemplate__c) new JobTemplate().name('Sample').persist();

            JobExecution__c job = (JobExecution__c) new JobExecution()
                .status('Not Started')
                .template(template.Id)
                .add(
                    new JobStep()
                        .name('step1')
                        .type('Function')
                        .order(1)
                        .configJson('{"functionName" : "MockedFunction", "sharedResource": "R1", "blockQueueOnError": true}')
                )
                .add(new JobStep().name('step2').type('Function').order(2).configJson('{"functionName" : "MockedFunction", "sharedResource": "R1"}'))
                .persist();

            FunctionEngine.mockResponse = functionCompletionEvent(false, 'Custom error', '');
            Jobs.ExecutionRequest request = new Jobs.ExecutionRequest(job.Id, '');

            // Exercise
            Test.startTest();
            Jobs.ExecutionResult response = Jobs.Execution.execute(request);
            Test.stopTest();

            // Verify
            List<Queue__c> queues = [SELECT Status__c, Resource__c FROM Queue__c];

            System.assertEquals(1, [SELECT COUNT() FROM Result__c], 'Result record is created.');
            System.assertEquals('Error', response.jobExecution.Status__c, 'Job execution errors out.');
            System.assertEquals('Custom error', response.jobExecution.ErrorMessage__c, 'The error message matches.');

            Assert.areEqual(1, queues.size(), 'Queue should have one element');
            Assert.areEqual('Blocked', queues[0].Status__c, 'Queue should be blocked');
            Assert.areEqual('R1', queues[0].Resource__c, 'Queue should be blocked');
        }
    }

    @IsTest
    private static void releaseQueueOnStepSuccess() {
        User user = getUser();
        System.runAs(user) {
            // Setup
            insert new Personal_Settings__c(SetupOwnerId = user.Id, API_Key__c = DeployAPI.encryptAPIKey('000111222333'));

            new Function().apiName('MockedFunction').script('echo hi');
            JobTemplate__c template = (JobTemplate__c) new JobTemplate().name('Sample').persist();

            JobExecution__c job = (JobExecution__c) new JobExecution()
                .status('Not Started')
                .template(template.Id)
                .add(new JobStep().name('step1').type('Function').order(1).configJson('{"functionName" : "MockedFunction", "sharedResource": "R1"}'))
                .add(new JobStep().name('step2').type('Function').order(2).configJson('{"functionName" : "MockedFunction", "sharedResource": "R1"}'))
                .persist();

            FunctionEngine.mockResponse = functionCompletionEvent(true, '', '');
            Jobs.ExecutionRequest request = new Jobs.ExecutionRequest(job.Id, '');

            // Exercise
            Test.startTest();
            Jobs.Execution.execute(request);
            Test.getEventBus().deliver();
            Test.stopTest();

            // Verify
            List<Queue__c> queues = [SELECT Status__c, Resource__c FROM Queue__c];

            Assert.areEqual(1, queues.size(), 'Queue should have one element');
            Assert.areEqual('Queued', queues[0].Status__c, 'Queue should be ready to start');
            Assert.areEqual('R1', queues[0].Resource__c, 'Queue should be blocked');
        }
    }

    @IsTest
    private static void blockQueueForTransaction() {
        User user = getUser();
        System.runAs(user) {
            // Setup
            insert new Personal_Settings__c(SetupOwnerId = user.Id, API_Key__c = DeployAPI.encryptAPIKey('000111222333'));

            new Function().apiName('MockedFunction').script('echo hi');
            JobTemplate__c template = (JobTemplate__c) new JobTemplate().name('Sample').persist();

            JobExecution__c job = (JobExecution__c) new JobExecution()
                .status('Not Started')
                .template(template.Id)
                .volumeOptions('[{"name" : "transactionId", "value" : "T1"} ]')
                .dataJson('{"blockQueueForTransaction": true}')
                .add(new JobStep().name('step1').type('Function').order(1).configJson('{"functionName" : "MockedFunction", "sharedResource": "R1"}'))
                .add(new JobStep().name('step2').type('Function').order(2).configJson('{"functionName" : "MockedFunction", "sharedResource": "R1"}'))
                .persist();

            FunctionEngine.mockResponse = functionCompletionEvent(false, 'Custom error', '');
            Jobs.ExecutionRequest request = new Jobs.ExecutionRequest(job.Id, '');

            // Exercise
            Test.startTest();
            Jobs.ExecutionResult response = Jobs.Execution.execute(request);
            Test.stopTest();

            // Verify
            List<Queue__c> queues = [SELECT Status__c, Transaction__c, Resource__c FROM Queue__c];

            System.assertEquals(1, [SELECT COUNT() FROM Result__c], 'Result record is created.');
            System.assertEquals('Error', response.jobExecution.Status__c, 'Job execution errors out.');
            System.assertEquals('Custom error', response.jobExecution.ErrorMessage__c, 'The error message matches.');

            /*Assert.areEqual(1, queues.size(), 'Queue should have one element');
            Assert.areEqual('Blocked', queues[0].Status__c, 'Queue should be blocked');
            Assert.areEqual('T1', queues[0].Transaction__c, 'Queue should be blocked');
            Assert.areEqual('R1', queues[0].Resource__c, 'Queue should be blocked');*/
        }
    }

    //HELPER

    private static User getUser() {
        return [SELECT Id, Email FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1];
    }

    private static Org__c credential() {
        return new Org__c(
            Oauth_Signature__c = 'Valid',
            Validated_Date__c = System.today(),
            Username__c = UserInfo.getUserName(),
            SFDC_Org_ID__c = UserInfo.getOrganizationId() + '_' + UserInfo.getUserId()
        );
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
}