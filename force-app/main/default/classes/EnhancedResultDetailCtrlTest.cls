@SuppressWarnings('PMD.CognitiveComplexity')
@IsTest
private class EnhancedResultDetailCtrlTest {
    @TestSetup
    private static void setupData() {
        TestUtilities.getAllMultilicense();
        new User_t().standard().alias('noAccess');
        User stdUsr = (User) new User_t()
            .alias('stdUsr')
            .assign(new PermissionSetAssignment_t().copadoUser())
            .assign(new PermissionSetAssignment_t().jobEngine())
            .assign(new PermissionSetAssignment_t().functions())
            .persist();

        System.runAs(stdUsr) {
            new CopadoLicense().user(stdUsr).enableAll().persist();
        }
    }

    @IsTest
    private static void getDetailsWithSubJob() {
        User user = user();
        System.runAs(user) {
            // Setup
            createJobExecutionWithSubJob();

            // Exercise
            Id resultId = [SELECT Id FROM Result__c WHERE Status__c = 'In Progress' AND Job_Type__c = 'Manual' LIMIT 1].Id;
            Test.startTest();
            EnhancedResultDetailCtrl.ResultDetails response = EnhancedResultDetailCtrl.getDetails(resultId);
            Test.stopTest();

            // Verify
            Assert.isNotNull(response, 'Response is null');
            Assert.areEqual(Settings.ns, response.namespace, 'Incorrect namespace was returned by the controller.');

            Assert.areEqual('In Progress', response.resultDetails.Status__c, 'The result status does not match');
            Assert.areEqual('Manual', response.resultDetails.Job_Type__c, 'The job type does not match');
            Assert.areEqual('None', response.resultDetails.Progress_Status__c, 'The progress status does not match');

            Assert.areEqual(2, response.subJobExecutionSteps.size(), 'The number of steps returned are inaccurate');
            Assert.areEqual('Sub Step Manual', response.subJobExecutionSteps[0].Name, 'The name of first step is inaccurate');
            Assert.areEqual('Manual Task Step 2', response.subJobExecutionSteps[1].Name, 'The name of second step is inaccurate');
            Assert.areEqual('Success', response.subJobExecutionSteps[0].Result__r.Status__c, 'The status of first step is inaccurate');
            Assert.areEqual('In Progress', response.subJobExecutionSteps[1].Result__r.Status__c, 'The status of second step is inaccurate');
        }
    }

    @IsTest
    private static void getDetailsForTestResult() {
        System.runAs(user()) {
            // SETUP
            createJobExecutionForSingleTestExecution();

            // EXERCISE
            Id resultId = [SELECT Id FROM Result__c WHERE Status__c = 'Failed' AND JobStep__c != NULL AND Test__c = NULL LIMIT 1].Id;
            Test.startTest();
            EnhancedResultDetailCtrl.ResultDetails response = EnhancedResultDetailCtrl.getDetails(resultId);
            Test.stopTest();

            // VALIDATE
            Assert.isNotNull(response, 'Response is null');
            Assert.areEqual(Settings.ns, response.namespace, 'Incorrect namespace was returned by the controller.');

            Assert.areEqual('Failed', response.resultDetails.Status__c, 'The result status does not match');
            Assert.areEqual('Manual', response.resultDetails.Job_Type__c, 'The job type does not match');
            Assert.areEqual(null, response.resultDetails.Progress_Status__c, 'The progress status does not match');

            Assert.areEqual(2, response.subJobExecutionSteps.size(), 'The number of steps returned are inaccurate');
            Assert.areEqual('Verify Details', response.subJobExecutionSteps[0].Name, 'The name of first step is inaccurate');
            Assert.areEqual('Approve Form', response.subJobExecutionSteps[1].Name, 'The name of second step is inaccurate');
            Assert.areEqual('Success', response.subJobExecutionSteps[0].Result__r.Status__c, 'The status of first step is inaccurate');
            Assert.areEqual('Failed', response.subJobExecutionSteps[1].Result__r.Status__c, 'The status of second step is inaccurate');
        }
    }

