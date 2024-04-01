@IsTest
private with sharing class QualityChecksMonitorCtrlTest {
    @TestSetup
    private static void setup() {
        TestUtilities.getAllMultilicense();
        User user = (User) new User_t()
            .assign(new PermissionSetAssignment_t().copadoUser())
            .assign(new PermissionSetAssignment_t().jobEngine())
            .assign(new PermissionSetAssignment_t().functions())
            .assign(new PermissionSetAssignment_t().qualityGatesAdmin())
            .persist();
        System.runAs(user) {
            new CopadoLicense().user(user).enableAll().persist();
            createData();
        }
    }

    @IsTest
    private static void getAfterQualityGateJobs() {
        System.runAs(getRunAsUser()) {
            // Setup
            Promotion__c promotion = createPromotionForProject();
            JobExecution__c mainJob = new JobExecution__c(Promotion__c = promotion.Id);
            insert mainJob;
            QualityChecksMonitorCtrl.JobExecutionData dataJson = new QualityChecksMonitorCtrl.JobExecutionData();
            dataJson.parentJobExecutionId = mainJob.Id;
            JobExecution__c qualityCheckJob = new JobExecution__c(Promotion__c = promotion.Id, DataJson__c = JSON.serialize(dataJson));
            insert qualityCheckJob;

            // Exercise
            Test.startTest();
            QualityChecksMonitorCtrl.QualityChecksData result = QualityChecksMonitorCtrl.getAfterQualityGateJobs(promotion.Id, mainJob.Id);
            Test.stopTest();

            // Verify
            System.assertEquals(1, result.jobExecutions.size(), 'Should have 1 quality check job');
        }
    }

    private static User getRunAsUser() {
        return [SELECT Id FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1];
    }

    private static void createData() {
        new JobTemplate().name('Promotion_Template').mockAutomation('Promotion').add(new JobStep());

        new JobTemplate().name('PromotionDeployment_Template').mockAutomation('PromotionDeployment').add(new JobStep()).persist();

        Credential dev1Credential = new Credential();
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
            .add(
                new Project()
                    .add(new UserStory().title('US1').credential(dev1Credential).add(new UserStoryMetadata().name('TestClass').type('ApexClass')))
                    .add(new UserStory().title('US2').credential(dev1Credential).add(new UserStoryMetadata().name('TestClass').type('ApexClass')))
                    .add(new UserStory().title('US3').credential(dev1Credential).add(new UserStoryMetadata().name('TestClass').type('ApexClass')))
            )
            .persist();
    }

    private static Promotion__c createPromotionForProject() {
        Promotion__c firstPromotion = createPromotion();
        createPromotedUserStories(firstPromotion.Id, [SELECT Id FROM User_Story__c]);
        return firstPromotion;
    }

    private static Promotion__c createPromotion() {
        return (Promotion__c) new Promotion()
            .projectId([SELECT Id FROM Project__c LIMIT 1].Id)
            .sourceEnvId([SELECT Id FROM Environment__c WHERE Name = 'dev1' LIMIT 1].Id)
            .persist();
    }

    private static List<Promoted_User_Story__c> createPromotedUserStories(Id promotionId, List<User_Story__c> userStories) {
        List<Promoted_User_Story__c> result = new List<Promoted_User_Story__c>();

        for (User_Story__c userStory : userStories) {
            result.add(new Promoted_User_Story__c(User_Story__c = userStory.Id, Promotion__c = promotionId));
        }

        insert result;
        return result;
    }
}