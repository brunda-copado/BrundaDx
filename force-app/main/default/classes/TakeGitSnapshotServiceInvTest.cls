@isTest
private class TakeGitSnapshotServiceInvTest {

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
            new JobTemplate().name('Snapshot Template').mockAutomation(ActionConstants.TAKE_SNAPSHOT).add(new JobStep()).persist();

            Environment dev = new Environment().name('dev').type('Sandbox').platform('Other').add(new Credential());
            Environment prod = new Environment().name('prod').type('Sandbox').platform('Other').add(new Credential());

            Deployment_Flow__c pipeline = (Deployment_Flow__c) new Pipeline()
                .active(true)
                .mainBranch('main')
                .setPlatform('Other')
                .add(new Connection(dev, prod).branch('dev'))
                .persist();

            Org__c credential = [SELECT Id FROM Org__c WHERE Environment__r.Name = 'dev' LIMIT 1];

            Git_Repository__c repository = [SELECT Id FROM Git_Repository__c LIMIT 1];

            new GitSnapshot().name('Test Backup').gitRepository(repository.Id).credential(credential.Id).pipeline(pipeline.Id).persist();
        }
    }

    @IsTest
    private static void takeSnapshot() {
        User runUser = [SELECT Id FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1]; 
        System.runAs(runUser){
            // Setup
            Id snapshotId = [SELECT Id FROM Git_Backup__c LIMIT 1].Id;

            Actions.TakeGitSnapshotRequest request = new Actions.TakeGitSnapshotRequest();
            request.snapshotId = snapshotId;
            request.message = 'test';

            Flow.mockResponse = new Event__e(
                Topic_Uri__c = OnJobStepComplete.STEP_ENDPOINT
                ,Payload__c = Json.serialize(new OnJobStepComplete.EventPayload(true,'', '{"commitId": "test_commit_id"}'))
            );

            // Exercise
            Test.startTest();
                Actions.TakeGitSnapshotResult[] results = TakeGitSnapshotServiceInv.executeInv( new Actions.TakeGitSnapshotRequest[]{request});
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

            // Verify callback
            Git_Backup__c gitSnapshot = [SELECT Last_Backup__c FROM Git_Backup__c WHERE Id = :snapshotId LIMIT 1];
            System.assertNotEquals(
                null,
                gitSnapshot.Last_Backup__c,
                'Git Snapshot should have been updated with last backup date in callback execution'
            );
            System.assertEquals(CommitConstants.STATUS_COMPLETE, gitCommits[0].Status__c, 'Git Snapshot Commit status should have been updated');
            System.assertEquals('test_commit_id', gitCommits[0].Commit_Id__c, 'Git Snapshot Commit status should have been updated');

            List<Automation_Event__c> events = [SELECT Id, Action_Name__c, Environment_Id__c FROM Automation_Event__c];
            System.assertEquals(1, events.size(), 'An Automation Event should be created');
            System.assertEquals(ActionConstants.TAKE_SNAPSHOT, events[0].Action_Name__c, 'Action Name should match');
            Environment__c environment = [SELECT Id FROM Environment__c WHERE Name = 'dev'];
            System.assertEquals(environment.Id, events[0].Environment_Id__c, 'Environment should match');
        }
    }
}