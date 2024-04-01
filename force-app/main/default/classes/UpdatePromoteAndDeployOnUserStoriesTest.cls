@IsTest
private class UpdatePromoteAndDeployOnUserStoriesTest {
    
    @TestSetup
    private static void makeData() {
        TestUtilities.getAllMultilicense();
        User user = (User) new User_t()
            .assign(new PermissionSetAssignment_t().copadoUser())
            .assign(new PermissionSetAssignment_t().executeAutomations())
            .persist();
        System.runAs(user) {
            new CopadoLicense().user(user).enableAll().persist();
            createData();
        }
    }

    @IsTest
    static void updatePromoteAndDeployOnUserStoriesExecute() {
        System.runAs(getUser()) {
            // Setup
            Promotion__c promotion = createPromotion();

            User_Story__c userStory = [SELECT Id FROM User_Story__c];
            UserStories.bypassTrigger = true;
            userStory.Promote_and_Deploy__c = true;
            update userStory;
            UserStories.bypassTrigger = false;
            
            // Exercise
            Test.startTest();
            new UpdatePromoteAndDeployOnUserStories(new Set<Id> {promotion.Id}).execute();
            Test.stopTest();

            // Verify
            User_Story__c resultUserStory = [SELECT Promote_and_Deploy__c FROM User_Story__c WHERE Id = :userStory.Id];
            System.assertEquals(false, resultUserStory.Promote_and_Deploy__c, 'Promote And Deploy should be set to false');
        }
    }

    // HELPER

    private static void createData() {
        Credential dev1Credential = new Credential();
        Environment dev1 = new Environment().name('dev1').type('Sandbox').platform('Other').add(dev1Credential);
        Environment integration = new Environment().name('int').type('Sandbox').platform('Other').add(new Credential());

        new Pipeline()
            .active(true)
            .mainBranch('main')
            .setPlatform('Other')
            .add(new Connection(dev1, integration).branch('dev1'))
            .add(new Project().add(new UserStory().credential(dev1Credential)))
            .persist();
    }

    private static Promotion__c createPromotion() {
        Promotion__c promotion = (Promotion__c) new Promotion()
            .projectId([SELECT Id FROM Project__c LIMIT 1].Id)
            .sourceEnvId([SELECT Id FROM Environment__c WHERE Name = 'dev1' LIMIT 1].Id)
            .persist();

        Promoted_User_Story__c promotedUserStory = new Promoted_User_Story__c(
            User_Story__c = [SELECT Id FROM User_Story__c LIMIT 1].Id,
            Promotion__c = promotion.Id
        );
        insert promotedUserStory;
        return promotion;
    }

    private static User getUser() {
        return [SELECT Id FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1];
    }

}