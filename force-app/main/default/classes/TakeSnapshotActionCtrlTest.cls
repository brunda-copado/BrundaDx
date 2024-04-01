@IsTest
private with sharing class TakeSnapshotActionCtrlTest {
    @TestSetup
    private static void setup() {
        TestUtilities.getAllMultilicense();
        User user = (User) new User_t()
            .assign(new PermissionSetAssignment_t().copadoUser())
            .assign(new PermissionSetAssignment_t().functions())
            .assign(new PermissionSetAssignment_t().jobEngine())
            .assign(new PermissionSetAssignment_t().executeAutomations())
            .assign(new PermissionSetAssignment_t().configureSnapshots())
            .persist();
        System.runAs(user) {
            new CopadoLicense().user(user).enableAll().persist();
            createData();
        }
    }

    @IsTest
    private static void takeSnapshot() {
        System.runAs(getRunAsUser()) {
            // Setup
            Id snapshotId = gitSnapshot();
            Flow.mockResponse = flowCompletionEvent(true, '', '{"commitId": "test_commit_id"}');

            // Exercise
            Test.startTest();
            TakeSnapshotActionCtrl.executeAction(snapshotId, 'message');
            Test.stopTest();

            // Verify
            JobExecution__c jobExecution = [SELECT Status__c, ErrorMessage__c, DataJson__c FROM JobExecution__c LIMIT 1];
            System.assertEquals(
                JobExecutionConstants.STATUS_SUCCESSFUL,
                jobExecution.Status__c,
                'Job execution status after stop test should be Successful'
            );
            List<Git_Org_Commit__c> gitCommits = [SELECT Status__c, Commit_Id__c FROM Git_Org_Commit__c WHERE Git_Backup__c = :snapshotId];
            System.assertEquals(1, gitCommits.size(), 'One Git Org Commit record should have been created');
        }
    }

    @IsTest
    private static void exceptionOnInvalidSnapshot() {
        // Setup
        Id snapshotId = gitSnapshot();
        Deployment_Flow__c pipeline = getPipeline();
        pipeline.Active__c = false;
        update pipeline;

        // Exercise
        String exceptionMessage;
        Test.startTest();
        try {
            TakeSnapshotActionCtrl.executeAction(snapshotId, 'message');
        } catch (Exception e) {
            exceptionMessage = e.getMessage();
        }
        Test.stopTest();

        // Verify
        System.assert(exceptionMessage != null, 'Exception should have been thrown');
    }

    private static Deployment_Flow__c createData() {
        new JobTemplate().name('Snapshot Template').mockAutomation(ActionConstants.TAKE_SNAPSHOT).add(new JobStep()).persist();

        Environment dev = new Environment().name('dev').type('Sandbox').platform('Other').add(new Credential());
        Environment prod = new Environment().name('prod').type('Sandbox').platform('Other').add(new Credential());

        Deployment_Flow__c pipeline = (Deployment_Flow__c) new Pipeline()
            .active(true)
            .mainBranch('main')
            .setPlatform('Other')
            .add(new Connection(dev, prod).branch('dev'))
            .persist();

        Org__c credential = getCredential();

        Git_Repository__c repository = getRepository();

        new GitSnapshot().name('Test Backup').gitRepository(repository.Id).credential(credential.Id).pipeline(pipeline.Id).persist();

        return pipeline;
    }

    private static User getRunAsUser() {
        return [SELECT Id FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1];
    }

    private static Id gitSnapshot() {
        return [SELECT Id FROM Git_Backup__c LIMIT 1].Id;
    }

    private static Org__c getCredential() {
        return [SELECT Id FROM Org__c WHERE Environment__r.Name = 'dev' LIMIT 1];
    }

    private static Git_Repository__c getRepository() {
        return [SELECT Id FROM Git_Repository__c LIMIT 1];
    }

    private static Deployment_Flow__c getPipeline() {
        return [SELECT Id FROM Deployment_Flow__c LIMIT 1];
    }

    private static Event__e flowCompletionEvent(Boolean isSuccess, String errorMessage, String data) {
        Event__e result = new Event__e();
        result.Topic_Uri__c = OnJobStepComplete.STEP_ENDPOINT;
        result.Payload__c = Json.serialize(new OnJobStepComplete.EventPayload(isSuccess, errorMessage, data));

        return result;
    }
}