    @IsTest
    private static void getDetailsWithNoSubJob() {
        User user = user();
        System.runAs(user) {
            // Setup
            createJobExecutionWithNoSubJob();

            // Exercise
            Id resultId = [SELECT Id FROM Result__c WHERE Status__c = 'In Progress' LIMIT 1].Id;
            Test.startTest();
            EnhancedResultDetailCtrl.ResultDetails response = EnhancedResultDetailCtrl.getDetails(resultId);
            Test.stopTest();

            // Verify
            Assert.isNotNull(response, 'Response is null');
            Assert.areEqual(Settings.ns, response.namespace, 'Incorrect namespace was returned by the controller.');

            Assert.areEqual('In Progress', response.resultDetails.Status__c, 'The result status does not match');
            Assert.areEqual('Manual', response.resultDetails.Job_Type__c, 'The job type does not match');
            Assert.areEqual('Fetching file', response.resultDetails.Progress_Status__c, 'The progress status does not match');

            Assert.areEqual(null, response.subJobExecutionSteps, 'The sub job steps returned are inaccurate');
        }
    }

    @IsTest
    private static void getResultDetailsWithInvalidId() {
        User user = user();
        System.runAs(user) {
            // Exercise

            Test.startTest();
            EnhancedResultDetailCtrl.ResultDetails response = EnhancedResultDetailCtrl.getDetails(user.Id);
            Test.stopTest();

            // Verify

            Assert.isNotNull(response, 'The response is null');
            Assert.areEqual(Settings.ns, response.namespace, 'Incorrect namespace was returned by the controller.');
            Assert.isNull(response.resultDetails, 'The resultDetails is not null.');
        }
    }

    @IsTest
    private static void getResultDetailsInsufficientAccess() {
        // Setup

        Exception expectedException;
        Result__c result = (Result__c) new Result().jobType('Test').status('Error').errMsg('Failed').progress('None').persist();

        // Exercise

        System.runAs(noAccessUser()) {
            Test.startTest();
            try {
                EnhancedResultDetailCtrl.getDetails(result.Id);
            } catch (Exception ex) {
                expectedException = ex;
            }
            Test.stopTest();
        }

        // Verify

        Assert.isNotNull(expectedException, 'There is no exception');
        Assert.areEqual('Script-thrown exception', expectedException.getMessage(), 'The exception messages do not match');
    }

    @IsTest
    private static void getLatestResultIdForSingleTestExecution() {
        System.runAs(user()) {
            // SETUP
            Id resultId = createJobExecutionForSingleTestExecution();

            // EXERCISE
            Test.startTest();
            Id subJobResultId = EnhancedResultDetailCtrl.getSubJobResultId(resultId);
            Test.stopTest();

            // VALIDATE
            Assert.isNotNull(subJobResultId, 'subJobResultId is null');
            Assert.areEqual(
                [SELECT Id FROM Result__c WHERE Status__c = 'Failed' AND JobStep__r.Order__c = 2]
                .Id,
                subJobResultId,
                'SubJobResultId does not match the last step result Id'
            );
        }
    }

    @IsTest
    private static void getLatestResultIdForSingleTestExecutionWithMultipleJobs() {
        System.runAs(user()) {
            // SETUP
            Id resultId = createJobExecutionForSingleTestExecution();

            Test__c testRecord = [SELECT Id, LatestJobExecution__c FROM Test__c WHERE Name = 'Test1' LIMIT 1];
            JobExecution__c latestJob = (JobExecution__c) new JobExecution()
                .status('In Progress')
                .template([SELECT Id FROM JobTemplate__c LIMIT 1].Id)
                .add(new JobStep().name('Verify Details').type('Manual').order(1).configJson(''))
                .add(new JobStep().name('Approve Form').type('Manual').order(2).configJson(''))
                .persist();

            List<JobStep__c> jobSteps = [SELECT Id, Type__c, Result__c FROM JobStep__c WHERE JobExecution__c = :latestJob.Id ORDER BY Order__c];
            new Result().jobType(jobSteps[0].Type__c).status('Success').step(jobSteps[0].Id);
            new Result().jobType(jobSteps[1].Type__c).status('In Progress').step(jobSteps[1].Id);

            Result__c testResult = (Result__c) new Result().jobType('Manual').status('In Progress').test(testRecord.Id).persist();

            List<Result__c> jobStepResults = [
                SELECT Id, Job_Type__c, JobStep__c
                FROM Result__c
                WHERE Test__c = NULL AND JobStep__r.JobExecution__c = :latestJob.Id
            ];

            for (JobStep__c jobStep : jobSteps) {
                for (Result__c result : jobStepResults) {
                    if (result.JobStep__c == jobStep.Id) {
                        jobStep.Result__c = result.Id;
                    }
                }
            }
            update jobSteps;

            latestJob.ParentRecord_Id__c = testRecord.Id;
            latestJob.DataJSON__c = '{"testIds" :["' + testRecord.Id + '"], "resultIds" :["' + testResult.Id + '"]}';
            update latestJob;

            // EXERCISE
            Test.startTest();
            Id subJobResultId = EnhancedResultDetailCtrl.getSubJobResultId(resultId);
            Test.stopTest();

            // VALIDATE
            Assert.isNotNull(subJobResultId, 'subJobResultId is null');
            Assert.areEqual(
                [SELECT Id FROM Result__c WHERE Status__c = 'Failed' AND JobStep__r.Order__c = 2 AND JobStep__r.JobExecution__c != :latestJob.Id]
                .Id,
                subJobResultId,
                'SubJobResultId does not match the last step result Id'
            );
        }
    }

