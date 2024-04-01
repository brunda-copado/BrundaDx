@isTest
private with sharing class CreateAttachmentActionTest {
    @isTest
    private static void execute() {
        System.runAs(getTestUser()) {
            // Setup
            User_Story__c userStory = new User_Story__c();
            insert userStory;

            CreateAttachmentAction.Request request = new CreateAttachmentAction.Request();
            request.stringData = '{"testKey": "testString"}';
            request.parentRecord = userStory.Id;

            // Exercise
            List<CreateAttachmentAction.Request> requests = new List<CreateAttachmentAction.Request>{ request };
            CreateAttachmentAction.execute(requests);

            // Verify
            System.assertEquals(
                request.stringData,
                [SELECT Body FROM Attachment WHERE ParentId = :userStory.Id].Body.toString(),
                'Body of attachment should be equals to the action input'
            );
        }
    }

    @TestSetup
    private static void setupUser() {
        new CopadoSetupTestDefaults.UserDefaults().createRunAsUsers().executeDML();
    }

    private static User getTestUser() {
        return [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test@test.org' LIMIT 1].get(0);
    }
}