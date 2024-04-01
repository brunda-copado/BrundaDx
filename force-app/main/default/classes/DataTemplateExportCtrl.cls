public with sharing class DataTemplateExportCtrl {
    
    @AuraEnabled
    public static String queryTemplateDetail(String parentId) {
        if (!checkDataDeploymentLicense()) {
            throw new ApplicationException(System.label.LicenseError);
        } 
        List<Attachment> attachments = new AttachmentsSelector().byParentIdAndName(new Set<Id>{parentId}, new Set<String>{DataTemplateDetail.ATTACHMENT_NAME });
        return attachments.isEmpty() ? null : attachments.get(0).Body.toString();
    }
    
    private static Boolean checkDataDeploymentLicense() {
        LicenseHelper.automatedProcessTriggeringUserId = UserInfo.getUserId();
        return new licenseHelper().addEnabled;
    }     
}