@IsTest
private with sharing class TestCustomLookupComponentHelper {
    private static final String DEPLOYMENT_AUTOMATION_TEMPLATE_RECORD_TYPE_NAME = 'Automation_Template';
    private static final String STANDARD_USER = 'test_user@myorg.com';

    private static Map<String, Schema.RecordTypeInfo> recordTypeInfoByDeveloperName = Schema.SObjectType.Deployment__c.getRecordTypeInfosByDeveloperName();

    @TestSetup
    static void makeData() {
        TestUtilities.enableLicenses(2, 2, 2, 2, 2, 30);
        ITestDefaults userCreation = new CopadoSetupTestDefaults.UserDefaults().createRunAsUsers().executeDML();
        User standardUser = userCreation.getRunAsUsers().get('Standard')[0];
        System.runAs(standardUser) {
            TestUtilities.assignLicense(String.valueOf(standardUser.Username), true, false, false, false, false);
            new CopadoUserStoryTestDefaults.DeploymentDefaults()
                .setFieldDefaults()
                .setFieldValue(
                    Deployment__c.SObjectType,
                    Deployment__c.RecordTypeId,
                    recordTypeInfoByDeveloperName.get(DEPLOYMENT_AUTOMATION_TEMPLATE_RECORD_TYPE_NAME).getRecordTypeId()
                )
                .setDataSize(Deployment__c.SObjectType, 1)
                .generateDefaults()
                .executeDML();

            new CopadoUserStoryTestDefaults.TestScriptDefaults()
                .setFieldDefaults()
                .setDataSize(Test_Script__c.SObjectType, 1)
                .generateDefaults()
                .executeDML();
        }
    }

    @IsTest
    static void testFindRecordsWithoutExtraFilter() {
        System.runAs(getStandardUser()) {
            CustomLookupQueryConfiguration queryConfig = createQueryConfigs('Name', 'Deployment__c', 'Deploy', null, null, null);
            List<LookupSearchResult> records = CustomLookupComponentHelper.search(queryConfig, 'Deployment');

            List<Deployment__c> expectedResult = [SELECT Name FROM Deployment__c WHERE Name LIKE '%Deploy%' WITH SECURITY_ENFORCED LIMIT 10];
            System.assertEquals(expectedResult.size(), records.size(), 'records size should match expectedResult size (1 record)');
        }
    }

    @IsTest
    static void testFindRecordsWithExtraFilters() {
        System.runAs(getStandardUser()) {
            Deployment__c deployment = [SELECT Id FROM Deployment__c];
            CustomLookupQueryConfiguration queryConfig = createQueryConfigs(
                'Name',
                'Deployment__c',
                'Deploy',
                'AutomationTemplateFilter',
                null,
                new List<Object>{ deployment.Id }
            );
            List<LookupSearchResult> records = CustomLookupComponentHelper.search(queryConfig, 'Deployment');

            List<Deployment__c> expectedResult = [
                SELECT Name
                FROM Deployment__c
                WHERE Name LIKE '%Deploy%' AND RecordType.DeveloperName = 'Automation_Template' AND Active__c = TRUE AND Id != :deployment.Id
                WITH SECURITY_ENFORCED
                LIMIT 10
            ];
            System.assertEquals(expectedResult.size(), records.size(), 'records size should match expecteResult size (empty with 0 records)');
        }
    }

    @IsTest
    static void testFindRecordsWithActiveUser() {
        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            CustomLookupQueryConfiguration queryConfig = createQueryConfigs('FirstName', 'User', 'AdminUser', 'ActiveUserFilter', null, null);
            List<LookupSearchResult> records = CustomLookupComponentHelper.search(queryConfig, 'User');

            List<User> expectedResult = [
                SELECT Id
                FROM User
                WHERE FirstName LIKE '%AdminUser%' AND IsActive = TRUE
                LIMIT 10
            ];
            System.assertEquals(expectedResult.size(), records.size(), 'records size should match expecteResult size (empty with 1 records)');
        }
    }

    @IsTest
    static void testFindRecordsWithInvalidExtraFilters() {
        System.runAs(getStandardUser()) {
            CustomLookupQueryConfiguration queryConfig = createQueryConfigs(
                'Name',
                'Deployment__c',
                'Deploy',
                'NotAutomationTemplateFilter',
                null,
                null
            );
            List<LookupSearchResult> records = CustomLookupComponentHelper.search(queryConfig, 'Deployment');

            List<Deployment__c> expectedResult = [SELECT Name FROM Deployment__c WHERE Name LIKE '%Deploy%' WITH SECURITY_ENFORCED LIMIT 10];
            System.assertEquals(expectedResult.size(), records.size(), 'records size should match expectedResult size (1 record)');
        }
    }

    @IsTest
    static void testFindRecordsWithIcon() {
        System.runAs(getStandardUser()) {
            CustomLookupQueryConfiguration queryConfig = createQueryConfigs('Name', 'Deployment__c', 'Deploy', null, null, null);
            List<LookupSearchResult> records = CustomLookupComponentHelper.search(queryConfig, 'Deployment', 'standard:user');

            List<Deployment__c> expectedResult = [SELECT Name FROM Deployment__c WHERE Name LIKE '%Deploy%' WITH SECURITY_ENFORCED LIMIT 10];
            System.assertEquals(expectedResult.size(), records.size(), 'records size should match expectedResult size (1 record)');
            System.assertEquals('standard:user', records[0].getIcon(), 'icon should match with the specified in the method');
        }
    }

    @IsTest
    static void testFindRecordsWithExtraFiltersForTitle() {
        System.runAs(getStandardUser()) {
            CustomLookupQueryConfiguration queryConfig = createQueryConfigs(
                'Name',
                'Test_Script__c',
                'Test',
                'TestScriptTitleFilter',
                new List<String>{ 'Test_Title__c' },
                new List<Object>{ 'Test' }
            );
            List<LookupSearchResult> records = CustomLookupComponentHelper.search(queryConfig, 'Test Script', 'standard:article', 'Test_Title__c');

            List<Test_Script__c> testScripts = [
                SELECT Name, Test_Title__c
                FROM Test_Script__c
                WHERE Name LIKE '%Test%' OR Test_Title__c LIKE '%Test%'
                WITH SECURITY_ENFORCED
                LIMIT 10
            ];
            System.assertEquals(testScripts.size(), records.size(), 'records size should match testScripts size (1 record)');
        }
    }

    // PRIVATE

    @SuppressWarnings('PMD.ExcessiveParameterList')
    private static CustomLookupQueryConfiguration createQueryConfigs(
        String searchField,
        String objectName,
        String searchKey,
        String extraFilterType,
        List<String> additionalFields,
        List<Object> filterFormattingParameters
    ) {
        CustomLookupQueryConfiguration result = new CustomLookupQueryConfiguration();
        result.searchField = searchField;
        result.objectName = objectName;
        result.searchKey = searchKey;
        result.extraFilterType = extraFilterType;
        result.additionalFields = additionalFields;
        result.filterFormattingParameters = filterFormattingParameters;

        return result;
    }

    private static User getStandardUser() {
        return [SELECT Username FROM User WHERE Username = :STANDARD_USER LIMIT 1];
    }
}