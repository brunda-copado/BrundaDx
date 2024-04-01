@SuppressWarnings('PMD.ExcessivePublicCount, PMD.CyclomaticComplexity')
public with sharing class DataTemplateImportCtrl {
    @TestVisible
    private static final String ADD_DESCRIBE_GLOBAL = 'ADD_Describe_Global_Result';
    private static final String ADD_DESCRIBE_SOBJECT = 'ADD_Describe_SObject_Result';

    public String namespace {get; set;}
    
    public DataTemplateImportCtrl(ApexPages.StandardSetController ctrl){
        String ns = DataTemplateImportCtrl.class.getName().substringBefore('DataTemplateImportCtrl').removeEnd('.').toLowerCase();
        namespace =  String.isBlank(ns) ? 'c' : ns;
    }

    @AuraEnabled
    public static string getNameSpace(){
        try {
            return new Settings().namespace;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static String fetchAddDescribeGlobalResults(String orgId) {
        try {
            DescribeSObjectService.DescribeGlobalResponse describerResponse = new DescribeSObjectService(orgId).getObjects();
            if (!describerResponse.success) {
                throw new ApplicationException(describerResponse.error);
            }
            updateOrgObjectsAttachment(orgId, describerResponse);
            return JSON.serialize(describerResponse);
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }
    }

    @AuraEnabled
    public static Data_Template__c createDataTemplate(Data_Template__c dataTemplate){
        try {
            Data_Template__c template = (Data_Template__c) Utilities.Secure_DML(dataTemplate, Utilities.DML_Action.UPS, schema.SObjectType.Data_Template__c);
            return template;
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }
    }

    @AuraEnabled
    public static String validateTemplateNameAndObject(String orgId, String mainObject, String templateName) {
        try {
            ValidationResult result = new ValidationResult();
            List<Data_Template__c> existineTemplates = [SELECT Id,Name FROM Data_Template__c WHERE Main_Object__c =:mainObject AND Name =: templateName WITH USER_MODE];
            result.duplicateName = existineTemplates.size() > 0 ;
            DescribeSObjectService.DescribeResponse describerResponse = new DescribeSObjectService(orgId).getCreateableUpdateableFields(mainObject);
            if (describerResponse.success) {
                result.validObject = describerResponse.success;
            }
            if(!describerResponse.success && String.isNotBlank(describerResponse.error)){
                throw new AuraHandledException(describerResponse.error);
            }
            return JSON.serialize(result) ;
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }
    }

    @AuraEnabled
    public static String fetchObjectFieldsDetail(String orgId, String mainObject) {
        try{
            DescribeSObjectService.DescribeResponse describerResponse = new DescribeSObjectService(orgId).getCreateableUpdateableFields(mainObject);
            if(!describerResponse.success && String.isNotBlank(describerResponse.error)){
                throw new AuraHandledException(describerResponse.error);
            }
            return JSON.serialize(describerResponse) ;
        }
        catch (Exception e){
            throw new ApplicationException().auraHandled(e);
        }
    }

    @AuraEnabled
    public static void createDataTemplateAttachments( String dataTemplateId, String configuredAttachments ){ 
        try {
            List<Attachment> attachmentsToCreate = new List<Attachment>();
            TemplateAttachments attachments = (TemplateAttachments)JSON.deserialize(configuredAttachments, TemplateAttachments.class);
            
            Map<String, Attachment> existingDataTemplateAttachments = getAttachments(dataTemplateId, new set<String>{ DataTemplateDetail.ATTACHMENT_NAME, ADD_DESCRIBE_SOBJECT});
            Attachment templateDetailAttchment = existingDataTemplateAttachments.containsKey(DataTemplateDetail.ATTACHMENT_NAME)
                ? existingDataTemplateAttachments.get(DataTemplateDetail.ATTACHMENT_NAME)
                : createAttachment(DataTemplateDetail.ATTACHMENT_NAME, dataTemplateId);
            templateDetailAttchment.Body = Blob.valueOf(attachments.templateDetail);
            attachmentsToCreate.add(templateDetailAttchment);

            Attachment describeSobjectAttachment = existingDataTemplateAttachments.containsKey(ADD_DESCRIBE_SOBJECT)
                ? existingDataTemplateAttachments.get(ADD_DESCRIBE_SOBJECT)
                : createAttachment(ADD_DESCRIBE_SOBJECT, dataTemplateId);
            describeSobjectAttachment.Body = Blob.valueOf(attachments.describeSobject);
            attachmentsToCreate.add(describeSobjectAttachment);

            Utilities.Secure_DML(attachmentsToCreate, Utilities.DML_Action.UPS, schema.SObjectType.Attachment);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static void updateTemplateDetailAttachment(string dataTemplateId, String templateDetail){
        try{
            Map<String, Attachment> templateDetailAttachments = getAttachments(dataTemplateId, new set<String>{ DataTemplateDetail.ATTACHMENT_NAME });
            Attachment templateDetailAttachment = templateDetailAttachments.containsKey(DataTemplateDetail.ATTACHMENT_NAME)
                ? templateDetailAttachments.get(DataTemplateDetail.ATTACHMENT_NAME)
                : createAttachment(DataTemplateDetail.ATTACHMENT_NAME, dataTemplateId);
            templateDetailAttachment.Body = Blob.valueOf(templateDetail);

            Utilities.Secure_DML(templateDetailAttachment, Utilities.DML_Action.UPS, schema.SObjectType.Attachment);
        }catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, String> getAvailableTemplateProviders(){
        try {
          Map<String, String> staticResourceByProvider = new Map<String, String>();
          List<ExtensionKeyValueSetting__mdt> keyValues = [SELECT Key__c, Value__c FROM ExtensionKeyValueSetting__mdt WHERE Extension__r.Platform__c = 'DataTemplateExtension' WITH USER_MODE];
          if(Test.isRunningTest()){
            keyValues.add(new ExtensionKeyValueSetting__mdt(Key__c = 'platform', Value__c = 'nCino'));
            keyValues.add(new ExtensionKeyValueSetting__mdt(Key__c = 'nCino', Value__c = 'nCinoTemplates'));
          }
          if(!keyValues.isEmpty()){
            for(ExtensionKeyValueSetting__mdt keyValue : keyValues){
                if(keyValue.Key__c.toLowerCase().trim() == 'platform' && !staticResourceByProvider.containsKey(keyValue.Value__c.trim())) {
                    staticResourceByProvider.put(keyValue.Value__c.trim(), '');
                }
              }
              for(ExtensionKeyValueSetting__mdt keyValue : keyValues){
                if(staticResourceByProvider.containsKey(keyValue.Key__c.trim())){
                    staticResourceByProvider.put(keyValue.Key__c.trim(), keyValue.Value__c.trim());
                }
              }
          }
          return staticResourceByProvider;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static string getTemplateStaticResource(String provider) {
        String result;
        try {
            StaticResource templateResource = new StaticResourcesSelector().byName(provider).get(0);
            Blob body = templateResource.Body;
            result = EncodingUtil.base64Encode(body);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return result;
    }

    @AuraEnabled
    public static List<List<TemplateInformation>> parseImportedFile(List<String> jsonValue) {
        List<List<TemplateInformation>> response = new List<List<TemplateInformation>>();
        try {
            for(String currentValue : jsonValue){
                response.add((List<TemplateInformation>) JSON.deserialize(currentValue, List<TemplateInformation>.class));
            }
            return response;
        } catch (Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }


    private static Attachment updateOrgObjectsAttachment(String orgId, DescribeSObjectService.DescribeGlobalResponse objectsResponse) {
        Map<String, Attachment> existingAttachments = getAttachments(orgId, new Set<String>{ ADD_DESCRIBE_GLOBAL });
        Attachment result = existingAttachments.containsKey(ADD_DESCRIBE_GLOBAL)
            ? existingAttachments.get(ADD_DESCRIBE_GLOBAL)
            : createAttachment(ADD_DESCRIBE_GLOBAL, orgId);
        result.Body = Blob.valueOf(JSON.serialize(objectsResponse));
        Utilities.Secure_DML(result, Utilities.DML_Action.UPS, schema.SObjectType.Attachment);
        return result;
    }

    private static Map<String, Attachment> getAttachments(String recordId, Set<String> attachmentNames) {
        Map<String, Attachment> result = new Map<String, Attachment>();
        for (Attachment attachment : new AttachmentsSelector().byParentIdAndName(new Set<Id>{ recordId }, attachmentNames)) {
            result.put(attachment.Name, attachment);
        }
        return result;
    }

    private static Attachment createAttachment(String name, String parentId) {
        Attachment result = new Attachment();
        result.ParentId = parentId;
        result.Name = name;
        return result;
    }

    public class ValidationResult{
        @AuraEnabled
        public Boolean duplicateName {get; set;}
        @AuraEnabled
        public Boolean validObject {get; set;}

        public ValidationResult(){
            this.duplicateName = false;
            this.validObject = false;
        }
    }

    public class TemplateAttachments {
        public String templateDetail {get; set;}
        public String describeSobject {get; set;}
    }

    public class TemplateInformation {
        @AuraEnabled
        public String templateUUId { get; set; }
        @AuraEnabled
        public Values values { get; set; }
    }

    public class Values {
        @AuraEnabled
        public DataTemplate dataTemplate { get; set; }
        @AuraEnabled
        public Content content { get; set; }
        @AuraEnabled
        public List<RelationTemplateDetails> relationList { get; set; }
        @AuraEnabled
        public Integer relationListSize { 
            get {
                if(null == relationListSize){
                    relationListSize = this.relationList.size();
                }
                return relationListSize;
            }
            set; 
        }
    }

    public class DataTemplate {
        @AuraEnabled
        public String templateName { get; set; }
        @AuraEnabled
        public String encodedTemplateName {
            get {
                if (null != templateName) {
                    encodedTemplateName = templateName.replaceAll('[^a-zA-Z0-9]', '');
                }
                return encodedTemplateName;
            }
            set;
        }
        @AuraEnabled
        public String templateMainObject { get; set; }
        @AuraEnabled
        public String templateDescription { get; set; }
        @AuraEnabled
        public Boolean templateMatchOwners { get; set; }
        @AuraEnabled
        public Boolean templateMatchRecordTypes { get; set; }
        @AuraEnabled
        public String templateAttachmentOption { get; set; }
        @AuraEnabled
        public String templateContinueOnError { get; set; }
        @AuraEnabled
        public Decimal templateBatchSize { get; set; }
        @AuraEnabled
        public Decimal templateQueryLimit { get; set; }
    }

    public class Content {
        @AuraEnabled
        public List<ObjectFields> objectFields { get; set; }
        @AuraEnabled
        public List<ObjectFields> parentFields { get; set; }
        @AuraEnabled
        public List<ChildObjects> childObjects { get; set; }
    }

    public class RelationTemplateDetails {
        @AuraEnabled
        public String templateId { get; set; }
        @AuraEnabled
        public String relationName { get; set; }
    }

    public class ObjectFields {
        @AuraEnabled
        public String name { get; set; }
        @AuraEnabled
        public String apiName { get; set; }
    }

    public class ChildObjects {
        @AuraEnabled
        public String field { get; set; }
        @AuraEnabled
        public String relationshipName { get; set; }
        @AuraEnabled
        public String childSObject { get; set; }
        @AuraEnabled
        public String childSObjectLabel { get; set; }
    }

}