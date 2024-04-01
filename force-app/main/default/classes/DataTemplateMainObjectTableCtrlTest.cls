@isTest
private with sharing class DataTemplateMainObjectTableCtrlTest {
    @TestSetup
    private static void setup() {
        User standardUser = setupUser();
        System.runAs(standardUser) {
            setupLicense();
            createTestData();
        }
    }

    @isTest
    private static void getDescribeObject() {
        System.runAs(getStandardUser()) {
            //Setup
            Data_Template__c dataTemplate = getDataTemplate();

            //Execute
            Test.startTest();
            String fieldDetails = DataTemplateMainObjectTableCtrl.getDescribeObject(dataTemplate.Id);
            Test.stopTest();

            //Verify
            List<DescribeSObjectService.CopadoField> fields = (List<DescribeSObjectService.CopadoField>) JSON.deserialize(
                fieldDetails,
                List<DescribeSObjectService.CopadoField>.class
            );
            System.assertEquals(1, fields.size(), 'There should be a field in the attachment');
        }
    }

    @isTest
    private static void getTemplateDetail() {
        System.runAs(getStandardUser()) {
            //Setup
            Data_Template__c dataTemplate = getDataTemplate();

            //Execute
            Test.startTest();
            String templateDetails = DataTemplateMainObjectTableCtrl.getTemplateDetail(dataTemplate.Id);
            Test.stopTest();

            //Verify
            DataTemplateDetail detail = (DataTemplateDetail) JSON.deserialize(templateDetails, DataTemplateDetail.class);
            System.assertEquals(1, detail.selectableFieldsMap.size(), 'There should be a selectable field');
        }
    }

    @isTest
    private static void refreshFields() {
        System.runAs(getStandardUser()) {
            //Setup
            Data_Template__c dataTemplate = getDataTemplate();
            Test.setMock(HttpCalloutMock.class, mockResponseForFields());

            //Execute
            Test.startTest();
            DataTemplateMainObjectTableCtrl.refreshFields(dataTemplate.Id);
            Test.stopTest();

            //Verify
            Attachment allFieldsAttachment = getAttachment(dataTemplate.Id, 'ADD_Describe_SObject_Result');
            System.assert(allFieldsAttachment.Body != null, 'One Attachment with name ADD_Describe_SObject_Result must be present');
        }
    }

    @isTest
    private static void updateTemplateDetailAttachment() {
        System.runAs(getStandardUser()) {
            //Setup
            Data_Template__c dataTemplate = getDataTemplate();
            String modifiedTemplateDetail = modifyExistingTemplateDetail(dataTemplate.Id);

            //Execute
            Test.startTest();
            DataTemplateMainObjectTableCtrl.updateTemplateDetailAttachment(dataTemplate.Id, modifiedTemplateDetail);
            Test.stopTest();

            //Verify
            Attachment attachment = getAttachment(dataTemplate.Id, DataTemplateDetail.ATTACHMENT_NAME);
            DataTemplateDetail templateDetail = (DataTemplateDetail) JSON.deserialize(attachment.Body.toString(), DataTemplateDetail.class);
            System.assert(templateDetail.selectableFieldsMap.containsKey('Custom_Field_2__c'), 'The new selected field should be in the attachment');
        }
    }

    @isTest
    private static void handleExceptions() {
        System.runAs(getStandardUser()) {
            //Execute + Verify
            Test.startTest();
            
            Exception handledException;
            try {
                DataTemplateMainObjectTableCtrl.getDescribeObject(null);
            } catch (Exception e) {
                handledException = e;
            }
            System.assert(handledException != null, 'Record Id should be mandatory');

            handledException = null;
            try {
                DataTemplateMainObjectTableCtrl.getTemplateDetail(null);
            } catch (Exception e) {
                handledException = e;
            }
            System.assert(handledException != null, 'Record Id should be mandatory');

            handledException = null;
            try {
                DataTemplateMainObjectTableCtrl.refreshFields(null);
            } catch (Exception e) {
                handledException = e;
            }
            System.assert(handledException != null, 'Record Id should be mandatory');

            handledException = null;
            try {
                DataTemplateMainObjectTableCtrl.updateTemplateDetailAttachment(null, null);
            } catch (Exception e) {
                handledException = e;
            }
            System.assert(handledException != null, 'Record Id should be mandatory');

            Test.stopTest();
        }
    }

    private static Org__c getOrg() {
        return [SELECT Id, Name FROM Org__c LIMIT 1];
    }

    private static Data_Template__c getDataTemplate() {
        return [SELECT Id, Name, Template_Source_Org__c, Main_Object__c FROM Data_Template__c WHERE Name = 'test'];
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

        Data_Template__c dataTemplate = new Data_Template__c(
            Name = 'test',
            Template_Source_Org__c = orgs.get(0).Id,
            Main_Object__c = 'Custom_Object__c'
        );
        insert dataTemplate;

        createDescribeObjectAttachment(dataTemplate.Id);

        createTemplateDetailAttachment(dataTemplate.Id);
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

    private static Attachment getAttachment(String parentId, String attachmentName) {
        return [SELECT Id, Body FROM Attachment WHERE parentId = :parentId AND Name = :attachmentName LIMIT 1];
    }

    private static void createDescribeObjectAttachment(String parentId) {
        DescribeSObjectService.DescribeResponse response = createDescribeResponse();

        Attachment attachment = createAttachment(parentId, DataTemplateConfigurator.ADD_DESCRIBE_SOBJECT, Blob.valueOf(JSON.serialize(response)));
        insert attachment;
    }

    private static void createTemplateDetailAttachment(String parentId) {
        DataTemplateDetail templateDetail = new DataTemplateDetail();
        DataTemplateDetail.CopadoSelectedField selectedField = createSelectedField('Custom_Field__c', 'Custom Field');
        templateDetail.selectableFieldsMap.put(selectedField.Name, selectedField);

        Attachment attachment = createAttachment(parentId, DataTemplateDetail.ATTACHMENT_NAME, Blob.valueOf(JSON.serialize(templateDetail)));
        insert attachment;
    }

    private static Attachment createAttachment(String parentId, String name, Blob body) {
        Attachment attachment = new Attachment();
        attachment.ParentId = parentId;
        attachment.Name = name;
        attachment.body = body;
        return attachment;
    }

    private static String modifyExistingTemplateDetail(String dataTemplateId) {
        List<Attachment> attachments = [
            SELECT Id, Body
            FROM Attachment
            WHERE parentId = :dataTemplateId AND Name = :DataTemplateDetail.ATTACHMENT_NAME
        ];
        DataTemplateDetail existingAttachment = (DataTemplateDetail) JSON.deserialize(attachments.get(0).Body.toString(), DataTemplateDetail.class);
        DataTemplateDetail.CopadoSelectedField selectedField = createSelectedField('Custom_Field_2__c', 'Custom Field 2');
        existingAttachment.selectableFieldsMap.put(selectedField.Name, selectedField);
        return json.serialize(existingAttachment);
    }

    private static MockHttpResponseGenerator mockResponseForFields() {
        DescribeSObjectService.DescribeResponse response = createDescribeResponse();
        return new MockHttpResponseGenerator(200, 'Complete', JSON.serialize(response), null);
    }

    private static DescribeSObjectService.DescribeResponse createDescribeResponse() {
        DescribeSObjectService.DescribeResponse response = new DescribeSObjectService.DescribeResponse();
        response.success = true;
        response.fields = new List<DescribeSObjectService.CopadoField>();
        response.fields.add(createField('Name', 'Account Name', 'string'));
        response.childRelationships = new List<DescribeSObjectService.CopadoChildRelationship>();
        response.childRelationships.add(createChildRelationship('ParentId', 'ChildAccounts', 'Account'));
        return response;
    }

    private static DescribeSObjectService.CopadoField createField(String name, String label, String type) {
        DescribeSObjectService.CopadoField field = new DescribeSObjectService.CopadoField();
        field.writeRequiresMasterRead = false;
        field.creatable = true;
        field.updateable = true;
        field.unique = false;
        field.type = type;
        field.sortable = true;
        field.nameField = true;
        field.name = name;
        field.length = 255;
        field.label = label;
        field.externalId = false;
        return field;
    }

    private static DescribeSObjectService.CopadoChildRelationship createChildRelationship(
        String field,
        String relationshipName,
        String chilsSObject
    ) {
        DescribeSObjectService.CopadoChildRelationship childRelationship = new DescribeSObjectService.CopadoChildRelationship();
        childRelationship.relationshipName = relationshipName;
        childRelationship.field = field;
        childRelationship.childSObject = chilsSObject;
        return childRelationship;
    }

    private static DataTemplateDetail.CopadoSelectedField createSelectedField(String name, String label) {
        DataTemplateDetail.CopadoSelectedField selectedField = new DataTemplateDetail.CopadoSelectedField();
        selectedField.name = name;
        selectedField.label = label;
        return selectedField;
    }
}