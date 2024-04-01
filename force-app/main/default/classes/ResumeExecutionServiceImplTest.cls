@IsTest
private class ResumeExecutionServiceImplTest {
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
                expectedResult = Jobs.Execution.resume(null);
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
    private static void resumeExecutionWithoutJobSteps() {
        System.runAs(getUser()) {
            // Setup
            Exception expectedException;
            Jobs.ExecutionResult expectedResult;

            JobTemplate__c template = (JobTemplate__c) new JobTemplate().name('Sample').persist();
            JobExecution__c job = (JobExecution__c) new JobExecution().status('Failed').template(template.Id).persist();

            // Exercise
            Test.startTest();
            try {
                expectedResult = Jobs.Execution.resume(job.Id);
            } catch (Exception ex) {
                expectedException = ex;
            }
            Test.stopTest();

            // Verify
            System.assertEquals(null, expectedResult, 'Response should be null');
            System.assertNotEquals(null, expectedException, 'An exception should be thrown');
            System.assertEquals(
                String.format(Label.JobHasNoStep, new List<String>{ 'resume' }),
                expectedException.getMessage(),
                'Exception message should match.'
            );
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
                .add(new JobStep().name('step1').type('Manual').configJson('').order(1))
                .persist();

            // Exercise
            Test.startTest();
            try {
                expectedResult = Jobs.Execution.resume(job.Id);
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
    private static void shouldFailExecutionForInvalidFunctionName() {
        User user = getUser();
        System.runAs(user) {
            // Setup
            insert new Personal_Settings__c(SetupOwnerId = user.Id, API_Key__c = DeployAPI.encryptAPIKey('000111222333'));

            JobTemplate__c template = (JobTemplate__c) new JobTemplate().name('Sample').persist();
            JobExecution__c job = (JobExecution__c) new JobExecution()
                .status('Not Started')
                .template(template.Id)
                .add(new JobStep().name('step1').type('Function').order(1).configJson('{"functionName" : "Invalid Function"}'))
                .persist();

            credential();

            // Exercise
            Test.startTest();
            Jobs.ExecutionResult response = Jobs.Execution.resume(job.Id);
            Test.stopTest();

            // Verify
            String errorMessage = Label.Function_not_Found + ' Invalid Function';
            List<Result__c> results = [SELECT Error_Message__c FROM Result__c];

            System.assertEquals('Error', response.jobExecution.Status__c, 'The Job Execution errors out.');
            System.assert(results[0].Error_Message__c.contains(errorMessage), 'Result\'s error message contains the given text.');
            System.assertEquals(results[0].Error_Message__c, response.jobExecution.ErrorMessage__c, 'The message matches.');
        }
    }

    @IsTest
    private static void resumeJobExecution() {
        User user = getUser();
        System.runAs(user) {
            // Setup
            insert new Personal_Settings__c(SetupOwnerId = user.Id, API_Key__c = DeployAPI.encryptAPIKey('000111222333'));

            new Function().apiName('MockedFunction').script('echo hi');
            JobTemplate__c template = (JobTemplate__c) new JobTemplate().name('Sample').persist();
            JobExecution__c job = (JobExecution__c) new JobExecution()
                .status('Failed')
                .template(template.Id)
                .add(
                    new JobStep()
                        .name('step1')
                        .type('Flow')
                        .order(1)
                        .configJson('{"flowName" : "MockedFlow"}')
                        .result(new Result().jobType('Flow').status('Success'))
                )
                .add(
                    new JobStep()
                        .name('step2')
                        .type('Function')
                        .order(2)
                        .configJson('{"functionName" : "MockedFunction"}')
                        .result(new Result().jobType('Function').status('Failed'))
                )
                .persist();

            credential();

            Flow.mockResponse = flowCompletionEvent(true, '', 'Success data');
            FunctionEngine.mockResponse = functionCompletionEvent(true, '', 'Sample Data');

            // Exercise
            Test.startTest();
            Jobs.ExecutionResult response = Jobs.Execution.resume(job.Id);
            Test.stopTest();

            // Verify
            JobStep__c step = [SELECT Status__c FROM JobStep__c WHERE Name = 'step2' AND JobExecution__c = :response.jobExecution.Id];
            System.assertEquals(3, [SELECT COUNT() FROM Result__c], 'The count matches.');
            System.assertEquals('Success', step.Status__c, 'Step status is successful');
            System.assertEquals('Successful', response.jobExecution.Status__c, 'Job execution status is successful.');
        }
    }

    @IsTest
    private static void shouldResetResultOnExistingStepsOnRerun() {
        System.runAs(getUser()) {
            // Setup
            JobTemplate__c template = (JobTemplate__c) new JobTemplate().name('Sample').persist();
            JobExecution__c job = (JobExecution__c) new JobExecution()
                .status('Cancelled')
                .template(template.Id)
                .add(new JobStep().name('step1').type('Manual').order(1).configJson('').result(new Result().jobType('Manual').status('Success')))
                .add(new JobStep().name('step2').type('Manual').order(2).configJson('').result(new Result().jobType('Manual').status('Failed')))
                .add(new JobStep().name('step3').type('Manual').order(3).configJson('').result(new Result().jobType('Manual').status('Cancelled')))
                .persist();

            // Exercise
            Test.startTest();
            Jobs.ExecutionResult response = Jobs.Execution.resume(job.Id);
            Test.stopTest();
            Test.getEventBus().deliver();

            // Verify
            System.assertEquals(4, [SELECT COUNT() FROM Result__c], 'There are 4 result records.');
            System.assertEquals('In Progress', response.jobExecution.Status__c, 'Job Execution is in progress.');
            System.assertEquals(null, [SELECT Result__c FROM JobStep__c WHERE Name = 'step3'].Result__c, 'No result for step3.');
            System.assertNotEquals(null, [SELECT Result__c FROM JobStep__c WHERE Name = 'step2'].Result__c, 'Step2 result exists.');
            System.assertNotEquals(null, [SELECT Result__c FROM JobStep__c WHERE Name = 'step1'].Result__c, 'Step1 result exists.');
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