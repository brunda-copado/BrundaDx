public with sharing class DataTemplateDeploymentTemplateCtrl {
    @AuraEnabled(cacheable=true)
    public static List<Data_Template__c> getDataTemplatesForObject(String recordId, String objectName) {
        try {
            return new DataTemplatesSelector().byObjectRelatedToExistingTemplate(objectName, recordId);
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }
    }

    @AuraEnabled(cacheable=false)
    public static Boolean checkDuplicateName(String templateName) {
        try {
            List<Data_Template__c> dataTemplates = new DataTemplatesSelector().byTemplateName(templateName);
            return !dataTemplates.isEmpty();
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }
    }

    @AuraEnabled
    public static void quickCreateTemplate(String templateId, String mainObject, String schemaCredential) {
        try {
            //create templatedetail attchment
            new DataTemplateConfigurator(templateId).setSource(schemaCredential, mainObject);
            // update attachment with active=true;
            Attachment templateDetailAttachment = fetchDataTemplateDetailAttachment(templateId);
            DataTemplateDetail templateDetail = (DataTemplateDetail) JSON.deserialize(
                templateDetailAttachment.Body.toString(),
                DataTemplateDetail.class
            );
            templateDetail.dataTemplate.templateActive = true;
            templateDetailAttachment.Body = Blob.valueOf(JSON.serialize(templateDetail));
            Utilities.Secure_DML(templateDetailAttachment, Utilities.DML_Action.UPD, Schema.SObjectType.Attachment);
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }
    }

    private static Attachment fetchDataTemplateDetailAttachment(String templateId) {
        return new AttachmentsSelector().byParentIdAndName(new Set<Id>{ templateId }, new Set<String>{ DataTemplateDetail.ATTACHMENT_NAME }).get(0);
    }
}