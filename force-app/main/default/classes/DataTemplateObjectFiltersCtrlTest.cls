@isTest
private with sharing class DataTemplateObjectFiltersCtrlTest {
    @TestSetup
    private static void setup() {
        User standardUser = setupUser();
        System.runAs(standardUser) {
            setupLicense();
            createTestData();
        }
    }

    @isTest
    private static void getDataTemplateFilters() {
        System.runAs(getStandardUser()) {
            //Setup
            Data_Template__c dataTemplate = getDataTemplate();

            //Execute
            Test.startTest();
            DataFiltersConfiguration filterConfiguration = DataTemplateObjectFiltersCtrl.getDataTemplateFilters(dataTemplate.Id);
            Test.stopTest();

            //Verify
            System.assertEquals(2, filterConfiguration.filters.size(), 'There should be two filter criteria');
            System.assert(filterConfiguration.filterLogic == '1 AND 2', 'There should be two filter criteria');
        }
    }

    @isTest
    private static void updateDataTemplateFilters() {
        System.runAs(getStandardUser()) {
            //Setup
            Data_Template__c dataTemplate = getDataTemplate();
            String filterLogic = '1 OR 2';
            Decimal batchSize = 100;
            Decimal recordLimit = 2000;
            List<DataFilter> filters = new List<DataFilter>();
            filters.add(new DataFilter(createFilterCriteria('testField1-testField1', 'STRING', 'testField1=\'test1\'', 1, 'e', 'test1')));
            filters.add(new DataFilter(createFilterCriteria('testField2-testField2', 'STRING', 'testField2=\'test2\'', 2, 'e', 'test2')));

            //Execute
            Test.startTest();
            DataTemplateObjectFiltersCtrl.updateDataTemplateFilters(dataTemplate.Id, filters, filterLogic, batchSize, recordLimit);
            Test.stopTest();

            //Verify
            Attachment attachment = getAttachment(dataTemplate.Id, DataTemplateDetail.ATTACHMENT_NAME);
            DataTemplateDetail templateDetail = (DataTemplateDetail) JSON.deserialize(attachment.Body.toString(), DataTemplateDetail.class);
            System.assert(templateDetail.dataTemplate.templateFilterLogic == '1 OR 2', 'filterlogic is not correct in data template');
            System.assertEquals(2, templateDetail.queryFilterList.size(), 'There should be 2 filter criteria present');
        }
    }

    @isTest
    private static void handleExceptions() {
        System.runAs(getStandardUser()) {
            //Execute + Verify
            Test.startTest();

            Exception handledException;
            try {
                DataTemplateObjectFiltersCtrl.updateDataTemplateFilters(null, null, null, null, null);
            } catch (Exception e) {
                handledException = e;
            }
            System.assert(handledException != null, 'all parameters are mandatory');
            
            handledException = null;
            try {
                DataTemplateObjectFiltersCtrl.getDataTemplateFilters('0');
            } catch (Exception e) {
                handledException = e;
            }
			System.assert(handledException != null, 'Id is required');
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
    
    private static void createTemplateDetailAttachment(String parentId) {
        DataTemplateDetail templateDetail = new DataTemplateDetail();
        templateDetail.queryFilterList.add(createFilterCriteria('testField1-testField1', 'STRING', 'testField1=\'test1\'', 1, 'e', 'test1'));
        templateDetail.queryFilterList.add(createFilterCriteria('testField2-testField2', 'STRING', 'testField2=\'test2\'', 2, 'e', 'test2'));
        templateDetail.dataTemplate.templateFilterLogic = '1 AND 2';
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

    private static QueryEditor.CriteriaWrapper createFilterCriteria(
        String fieldName,
        String fieldType,
        String finalValue,
        Integer order,
        String operator,
        String input
    ) {
        QueryEditor.CriteriaWrapper filterCriteria = new QueryEditor.CriteriaWrapper();
        filterCriteria.fieldName = fieldName;
        filterCriteria.fieldType = fieldType;
        filterCriteria.finalValue = finalValue;
        filterCriteria.order = order;
        filterCriteria.operator = operator;
        filterCriteria.input = input;

        return filterCriteria;
    }
}