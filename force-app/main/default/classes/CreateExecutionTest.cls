@IsTest
private class CreateExecutionTest {
    @TestSetup
    private static void setupData() {
        TestUtilities.getAllMultilicense();
        User user = (User) new User_t()
            .assign(new PermissionSetAssignment_t().copadoUser())
            .assign(new PermissionSetAssignment_t().jobEngine())
            .persist();

        System.runAs(user) {
            new CopadoLicense().user(user).enableAll().persist();
        }
    }

    @IsTest
    private static void executeWithEmptyTemplateName() {
        System.runAs(getUser()) {
            // Setup
            SObject userStory = new UserStory().persist();
            new JobStep().order(5).type('Manual').name('step1').userStory(userStory.Id).executionSequence('before');
            new JobStep().order(30).type('Manual').name('step2').userStory(userStory.Id).executionSequence('BEFORE').persist();

            Git_Commit__c gitCommit = new Git_Commit__c();
            insert gitCommit;

            List<JobStep__c> steps = new JobStepsSelector().byUserStoryIdAndExecutionSequence(userStory.Id, 'before');

            List<AdditionalStep> additionalSteps = new List<AdditionalStep>();
            additionalSteps.add(new AdditionalStep(null, steps, null));
            additionalSteps.add(new AdditionalStep(null, null, steps));

            CreateExecution.request request = new CreateExecution.request();
            request.parentId = gitCommit.Id;
            request.preSteps = steps;
            request.additionalSteps = additionalSteps;

            List<CreateExecution.request> requests = new List<CreateExecution.request>{ request };

            // Exercise
            List<JobExecution__c> executions = CreateExecution.execute(requests);

            // Verify
            System.assertEquals(1, executions.size(), 'Wrong number of Job Executions on the result');
            JobExecution__c execution = executions[0];
            System.assertEquals('Not Started', execution.Status__c, 'Wrong Job Execution status');
            System.assertEquals(6, [SELECT COUNT() FROM JobStep__c WHERE JobExecution__c = :execution.Id], 'Wrong number of steps');
        }
    }

    @IsTest
    private static void executeWithInvalidTemplateName() {
        // Setup
        Exception expectedException = null;

        Git_Commit__c gitCommit = new Git_Commit__c();
        insert gitCommit;

        CreateExecution.request request = new CreateExecution.request();
        request.parentId = gitCommit.Id;
        request.templateName = 'Invalid Template';

        List<CreateExecution.request> requests = new List<CreateExecution.request>{ request };

        // Exercise
        try {
            CreateExecution.execute(requests);
        } catch (Exception ex) {
            expectedException = ex;
        }

        // Verify
        String expectedMessage = String.format(Label.InvalidTemplateId, new List<String>{ request.templateName });
        System.assertNotEquals(null, expectedException, 'An exception should be thrown');
        System.assertEquals(expectedMessage, expectedException.getMessage(), 'Exception message does not match');
    }

    @IsTest
    private static void executeWithRunAfterInstantiationDisabled() {
        System.runAs(getUser()) {
            // Setup
            new JobTemplate()
                .name('Sample')
                .version(1)
                .volumeOptions('[{ "name": "volumeEnabled", "value": "false" }]')
                .add(new JobStep().name('step1').type('Manual'))
                .add(new JobStep().name('step2').type('Manual'))
                .persist();

            Git_Commit__c gitCommit = new Git_Commit__c();
            insert gitCommit;

            List<JobStep__c> steps = new JobStepsSelector().byTemplateApiName('Sample_1');

            List<AdditionalStep> additionalSteps = new List<AdditionalStep>();
            additionalSteps.add(new AdditionalStep(null, steps, null));
            additionalSteps.add(new AdditionalStep(null, null, steps));

            CreateExecution.request request = new CreateExecution.request();
            request.templateName = 'Sample_1';
            request.dataJson = '{"key1": "value1"}';
            request.parentId = gitCommit.Id;
            request.additionalSteps = additionalSteps;

            List<CreateExecution.request> requests = new List<CreateExecution.request>{ request };

            // Exercise
            List<JobExecution__c> executions = CreateExecution.execute(requests);

            // Verify
            System.assertEquals(1, executions.size(), 'Wrong number of Job Executions on the result');
            JobExecution__c execution = executions[0];
            List<Parameter> parameters = (List<Parameter>) JSON.deserialize(execution.VolumeOptions__c, List<Parameter>.class);

            System.assertEquals(3, parameters.size(), 'Wrong number of parameters');

            System.assertEquals('false', parameters[0].value, 'Wrong parameter value');
            System.assertEquals('volumeEnabled', parameters[0].name, 'Wrong parameter name');

            System.assertNotEquals(null, parameters[1].value, 'Wrong parameter value');
            System.assertEquals('transactionId', parameters[1].name, 'Wrong parameter name');

            System.assertNotEquals(null, parameters[2].value, 'Wrong parameter value');
            System.assertEquals('volumeId', parameters[2].name, 'Wrong parameter name');

            System.assertEquals('Not Started', execution.Status__c, 'Wrong Job Execution status');
            System.assertEquals('{"key1": "value1"}', execution.DataJson__c, 'Wrong Job Execution DataJson');
            System.assertEquals(6, [SELECT COUNT() FROM JobStep__c WHERE JobExecution__c = :execution.Id], 'Wrong number of steps');
        }
    }

