@IsTest
private with sharing class ValidateGitSnapshotTest {
    @TestSetup
    static void setupData() {
        TestUtilities.getAllMultilicense();
        User user = (User) new User_t()
            .assign(new PermissionSetAssignment_t().copadoUser())
            .assign(new PermissionSetAssignment_t().functions())
            .assign(new PermissionSetAssignment_t().jobEngine())
            .assign(new PermissionSetAssignment_t().configureSnapshots())
            .persist();
        System.runAs(user) {
            new CopadoLicense().user(user).enableAll().persist();
            createData();
        }
    }

    @IsTest
    static void validatePermissionSet() {
        System.runAs(getRunAsUser()) {
            // Setup
            Org__c credWithOtherPlatform = getCredential('Other', 'dev');
            Git_Repository__c gitRepo = getRepository();
            delete [SELECT Id FROM PermissionSetAssignment WHERE AssigneeId = :UserInfo.getUserId() AND PermissionSet.Name = 'Configure_Snapshot'];

            // Exercise
            Test.startTest();
            try {
                new GitSnapshot()
                    .name('testbackup')
                    .credential(credWithOtherPlatform.Id)
                    .gitRepository(gitRepo.Id)
                    .pipeline(getPipeline('Other').Id)
                    .persist();
            } catch (Exception ex) {
                // Verify
                System.assert(
                    ex.getMessage().contains(Label.ConfigureSnapshotPermIsRequiredCurrentUser),
                    'Configure Snapshot permission set should be assigned to User'
                );
            }

            Test.stopTest();
        }
    }

    @IsTest
    static void testPipelineIsActive() {
        System.runAs(getRunAsUser()) {
            // Setup
            Org__c credWithOtherPlatform = getCredential('Other', 'dev');
            Deployment_Flow__c pipeline = getPipeline('Other');
            Git_Repository__c gitRepo = getRepository();

            // Exercise
            Test.startTest();
            new GitSnapshot().name('testbackup').credential(credWithOtherPlatform.Id).gitRepository(gitRepo.Id).pipeline(pipeline.Id).persist();
            Test.stopTest();

            // Verify
            System.assertEquals(true, pipeline.Active__c, 'Pipeline record should be active');
            Git_Backup__c fetchedGiSnapshot = [SELECT Id FROM Git_Backup__c];
            System.assert(fetchedGiSnapshot.Id != null, 'Git Snapshot record should be inserted');
        }
    }

    @IsTest
    static void testPipelineIsNotActive() {
        System.runAs(getRunAsUser()) {
            // Setup
            Org__c credWithOtherPlatform = getCredential('Other', 'dev');
            Deployment_Flow__c pipeline = getPipeline('Other');
            pipeline.Active__c = false;
            update pipeline;
            Git_Repository__c gitRepo = getRepository();

            // Exercise + Verify
            Test.startTest();
            try {
                new GitSnapshot().name('testbackup').credential(credWithOtherPlatform.Id).gitRepository(gitRepo.Id).pipeline(pipeline.Id).persist();
            } catch (Exception ex) {
                System.assertEquals(false, pipeline.Active__c, 'Pipeline record should not be active');
                System.assert(ex.getMessage().contains(Label.PipelineIsNotActive), 'Pipeline is not active error shoudl be thrown');
            }
            Test.stopTest();
        }
    }

    @IsTest
    static void testCredentialSecondGen() {
        System.runAs(getRunAsUser()) {
            // Setup
            Org__c credWithOtherPlatform = getCredential('Salesforce', 'dev');
            Git_Repository__c gitRepo = getRepository();

            // Exercise + Verify
            Test.startTest();
            try {
                new GitSnapshot()
                    .name('testbackup')
                    .credential(credWithOtherPlatform.Id)
                    .gitRepository(gitRepo.Id)
                    .pipeline(getPipeline('Other').Id)
                    .persist();
            } catch (Exception ex) {
                System.assert(
                    ex.getMessage()
                        .contains(String.format(Label.SecondGenCredentialShouldBeAssociated, new List<string>{ credWithOtherPlatform.Name })),
                    'Credential should be 2nd Gen'
                );
            }
            Test.stopTest();
        }
    }

    @IsTest
    static void testSecondGenPipeline() {
        System.runAs(getRunAsUser()) {
            // Setup
            Org__c credential = getCredential('Salesforce', 'dev');
            Deployment_Flow__c pipeline = getPipeline('Salesforce');
            Git_Repository__c gitRepo = getRepository();

            // Exercise + Verify
            Test.startTest();
            try {
                new GitSnapshot().name('testbackup').credential(credential.Id).gitRepository(gitRepo.Id).pipeline(pipeline.Id).persist();
            } catch (Exception ex) {
                System.assert(ex.getMessage().contains(Label.SecondGenPlatformShouldBeAssociated), 'Pipeline should be 2nd Gen');
            }
            Test.stopTest();
        }
    }

    @IsTest
    static void testcronExpressionWithValidData() {
        System.runAs(getRunAsUser()) {
            // Setup
            Org__c credWithOtherPlatform = getCredential('Other', 'dev');
            Git_Repository__c gitRepo = getRepository();

            // Exercise
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

            // Verify
            String jobName = gitBackup.Id + '_' + gitRepo.Name;
            AsyncApexJob scheduledJob = [
                SELECT ApexClass.Name, Id, JobType, Status, CronTrigger.CronJobDetail.Name, CronTrigger.CronExpression
                FROM AsyncApexJob
                WHERE CronTrigger.CronJobDetail.Name = :jobName AND JobType = 'ScheduledApex'
            ];
            System.assert(scheduledJob.Id != null, 'Job should be scheduled');
        }
    }

    @IsTest
    static void testcronExpressionWithEmptyCronExpression() {
        System.runAs(getRunAsUser()) {
            // Setup
            Org__c credWithOtherPlatform = getCredential('Other', 'dev');
            Git_Repository__c gitRepo = getRepository();

            // Exercise + Verify
            try {
                Test.startTest();
                new GitSnapshot()
                    .name('testbackup')
                    .credential(credWithOtherPlatform.Id)
                    .gitRepository(gitRepo.Id)
                    .pipeline(getPipeline('Other').Id)
                    .mcFrequency('Schedule')
                    .cronExpression('')
                    .persist();

                Test.stopTest();
            } catch (Exception ex) {
                System.assertEquals(ex.getMessage().contains(Label.CronExpressionIsRequired), true, 'cronExpression is Required');
            }
        }
    }

    private static void createData() {
        new JobTemplate().name('Snapshot Template').mockAutomation(ActionConstants.TAKE_SNAPSHOT).add(new JobStep()).persist();
        createPipeline('Other');
        createPipeline('Salesforce');
    }

    private static Deployment_Flow__c createPipeline(String platform) {
        Environment dev = new Environment().name(platform + 'dev').type('Sandbox').platform(platform).add(new Credential());
        Environment prod = new Environment().name(platform + 'prod').type('Sandbox').platform(platform).add(new Credential());

        Deployment_Flow__c pipeline = (Deployment_Flow__c) new Pipeline()
            .active(true)
            .mainBranch('main')
            .setPlatform(platform)
            .add(new Connection(dev, prod).branch('dev'))
            .persist();

        return pipeline;
    }

    private static User getRunAsUser() {
        return [SELECT Id FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1];
    }

    private static Deployment_Flow__c getPipeline(String platform) {
        return [SELECT Id, Active__c FROM Deployment_Flow__c WHERE Platform__c = :platform LIMIT 1];
    }

    private static Org__c getCredential(String platform, String environmentName) {
        String environment = platform + environmentName;
        return [SELECT Id, Name FROM Org__c WHERE Platform__c = :platform AND Environment__r.Name = :environment LIMIT 1];
    }

    private static Git_Repository__c getRepository() {
        return [SELECT Id, Name FROM Git_Repository__c LIMIT 1];
    }

    private static Git_Backup__c getSnapshot() {
        return [SELECT Id, Name FROM Git_Backup__c LIMIT 1];
    }
}