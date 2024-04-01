@IsTest
private with sharing class FilesTest {
    @TestSetup
    private static void setup() {
        new User_t().persist();
        new UserStory().persist();
    }

    @IsTest
    private static void createNewFile() {
        // Setup
        User_Story__c userStory = getUserStory();
        String filename = 'my file.txt';

        // Exercise
        System.runAs(getRunAsUser()) {
            new Files().upsertFile(userStory.Id, filename, 'data1');
        }

        // Verify
        List<ContentVersion> versions = getContentVersions(userStory.Id);
        System.assertEquals(1, versions.size(), 'New file should be generated with one version only');
        System.assertEquals('my file', versions[0].Title, 'File title should not contain extension');
    }

    @IsTest
    private static void upsertFile() {
        // Setup
        User_Story__c userStory = getUserStory();
        String filename = 'my file.txt';

        // Exercise
        System.runAs(getRunAsUser()) {
            new Files().upsertFile(userStory.Id, filename, 'data1');
            new Files().upsertFile(userStory.Id, filename, 'data2');
        }

        // Verify
        List<ContentVersion> versions = getContentVersions(userStory.Id);
        System.assertEquals(1, versions.size(), 'New file should be generated with one version only');
    }

    @IsTest
    private static void createNewVersion() {
        // Setup
        User_Story__c userStory = getUserStory();
        String filename = 'my file.txt';

        // Exercise
        System.runAs(getRunAsUser()) {
            new Files().upsertFile(userStory.Id, filename, 'data1');
        }

        User otherUser = (User) new User_t().persist();
        System.runAs(otherUser) {
            new Files().upsertFile(userStory.Id, filename, 'data2');
        }

        // Verify
        List<ContentVersion> versions = getContentVersions(userStory.Id);
        System.assertEquals(2, versions.size(), 'New file version should be generated');
    }

    private static User getRunAsUser() {
        return [SELECT Id FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1];
    }

    private static User_Story__c getUserStory() {
        return [SELECT Id FROM User_Story__c LIMIT 1];
    }

    private static List<ContentVersion> getContentVersions(Id recordId) {
        List<Id> contentDocumentIds = new List<Id>();
        for (ContentDocumentLink link : [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :recordId]) {
            contentDocumentIds.add(link.ContentDocumentId);
        }
        return [SELECT Id, Title FROM ContentVersion WHERE ContentDocumentId IN :contentDocumentIds];
    }
}