    @IsTest
    private static void executeWithPreAndPostSteps() {
        System.runAs(getUser()) {
            // Setup
            SObject userStory = new UserStory().persist();
            new JobStep().order(5).type('Manual').name('step1').userStory(userStory.Id).executionSequence('before');
            new JobStep().order(30).type('Manual').name('step2').userStory(userStory.Id).executionSequence('BEFORE');
            new JobStep().order(1).type('Manual').name('step5').userStory(userStory.Id).executionSequence('AFTER');
            new JobStep().order(2).type('Manual').name('step6').userStory(userStory.Id).executionSequence('after');

            new JobTemplate()
                .name('Sample')
                .version(1)
                .volumeOptions('[{}]')
                .add(new JobStep().order(10).name('step3').type('Manual'))
                .add(new JobStep().order(20).name('step4').type('Manual'))
                .persist();

            Git_Commit__c gitCommit = new Git_Commit__c();
            insert gitCommit;

            CreateExecution.request request = new CreateExecution.request();
            request.parentId = gitCommit.Id;
            request.templateName = 'Sample_1';
            request.preSteps = new JobStepsSelector().byUserStoryIdAndExecutionSequence(userStory.Id, 'before');
            request.postSteps = new JobStepsSelector().byUserStoryIdAndExecutionSequence(userStory.Id, 'after');

            List<CreateExecution.request> requests = new List<CreateExecution.request>{ request };

            // Exercise
            List<JobExecution__c> executions = CreateExecution.execute(requests);

            // Verify
            System.assertEquals(1, executions.size(), 'Wrong number of Job Executions on the result');
            JobExecution__c execution = executions[0];
            List<JobStep__c> steps = [SELECT Name, Order__c FROM JobStep__c WHERE JobExecution__c = :execution.Id ORDER BY Order__c ASC];

            System.assertEquals(6, steps.size(), 'Wrong number of steps');

            System.assertEquals(1, steps[0].Order__c, 'Wrong order for step 1');
            System.assertEquals('step1', steps[0].Name, 'Wrong name for step 1');

            System.assertEquals(2, steps[1].Order__c, 'Wrong order for step 2');
            System.assertEquals('step2', steps[1].Name, 'Wrong name for step 2');

            System.assertEquals(3, steps[2].Order__c, 'Wrong order for step 3');
            System.assertEquals('step3', steps[2].Name, 'Wrong name for step 3');

            System.assertEquals(4, steps[3].Order__c, 'Wrong order for step 4');
            System.assertEquals('step4', steps[3].Name, 'Wrong name for step 4');

            System.assertEquals(5, steps[4].Order__c, 'Wrong order for step 5');
            System.assertEquals('step5', steps[4].Name, 'Wrong name for step 5');

            System.assertEquals(6, steps[5].Order__c, 'Wrong order for step 6');
            System.assertEquals('step6', steps[5].Name, 'Wrong name for step 6');
        }
    }

