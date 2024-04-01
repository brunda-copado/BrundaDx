@IsTest
@SuppressWarnings('PMD.CognitiveComplexity')
private with sharing class DataTemplateImportCtrlTest {
    @TestSetup
    private static void setup() {
        User standardUser = setupUser();
        System.runAs(standardUser) {
            setupLicense();
            createTestData();
        }
    }

    @isTest
    private static void fetchAddDescribeGlobalResults() {
        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            //Setup
            Org__c org = getOrg();
            test.setMock(HttpCalloutMock.class, mockResponseForGlobalDescribe());

            //Ecercise
            test.startTest();
            String globalResultResponse = DataTemplateImportCtrl.fetchAddDescribeGlobalResults(org.Id);
            test.stopTest();

            //Verify
            Assert.isNotNull(globalResultResponse, 'Describe Global Response should not be null');
        }
    }

    @isTest
    private static void testNameSpace() {
        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            //Ecercise
            test.startTest();
            String ns = new DataTemplateImportCtrl(null).namespace;
            test.stopTest();

            //Verify
            Assert.isNotNull(ns, 'name space must not be null');
        }
    }

    @isTest
    private static void createDataTemplate() {
        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            //Setup
            Data_Template__c template = new Data_Template__c(Name = 'Test Template');

            //Ecercise
            test.startTest();
            template = DataTemplateImportCtrl.createDataTemplate(template);
            test.stopTest();

            //Verify
            Assert.isNotNull(template.Id, 'Template Id can not be null');
        }
    }

    @isTest
    private static void validateTemplateNameAndObject() {
        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            //Setup
            Org__c org = getOrg();
            test.setMock(HttpCalloutMock.class, mockResponseForFields());

            //Ecercise
            test.startTest();
            DataTemplateImportCtrl.ValidationResult result = (DataTemplateImportCtrl.ValidationResult) JSON.deserialize(
                DataTemplateImportCtrl.validateTemplateNameAndObject(org.Id, 'Custom_Object__c', 'TestTemplate'),
                DataTemplateImportCtrl.ValidationResult.class
            );
            test.stopTest();

            //Verify
            Assert.isTrue(result.validObject, 'The mentioned object must be available in org');
            Assert.isFalse(result.duplicateName, 'There must not be any duplicate template in org');
        }
    }

    @isTest
    private static void fetchObjectFieldsDetail() {
        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            //Setup
            Org__c org = getOrg();
            test.setMock(HttpCalloutMock.class, mockResponseForFields());

            //Ecercise
            test.startTest();
            DescribeSObjectService.DescribeResponse describerResponse = (DescribeSObjectService.DescribeResponse) JSON.deserialize(
                DataTemplateImportCtrl.fetchObjectFieldsDetail(org.Id, 'Custom_Object__c'),
                DescribeSObjectService.DescribeResponse.class
            );
            test.stopTest();

            //Verify
            Assert.isTrue(describerResponse.success, 'The response for the field information must be successful');
        }
    }

    @isTest
    private static void createDataTemplateAttachments() {
        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            //Setup
            Data_Template__c dataTemplate = new Data_Template__c(Name = 'test');
            insert dataTemplate;
            DataTemplateImportCtrl.TemplateAttachments attachments = new DataTemplateImportCtrl.TemplateAttachments();
            attachments.templateDetail = 'SampleDataInTemplateDetailAttachment';
            attachments.describeSobject = JSON.serialize(mockResponseForFields());

            //Ecercise
            test.startTest();
            DataTemplateImportCtrl.createDataTemplateAttachments(dataTemplate.Id, JSON.serialize(attachments));
            test.stopTest();

            //Verify
            List<Attachment> templateDetailAttachment = [
                SELECT Id
                FROM Attachment
                WHERE ParentId = :dataTemplate.Id AND Name = :DataTemplateDetail.ATTACHMENT_NAME
            ];
            Assert.areEqual(1, templateDetailAttachment.size(), 'One Attachment with name Template Detail must be created');
            List<Attachment> allFieldsAttachment = [
                SELECT Id
                FROM Attachment
                WHERE ParentId = :dataTemplate.Id AND Name = :DataTemplateConfigurator.ADD_DESCRIBE_SOBJECT
            ];
            Assert.areEqual(1, allFieldsAttachment.size(), 'One Attachment with name ADD_Describe_SObject_Result must be created');
        }
    }

    @isTest
    private static void updateTemplateDetailAttachment() {
        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            //Setup
            Data_Template__c dataTemplate = new Data_Template__c(Name = 'test');
            insert dataTemplate;

            //Ecercise
            test.startTest();
            DataTemplateImportCtrl.updateTemplateDetailAttachment(dataTemplate.Id, 'SampleDataInTemplateDetailAttachment');
            test.stopTest();
        }
    }

    @isTest
    private static void getAvailableTemplateProviders() {
        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            //Ecercise
            test.startTest();
            Map<String, String> staticResourceByProvider = DataTemplateImportCtrl.getAvailableTemplateProviders();
            test.stopTest();

            //Verify
            Assert.isTrue(staticResourceByProvider.keySet().contains('nCino'), 'There must be nCino provider');
            Assert.areEqual('nCinoTemplates', staticResourceByProvider.get('nCino'), 'There must be a static resource name by nCinnCinoTemplates');
        }
    }

    @isTest
    private static void getTemplateStaticResource() {
        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            try {
                //Ecercise
                test.startTest();
                DataTemplateImportCtrl.getTemplateStaticResource('nCino');
                test.stopTest();
            } catch (Exception ex) {
                //Verify
                Assert.isNotNull(ex, 'There must be exception as there is no statuc resource named nCino');
            }
        }
    }

    @isTest
    private static void handleExceptions() {
        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            try {
                //Ecercise
                test.startTest();
                DataTemplateImportCtrl.createDataTemplate(null);
                test.stopTest();
            } catch (Exception ex) {
                //Verify
                Assert.isNotNull(ex, 'There must be exception');
            }
        }
    }

    @isTest
    private static void parseImportedFile() {
        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            //Setup
            String jsonValue = '[{"templateUUId":"54b736aa-a0eb-44b1-9a91-5fdbff600c3a","values":{"dataTemplate":{"templateName":"Data Template 27 Feb","templateMainObject":"Account","templateQueryLimit":null,"templateDescription":null,"templateFilterLogic":"1","templateAttachmentOptions":"No Attachments","templateBatchSize":200,"templateMatchOwners":false,"templateMatchRecordTypes":false,"templateContinueOnError":"Continue deployment until blocker issue","templateActive":null,"templateAttachmentType":"files"},"content":{"objectFields":[{"name":"Account Description","apiName":"Description","contentValueUpdateValues":{"Scramble With Format":"scrambleWithFormat","Scramble Value":"scramble","Replace Value":"replace"}},{"name":"Account Name","apiName":"Name","contentValueUpdateValues":{"Scramble With Format":"scrambleWithFormat","Scramble Value":"scramble","Replace Value":"replace"}},{"name":"Account ID","apiName":"Id","contentValueUpdateValues":{"Replace Value":"replace"}}],"parentObjects":[],"childObjects":[{"field":"AccountId","relationshipName":"Opportunities","childSObject":"Opportunity","childSObjectLabel":"Opportunity"}]},"relationList":[{"templateUUId":"b40c7a55-b34f-4e48-a19b-d97401134d06","relationName":"Opportunities","childSObject":"Opportunity"}],"filterList":[]}},{"templateUUId":"b40c7a55-b34f-4e48-a19b-d97401134d06","values":{"dataTemplate":{"templateName":"Opportunity Template Child","templateMainObject":"Opportunity","templateQueryLimit":null,"templateDescription":null,"templateFilterLogic":"1","templateAttachmentOptions":"No Attachments","templateBatchSize":200,"templateMatchOwners":false,"templateMatchRecordTypes":false,"templateContinueOnError":"Continue deployment until blocker issue","templateActive":true,"templateAttachmentType":"files"},"content":{"objectFields":[{"name":"Opportunity ID","apiName":"Id","contentValueUpdateValues":{"Replace Value":"replace"}},{"name":"Name","apiName":"Name","contentValueUpdateValues":{"Replace Value":"replace","Scramble Value":"scramble","Scramble With Format":"scrambleWithFormat"}},{"name":"Stage","apiName":"StageName","contentValueUpdateValues":{"Replace Value":"replace"}},{"name":"Close Date","apiName":"CloseDate","contentValueUpdateValues":{"Replace Value":"replace"}}],"parentObjects":[],"childObjects":[]},"relationList":[],"filterList":[]}}]';
            List<String> listString = new List<String>{ jsonValue };

            //Ecercise
            test.startTest();
            List<List<DataTemplateImportCtrl.TemplateInformation>> parsedList = DataTemplateImportCtrl.parseImportedFile(listString);
            createTemplateInformation();
            test.stopTest();

            //Verify
            Assert.areEqual(1, parsedList.size(), 'There must be one template group');
            Assert.areEqual(2, parsedList.get(0).size(), 'There must be 2 related template');
        }

    }

    @isTest
    private static void getNameSpace() {
        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            //Setup
            String ns = new Settings().namespace;

            //Excercise
            test.startTest();
            String nameSpace = DataTemplateImportCtrl.getNameSpace();
            test.stopTest();

            //Verify
            Assert.areEqual(ns, nameSpace, 'Name space must match');
        }
    }

    private static Org__c getOrg() {
        Org__c org = [SELECT Id, Name FROM Org__c LIMIT 1];
        return org;
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

    private static MockHttpResponseGenerator mockResponseForGlobalDescribe() {
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

    private static DataTemplateImportCtrl.TemplateInformation createTemplateInformation() {
        DataTemplateImportCtrl.ChildObjects chldObj = new DataTemplateImportCtrl.ChildObjects();
        chldObj.field = 'AccountId';
        chldObj.relationshipName = 'Opportunities';
        chldObj.childSObject = 'Opportunity';
        chldObj.childSObjectLabel = 'Opportunity';

        DataTemplateImportCtrl.ObjectFields objFields = new DataTemplateImportCtrl.ObjectFields();
        objFields.apiName = 'Account Name';
        objFields.name = 'Name';

        DataTemplateImportCtrl.RelationTemplateDetails rltnDetails = new DataTemplateImportCtrl.RelationTemplateDetails();
        rltnDetails.relationName = 'Opportunities';
        rltnDetails.templateId = 'b40c7a55-b34f-4e48-a19b-d97401134d06';

        DataTemplateImportCtrl.Content content = new DataTemplateImportCtrl.Content();
        content.childObjects = new List<DataTemplateImportCtrl.ChildObjects>{ chldObj };
        content.objectFields = new List<DataTemplateImportCtrl.ObjectFields>{ objFields };
        content.parentFields = new List<DataTemplateImportCtrl.ObjectFields>{ objFields };

        DataTemplateImportCtrl.DataTemplate dataTemplate = new DataTemplateImportCtrl.DataTemplate();
        dataTemplate.encodedTemplateName = 'Data Template';
        dataTemplate.templateAttachmentOption = 'No Attachments';
        dataTemplate.templateBatchSize = 200;
        dataTemplate.templateContinueOnError = 'Continue deployment until blocker issue';
        dataTemplate.templateDescription = 'Sample Data Template';
        dataTemplate.templateMainObject = 'Account';
        dataTemplate.templateMatchOwners = false;
        dataTemplate.templateMatchRecordTypes = false;
        dataTemplate.templateName = 'Data Template';
        dataTemplate.templateQueryLimit = null;

        DataTemplateImportCtrl.Values values = new DataTemplateImportCtrl.Values();
        values.content = content;
        values.dataTemplate = dataTemplate;
        values.relationList = new List<DataTemplateImportCtrl.RelationTemplateDetails>{ rltnDetails };
        values.relationListSize = 1;

        DataTemplateImportCtrl.TemplateInformation tempInfo = new DataTemplateImportCtrl.TemplateInformation();
        tempInfo.templateUUId = 'b40c7a55-b34f-4e48-a19b-d97401134d06';
        tempInfo.values = values;

        return tempInfo;
    }
}