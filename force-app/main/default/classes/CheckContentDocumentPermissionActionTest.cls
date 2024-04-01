@IsTest
private with sharing class CheckContentDocumentPermissionActionTest {
    private static final Integer NUMBER_OF_RECORDS = 2;
    private static final Integer NUMBER_OF_VERSIONS = 3;
    @TestSetup
    private static void makeData() {
        User standardUser = setupUser();
        System.runAs(standardUser) {
            setupLicense();
        }
    }

    @IsTest
    private static void deleteFilesOwnedByMe() {
        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            // Setup
            List<Account> accounts = createRecordsAndFiles();
            List<CheckContentDocumentPermissionAction.Request> requests = createRequests(accounts);

            // Exercise
            Test.startTest();
            List<CheckContentDocumentPermissionAction.Result> results = CheckContentDocumentPermissionAction.execute(requests);
            Test.stopTest();

            // Verify
            for (CheckContentDocumentPermissionAction.Result result : results) {
                System.assertEquals(true, result.canDeleteFiles, 'User should be able to delete files');
            }
        }
    }

    @IsTest
    private static void deleteFilesOwnedByOther() {
        // Setup
        List<Account> accounts = createRecordsAndFiles();
        List<CheckContentDocumentPermissionAction.Request> requests = createRequests(accounts);

        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            // Exercise
            Test.startTest();
            List<CheckContentDocumentPermissionAction.Result> results = CheckContentDocumentPermissionAction.execute(requests);
            Test.stopTest();

            // Verify
            for (CheckContentDocumentPermissionAction.Result result : results) {
                System.assertEquals(false, result.canDeleteFiles, 'User should not be able to delete files');
            }
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

    private static List<CheckContentDocumentPermissionAction.Request> createRequests(List<Account> accounts) {
        List<CheckContentDocumentPermissionAction.Request> requests = new List<CheckContentDocumentPermissionAction.Request>();
        for (Account account : accounts) {
            CheckContentDocumentPermissionAction.Request request = new CheckContentDocumentPermissionAction.Request();
            request.recordId = account.Id;
            requests.add(request);
        }
        return requests;
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