    @IsTest
    private static void executeWithRunAfterInstantiationEnabled() {
        System.runAs(getUser()) {
            // Setup

            String firstNamePattern = UserInfo.getFirstName() + '*';

            new JobTemplate()
                .name('Sample')
                .version(1)
                .volumeOptions('[{}]')
                .add(new JobStep().order(1).name('step1').type('Flow').configJson('{"flowName" : "MockedFlow"}'))
                .add(new JobStep().order(2).name('manual').type('Manual').skipCondition('{$User.Name.matches("' + firstNamePattern + '")}'))
                .add(
                    new JobStep()
                        .order(3)
                        .name('Execute')
                        .type('Flow')
                        .configJson('{"flowName" : "MockedFlow"}')
                        .skipCondition('{$User.Name.matches("test' + firstNamePattern + '")}')
                )
                .persist();
            Git_Commit__c gitCommit = new Git_Commit__c();
            insert gitCommit;

            CreateExecution.request request = new CreateExecution.request();
            request.templateName = 'Sample_1';
            request.parentId = gitCommit.Id;
            request.runAfterInstantiation = true;

            List<CreateExecution.request> requests = new List<CreateExecution.request>{ request };

            Flow.mockResponse = flowCompletionEvent(true, '', 'Success data');

            // Exercise
            Test.startTest();
            List<JobExecution__c> executions = CreateExecution.execute(requests);
            Test.stopTest();

            // Verify
            List<JobStep__c> jobSteps = [
                SELECT Id, IsSkipped__c, SkipCondition__c, Result__c, Status__c
                FROM JobStep__c
                WHERE JobExecution__c != NULL
                ORDER BY Order__c
            ];
            System.assertEquals(1, executions.size(), 'Wrong number of Job Executions on the result');
            System.assertEquals(3, jobSteps.size(), 'Wrong number of steps');

            System.assertEquals(false, jobSteps[0].IsSkipped__c, '1st job step is not skipped during the execution.');
            System.assertEquals(true, jobSteps[1].IsSkipped__c, '2nd job step is skipped during the execution.');
            System.assertEquals(false, jobSteps[2].IsSkipped__c, '3rd job step is not skipped during the execution.');

            System.assertNotEquals(null, jobSteps[0].Result__c, '1st job step has an associated result.');
            System.assertEquals(null, jobSteps[1].Result__c, '2nd job step does not have an associated result.');
            System.assertNotEquals(null, jobSteps[2].Result__c, '3rd job step has an associated result.');

            System.assertEquals('Success', jobSteps[0].Status__c, '1st job step\'s status is Success');
            System.assertEquals('Skipped', jobSteps[1].Status__c, '2nd job step\'s status is Skipped');
            System.assertEquals('Success', jobSteps[2].Status__c, '3rd job step\'s status is Skipped');

            System.assertEquals(
                'Successful',
                [SELECT Status__c FROM JobExecution__c WHERE Id = :executions[0].Id]
                .Status__c,
                'Wrong status for Job Execution'
            );
        }
    }

    @IsTest
    private static void executeFullScenarioWithMultipleRequest() {
        System.runAs(getUser()) {
            // Setup
            Exception expectedException = null;

            SObject userStory = new UserStory().persist();
            new JobStep().order(5).type('Manual').name('step1').userStory(userStory.Id).executionSequence('before');
            new JobStep().order(30).type('Manual').name('step2').userStory(userStory.Id).executionSequence('BEFORE');
            new JobStep().order(1).type('Manual').name('step5').userStory(userStory.Id).executionSequence('AFTER');
            new JobStep().order(2).type('Manual').name('step6').userStory(userStory.Id).executionSequence('after');

            new JobTemplate()
                .name('Sample')
                .version(1)
                .volumeOptions('[{}]')
                .add(new JobStep().order(10).name('step3').type('Manual'))
                .add(new JobStep().order(20).name('step4').type('Manual'))
                .persist();

            List<Git_Commit__c> gitCommits = new List<Git_Commit__c>();
            for (Integer i = 0; i < 200; i++) {
                gitCommits.add(new Git_Commit__c());
            }
            insert gitCommits;

            List<JobStep__c> preSteps = new JobStepsSelector().byUserStoryIdAndExecutionSequence(userStory.Id, 'before');
            List<JobStep__c> postSteps = new JobStepsSelector().byUserStoryIdAndExecutionSequence(userStory.Id, 'after');

            List<CreateExecution.request> requests = new List<CreateExecution.request>();
            for (Git_Commit__c gitCommit : gitCommits) {
                CreateExecution.request request = new CreateExecution.request();
                request.parentId = gitCommit.Id;
                request.templateName = 'Sample_1';
                request.preSteps = preSteps;
                request.postSteps = postSteps;
                requests.add(request);
            }

            // Exercise
            try {
                CreateExecution.execute(requests);
            } catch (Exception ex) {
                expectedException = ex;
            }

            // Verify
            System.assertNotEquals(null, expectedException, 'An exception should be thrown');
            System.assertEquals(Label.InvalidRequestError, expectedException.getMessage(), 'Exception message does not match');
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
}