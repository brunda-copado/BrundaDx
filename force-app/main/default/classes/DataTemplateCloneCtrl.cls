public with sharing class DataTemplateCloneCtrl {
    private static final String BLANK_SPACE = ' ';
    private static final String TEMPLATE_DETAIL = 'Template Detail';

    @AuraEnabled
    public static String cloneTemplate(String recordId){
        try {      
            if (!checkDataDeploymentLicense()) {
                throw new ApplicationException(System.label.LicenseError);
            }                      
            List<Data_Template__c> templates = new DataTemplatesSelector().byIdWithAllFields(new Set<ID>{recordId});
            Data_Template__c template = templates.get(0);
            if (!DataTemplateConfigurator.checkCredentialAccess(template.Template_Source_Org__c)) {
                throw new ApplicationException(System.label.CredentialAccessMessage);
            }          
            Data_Template__c cloneTemplate = template.clone(false, true, false, false);
            cloneTemplate.Name = Label.Clone_of + BLANK_SPACE + template.Name;
            cloneTemplate.active__c = false;                       
            ensureTemplateIsUnique(cloneTemplate.Name);
            return saveRelatedTemplates(recordId, cloneTemplate);            
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }
    }

    private static String saveRelatedTemplates(Id orginalTemplateId, Data_Template__c referenceTemplate) {
        Savepoint sp = Database.setSavepoint();
        try {                     
            Utilities.Secure_DML(referenceTemplate, Utilities.DML_Action.UPS, schema.SObjectType.Data_Template__c);
            List<Attachment> attachmentsToBeInserted = new List<Attachment>();
            List<Attachment> existingAttachment = new AttachmentsSelector().byParentId(new Set<Id>{orginalTemplateId});
            for(Attachment  attachment : existingAttachment) {
                Attachment clonedAttachment = attachment.clone(false, true, false, false);
                clonedAttachment.ParentId = referenceTemplate.id;
                if(clonedAttachment.Name.equalsIgnoreCase(TEMPLATE_DETAIL)) {
                    DataTemplateDetail templateDetail = (DataTemplateDetail) JSON.deserialize(
                        clonedAttachment.Body.toString(),
                        DataTemplateDetail.class
                    );            
                    templateDetail.dataTemplate.templateActive = false;
                    templateDetail.dataTemplate.templateName = referenceTemplate.Name;
                    templateDetail.dataTemplate.templateId = referenceTemplate.id;
                    clonedAttachment.Body = Blob.valueOf(JSON.serialize(templateDetail));                    
                }
                attachmentsToBeInserted.add(clonedAttachment);
            }
            Utilities.Secure_DML(attachmentsToBeInserted, Utilities.DML_Action.INS, schema.SObjectType.Attachment);
            return referenceTemplate.id;
        } catch (Exception excp) {
            Database.rollback(sp);
            throw new ApplicationException(excp.getMessage());
        }
    }    
    
    private static void ensureTemplateIsUnique(String givenTemplateName) {
        List<Data_Template__c> duplicateTemplates = new DataTemplatesSelector().byTemplateName(givenTemplateName);
        if(!duplicateTemplates.isEmpty()) {
            String message = String.format(Label.Duplicate_Template_Name, new List<String>{ givenTemplateName });
            throw new ApplicationException(message);
        }
    }  
    private static Boolean checkDataDeploymentLicense() {
        LicenseHelper.automatedProcessTriggeringUserId = UserInfo.getUserId();
        return new licenseHelper().addEnabled;
    }      
}