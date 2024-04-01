@IsTest
private with sharing class DataTemplateDeploymentTemplateCtrlTest {
    @TestSetup
    private static void setup() {
        User standardUser = setupUser();
        System.runAs(standardUser) {
            setupLicense();
            createTestData();
        }
    }

    @isTest
    private static void getTemplates() {
        System.runAs(getStandardUser()) {
            // Setup
            Data_Template__c dataTemplate = getDataTemplate();
            insertDataTemplate('related', 'Account', dataTemplate.Template_Source_Org__c);

            // Execute
            Test.startTest();
            List<Data_Template__c> relatedDataTemplates = DataTemplateDeploymentTemplateCtrl.getDataTemplatesForObject(dataTemplate.Id, 'Account');
            Test.stopTest();

            // Verify
            System.assertEquals(1, relatedDataTemplates.size(), 'There should be a related Data Template for the object');
        }
    }
    
   @isTest
    private static void checkDuplicateName(){
        System.runAs(getStandardUser()) {
            // Execute
            Test.startTest();
            Boolean hasDuplicate = DataTemplateDeploymentTemplateCtrl.checkDuplicateName('test');
            Test.stopTest();

            // Verify
            System.assert(hasDuplicate, 'There should be a template with same name');

        }
    }
    
    @isTest
    private static void quickCreateTemplate(){
        System.runAs(getStandardUser()) {
            // Setup
            Data_Template__c dataTemplate = getDataTemplate();
            test.setMock(HttpCalloutMock.class, mockResponseForFields());
            
            // Execute
            Test.startTest();
            DataTemplateDeploymentTemplateCtrl.quickCreateTemplate(dataTemplate.Id, dataTemplate.Main_Object__c, dataTemplate.Template_Source_Org__c);
            Test.stopTest();

            // Verify
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
    private static void handleExceptions() {
        System.runAs(getStandardUser()) {
            //Execute + Verify
            Test.startTest();
            
            Exception handledException;
            try {
               DataTemplateDeploymentTemplateCtrl.getDataTemplatesForObject('test', 'test'); 
            }
            catch(Exception ex){
                handledException = ex;
            }
            System.assert(handledException != null, 'Template Id is Mandatory, there should be an exception');
            
            handledException = null;
            try {
               DataTemplateDeploymentTemplateCtrl.quickCreateTemplate(null, null, null);
            }
            catch(Exception ex){
                handledException = ex;
            }
            System.assert(handledException != null, 'all parameters are required');
            Test.stopTest();
        }
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

        insertDataTemplate('test', 'Custom_Object__c', orgs.get(0).Id);
    }

    private static Data_Template__c insertDataTemplate(String name, String mainObject, String sourceOrg) {
        Data_Template__c dataTemplate = createDataTemplate(name, mainObject, sourceOrg);
        insert dataTemplate;

        createDescribeObjectAttachment(dataTemplate.Id);

        createTemplateDetailAttachment(dataTemplate.Id);

        return dataTemplate;
    }

    private static Data_Template__c createDataTemplate(String name, String mainObject, String sourceOrg) {
        Data_Template__c dataTemplate = new Data_Template__c(
            Name = name,
            Template_Source_Org__c = sourceOrg,
            Main_Object__c = mainObject,
            Active__c = true
        );
        return dataTemplate;
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

    private static DescribeSObjectService.DescribeResponse createDescribeResponse() {
        DescribeSObjectService.DescribeResponse response = new DescribeSObjectService.DescribeResponse();
        response.success = true;
        response.fields = new List<DescribeSObjectService.CopadoField>();
        response.fields.add(createField('Name', 'Name', 'string'));
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
}