    @IsTest
    private static void getLatestResultIdForIrrelevantResult() {
        System.runAs(user()) {
            // SETUP
            Result__c result = (Result__c) new Result().jobType('Manual').status('Success').persist();

            // EXERCISE
            Test.startTest();
            Id subJobResultId = EnhancedResultDetailCtrl.getSubJobResultId(result.Id);
            Test.stopTest();

            // VERIFY
            Assert.isNull(subJobResultId, 'subJobResultId is not null');
        }
    }

    @IsTest
    private static void getLatestResultIdInsufficientAccess() {
        // Setup

        Exception expectedException;
        Result__c result = (Result__c) new Result().jobType('Test').status('Error').errMsg('Failed').progress('None').persist();

        // Exercise

        System.runAs(noAccessUser()) {
            Test.startTest();
            try {
                EnhancedResultDetailCtrl.getSubJobResultId(result.Id);
            } catch (Exception ex) {
                expectedException = ex;
            }
            Test.stopTest();
        }

        // Verify

        Assert.isNotNull(expectedException, 'There is no exception');
        Assert.areEqual('Script-thrown exception', expectedException.getMessage(), 'The exception messages do not match');
    }

    @IsTest
    private static void getLatestResultIdForIncorrectId() {
        User user = user();
        System.runAs(user) {
            // EXERCISE
            Test.startTest();
            Id subJobResultId = EnhancedResultDetailCtrl.getSubJobResultId(user.Id);
            Test.stopTest();

            // VERIFY
            Assert.areEqual(null, subJobResultId, 'SubJobResultId is not null');
        }
    }

    @IsTest
    private static void getLatestResultIdWithSubJob() {
        System.runAs(user()) {
            // Setup
            createJobExecutionWithSubJob();

            // Exercise
            Id resultId = [SELECT Id FROM Result__c WHERE Status__c = 'In Progress' AND Job_Type__c = 'Test' LIMIT 1].Id;
            Test.startTest();
            Id subJobResultId = EnhancedResultDetailCtrl.getSubJobResultId(resultId);
            Test.stopTest();

            // Verify
            Assert.isNotNull(subJobResultId, 'subJobResultId is null');
            Assert.areEqual(
                [SELECT Id FROM Result__c WHERE Status__c = 'In Progress' AND Job_Type__c = 'Manual' AND JobStep__r.Order__c = 2]
                .Id,
                subJobResultId,
                'SubJobResultId does not match the last step result Id'
            );
        }
    }

    // HELPER

    private static User user() {
        return [SELECT Id, Email FROM User WHERE Profile.Name = 'Standard User' AND Alias = 'stdUsr' ORDER BY CreatedDate DESC LIMIT 1];
    }

    private static User noAccessUser() {
        return [SELECT Id, Email FROM User WHERE Profile.Name = 'Standard User' AND Alias = 'noAccess' ORDER BY CreatedDate DESC LIMIT 1];
    }

