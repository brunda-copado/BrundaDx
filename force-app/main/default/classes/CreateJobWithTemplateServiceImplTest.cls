@IsTest
private class CreateJobWithTemplateServiceImplTest {
    @TestSetup
    private static void setupData() {
        TestUtilities.getAllMultilicense();
        User user = (User) new User_t()
            .assign(new PermissionSetAssignment_t().copadoUser())
            .assign(new PermissionSetAssignment_t().jobEngine())
            .persist();

        System.runAs(user) {
            new CopadoLicense().user(user).enableAll().persist();
            createData();
        }
    }

    @IsTest
    private static void executeWithoutRequiredParams() {
        System.runAs(getUser()) {
            // Setup
            Exception expectedException;

            Git_Commit__c gitCommit = new Git_Commit__c();
            insert gitCommit;

            Jobs.ExecutionCreateFromTemplateRequest request = new Jobs.ExecutionCreateFromTemplateRequest();
            request.parentId = gitCommit.Id;

            // Exercise
            Test.startTest();
            try {
                Jobs.Execution.createFromTemplate(request);
            } catch (Exception ex) {
                expectedException = ex;
            }
            Test.stopTest();

            // Verify
            System.assertNotEquals(null, expectedException, 'An exception should be thrown.');
            System.assertEquals('Missing required parameters : Template Name', expectedException.getMessage(), 'Exception messages match.');
        }
    }

    @IsTest
    private static void executeWithInvalidTemplateName() {
        // Setup
        Exception expectedException;

        Git_Commit__c gitCommit = new Git_Commit__c();
        insert gitCommit;

        Jobs.ExecutionCreateFromTemplateRequest request = new Jobs.ExecutionCreateFromTemplateRequest();
        request.parentId = gitCommit.Id;
        request.templateAPIName = 'Invalid Template';

        // Exercise
        try {
            Jobs.Execution.createFromTemplate(request);
        } catch (Exception ex) {
            expectedException = ex;
        }

        // Verify
        String expectedMessage = String.format(Label.InvalidTemplateId, new List<String>{ request.templateAPIName });
        System.assertNotEquals(null, expectedException, 'An exception should be thrown');
        System.assertEquals(expectedMessage, expectedException.getMessage(), 'Exception message matches');
    }

