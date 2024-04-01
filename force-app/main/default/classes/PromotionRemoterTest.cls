@IsTest
private with sharing class PromotionRemoterTest {
    @TestSetup
    private static void setupData() {
        TestUtilities.getAllMultilicense();
        User user = (User) new User_t()
            .assign(new PermissionSetAssignment_t().copadoUser())
            .assign(new PermissionSetAssignment_t().functions())
            .assign(new PermissionSetAssignment_t().jobEngine())
            .assign(new PermissionSetAssignment_t().qualityGatesAdmin())
            .assign(new PermissionSetAssignment_t().configureAutomations())
            .assign(new PermissionSetAssignment_t().executeAutomations())
            .persist();
        System.runAs(user) {
            new CopadoLicense().user(user).enableAll().persist();
            createData();
        }
    }

    @IsTest
    private static void executePromotionAction() {
        System.runAs(getUser()) {
            // Setup
            Promotion__c promotion = createPromotion();
            Flow.mockResponse = flowCompletionEvent(true, '', '');

            // Exercise
            Test.startTest();
            PromotionRemoter.executePromotionAction(promotion.Id, false);
            Test.stopTest();

            // Verify
            JobExecution__c jobExecution = [SELECT Status__c, Promotion__c FROM JobExecution__c LIMIT 1];
            System.assertEquals('Successful', jobExecution.Status__c, 'Job execution status should be Successful');
            System.assertEquals(promotion.Id, jobExecution.Promotion__c, 'There should be a Promotion created');
        }
    }

    private static User getUser() {
        return [SELECT Id, Email FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1];
    }

    private static void createData() {
        new JobTemplate().name('Commit_Template').mockAutomation('Commit').add(new JobStep());
        new JobTemplate().name('Promotion_Template').mockAutomation('Promotion').add(new JobStep());
        new JobTemplate().name('PromotionDeployment_Template').mockAutomation('PromotionDeployment').add(new JobStep());
        new JobTemplate().name('Package_Create_Template').mockAutomation('CreatePackage').add(new JobStep());
        new JobTemplate().name('Package_Version_Create').mockAutomation('CreatePackageVersion').add(new JobStep());
        new JobTemplate().name('Package_Distribute').mockAutomation('PublishPackageVersion').add(new JobStep()).persist();

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
                    .add(new UserStory().credential(dev1Credential).add(new UserStoryMetadata().name('TestClass').type('ApexClass')))
                    .add(new UserStory().credential(dev1Credential).add(new UserStoryMetadata().name('TestClass 1').type('ApexClass')))
            )
            .persist();
    }

    private static Promotion__c createPromotion() {
        Promotion__c firstPromotion = (Promotion__c) new Promotion()
            .projectId([SELECT Id FROM Project__c LIMIT 1].Id)
            .sourceEnvId([SELECT Id FROM Environment__c WHERE Name = 'dev1' LIMIT 1].Id)
            .persist();

        Promoted_User_Story__c promotedUserStory = new Promoted_User_Story__c(
            User_Story__c = [SELECT Id FROM User_Story__c LIMIT 1]
            .Id,
            Promotion__c = firstPromotion.Id
        );
        insert promotedUserStory;
        return firstPromotion;
    }

    private static Event__e flowCompletionEvent(Boolean isSuccess, String errorMessage, String data) {
        Event__e result = new Event__e();
        result.Topic_Uri__c = OnJobStepComplete.STEP_ENDPOINT;
        result.Payload__c = Json.serialize(new OnJobStepComplete.EventPayload(isSuccess, errorMessage, data));

        return result;
    }
}