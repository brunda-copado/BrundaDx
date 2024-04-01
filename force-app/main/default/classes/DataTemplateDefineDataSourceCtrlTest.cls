@isTest
private with sharing class DataTemplateDefineDataSourceCtrlTest {
    @TestSetup
    private static void setup() {
        User standardUser = setupUser();
        System.runAs(standardUser) {
            setupLicense();
            createTestData();
        }
    }
    @isTest
    private static void validateOrg() {
        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            //Setup
            Org__c org = getOrg();
            test.setMock(HttpCalloutMock.class, mockResponseForOrg());

            // Exercise
            test.startTest();
            Boolean validCredential = DataTemplateDefineDataSourceCtrl.validateOrg(org.Id);
            test.stopTest();

            //Validate
            System.assertEquals(true, validCredential, 'Org Credential must be a valid one');
        }
    }

    @isTest
    private static void setDataTemplateDataSource() {
        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            //Setup
            Org__c org = getOrg();
            Data_Template__c dataTemplate = getDataTemplate();
            test.setMock(HttpCalloutMock.class, mockResponseForFields());

            //Excercise
            test.startTest();
            DataTemplateDefineDataSourceCtrl.setDataTemplateDataSource(dataTemplate.Id, org.Id, 'Custom_Object__c');
            test.stopTest();

            //Validate
            List<Attachment> templateDetailAttachment = [
                SELECT Id
                FROM Attachment
                WHERE ParentId = :dataTemplate.Id AND Name = :DataTemplateDetail.ATTACHMENT_NAME
            ];
            System.assertEquals(1, templateDetailAttachment.size(), 'One Attachment with name Template Detail must be created');
            List<Attachment> allFieldsAttachment = [
                SELECT Id
                FROM Attachment
                WHERE ParentId = :dataTemplate.Id AND Name = :DataTemplateConfigurator.ADD_DESCRIBE_SOBJECT
            ];
            System.assertEquals(1, allFieldsAttachment.size(), 'One Attachment with name ADD_Describe_SObject_Result must be created');
        }
    }

    @isTest
    private static void fetchObjects() {
        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            //Setup
            Org__c org = getOrg();
            test.setMock(HttpCalloutMock.class, mockResponseForObjects());

            //Ecercise
            test.startTest();
            List<DataTemplateDefineDataSourceCtrl.MainObjectOption> mainObjects = DataTemplateDefineDataSourceCtrl.fetchObjects(org.Id);
            test.stopTest();

            //Verify
            System.assertEquals(1, mainObjects.size(), 'One object option must be created');
            System.assertEquals('Custom_Object__c', mainObjects.get(0).value, 'A object wil value Custom_Object__c shold be created');
        }
    }

    private static Org__c getOrg() {
        Org__c org = [SELECT Id, Name FROM Org__c LIMIT 1];
        return org;
    }

    private static Data_Template__c getDataTemplate() {
        Data_Template__c dataTemplate = [SELECT Id, Name, Template_Source_Org__c, Main_Object__c FROM Data_Template__c WHERE Name = 'test'];
        return dataTemplate;
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

        Data_Template__c dataTemplate = new Data_Template__c(Name = 'test');
        insert dataTemplate;
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

    private static MockHttpResponseGenerator mockResponseForFields() {
        DescribeSObjectService.DescribeResponse response = new DescribeSObjectService.DescribeResponse();
        response.success = true;
        response.fields = new List<DescribeSObjectService.CopadoField>();
        DescribeSObjectService.CopadoField field = new DescribeSObjectService.CopadoField();
        field.writeRequiresMasterRead = false;
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

    private static MockHttpResponseGenerator mockResponseForObjects() {
        DescribeSObjectService.DescribeGlobalResponse response = new DescribeSObjectService.DescribeGlobalResponse();
        response.success = true;
        response.sobjects = new List<DescribeSObjectService.CopadoObject>();
        DescribeSObjectService.CopadoObject copadoObject = new DescribeSObjectService.CopadoObject();
        copadoObject.custom = true;
        copadoObject.label = 'Custom Object';
        copadoObject.name = 'Custom_Object__c';
        copadoObject.queryable = true;
        copadoObject.triggerable = true;
        copadoObject.updateable = true;
        response.sobjects.add(copadoObject);
        return new MockHttpResponseGenerator(200, 'Complete', JSON.serialize(response), null);
    }

    private static MockHttpResponseGenerator mockResponseForOrg() {
        ValidateOrgResponse response = new ValidateOrgResponse();
        response.organizationId = 'sfdcOrgId';
        return new MockHttpResponseGenerator(200, 'Complete', JSON.serialize(response), null);
    }

    private class ValidateOrgResponse {
        public String organizationId;
    }
}