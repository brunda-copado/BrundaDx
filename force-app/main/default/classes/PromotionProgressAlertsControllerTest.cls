@isTest
private with sharing class PromotionProgressAlertsControllerTest {
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
    private static void getPromotionJobExecution() {
        System.runAs(getRunAsUser()) {
            //Setup
            User_Story__c userStory = getUserStory();
            JobTemplate__c jobTemplate = getJobTemplate('Promotion Template');
            
            Promotion__c promotion = (Promotion__c) new Promotion()
                .projectId(userStory.Project__c)
                .sourceEnvId(userStory.Environment__c)
                .status(PromotionConstants.STATUS_DRAFT)
                .persist();
            new PromotedUSerStory().promotion(promotion.Id).userStory(userStory.Id).persist();

            JobExecution__c job = (JobExecution__c) new JobExecution()
                .status(JobExecutionConstants.STATUS_IN_PROGRESS)
                .template(jobTemplate.Id)
                .promotion(promotion.Id)
                .add(new JobStep().name('step1').type('Flow').order(1))
                .persist();

            //Exercise
            Test.startTest();
            JobExecution__c jobExecution = PromotionProgressAlertsController.getPromotionJob(promotion.Id);
            Test.stopTest();

            // Verify
            System.assertEquals(jobExecution.Id, job.Id, 'Job Execution should match');
        }
    }

    @isTest
    private static void getDeploymentJobExecution() {
        System.runAs(getRunAsUser()) {
            //Setup
            User_Story__c userStory = getUserStory();
            JobTemplate__c jobTemplate = getJobTemplate('Deployment Template');
            
            Promotion__c promotion = (Promotion__c)new Promotion()
                .projectId(userStory.Project__c)
                .sourceEnvId(userStory.Environment__c)
                .status(PromotionConstants.STATUS_DRAFT)
                .persist();
            new PromotedUSerStory().promotion(promotion.Id).userStory(userStory.Id).persist();

            Deployment__c deployment = new Deployment__c(Promotion__c = promotion.Id);
            insert deployment;

            JobExecution__c job = (JobExecution__c) new JobExecution()
                .status(JobExecutionConstants.STATUS_IN_PROGRESS)
                .template(jobTemplate.Id)
                .deployment(deployment.Id)
                .add(new JobStep().name('step1').type('Flow').order(1))
                .persist();

            //Exercise
            Test.startTest();
            JobExecution__c jobExecution = PromotionProgressAlertsController.getDeploymentJob(promotion.Id);
            Test.stopTest();

            // Verify
            System.assertEquals(jobExecution.Id, job.Id, 'Job Execution should match');
        }
    }
    private static void createData() {
        new JobTemplate().name('Promotion Template').version(1).mockAutomation('Promotion').add(new JobStep()).persist();
        new JobTemplate().name('Deployment Template').version(1).mockAutomation('PromotionDeployment').add(new JobStep()).persist();

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

    private static User_Story__c getUserStory() {
        return [SELECT Id, Environment__c, Project__c FROM User_Story__c LIMIT 1];
    }

    private static JobTemplate__c getJobTemplate(String templateName) {
        return [SELECT Id FROM JobTemplate__c WHERE Name =: templateName LIMIT 1];
    }
}