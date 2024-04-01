public with sharing class DataTemplateTabContainerCtrl {

    @AuraEnabled(cacheable=false)
    public static Boolean isADDEnabled() {
        try{
            return LicenseHelper.isADDEnabled();
        }catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }
    }
 
    @AuraEnabled(cacheable=true)
    public static Boolean hasInactiveRelatedTemplate(String recordId) {
        try {
            Boolean hasInactiveRelatedTemplate = false;
            DataTemplateDetail template = new DataTemplateConfigurator(recordId).getTemplateDetail();
            Set<ID> relatedTemplateIds = new Set<ID>();
            for(DataTemplateDetail.RelationTemplateDetails relatedTemplate : template.parentObjectsReferenceList) {
                relatedTemplateIds.add(relatedTemplate.templateId);
            }
            for(DataTemplateDetail.RelationTemplateDetails relatedTemplate : template.childrenObjectsReferenceList) {
                relatedTemplateIds.add(relatedTemplate.templateId);
            }            
            List<Data_Template__c> relatedTempaltes = new DataTemplatesSelector().byIdWithAllFields(relatedTemplateIds);
            for(Data_Template__c dt : relatedTempaltes) {
                if(!dt.Active__c){
                    hasInactiveRelatedTemplate = true;
                    break;
                }
            }
            return hasInactiveRelatedTemplate;
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }
    }   
}