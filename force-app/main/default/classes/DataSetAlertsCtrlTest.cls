@IsTest
private with sharing class DataSetAlertsCtrlTest {
    @TestSetup
    private static void setup() {
        User standardUser = setupUser();
        System.runAs(standardUser) {
            setupLicense();
            createTestData();
        }
    }

    @IsTest
    private static void verifyDataTemplateFilters() {
        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            // Setup
            Data_Set__c dataSet = getDataSet();
            configureSuccessMock(dataSet.Data_Template__r.Template_Source_Org__c, dataSet.Data_Template__r.Main_Object__c);

            // Exercise
            Test.startTest();
            List<CopadoAlert> alerts = DataSetAlertsCtrl.verifyDataSet(dataSet.Id);
            Test.stopTest();

            // Verify
            System.assert(!alerts.isEmpty(), 'A warning alert should be generated');
            System.assertEquals(Label.DataTemplateInvalidFilters, alerts[0].message, 'Alert label should match');
            System.assertEquals(CopadoAlert.Variant.WARNING.name().toLowerCase(), alerts[0].variant, 'Alert variant must be warning');
        }
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

    private static void createTestData() {
        List<Environment__c> environments = TestDataFactory.createEnvironments(1);
        List<Org__c> orgs = TestDataFactory.createOrgCredentials(1, UserInfo.getUserName(), environments);
        for (Org__c org : orgs) {
            org.SFDC_Org_ID__c = UserInfo.getOrganizationId() + '_' + UserInfo.getUserId();
        }
        update orgs;
        Data_Template__c dataTemplate = TestDataFactory.createDataTemplate(
            'test',
            orgs.get(0).Id,
            'Account',
            null,
            null,
            getFilters(),
            getFilterLogic(),
            null
        );
        Data_Set__c dataSet = new Data_Set__c(Data_Template__c = dataTemplate.Id);
        insert dataSet;
    }

    private static Data_Set__c getDataSet() {
        return [SELECT Id, Data_Template__c, Data_Template__r.Template_Source_Org__c, Data_Template__r.Main_Object__c FROM Data_Set__c LIMIT 1];
    }

    private static List<DataFilter> getFilters() {
        List<DataFilter> filters = new List<DataFilter>();
        filters.add(createDataFilter('Name', 'TEXTAREA', 'e', 'value1'));
        filters.add(createDataFilter('Id', 'ID', 'e', 'value2'));
        return filters;
    }

    private static String getFilterLogic() {
        return '1 OR 2';
    }

    private static DataFilter createDataFilter(String fieldName, String fieldType, String operatorCode, String value) {
        DataFilter filter = new DataFilter();
        filter.fieldName = fieldName;
        filter.fieldType = fieldType;
        filter.operatorCode = operatorCode;
        filter.value = value;
        return filter;
    }

    private static void configureSuccessMock(Id orgId, String objectName) {
        DescribeSObjectService.DescribeResponse mockResponse = getFieldsMockResponse();
        configureMock(orgId, objectname, mockResponse, 200);
    }

    private static void configureMock(Id orgId, String objectName, Object body, Integer statusCode) {
        String url = String.format(
            DescribeSObjectService.DESCRIBE_FULL_ENDPOINT,
            new List<String>{ EncodingUtil.urlEncode(orgId, 'UTF-8'), EncodingUtil.urlEncode(objectName, 'UTF-8') }
        );
        new HttpMock().get(url, body, statusCode).mock();
    }

    private static DescribeSObjectService.DescribeResponse getFieldsMockResponse() {
        DescribeSObjectService.DescribeResponse mockResponse = new DescribeSObjectService.DescribeResponse();
        mockResponse.success = true;
        mockResponse.fields = new List<DescribeSObjectService.CopadoField>{ createTestField('Name', 'Name'), createTestField('Id', 'Id') };
        return mockResponse;
    }

    private static DescribeSObjectService.CopadoField createTestField(String label, String name) {
        DescribeSObjectService.CopadoField testField = new DescribeSObjectService.CopadoField();
        testField.custom = false;
        testField.label = label;
        testField.name = name;
        testField.referenceTo = null;
        testField.filterable = true;
        testField.type = 'STRING';
        return testField;
    }
}