    @SuppressWarnings('PMD.NcssMethodCount')
    @IsTest
    private static void execute() {
        System.runAs(getUser()) {
            // Setup
            String skipStepCondition = '{$User.Name.matches("' + UserInfo.getFirstName() + '*' + '")}';

            Git_Commit__c gitCommit = new Git_Commit__c();
            insert gitCommit;

            List<Jobs.ExecutionStep> steps = new List<Jobs.ExecutionStep>();
            steps.addAll(steps('before'));
            steps.addAll(steps('after'));
            steps.addAll(steps());

            Jobs.ExecutionCreateFromTemplateRequest request = new Jobs.ExecutionCreateFromTemplateRequest();
            request.parentId = gitCommit.Id;
            request.templateAPIName = jobTemplateApiName().ApiName__c;
            request.steps = steps;

            // Exercise
            Test.startTest();
            Jobs.ExecutionCreateFromTemplateResult result = Jobs.Execution.createFromTemplate(request);
            Test.stopTest();

            // Verify
            List<JobStep__c> jobSteps = [
                SELECT Name, Order__c, Resource_Observations__c, Result_Viewer_Component__c, SkipCondition__c, IsSkipped__c
                FROM JobStep__c
                WHERE JobExecution__c = :result.jobExecution.id
                ORDER BY Order__c ASC
            ];
            System.assertEquals(8, jobSteps.size(), 'Total step count should be 8');

            System.assertEquals('Encode', jobSteps[0].Name, 'Step 1 name should be Encode');
            System.assertEquals(1, jobSteps[0].Order__c, 'The order of Encode should be 1');
            System.assertEquals('Local branch ready', jobSteps[0].Resource_Observations__c, 'The state of Encode should be \'Local branch ready\'');

            System.assertEquals('Encode', jobSteps[1].Name, 'Step 2 name should be Encode');
            System.assertEquals(2, jobSteps[1].Order__c, 'The order of Encode should be 2');
            System.assertEquals('Local branch ready', jobSteps[1].Resource_Observations__c, 'The state of Encode should be \'Local branch ready\'');

            System.assertEquals('Decode', jobSteps[2].Name, 'Step 3 name should be Decode');
            System.assertEquals(3, jobSteps[2].Order__c, 'The order of Decode should be 3');
            System.assertEquals(null, jobSteps[2].Resource_Observations__c, 'The state of Decode should be blank');

            System.assertEquals('Encode', jobSteps[3].Name, 'Step 4 name should be Encode');
            System.assertEquals(4, jobSteps[3].Order__c, 'The order of Encode should be 4');
            System.assertEquals('Local branch ready', jobSteps[3].Resource_Observations__c, 'The state of Encode should be \'Local branch ready\'');

            System.assertEquals('Decode', jobSteps[4].Name, 'Step 5 name should be Decode');
            System.assertEquals(5, jobSteps[4].Order__c, 'The order of Decode should be 5');
            System.assertEquals(null, jobSteps[4].Resource_Observations__c, 'The state of Decode should be blank');

            System.assertEquals('Decode', jobSteps[5].Name, 'Step 6 name should be Decode');
            System.assertEquals(6, jobSteps[5].Order__c, 'The order of Decode should be 6');
            System.assertEquals(null, jobSteps[5].Resource_Observations__c, 'The state of Decode should be blank');

            System.assertEquals('S2', jobSteps[6].Name, 'Step 7 name should be S2');
            System.assertEquals(7, jobSteps[6].Order__c, 'The order of S2 should be 7');
            System.assertEquals('Local branch ready', jobSteps[6].Resource_Observations__c, 'The state of S2 should be \'Local branch ready\'');
            System.assertEquals(skipStepCondition, jobSteps[6].SkipCondition__c, 'Step 7\'s skip condition matches');
            System.assertEquals(false, jobSteps[6].IsSkipped__c, 'Step 7\'s skip status is false');

            System.assertEquals('S1', jobSteps[7].Name, 'Step 8 name should be S1');
            System.assertEquals(8, jobSteps[7].Order__c, 'The order of S1 should be 8');
            System.assertEquals(null, jobSteps[7].Resource_Observations__c, 'The state of S1 should be blank');
            System.assertEquals(null, jobSteps[7].SkipCondition__c, 'Step 8\'s skip condition is blank');
            System.assertEquals(false, jobSteps[7].IsSkipped__c, 'Step 8\'s skip status is false');
            System.assertEquals(
                'c.showDetails',
                jobSteps[7].Result_Viewer_Component__c,
                'The result viewer component for S1 should be c.showDetails'
            );

            System.assertEquals(gitCommit.Id, result.jobExecution.ParentRecord_Id__c, 'Parent Id matches.');
            System.assertEquals(jobTemplateApiName().Id, result.jobExecution.Template__c, 'Template Id matches');
            System.assertEquals('Not Started', result.jobExecution.Status__c, 'Job Execution status is Not Started.');
        }
    }

    @IsTest
    private static void executeWithNoStepsTemplate() {
        System.runAs(getUser()) {
            // Setup
            JobTemplate__c template = (JobTemplate__c) new JobTemplate().name('Sample').persist();

            Jobs.ExecutionCreateFromTemplateRequest request = new Jobs.ExecutionCreateFromTemplateRequest();
            request.templateAPIName = 'Sample_1';

            // Exercise
            Test.startTest();
            Jobs.ExecutionCreateFromTemplateResult result = Jobs.Execution.createFromTemplate(request);
            Test.stopTest();

            // Verify
            System.assertEquals(0, [SELECT COUNT() FROM JobStep__c WHERE JobExecution__c = :result.jobExecution.id], 'Total step count should be 0');
            System.assertEquals(template.Id, result.jobExecution.Template__c, 'Template Id matches');
            System.assertEquals('Not Started', result.jobExecution.Status__c, 'Job Execution status is Not Started.');
        }
    }

