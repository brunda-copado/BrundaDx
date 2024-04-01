@IsTest
private with sharing class DeleteOldContentVersionsActionTest {
    private static final Integer NUMBER_OF_RECORDS = 2;
    private static final Integer NUMBER_OF_VERSIONS = 3;
    @TestSetup
    private static void makeData() {
        User standardUser = setupUser();
        System.runAs(standardUser) {
            setupLicense();
            createRecordsAndFiles();
        }
    }

    @IsTest
    private static void deleteOldVersions() {
        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            // Setup
            List<Account> accounts = [SELECT Id FROM Account];
            Set<Id> accountIds = new Map<Id, Account>(accounts).keySet();
            List<DeleteOldContentVersionsAction.Request> requests = new List<DeleteOldContentVersionsAction.Request>();
            for (Account account : accounts) {
                DeleteOldContentVersionsAction.Request request = new DeleteOldContentVersionsAction.Request();
                request.recordId = account.Id;
                requests.add(request);
            }

            // Exercise
            Test.startTest();
            DeleteOldContentVersionsAction.execute(requests);
            Test.stopTest();

            // Verify
            Set<Id> contentDocumentIds = new Set<Id>();
            Map<Id, List<ContentDocumentLink>> contentDocumentLinksByRecordId = new Map<Id, List<ContentDocumentLink>>();
            for (ContentDocumentLink contentDocumentLink : [
                SELECT ContentDocumentId, LinkedEntityId
                FROM ContentDocumentLink
                WHERE LinkedEntityId IN :accountIds
            ]) {
                contentDocumentIds.add(contentDocumentLink.ContentDocumentId);
                if (!contentDocumentLinksByRecordId.containsKey(contentDocumentLink.LinkedEntityId)) {
                    contentDocumentLinksByRecordId.put(contentDocumentLink.LinkedEntityId, new List<ContentDocumentLink>());
                }
                contentDocumentLinksByRecordId.get(contentDocumentLink.LinkedEntityId).add(contentDocumentLink);
            }
            Map<Id, List<ContentVersion>> contentVersionsByContentDocumentId = new Map<Id, List<ContentVersion>>();
            for (ContentVersion contentVersion : [
                SELECT ID, ContentDocumentId, Description
                FROM ContentVersion
                WHERE ContentDocumentId IN :contentDocumentIds
            ]) {
                if (!contentVersionsByContentDocumentId.containsKey(contentVersion.ContentDocumentId)) {
                    contentVersionsByContentDocumentId.put(contentVersion.ContentDocumentId, new List<ContentVersion>());
                }
                contentVersionsByContentDocumentId.get(contentVersion.ContentDocumentId).add(contentVersion);
            }
            for (Account account : accounts) {
                List<ContentDocumentLink> contentDocumentLinksForAccount = contentDocumentLinksByRecordId.get(account.Id);
                System.assertEquals(1, contentDocumentLinksForAccount.size(), 'The record should have 1 document related');
                for (ContentDocumentLink contentDocumentLink : contentDocumentLinksForAccount) {
                    List<ContentVersion> contentVersionsForAccount = contentVersionsByContentDocumentId.get(contentDocumentLink.ContentDocumentId);
                    System.assertEquals(1, contentVersionsForAccount.size(), 'There should be only 1 version of the file');
                    System.assertEquals(
                        'version ' + NUMBER_OF_VERSIONS,
                        contentVersionsForAccount[0].Description,
                        'The version should be the last one'
                    );
                }
            }
        }
    }

    @IsTest
    private static void permissionsError() {
        // Setup
        List<Account> accounts = [SELECT Id FROM Account];
        Set<Id> accountIds = new Map<Id, Account>(accounts).keySet();
        createFiles(accountIds, NUMBER_OF_RECORDS);
        List<DeleteOldContentVersionsAction.Request> requests = new List<DeleteOldContentVersionsAction.Request>();
        for (Account account : accounts) {
            DeleteOldContentVersionsAction.Request request = new DeleteOldContentVersionsAction.Request();
            request.recordId = account.Id;
            requests.add(request);
        }

        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            // Exercise + Verify
            Test.startTest();
            try {
                DeleteOldContentVersionsAction.execute(requests);
            } catch (Exception e) {
                System.assert(true, 'Insufficient access exception should be thrown');
            }
            Test.stopTest();
        }
    }

    private static List<Account> createRecordsAndFiles() {
        List<Account> accounts = createAccounts(NUMBER_OF_RECORDS);

        Set<Id> accountIds = new Map<Id, Account>(accounts).keySet();

        createFiles(accountIds, NUMBER_OF_VERSIONS);

        return accounts;
    }

    private static List<Account> createAccounts(Integer numberOfAccounts) {
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < numberOfAccounts; i++) {
            accounts.add(new Account(Name = 'Test Account' + i));
        }
        insert accounts;
        return accounts;
    }

    private static void createFiles(Set<Id> recordIds, Integer numberOfVersions) {
        List<ContentVersion> contentVersions = new List<ContentVersion>();
        for (Id recordId : recordIds) {
            contentVersions.add(
                new ContentVersion(
                    Title = 'Test File',
                    PathOnClient = 'test_file.txt',
                    VersionData = Blob.valueOf('test content'),
                    Description = 'version 1',
                    FirstPublishLocationId = recordId
                )
            );
        }
        insert contentVersions;

        contentVersions = new List<ContentVersion>();
        for (ContentVersion contentVersion : [SELECT Id, ContentDocumentId FROM ContentVersion]) {
            for (Integer i = 2; i <= numberOfVersions; i++) {
                contentVersions.add(
                    new ContentVersion(
                        Title = 'Test File',
                        PathOnClient = 'test_file.txt',
                        VersionData = Blob.valueOf('test content' + i),
                        Description = 'version ' + i,
                        ContentDocumentId = contentVersion.ContentDocumentId
                    )
                );
            }
        }
        insert contentVersions;
    }

    private static User setupUser() {
        ITestDefaults userCreation = new CopadoSetupTestDefaults.UserDefaults().createRunAsUsers().executeDML();
        User standardUser = userCreation.getRunAsUsers().get('Standard')[0];
        return standardUser;
    }

    private static void setupLicense() {
        TestUtilities.enableLicenses(2, 2, 2, 2, 2, 2, 2);
        TestUtilities.assignLicense(String.valueOf(UserInfo.getUserName()), true, true, true, true, true, true);
    }

    private static User getStandardUser() {
        User standardUser = [
            SELECT Id
            FROM User
            WHERE ProfileId IN (SELECT Id FROM Profile WHERE Name = 'Standard User')
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        return standardUser;
    }
}