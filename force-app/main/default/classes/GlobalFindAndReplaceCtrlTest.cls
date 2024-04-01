@IsTest
private class GlobalFindAndReplaceCtrlTest {

    @TestSetup
    private static void setup() {
        new User_t().persist();
        new UserStory().persist();
    }

    @IsTest
    private static void upsertFile() {
        // Setup
        User_Story__c userStory = getUserStory();
        String fileName = 'my file.txt';

        // Exercise
        System.runAs(getRunAsUser()) {
            GlobalFindAndReplaceCtrl.upsertFile(userStory.Id, fileName, 'data1');
            GlobalFindAndReplaceCtrl.upsertFile(userStory.Id, fileName, 'data2');
        }

        // Verify
        List<ContentVersion> versions = getContentVersions(userStory.Id);
        System.assertEquals(1, versions.size(), 'New file should be generated with one version only');
    }

    @IsTest
    private static void getFileWithCopadoFile() {
        // Setup
        User_Story__c userStory = getUserStory();
        String fileName = 'Copado.yml';
        String body = 'test content';

        GlobalFindAndReplaceCtrl.upsertFile(userStory.Id, fileName, body);

        GlobalFindAndReplaceCtrl.DocumentData document;

        // Exercise
        System.runAs(getRunAsUser()) {
            document = GlobalFindAndReplaceCtrl.getFile(userStory.Id);
        }

        // Verify
        System.assertNotEquals(null, document, 'A document should be returned');
        System.assertEquals(fileName, document.name, 'Document name should match');
        System.assertEquals(EncodingUtil.base64Encode(Blob.valueOf(body)), document.body, 'Document body should match');
    }

    @IsTest
    private static void getFileWithoutCopadoFile() {
        // Setup
        User_Story__c userStory = getUserStory();
        String fileName = 'other.txt';
        String body = 'test content';

        GlobalFindAndReplaceCtrl.upsertFile(userStory.Id, fileName, body);

        GlobalFindAndReplaceCtrl.DocumentData document;

        // Exercise
        System.runAs(getRunAsUser()) {
            document = GlobalFindAndReplaceCtrl.getFile(userStory.Id);
        }

        // Verify
        System.assertEquals(null, document, 'No document should be returned');
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
        return [SELECT Id FROM ContentVersion WHERE ContentDocumentId IN :contentDocumentIds];
    }
}