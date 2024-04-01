@isTest
private class OrderDeploymentStepsControllerTest {
    @TestSetup
    private static void setupData() {
        TestUtilities.getAllMultilicense();
        User user = (User) new User_t()
            .assign(new PermissionSetAssignment_t().copadoUser())
            .assign(new PermissionSetAssignment_t().jobEngine())
            .persist();
        System.runAs(user) {
            new CopadoLicense().user(user).enableAll().persist();
            createData();
        }
    }

    @isTest
    private static void getStepsFromPromotionId() {
        System.runAs(getRunAsUser()) {
            // Setup
            Promotion__c promotion = getPromotion();

            // Exercise
            Test.startTest();
            List<JobStep__c> steps = OrderDeploymentStepsController.getFilteredDeploymentSteps(promotion.Id, true);
            Test.stopTest();

            // Verify
            System.assertEquals(2, steps.size(), 'There should be 2 deployment steps');
        }
    }

    @isTest
    private static void getStepsFromUserId() {
        System.runAs(getRunAsUser()) {
            // Setup
            User_Story__c userStory = getUserStory();
            createDeploymentSteps(userStory.Id);

            // Exercise
            Test.startTest();
            List<JobStep__c> steps = OrderDeploymentStepsController.getFilteredDeploymentSteps(userStory.Id, true);
            Test.stopTest();

            // Verify
            System.assertEquals(2, steps.size(), 'There should be 2 deployment steps');
        }
    }

    // PRIVATE

    private static void createData() {
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
            .add(new Project().add(new UserStory().credential(source)))
            .persist();
    }

    private static User getRunAsUser() {
        return [SELECT Id FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1];
    }

    private static Deployment_Flow__c getPipeline() {
        return [SELECT Id FROM Deployment_Flow__c LIMIT 1];
    }

    private static User_Story__c getUserStory() {
        return [SELECT Id, Environment__c, Project__c FROM User_Story__c LIMIT 1];
    }

    private static Promotion__c getPromotion() {
        User_Story__c userStory = getUserStory();
        createDeploymentSteps(userStory.Id);

        Promotion__c promotion = (Promotion__c) new Promotion()
            .projectId(userStory.Project__c)
            .sourceEnvId(userStory.Environment__c)
            .status(PromotionConstants.STATUS_DRAFT)
            .persist();

        new PromotedUSerStory().promotion(promotion.Id).userStory(userStory.Id).persist();
        return promotion;
    }

    private static void createDeploymentSteps(Id userStoryId) {
        new JobStep().executionSequence(PromotionConstants.BEFORE_VALUE).userStory(userStoryId).configJson('{"runOnValidationDeployment":true}');
        new JobStep()
            .executionSequence(PromotionConstants.AFTER_VALUE)
            .userStory(userStoryId)
            .configJson('{"runOnValidationDeployment":true}')
            .persist();
    }
}