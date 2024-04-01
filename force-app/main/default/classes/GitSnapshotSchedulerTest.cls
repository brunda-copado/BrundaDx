@isTest
public with sharing class GitSnapshotSchedulerTest {
    @TestSetup
    static void setupData() {
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
    private static void createData() {
        createPipeline('Other');
    }

    @IsTest
    static void testGitSnaphotScheduler() {
        //Setup
        System.runAs(getRunAsUser()) {
            Org__c credWithOtherPlatform = getCredential('Other', 'dev1');

            Git_Repository__c gitRepo = (Git_Repository__c) new GitRepository().name('gitSnapshotRepo').persist();

            Flow.mockResponse = flowCompletionEvent(true, '', '{"commitId": "test_commit_id"}');

            Git_Backup__c gitSnapshot = (Git_Backup__c) new GitSnapshot()
                .name('testbackup')
                .credential(credWithOtherPlatform.Id)
                .gitRepository(gitRepo.Id)
                .pipeline(getPipeline('Other').Id)
                .persist();

            //Execute
            String jobName = gitSnapshot.Id + '_' + gitRepo.Name;
            Test.startTest();

            System.schedule(jobName, '0 0 12 1/1 * ? *', new GitSnapshotScheduler(gitSnapshot.Id));

            Test.stopTest();

            //Verify

            AsyncApexJob scheduledJob = [
                SELECT ApexClass.Name, Id, JobType, Status, CronTrigger.CronJobDetail.Name, CronTrigger.CronExpression
                FROM AsyncApexJob
                WHERE CronTrigger.CronJobDetail.Name = :jobName AND JobType = 'ScheduledApex'
            ];
            System.assertEquals(scheduledJob.Id != null, true, 'job got scheduled');

            JobExecution__c jobExecution = [SELECT Status__c, ErrorMessage__c, DataJson__c FROM JobExecution__c LIMIT 1];
            System.assertEquals(
                JobExecutionConstants.STATUS_SUCCESSFUL,
                jobExecution.Status__c,
                'Job execution status after stop test should be Successful'
            );

            List<Git_Org_Commit__c> gitCommits = [SELECT Status__c, Commit_Id__c FROM Git_Org_Commit__c WHERE Git_Backup__c = :gitSnapshot.Id];
            System.assertEquals(1, gitCommits.size(), 'One Git Org Commit record should have been created');

            // Verify callback
            Git_Backup__c gitBackup = [SELECT Last_Backup__c FROM Git_Backup__c WHERE Id = :gitSnapshot.Id LIMIT 1];
            System.assertNotEquals(
                null,
                gitBackup.Last_Backup__c,
                'Git Snapshot should have been updated with last backup date in callback execution'
            );
        }
    }

    private static User getRunAsUser() {
        return [SELECT Id FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1];
    }

    private static Deployment_Flow__c getPipeline(String platform) {
        return [SELECT Id, Active__c FROM Deployment_Flow__c WHERE Platform__c = :platform LIMIT 1];
    }
    private static Environment__c getEnvironmentByName(String environmentName) {
        return [SELECT Id, Name, Platform__c FROM Environment__c WHERE Name = :environmentName LIMIT 1];
    }

    private static Org__c getCredential(String platform, String environmentName) {
        return [
            SELECT Id, Name, Environment__c, OAuth_Signature__c, Platform__c, Environment__r.Platform__c, Environment__r.Name
            FROM Org__c
            WHERE Platform__c = :platform AND Environment__r.Name = :environmentName AND OAuth_Signature__c != NULL
            LIMIT 1
        ];
    }

    private static void createPipeline(String platform) {
        new JobTemplate().name('Snapshot Template').mockAutomation(ActionConstants.TAKE_SNAPSHOT).add(new JobStep()).persist();

        Credential dev1Credential = new Credential().oAuthSignature('authentication');
        Environment dev1 = new Environment().name('dev1').type('Sandbox').platform(platform).add(dev1Credential);
        Environment dev2 = new Environment().name('dev2').type('Sandbox').platform(platform).add(new Credential());
        Credential intCredential = new Credential();
        Environment integration = new Environment().name('int').type('Sandbox').platform(platform).add(intCredential);
        Environment uat = new Environment().name('uat').type('Sandbox').platform(platform).add(new Credential());
        Environment prod = new Environment().name('prod').type('Sandbox').platform(platform).add(new Credential());

        new Pipeline()
            .active(true)
            .mainBranch('main')
            .setPlatform(platform)
            .add(new Connection(dev1, integration).branch('dev1'))
            .add(new Connection(dev2, integration).branch('dev2'))
            .add(new Connection(integration, uat).branch('int'))
            .add(new Connection(uat, prod).branch('uat'))
            .add(new Project().add(new UserStory().credential(dev1Credential).add(new UserStoryMetadata().name('TestClass').type('ApexClass'))))
            .persist();
    }

    private static Event__e flowCompletionEvent(Boolean isSuccess, String errorMessage, String data) {
        Event__e result = new Event__e();
        result.Topic_Uri__c = OnJobStepComplete.STEP_ENDPOINT;
        result.Payload__c = Json.serialize(new OnJobStepComplete.EventPayload(isSuccess, errorMessage, data));

        return result;
    }
}