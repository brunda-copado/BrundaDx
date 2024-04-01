@isTest
private with sharing class DataTemplateRecordMatchingFormulaTest {
    @TestSetup
    private static void setup() {
        User standardUser = setupUser();
        System.runAs(standardUser) {
            setupLicense();
            createTestData();
        }
    }

    @isTest
    private static void getObjectFields() {
        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            //Setup
            Org__c org = getOrg();
            test.setMock(HttpCalloutMock.class, mockResponseForFields());

            // Exercise
            test.startTest();
            String result = DataTemplateRecordMatchingFormulaCtrl.getObjectFields(org.Id, 'test');
            DescribeSObjectService.DescribeResponse response = (DescribeSObjectService.DescribeResponse) JSON.deserialize(
                result,
                DescribeSObjectService.DescribeResponse.class
            );
            test.stopTest();

            //Validate
            System.assertEquals(1, response.fields.size(), 'There Should be one field present');
        }
    }

    @isTest
    private static void getDataTemplate() {
        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            //Setup
            String templateId = getTemplate().Id;

            //Execute
            Data_Template__c template = DataTemplateRecordMatchingFormulaCtrl.getDataTemplate(templateId);

            //Verify
            System.assertEquals('Test Object', template.Main_Object__c, 'Test Object must be the name of main object of the Data Template');
        }
    }

    @isTest
    private static void getRecordMatchingFormula() {
        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            //Setup
            Data_Template__c template = getTemplate();

            //Execute
            Record_Matching_Formula__c formula = DataTemplateRecordMatchingFormulaCtrl.getRecordMatchingFormula(
                template.Main_Object__c
            );

            //Verify
            System.assertEquals('Test Name', formula.Name, 'Test Name must be the name of record matching formula');
        }
    }

    @isTest
    private static void handleExceptions() {
        System.runAs(getStandardUser()) {
            //Execute + Verify
            Test.startTest();

            Exception handledException;
            try {
                DataTemplateRecordMatchingFormulaCtrl.getObjectFields(null, null);
            } catch (Exception e) {
                handledException = e;
            }
            System.assert(handledException != null, 'source credential and main object mandatory');

            handledException = null;
            try {
                DataTemplateRecordMatchingFormulaCtrl.getDataTemplate(null);
            } catch (Exception e) {
                handledException = e;
            }
            System.assert(handledException != null, 'Template Id should be mandatory');

            Test.stopTest();
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

    private static void createTestData() {
        List<Environment__c> environments = TestDataFactory.createEnvironments(1);
        List<Org__c> orgs = TestDataFactory.createOrgCredentials(1, UserInfo.getUserName(), environments);
        for (Org__c org : orgs) {
            org.SFDC_Org_ID__c = UserInfo.getOrganizationId() + '_' + UserInfo.getUserId();
        }
        update orgs;

        Data_Template__c dataTemplate = new Data_Template__c(Name = 'test', Template_Source_Org__c = orgs.get(0).Id, Main_Object__c = 'Test Object');
        insert dataTemplate;

        Record_Matching_Formula__c formula = new Record_Matching_Formula__c(
            Name = 'Test Name',
            Configuration_Source_Org__c = orgs.get(0).Id,
            Object__c = 'Test Object'
        );
        insert formula;
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

    private static Org__c getOrg() {
        Org__c org = [SELECT Id, Name FROM Org__c LIMIT 1];
        return org;
    }

    private static Data_Template__c getTemplate() {
        Data_Template__c dataTemplate = [SELECT Id, Name, Template_Source_Org__c, Main_Object__c FROM Data_Template__c WHERE Name = 'test'];
        return dataTemplate;
    }

    private static MockHttpResponseGenerator mockResponseForFields() {
        DescribeSObjectService.DescribeResponse response = new DescribeSObjectService.DescribeResponse();
        response.success = true;
        response.fields = new List<DescribeSObjectService.CopadoField>();
        DescribeSObjectService.CopadoField field = new DescribeSObjectService.CopadoField();
        field.writeRequiresMasterRead = false;
        field.filterable = true;
        field.creatable = true;
        field.updateable = true;
        field.unique = false;
        field.type = 'string';
        field.sortable = true;
        field.nameField = true;
        field.name = 'Name';
        field.length = 255;
        field.label = 'Account Name';
        field.externalId = false;
        response.fields.add(field);
        response.childRelationships = new List<DescribeSObjectService.CopadoChildRelationship>();
        DescribeSObjectService.CopadoChildRelationship childRelationship = new DescribeSObjectService.CopadoChildRelationship();
        childRelationship.relationshipName = 'ChildAccounts';
        childRelationship.field = 'ParentId';
        childRelationship.childSObject = 'Account';
        response.childRelationships.add(childRelationship);
        return new MockHttpResponseGenerator(200, 'Complete', JSON.serialize(response), null);
    }
}