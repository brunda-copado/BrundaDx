@isTest
private with sharing class UserStoryCommitProgressAlertsCtrlTest {
    @TestSetup
    private static void setup() {
        TestUtilities.getAllMultilicense();
        User user = (User) new User_t()
            .assign(new PermissionSetAssignment_t().copadoUser())
            .assign(new PermissionSetAssignment_t().functions())
            .assign(new PermissionSetAssignment_t().jobEngine())
            .persist();
        System.runAs(user) {
            new CopadoLicense().user(user).enableAll().persist();
            createData();
        }
    }

    @isTest
    private static void getJobExecution() {
        System.runAs(getRunAsUser()) {
            //Setup
            User_Story__c userStory = [SELECT Id FROM User_Story__c LIMIT 1];
            Org__c credential = [SELECT Id FROM Org__c LIMIT 1];
            JobTemplate__c jobTemplate = [SELECT Id FROM JobTemplate__c LIMIT 1];

            Git_Org_Commit__c snapshot = new Git_Org_Commit__c(Status__c = 'In progress', Org__c = credential.Id);
            insert snapshot;

            User_Story_Commit__c userStoryCommit = new User_Story_Commit__c(Name = 'Alerts');
            userStoryCommit.User_Story__c = userStory.Id;
            userStoryCommit.Snapshot_Commit__c = snapshot.Id;
            insert userStoryCommit;

            JobExecution__c job = (JobExecution__c) new JobExecution()
                .status('In Progress')
                .template(jobTemplate.Id)
                .userStoryCommit(userStoryCommit.Id)
                .add(new JobStep().name('step1').type('Flow').order(1))
                .persist();

            //Exercise
            Test.startTest();
            List<JobExecution__c> jobExecution = UserStoryCommitProgressAlertsCtrl.getJobExecution(userStory.Id);
            Test.stopTest();

            // Verify
            System.assertEquals(jobExecution[0].Id, job.Id, 'Job Execution should match');
        }
    }

    @isTest
    private static void getLastPromotion() {
        System.runAs(getRunAsUser()) {
            //Setup
            User_Story__c userStory = [SELECT Id, Environment__c, Project__c FROM User_Story__c LIMIT 1];

            Promotion__c promotion = (Promotion__c) new Promotion()
                .projectId(userStory.Project__c)
                .sourceEnvId(userStory.Environment__c)
                .status(PromotionConstants.STATUS_DRAFT)
                .persist();

            new PromotedUSerStory().promotion(promotion.Id).userStory(userStory.Id).persist();

            //Exercise
            Test.startTest();
            List<Promoted_User_Story__c> promotedUserStories = UserStoryCommitProgressAlertsCtrl.getLastPromotion(userStory.Id);
            Test.stopTest();

            // Verify
            System.assertEquals(1, promotedUserStories.size(), 'One promoted user story returned');
        }
    }

    private static void createData() {
        new JobTemplate().name('Commit Template').version(1).mockAutomation('Commit').add(new JobStep()).persist();

        Credential source = new Credential();

        new Pipeline()
            .mainBranch('main')
            .setPlatform('Other')
            .add(
                new Connection(
                        new Environment().name('dev1').platform('Other').add(source),
                        new Environment().platform('Other').add(new Credential())
                    )
                    .branch('dev1')
            )
            .add(
                new Connection(new Environment().platform('Other').add(new Credential()), new Environment().platform('Other').add(new Credential()))
                    .branch('dev2')
            )
            .add(
                new Project()
                    .add(
                        new UserStory()
                            .credential(source)
                            .add(new UserStoryMetadata().name('TestClass1').type('ApexClass1'))
                            .add(new UserStoryMetadata().name('TestClass2').type('ApexClass2'))
                    )
            )
            .persist();
    }

    private static User getRunAsUser() {
        return [SELECT Id FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1];
    }
}