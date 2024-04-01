public with sharing class DataTemplateDeactivateCtrl {
    @AuraEnabled
    public static void deActivateTemplate(String recordId) {
        try {
            Boolean hasLicense = checkDataDeploymentLicense();
            if (!hasLicense) {
                throw new ApplicationException(System.label.LicenseError);
            }
            Data_Template__c dataTemplate = fetchDataTemplate(recordId);
            if (!DataTemplateConfigurator.checkCredentialAccess(dataTemplate.Template_Source_Org__c)) {
                throw new ApplicationException(System.label.CredentialAccessMessage);
            }          
            Attachment templateDetailAttachment = fetchDataTemplateDetailAttachment(dataTemplate);
            DataTemplateDetail templateDetail = (DataTemplateDetail) JSON.deserialize(
                templateDetailAttachment.Body.toString(),
                DataTemplateDetail.class
            );            
            templateDetail.dataTemplate.templateActive = false;
            dataTemplate.Active__c = false;
            templateDetailAttachment.Body = Blob.valueOf(JSON.serialize(templateDetail));

            Utilities.Secure_DML(templateDetailAttachment, Utilities.DML_Action.UPD, Schema.SObjectType.Attachment);
            Utilities.Secure_DML(dataTemplate, Utilities.DML_Action.UPD, Schema.SObjectType.Data_Template__c);
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }
    }

    private static Boolean checkDataDeploymentLicense() {
        LicenseHelper.automatedProcessTriggeringUserId = UserInfo.getUserId();
        return new licenseHelper().addEnabled;
    } 

    private static Data_Template__c fetchDataTemplate(String recordId) {
        return new DataTemplatesSelector().byId(new Set<Id>{ recordId }).get(0);
    }

    private static Attachment fetchDataTemplateDetailAttachment(Data_Template__c dataTemplate) {
        return new AttachmentsSelector()
            .byParentIdAndName(new Set<Id>{ dataTemplate.Id }, new Set<String>{ DataTemplateDetail.ATTACHMENT_NAME })
            .get(0);
    }    
}