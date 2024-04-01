@isTest
private class AddStepsServiceImplTest {
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
    private static void executeWithoutRequiredParams() {
        System.runAs(getUser()) {
            // Setup
            Exception expectedException;
            Jobs.AddStepsRequest request = new Jobs.AddStepsRequest(null, null);

            // Exercise
            Test.startTest();
            try {
                Jobs.Execution.addSteps(request);
            } catch (Exception ex) {
                expectedException = ex;
            }
            Test.stopTest();

            // Verify
            System.assertNotEquals(null, expectedException, 'An exception should be thrown.');
            System.assertEquals('Missing required parameters : Job Execution Id, Steps', expectedException.getMessage(), 'Exception messages match.');
        }
    }

    @IsTest
    private static void execute() {
        System.runAs(getUser()) {
            // Setup
            List<Jobs.ExecutionStep> steps = steps('Local branch ready', 'before');
            steps.addAll(steps(null, 'after'));
            Jobs.AddStepsRequest request = new Jobs.AddStepsRequest(getJobId(), steps);

            // Exercise
            Test.startTest();
            Jobs.AddStepsResult result = Jobs.Execution.addSteps(request);
            Test.stopTest();

            // Verify
            List<JobStep__c> jobSteps = [
                SELECT Id, Name, Order__c, Result_Viewer_Component__c
                FROM JobStep__c
                WHERE JobExecution__c = :result.jobExecution.id
                ORDER BY Order__c ASC
            ];
            System.assertEquals(6, jobSteps.size(), 'Total step count should be 6');
            System.assertEquals('Follow up', jobSteps[0].Name, 'Name for Step 1 should be Follow up');
            System.assertEquals('Decrypt', jobSteps[1].Name, 'Name for Step 2 should be Decrypt');
            System.assertEquals('Z Step', jobSteps[2].Name, 'Name for Step 3 should be Z Step');
            System.assertEquals('Scope Check', jobSteps[3].Name, 'Name for Step 4 should be Scope Check');
            System.assertEquals('Follow up', jobSteps[4].Name, 'Name for Step 5 should be Follow up');
            System.assertEquals('Decrypt', jobSteps[5].Name, 'Name for Step 6 should be Decrypt');
            System.assertEquals(1, jobSteps[0].Order__c, 'Order for Step 1 should be 1');
            System.assertEquals(2, jobSteps[1].Order__c, 'Order for Step 2 should be 2');
            System.assertEquals(3, jobSteps[2].Order__c, 'Order for Step 3 should be 3');
            System.assertEquals(4, jobSteps[3].Order__c, 'Order for Step 4 should be 4');
            System.assertEquals(5, jobSteps[4].Order__c, 'Order for Step 5 should be 5');
            System.assertEquals(6, jobSteps[5].Order__c, 'Order for Step 6 should be 6');
            System.assertEquals('c.helloWorld', jobSteps[2].Result_Viewer_Component__c, 'Component for Step 3 should be c.helloWorld');
            System.assertEquals('c.showDetails', jobSteps[3].Result_Viewer_Component__c, 'Component for Step 4 should be c.showDetails');
        }
    }

    // HELPER

    private static User getUser() {
        return [SELECT Id, Email FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1];
    }

    private static void createData() {
        SObject userStory = new UserStory()
            .environment(new Environment().name('uat').type('Sandbox').platform('Other').add(new Credential()))
            .persist();

        new JobExecution()
            .status('Not Started')
            .add(
                new JobStep()
                    .name('Z Step')
                    .type('Function')
                    .order(1)
                    .resourceObservations('Local branch ready')
                    .resultViewerComponent('c.helloWorld')
                    .add(new Result().status('Not Started'))
            )
            .add(
                new JobStep().name('Scope Check').type('Flow').order(2).resultViewerComponent('c.showDetails').add(new Result().status('Not Started'))
            );

        new JobStep().order(1).type('Manual').name('Follow up').userStory(userStory.Id).executionSequence('before');
        new JobStep().order(2).type('Test').name('Decrypt').userStory(userStory.Id).executionSequence('before').persist();
    }

    private static User_Story__c getUserStory() {
        return [SELECT Id FROM User_Story__c WHERE Environment__r.Name = 'uat' LIMIT 1];
    }

    private static List<JobStep__c> getJobSteps() {
        return new JobStepsSelector().byParent(getUserStory().Id);
    }

    private static Id getJobId() {
        return [SELECT Id FROM JobExecution__c LIMIT 1].Id;
    }

    private static List<Jobs.ExecutionStep> steps(String state, String sequence) {
        List<Jobs.ExecutionStep> result = new List<Jobs.ExecutionStep>();

        Jobs.ExecutionStep execStep = new Jobs.ExecutionStep();
        execStep.resourceObservation = state;
        execStep.sequence = sequence;
        execStep.steps = getJobSteps();
        result.add(execStep);

        return result;
    }
}