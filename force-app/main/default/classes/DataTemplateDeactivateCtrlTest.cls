@isTest
private class DataTemplateDeactivateCtrlTest {

	@TestSetup
    private static void setup() {
        User standardUser = setupUser();
        System.runAs(standardUser) {
            setupLicense();
            createTestData();
        }
    }
    
    @isTest
    private static void validateDeactivateTemplate(){
        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            //Setup
            Data_Template__c dataTemplate = getTemplate();
            //Execute
            DataTemplateDeactivateCtrl.deActivateTemplate(dataTemplate.Id); 
            //Verify
            dataTemplate = getTemplate();
            System.assertEquals(dataTemplate.Active__c, false, 'Data Template Must be decativated');
        }
    }

    @isTest
    private static void validateExceptionHandling(){
        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            TestUtilities.assignLicense(String.valueOf(UserInfo.getUserName()), false, false, false, false, false, false);
            Data_Template__c dataTemplate = getTemplate();
            //validate exception
            Exception handledException;
            try{
                DataTemplateDeactivateCtrl.deActivateTemplate(dataTemplate.Id); 
            }catch(Exception ex) {
                handledException = ex;
            }
            System.assert(handledException != null, 'User without Data Deployer license should not be able to deactivate template.');
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
        
        DataTemplateDetail templateDetail =  configureTemplateDetail(orgs.get(0).Id);
		
        Attachment att = new Attachment();
        att.Name = DataTemplateDetail.ATTACHMENT_NAME;
        att.ParentId = dataTemplate.Id;
        att.Body = Blob.valueOf(JSON.serialize(templateDetail));
        insert att;
        
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
        Data_Template__c dataTemplate = [SELECT Id, Name, Template_Source_Org__c, Main_Object__c, Active__c FROM Data_Template__c WHERE Name = 'test'];
        return dataTemplate;
    }
    
    private static DataTemplateDetail configureTemplateDetail(String orgId){
        DataTemplateDetail templateDetail = new DataTemplateDetail();
        templateDetail.dataTemplate.templateMainObject = 'Test Object';
        templateDetail.dataTemplate.templateSourceOrg = orgId;
        templateDetail.selectableFieldsMap = createSelectableFieldsMap();
        templateDetail.selectableChildRelationsMap = createselectableChildRelationsMap();
        templateDetail.childrenObjectsReferenceList = createChildrenObjectsReferenceList();
        templateDetail.parentObjectsReferenceList  = createParentObjectsReferenceList(); 
        return templateDetail;
    }
    
    private static Map<String, DataTemplateDetail.CopadoSelectedField> createSelectableFieldsMap (){
        Map<String, DataTemplateDetail.CopadoSelectedField> fieldMap = new Map<String, DataTemplateDetail.CopadoSelectedField>();
        DataTemplateDetail.CopadoSelectedField field = new DataTemplateDetail.CopadoSelectedField();
        field.name = 'TestField';
        field.label = 'Test Field';
        field.isSelected = true;
        fieldMap.put(field.name, field);
        
        DataTemplateDetail.CopadoSelectedField externalIdField = new DataTemplateDetail.CopadoSelectedField();
        externalIdField.name = 'ExternalIdField';
        externalIdField.label = 'External Id Field';
        externalIdField.isSelected = true;
        externalIdField.useAsExternalId = true;
        externalIdField.externalId = true;
        externalIdField.fieldContentUpdate = 'recordMatching';
        fieldMap.put(externalIdField.name, externalIdField);
        
        DataTemplateDetail.CopadoSelectedField parentObjectField = new DataTemplateDetail.CopadoSelectedField();
        parentObjectField.name = 'ParentId';
        parentObjectField.label = 'Parent Lookup Field';
        parentObjectField.isSelected = true;
        parentObjectField.fieldType = 'reference';
        fieldMap.put(parentObjectField.name, parentObjectField);
        return fieldMap;
    }
    
    private static Map<String, DataTemplateDetail.CopadoSelectedChildRelationship> createselectableChildRelationsMap (){
        Map<String, DataTemplateDetail.CopadoSelectedChildRelationship> selectableChildMap = new Map<String, DataTemplateDetail.CopadoSelectedChildRelationship>();
    	DataTemplateDetail.CopadoSelectedChildRelationship child = new DataTemplateDetail.CopadoSelectedChildRelationship();
        child.childSObject='TestChildObject';
        child.isSelected = true;
        child.field = 'ChildId';
        child.objectApiNameMap = new Map <String, String>{'TestChildObject' => 'Test Child Object'};
        child.relationshipName = 'ChildRelations';
        selectableChildMap.put(child.field + child.relationshipName, child);
        return selectableChildMap;
    }
    
    private static List<DataTemplateDetail.RelationTemplateDetails> createChildrenObjectsReferenceList(){
        List<DataTemplateDetail.RelationTemplateDetails> relationDetails = new List<DataTemplateDetail.RelationTemplateDetails>();
        DataTemplateDetail.RelationTemplateDetails childRelation = new DataTemplateDetail.RelationTemplateDetails();
        childRelation.templateId = 'Test Id';
        childRelation.relationName = 'ChildRelations';
        childRelation.childSObject = 'TestChildObject';
		relationDetails.add(childRelation);   
        return relationDetails;
    }
    
    private static List<DataTemplateDetail.RelationTemplateDetails> createParentObjectsReferenceList(){
        List<DataTemplateDetail.RelationTemplateDetails> relationDetails = new List<DataTemplateDetail.RelationTemplateDetails>();
        DataTemplateDetail.RelationTemplateDetails parentRelation = new DataTemplateDetail.RelationTemplateDetails();
        parentRelation.templateId = 'Test Id';
        parentRelation.relationName = 'ParentId';
		relationDetails.add(parentRelation);   
        return relationDetails;
    }
}