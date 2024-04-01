@IsTest
private with sharing class PromotionJobExecutionsCtrlTest {
    @TestSetup
    private static void setupData() {
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

    @IsTest
    private static void getJobExecutions() {
        System.runAs(getRunAsUser()) {
            // Setup
            String promotionId = [SELECT Id FROM Promotion__c LIMIT 1].Id;

            // Exercise
            Test.startTest();
            List<Id> jobExecutionIds = PromotionJobExecutionsCtrl.getJobExecutionIds(promotionId);
            Test.stopTest();

            // Verify
            System.assertEquals(2, jobExecutionIds.size(), 'Number of job executions should match');
        }
    }

    private static User getRunAsUser() {
        return [SELECT Id FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1];
    }

    private static void createData() {
        new JobTemplate().name('Promotion').mockAutomation(ActionConstants.PROMOTION).add(new JobStep()).persist();

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
            .add(new Project().add(new UserStory().credential(source).add(new UserStoryMetadata().name('TestClass').type('ApexClass'))))
            .persist();

        Promotion__c promotion = (Promotion__c) new Promotion()
            .projectId([SELECT Id FROM Project__c LIMIT 1].Id)
            .sourceEnvId([SELECT Id FROM Environment__c WHERE Name = 'dev1' LIMIT 1].Id)
            .persist();
        Deployment__c deployment = new Deployment__c(Promotion__c = promotion.Id);
        insert deployment;
        new JobExecution().promotion(promotion.Id);
        new JobExecution().deployment(deployment.Id).persist();
    }
}