    @IsTest
    private static void executeWithJobTemplateSteps() {
        System.runAs(getUser()) {
            // Setup
            String skipStepCondition = '{$User.Name.matches("' + UserInfo.getFirstName() + '*' + '")}';

            Git_Commit__c gitCommit = new Git_Commit__c();
            insert gitCommit;

            Jobs.ExecutionCreateFromTemplateRequest request = new Jobs.ExecutionCreateFromTemplateRequest();
            request.parentId = gitCommit.Id;
            request.templateAPIName = jobTemplateApiName().ApiName__c;

            // Exercise
            Test.startTest();
            Jobs.ExecutionCreateFromTemplateResult result = Jobs.Execution.createFromTemplate(request);
            Test.stopTest();

            // Verify
            List<JobStep__c> jobSteps = [
                SELECT Name, Order__c, Resource_Observations__c, Result_Viewer_Component__c, SkipCondition__c
                FROM JobStep__c
                WHERE JobExecution__c = :result.jobExecution.id
                ORDER BY Order__c ASC
            ];
            System.assertEquals(2, jobSteps.size(), 'Total step count should be 2');

            System.assertEquals('S2', jobSteps[0].Name, 'Step 1 name should be S2');
            System.assertEquals(1, jobSteps[0].Order__c, 'The order of S2 should be 1');
            System.assertEquals('Local branch ready', jobSteps[0].Resource_Observations__c, 'The state of S2 should be \'Local branch ready\'');
            System.assertEquals(skipStepCondition, jobSteps[0].SkipCondition__c, 'Step 1\'s skip condition matches');

            System.assertEquals('S1', jobSteps[1].Name, 'Step 2 name should be S1');
            System.assertEquals(2, jobSteps[1].Order__c, 'The order of S1 should be 2');
            System.assertEquals(null, jobSteps[1].Resource_Observations__c, 'The state of S1 should be blank');
            System.assertEquals(null, jobSteps[1].SkipCondition__c, 'Step 2\'s skip condition is blank');
            System.assertEquals(
                'c.showDetails',
                jobSteps[1].Result_Viewer_Component__c,
                'The result viewer component for S1 should be c.showDetails'
            );

            System.assertEquals(gitCommit.Id, result.jobExecution.ParentRecord_Id__c, 'Parent Id matches.');
            System.assertEquals(jobTemplateApiName().Id, result.jobExecution.Template__c, 'Template Id matches');
            System.assertEquals('Not Started', result.jobExecution.Status__c, 'Job Execution status is Not Started.');
        }
    }

    // HELPER

    private static User getUser() {
        return [SELECT Id, Email FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1];
    }

    private static void createData() {
        String firstNamePattern = UserInfo.getFirstName() + '*';

        new JobTemplate()
            .name('JT')
            .apiName('JT_1')
            .version(1)
            .volumeOptions('[{}]')
            .add(
                new JobStep()
                    .order(1)
                    .name('S2')
                    .resourceObservations('Local branch ready')
                    .skipCondition('{$User.Name.matches("' + firstNamePattern + '")}')
            )
            .add(new JobStep().order(2).name('S1').type('Function').resultViewerComponent('c.showDetails'));

        new JobTemplate()
            .name('Extra')
            .apiName('Extra_1')
            .version(1)
            .volumeOptions('[{}]')
            .add(new JobStep().order(1).name('Encode').resourceObservations('Local branch ready'))
            .add(new JobStep().order(2).name('Decode'))
            .persist();
    }

    private static List<JobStep__c> getadditionalSteps() {
        return new JobStepsSelector().byTemplateApiName('Extra_1');
    }

    private static JobTemplate__c jobTemplateApiName() {
        return [SELECT Id, ApiName__c FROM JobTemplate__c WHERE Name = 'JT' LIMIT 1];
    }

    private static List<Jobs.ExecutionStep> steps(String sequence) {
        List<Jobs.ExecutionStep> result = new List<Jobs.ExecutionStep>();

        Jobs.ExecutionStep execStep = new Jobs.ExecutionStep();
        execStep.resourceObservation = 'Local branch ready';
        execStep.sequence = sequence;
        execStep.steps = getadditionalSteps();
        result.add(execStep);

        return result;
    }

    private static List<Jobs.ExecutionStep> steps() {
        List<Jobs.ExecutionStep> result = new List<Jobs.ExecutionStep>();

        Jobs.ExecutionStep execStep = new Jobs.ExecutionStep();
        execStep.resourceObservation = 'Local branch ready';
        execStep.steps = getadditionalSteps();
        result.add(execStep);

        return result;
    }
}