    private static void createJobExecutionWithSubJob() {
        JobTemplate__c template = (JobTemplate__c) new JobTemplate().name('Sample').persist();

        new JobExecution()
            .status('In Progress')
            .template(template.Id)
            .add(new JobStep().name('Mock QG').type('Test').order(1).configJson('{"type" : "QRT"}'));

        JobExecution__c subJob = (JobExecution__c) new JobExecution()
            .status('In Progress')
            .add(new JobStep().name('Sub Step Manual').type('Manual').order(1).configJson('{"type" : "Manual"}'))
            .add(new JobStep().name('Manual Task Step 2').type('Manual').order(2).configJson('{"type" : "Manual"}'))
            .persist();

        List<Result__c> results = new List<Result__c>();
        List<JobStep__c> steps = [SELECT Id, Result__c, Sub_Job_Execution__c, Type__c, Order__c FROM JobStep__c ORDER BY Order__c];

        for (JobStep__c step : steps) {
            Result__c result = new Result__c();

            if (step.Type__c == 'Test') {
                subJob.Job_Step__c = step.Id;
                result.Job_Type__c = 'Test';
                result.Status__c = 'In Progress';
                result.Progress_Status__c = 'Checking';
                result.JobStep__c = step.Id;
            } else {
                result.Job_Type__c = step.Type__c;
                result.Status__c = step.Order__c == 1 ? 'Success' : 'In Progress';
                result.Progress_Status__c = step.Order__c == 1 ? 'Completed' : 'None';
                result.JobStep__c = step.Id;
            }
            results.add(result);
        }

        insert results;
        update subJob;

        for (Result__c result : results) {
            for (JobStep__c step : steps) {
                if (result.JobStep__c == step.Id) {
                    step.Result__c = result.Id;
                }
                if (step.Type__c == 'Test') {
                    step.Sub_Job_Execution__c = subJob.Id;
                }
            }
        }

        update steps;
    }

    private static void createJobExecutionWithNoSubJob() {
        JobTemplate__c template = (JobTemplate__c) new JobTemplate().name('Sample').persist();

        new JobExecution()
            .status('In Progress')
            .template(template.Id)
            .add(
                new JobStep()
                    .name('Set File Id')
                    .type('Manual')
                    .order(1)
                    .configJson('{"type" : "QRT"}')
                    .result(new Result().jobType('Manual').status('In Progress').progress('Fetching file'))
            )
            .add(
                new JobStep()
                    .name('Fill details')
                    .type('Manual')
                    .order(2)
                    .configJson('{"type" : "QRT1"}')
                    .result(new Result().jobType('Manual').status('Not Started'))
            )
            .persist();
    }

    private static Id createJobExecutionForSingleTestExecution() {
        TestToolsSelector.mock(new List<TestTool__mdt>{ new TestTool__mdt(MasterLabel = 'None', TestType__c = 'Mock Type') });
        JobTemplate__c template = (JobTemplate__c) new JobTemplate().name('Sample').persist();

        JobExecution job = new JobExecution()
            .status('Failed')
            .template(template.Id)
            .add(new JobStep().name('Verify Details').type('Manual').order(1).configJson(''))
            .add(new JobStep().name('Approve Form').type('Manual').order(2).configJson(''));

        ExtensionConfiguration extensionConfiguration = new ExtensionConfiguration().application('Test').tool('Manual Tests').active((true));
        Test__c manualTest = (Test__c) new Test_t().name('Test1').extensionConfiguration(extensionConfiguration).jobExecution(job).persist();

        List<JobStep__c> jobSteps = [SELECT Id, Type__c, Result__c FROM JobStep__c ORDER BY Order__c];
        new Result().jobType(jobSteps[0].Type__c).status('Success').step(jobSteps[0].Id);
        new Result().jobType(jobSteps[1].Type__c).status('Failed').step(jobSteps[1].Id);

        Result__c testResult = (Result__c) new Result().jobType('Manual').status('Failed').test(manualTest.Id).persist();

        List<Result__c> jobStepResults = [SELECT Id, Job_Type__c, JobStep__c FROM Result__c WHERE Test__c = NULL];

        for (JobStep__c jobStep : jobSteps) {
            for (Result__c result : jobStepResults) {
                if (result.JobStep__c == jobStep.Id) {
                    jobStep.Result__c = result.Id;
                }
            }
        }
        update jobSteps;

        JobExecution__c firstJob = [SELECT Id, DataJSON__c, ParentRecord_Id__c FROM JobExecution__c LIMIT 1];
        firstJob.ParentRecord_Id__c = manualTest.Id;
        firstJob.DataJSON__c = '{"testIds" :["' + manualTest.Id + '"], "resultIds" :["' + testResult.Id + '"]}';
        update firstJob;

        return testResult.Id;
    }
}