@IsTest
private class CreateJobWithoutTemplateServiceImplTest {
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
            createData();
        }
    }

    @IsTest
    private static void executeWithEmptyRequest() {
        System.runAs(getUser()) {
            // Setup

            Exception expectedException;
            Jobs.ExecutionCreateResult result;

            // Exercise
            Test.startTest();
            try {
                result = Jobs.Execution.create(new Jobs.ExecutionCreateRequest());
            } catch (Exception ex) {
                expectedException = ex;
            }
            Test.stopTest();

            // Verify
            System.assertEquals(null, expectedException, 'There is no exception.');
            System.assertEquals(
                0,
                [SELECT COUNT() FROM JobStep__c WHERE JobExecution__c = :result.jobExecution.id],
                'There are no steps in the job execution.'
            );
            System.assertEquals('Not Started', result.jobExecution.Status__c, 'Job Execution status is Not Started.');
            System.assertEquals(null, result.jobExecution.Source__c, 'Job Execution DataJson matches.');
            System.assertEquals(null, result.jobExecution.Destination__c, 'Job Execution DataJson matches.');
            System.assertEquals(null, result.jobExecution.Pipeline__c, 'Job Execution DataJson matches.');
            System.assertEquals(null, result.jobExecution.ParentRecord_Id__c, 'Parent Id matches.');
            System.assertEquals(null, result.jobExecution.Callback__c, 'Job Execution callback matches.');
            System.assertEquals(null, result.jobExecution.DataJson__c, 'Job Execution DataJson matches.');
        }
    }

    @IsTest
    private static void executeWithoutSteps() {
        System.runAs(getUser()) {
            // Setup

            Exception expectedException;
            Jobs.ExecutionCreateResult result;

            Git_Commit__c gitCommit = new Git_Commit__c();
            insert gitCommit;

            Jobs.ExecutionCreateRequest request = new Jobs.ExecutionCreateRequest();
            request.parentId = gitCommit.Id;

            // Exercise
            Test.startTest();
            try {
                result = Jobs.Execution.create(request);
            } catch (Exception ex) {
                expectedException = ex;
            }
            Test.stopTest();

            // Verify
            System.assertEquals(null, expectedException, 'There is no exception.');
            System.assertEquals(
                0,
                [SELECT COUNT() FROM JobStep__c WHERE JobExecution__c = :result.jobExecution.id],
                'There are no steps in the job execution.'
            );
            System.assertEquals('Not Started', result.jobExecution.Status__c, 'Job Execution status is Not Started.');
        }
    }

    @IsTest
    private static void execute() {
        System.runAs(getUser()) {
            // Setup
            Git_Commit__c gitCommit = new Git_Commit__c();
            insert gitCommit;

            Jobs.ExecutionCreateRequest request = new Jobs.ExecutionCreateRequest();
            request.parentId = gitCommit.Id;
            request.steps = getJobSteps();
            request.callback = 'MockCallbackLogic';
            request.dataJson = '{"key1": "value1"}';
            request.sourceId = getEnvironment('dev1');
            request.destinationId = getEnvironment('int');
            request.pipelineId = getPipeline('main');
            request.transactionId = 'a0s08852';

            // Exercise
            Test.startTest();
            Jobs.ExecutionCreateResult result = Jobs.Execution.create(request);
            Test.stopTest();

            // Verify
            List<JobStep__c> steps = [SELECT Name, Order__c FROM JobStep__c WHERE JobExecution__c = :result.jobExecution.Id ORDER BY Order__c ASC];

            System.assertEquals(gitCommit.Id, result.jobExecution.ParentRecord_Id__c, 'Parent Id matches.');
            System.assertEquals('Not Started', result.jobExecution.Status__c, 'Job Execution status is Not Started.');
            System.assertEquals('MockCallbackLogic', result.jobExecution.Callback__c, 'Job Execution callback matches.');
            System.assertEquals(request.dataJson, result.jobExecution.DataJson__c, 'Job Execution DataJson matches.');
            System.assertEquals(
                true,
                JSON.serialize(result.jobExecution.VolumeOptions__c).contains(request.transactionId),
                'Job Execution contains the transaction Id.'
            );
            System.assertEquals(request.sourceId, result.jobExecution.Source__c, 'Job Execution DataJson matches.');
            System.assertEquals(request.destinationId, result.jobExecution.Destination__c, 'Job Execution DataJson matches.');
            System.assertEquals(request.pipelineId, result.jobExecution.Pipeline__c, 'Job Execution DataJson matches.');

            System.assertEquals(2, steps.size(), 'There are 2 steps in the job execution.');

            System.assertEquals(1, steps[0].Order__c, 'Order is 1.');
            System.assertEquals('Step1', steps[0].Name, 'Names match.');

            System.assertEquals(2, steps[1].Order__c, 'Order is 2.');
            System.assertEquals('Step2', steps[1].Name, 'Names match.');
        }
    }

    // HELPER

    private static User getUser() {
        return [SELECT Id, Email FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1];
    }

    private static void createData() {
        Credential dev1Credential = new Credential();
        Environment dev1 = new Environment().name('dev1').type('Sandbox').platform('Other').add(dev1Credential);
        Credential intCredential = new Credential();
        Environment integration = new Environment().name('int').type('Sandbox').platform('Other').add(intCredential);

        new Pipeline()
            .active(true)
            .mainBranch('main')
            .setPlatform('Other')
            .add(new Connection(dev1, integration).branch('dev1'))
            .add(new Project().add(new UserStory().credential(dev1Credential)))
            .persist();

        Id userStoryId = getUserStory().Id;

        new JobStep().order(1).type('Manual').name('Step1').userStory(userStoryId).executionSequence('before');
        new JobStep().order(2).type('Test').name('Step2').userStory(userStoryId).executionSequence('after').persist();
    }

    private static User_Story__c getUserStory() {
        return [SELECT Id FROM User_Story__c LIMIT 1];
    }

    private static List<JobStep__c> getJobSteps() {
        return new JobStepsSelector().byParent(getUserStory().Id);
    }

    private static Id getEnvironment(String name) {
        return [SELECT Id FROM Environment__c WHERE Name = :name LIMIT 1].Id;
    }

    private static Id getPipeline(String branch) {
        return [SELECT Id FROM Deployment_Flow__c WHERE Main_Branch__c = :branch LIMIT 1].Id;
    }
}