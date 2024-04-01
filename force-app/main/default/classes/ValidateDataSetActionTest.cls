@IsTest
private with sharing class ValidateDataSetActionTest {
    @TestSetup
    private static void makeData() {
        User standardUser = setupUser();
        System.runAs(standardUser) {
            setupLicense();
            createTestData();
        }
    }

    @IsTest
    private static void checkHasNoFiles() {
        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            // Setup
            Data_Set__c dataSet = getDataSet();
            ValidateDataSetAction.Request request = createRequest(dataSet);

            // Exercise
            Test.startTest();
            List<ValidateDataSetAction.Result> results = ValidateDataSetAction.execute(new List<ValidateDataSetAction.Request>{ request });
            Test.stopTest();

            // Verify
            for (ValidateDataSetAction.Result result : results) {
                System.assertEquals(false, result.hasValidFiles, 'Validation should return false, as the Data Set has no files related');
            }
        }
    }

    @IsTest
    private static void checkInvalidFiles() {
        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            // Setup
            Data_Set__c dataSet = getDataSet();
            createInvalidFiles(dataSet);
            ValidateDataSetAction.Request request = createRequest(dataSet);

            // Exercise
            Test.startTest();
            List<ValidateDataSetAction.Result> results = ValidateDataSetAction.execute(new List<ValidateDataSetAction.Request>{ request });
            Test.stopTest();

            // Verify
            for (ValidateDataSetAction.Result result : results) {
                System.assertEquals(false, result.hasValidFiles, 'Validation should return false, as the Data Set does not have csv files related');
            }
        }
    }

    @IsTest
    private static void checkValidFiles() {
        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            // Setup
            Data_Set__c dataSet = getDataSet();
            createValidFiles(dataSet);
            ValidateDataSetAction.Request request = createRequest(dataSet);

            // Exercise
            Test.startTest();
            List<ValidateDataSetAction.Result> results = ValidateDataSetAction.execute(new List<ValidateDataSetAction.Request>{ request });
            Test.stopTest();

            // Verify
            for (ValidateDataSetAction.Result result : results) {
                System.assertEquals(true, result.hasValidFiles, 'Validation should return true, as the Data Set has valid files related');
            }
        }
    }

    private static ValidateDataSetAction.Request createRequest(Data_Set__c dataSet) {
        ValidateDataSetAction.Request request = new ValidateDataSetAction.Request();
        request.recordId = dataSet.Id;
        return request;
    }

    private static void createValidFiles(Data_Set__c dataSet) {
        List<ContentVersion> contentVersions = new List<ContentVersion>();
        contentVersions.add(createCsvFile(dataSet));
        contentVersions.add(createTemplateFile(dataSet));
        insert contentVersions;
    }

    private static void createInvalidFiles(Data_Set__c dataSet) {
        List<ContentVersion> contentVersions = new List<ContentVersion>();
        contentVersions.add(createTemplateFile(dataSet));
        insert contentVersions;
    }

    private static ContentVersion createCsvFile(Data_Set__c dataSet) {
        String fileName = dataSet.Data_Template__c + '-' + dataSet.Data_Template__r.Name + '.records' + '.csv';
        ContentVersion contentVersion = new ContentVersion(
            Title = fileName,
            PathOnClient = fileName,
            VersionData = Blob.valueOf('csv records'),
            FirstPublishLocationId = dataSet.Id
        );
        return contentVersion;
    }

    private static ContentVersion createTemplateFile(Data_Set__c dataSet) {
        String fileName = 'MT-' + dataSet.Data_Template__c + '-' + dataSet.Data_Template__r.Name + '.template';
        ContentVersion contentVersion = new ContentVersion(
            Title = fileName,
            PathOnClient = fileName,
            VersionData = Blob.valueOf('template data'),
            FirstPublishLocationId = dataSet.Id
        );
        return contentVersion;
    }

    private static void createTestData() {
        Data_Template__c dataTemplate = new Data_Template__c(Name = 'test');
        insert dataTemplate;
        Data_Set__c dataSet = new Data_Set__c(Data_Template__c = dataTemplate.Id);
        insert dataSet;
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

    private static Data_Set__c getDataSet() {
        Data_Set__c dataSet = [SELECT Id, Data_Template__r.Name FROM Data_Set__c LIMIT 1];
        return dataSet;
    }
}