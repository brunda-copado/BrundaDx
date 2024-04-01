@isTest
private with sharing class GitSnapshotHelperTest {
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
        createPipeline();
    }

    @isTest
    static void testGitSnapshotByPass() {
        System.runAs(getRunAsUser()) {
            //Setup
            Org__c credWithOtherPlatform = getCredential('Other', 'dev1');

            Git_Repository__c gitRepo = (Git_Repository__c) new GitRepository().name('gitSnapshotRepo').persist();

            //Exercise
            Test.startTest();
            Git_Backup__c gitSnapshot = (Git_Backup__c) new GitSnapshot()
                .name('testbackup')
                .credential(credWithOtherPlatform.Id)
                .gitRepository(gitRepo.Id)
                .pipeline(getPipeline('Other').Id)
                .persist();

            Test.stopTest();
            //Verify
            System.assertEquals(gitSnapshot.Id != null, true, 'git snapshot record created successfully ');
        }
    }

    @IsTest
    static void testcronExpressionWithValidData() {
        System.runAs(getRunAsUser()) {
            //Setup

            Org__c credWithOtherPlatform = getCredential('Other', 'dev1');

            Git_Repository__c gitRepo = (Git_Repository__c) new GitRepository().name('gitSnapshotRepo').persist();

            Flow.mockResponse = flowCompletionEvent(true, '', '{"commitId": "test_commit_id"}');

            //Exercise
            Test.startTest();
            Git_Backup__c gitBackup = (Git_Backup__c) new GitSnapshot()
                .name('testbackup')
                .credential(credWithOtherPlatform.Id)
                .gitRepository(gitRepo.Id)
                .pipeline(getPipeline('Other').Id)
                .mcFrequency('Schedule')
                .cronExpression('0 0 12 1/1 * ? *')
                .persist();

            Test.stopTest();

            //Verify
            String jobName = gitBackup.Id + '_' + gitRepo.Name;
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

            List<Git_Org_Commit__c> gitCommits = [SELECT Status__c, Commit_Id__c FROM Git_Org_Commit__c WHERE Git_Backup__c = :gitBackup.Id];
            System.assertEquals(1, gitCommits.size(), 'One Git Org Commit record should have been created');

            // Verify callback
            Git_Backup__c gitSnapshot = [SELECT Last_Backup__c FROM Git_Backup__c WHERE Id = :gitBackup.Id LIMIT 1];
            System.assertNotEquals(
                null,
                gitSnapshot.Last_Backup__c,
                'Git Snapshot should have been updated with last backup date in callback execution'
            );
        }
    }

    @IsTest
    static void testcronExpressionWithInValidData() {
        System.runAs(getRunAsUser()) {
            //Setup
            Org__c credWithOtherPlatform = getCredential('Other', 'dev1');

            Git_Repository__c gitRepo = (Git_Repository__c) new GitRepository().name('gitSnapshotRepo').persist();

            //Exercise
            Test.startTest();
            String exceptionMessage;
            try {
                new GitSnapshot()
                    .name('testbackup')
                    .credential(credWithOtherPlatform.Id)
                    .gitRepository(gitRepo.Id)
                    .pipeline(getPipeline('Other').Id)
                    .mcFrequency('Schedule')
                    .cronExpression('34565464')
                    .persist();
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }
            Test.stopTest();

            //Verify
            System.assertEquals(exceptionMessage != null, true, 'cron expression is not in correct format');
        }
    }

    @IsTest
    static void testcronExpressionUpdate() {
        System.runAs(getRunAsUser()) {
            //Setup
            Org__c credWithOtherPlatform = getCredential('Other', 'dev1');

            Git_Repository__c gitRepo = (Git_Repository__c) new GitRepository().name('gitSnapshotRepo').persist();

            Flow.mockResponse = flowCompletionEvent(true, '', '{"commitId": "test_commit_id"}');

            Git_Backup__c gitSnapshot = (Git_Backup__c) new GitSnapshot()
                .name('testbackup')
                .credential(credWithOtherPlatform.Id)
                .gitRepository(gitRepo.Id)
                .pipeline(getPipeline('Other').Id)
                .mcFrequency('Schedule')
                .cronExpression('0 0 12 1/1 * ? *')
                .persist();

            //Exercise
            Test.startTest();

            gitSnapshot.Cron_Expression__c = '0 0 11 1/1 * ? *';
            update gitSnapshot;

            Test.stopTest();

            //Verify
            System.assertEquals(gitSnapshot.Cron_Expression__c == '0 0 11 1/1 * ? *', true, 'cron expression is updated');
        }
    }

    @IsTest
    static void testGitSnapshotDelete() {
        System.runAs(getRunAsUser()) {
            //Setup

            Org__c credWithOtherPlatform = getCredential('Other', 'dev1');

            Git_Repository__c gitRepo = (Git_Repository__c) new GitRepository().name('gitSnapshotRepo').persist();

            Flow.mockResponse = flowCompletionEvent(true, '', '{"commitId": "test_commit_id"}');

            Git_Backup__c gitBackup = (Git_Backup__c) new GitSnapshot()
                .name('testbackup')
                .credential(credWithOtherPlatform.Id)
                .gitRepository(gitRepo.Id)
                .pipeline(getPipeline('Other').Id)
                .mcFrequency('Schedule')
                .cronExpression('0 0 12 1/1 * ? *')
                .persist();

            Git_Org_Commit__c gitOrgCommit = createSnapshotCommit(gitBackup, credWithOtherPlatform);
            insert gitOrgCommit;

            String jobName = gitBackup.Id + '_' + gitRepo.Name;
            AsyncApexJob scheduledJob = [
                SELECT ApexClass.Name, Id, JobType, Status, CronTrigger.CronJobDetail.Name, CronTrigger.CronExpression
                FROM AsyncApexJob
                WHERE CronTrigger.CronJobDetail.Name = :jobName AND JobType = 'ScheduledApex'
            ];
            System.assertEquals(scheduledJob.Id != null, true, 'job got scheduled');

            //Exercise
            Test.startTest();
            delete gitBackup;
            Test.stopTest();

            //Verify
            List<AsyncApexJob> jobs = [
                SELECT ApexClass.Name, Id, JobType, Status, CronTrigger.CronJobDetail.Name, CronTrigger.CronExpression
                FROM AsyncApexJob
                WHERE CronTrigger.CronJobDetail.Name = :jobName AND JobType = 'ScheduledApex'
            ];
            System.assertEquals(jobs.isEmpty(), true, 'job got aborted');
            Integer commitsCount = [SELECT COUNT() FROM Git_Org_Commit__c];
            System.assertEquals(0, commitsCount, 'Snapshot commits should be deleted');
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

    private static void createPipeline() {
        new JobTemplate().name('Snapshot Template').mockAutomation(ActionConstants.TAKE_SNAPSHOT).add(new JobStep()).persist();

        Credential dev1Credential = new Credential().oAuthSignature('authentication');
        Environment dev1 = new Environment().name('dev1').type('Sandbox').platform('Other').add(dev1Credential);
        Environment dev2 = new Environment().name('dev2').type('Sandbox').platform('Other').add(new Credential());
        Credential intCredential = new Credential();
        Environment integration = new Environment().name('int').type('Sandbox').platform('Other').add(intCredential);
        Environment uat = new Environment().name('uat').type('Sandbox').platform('Other').add(new Credential());
        Environment prod = new Environment().name('prod').type('Sandbox').platform('Other').add(new Credential());

        new Pipeline()
            .active(true)
            .mainBranch('main')
            .setPlatform('Other')
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

    private static Git_Org_Commit__c createSnapshotCommit(Git_Backup__c gitBackup, Org__c credWithOtherPlatform) {
        Git_Org_Commit__c gitOrgCommit = new Git_Org_Commit__c();
        gitOrgCommit.Commit_Id__c = '7a6dfcvx';
        gitOrgCommit.Commit_Date__c = Date.today();
        gitOrgCommit.Git_Backup__c = gitBackup.Id;
        gitOrgCommit.Org__c = credWithOtherPlatform.Id;
        gitOrgCommit.Status__c = 'Complete';
        gitOrgCommit.Git_Operation__c = 'Commit Files';
        return gitOrgCommit;
    }
}