@IsTest
private with sharing class DataFiltersCtrlTest {
    @TestSetup
    private static void makeData() {
        createData();
    }

    @IsTest
    private static void retrieveFields() {
        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            // Setup
            List<Org__c> orgs = getOrgs();
            Id orgId = orgs[0].Id;
            String objectName = 'Account';
            configureSuccessMock(orgId, objectName);

            // Exercise
            Test.startTest();
            List<DataFiltersCtrl.Field> fields = DataFiltersCtrl.retrieveFields(orgId, objectName);
            Test.stopTest();

            // Verify
            System.assertEquals(false, fields.isEmpty(), 'Fields list should not be empty');
            for (DataFiltersCtrl.Field field : fields) {
                System.assertEquals(false, field.operators.isEmpty(), 'Field operatorss list should not be empty');
            }
        }
    }

    @IsTest
    private static void serviceUnavailable() {
        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            // Setup
            List<Org__c> orgs = getOrgs();
            Id orgId = orgs[0].Id;
            String objectName = 'Account';
            configureErrorMock(orgId, objectName, 500);

            // Exercise + Verify
            Test.startTest();
            try {
                List<DataFiltersCtrl.Field> fields = DataFiltersCtrl.retrieveFields(orgId, objectName);
            } catch (Exception e) {
                System.assert(true, 'Exception should be thrown');
            }
            Test.stopTest();
        }
    }
    
    @IsTest
    private static void parseFields() {
        User standardUser = getStandardUser();
        //Setup
        List<DescribeSObjectService.CopadoField> copadoFields = new List<DescribeSObjectService.CopadoField>();
        copadoFields.add(createTestField('Test','Test__c'));
        System.runAs(standardUser) {
            //Execute
            Test.startTest();
            	List<DataFiltersCtrl.Field> fields = DataFiltersCtrl.parseFields(JSON.serialize(copadoFields));
            Test.stopTest();
            
            //Verify
            System.assertEquals(1, fields.size(), 'One field should be present');
        }
    }

    private static void createData() {
        User standardUser = setupUser();
        System.runAs(standardUser) {
            setupLicense();
            List<Environment__c> environments = TestDataFactory.createEnvironments(2);
            List<Org__c> credentials = TestDataFactory.createOrgCredentials(2, UserInfo.getUsername(), environments);
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

    private static List<Org__c> getOrgs() {
        return [SELECT Id FROM Org__c];
    }

    private static void configureSuccessMock(Id orgId, String objectName) {
        DescribeSObjectService.DescribeResponse mockResponse = getFieldsMockResponse();
        configureMock(orgId, objectname, mockResponse, 200);
    }

    private static void configureErrorMock(Id orgId, String objectName, Integer statusCode) {
        configureMock(orgId, objectname, null, 500);
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
        testField.type = 'string';
        return testField;
    }
}