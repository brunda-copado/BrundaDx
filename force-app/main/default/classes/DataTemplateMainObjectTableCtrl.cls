public with sharing class DataTemplateMainObjectTableCtrl {
    @AuraEnabled
    public static void updateTemplateDetailAttachment(String recordId, String modifiedTemplateDetail) {
        try {
            new DataTemplateConfigurator(recordId).updateTemplateDetail(modifiedTemplateDetail);
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }
    }

    @AuraEnabled
    public static void refreshFields(String recordId) {
        try {
            List<Data_Template__c> dataTemplate = new DataTemplatesSelector().byId(new Set<Id>{ recordId });
            new DataTemplateConfigurator(recordId).setSource(dataTemplate.get(0).Template_Source_Org__c, dataTemplate.get(0).Main_Object__c);
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }
    }

    @AuraEnabled
    public static String getTemplateDetail(String recordId) {
        try {
            String result = JSON.serialize(new DataTemplateConfigurator(recordId).getTemplateDetail());
            return result;
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }
    }

    @AuraEnabled
    public static String getDescribeObject(String recordId) {
        try {
            String result = JSON.serialize(new DataTemplateConfigurator(recordId).getObjectDescribeFields());
            return result;
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }
    }

    @AuraEnabled
    public static boolean checkCredentialAccess(String orgId) {
        try {
            return DataTemplateConfigurator.checkCredentialAccess(orgId);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}