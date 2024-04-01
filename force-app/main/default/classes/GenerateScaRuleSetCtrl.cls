public with sharing class GenerateScaRuleSetCtrl {
     //PUBLIC
    @AuraEnabled(cacheable=true)
    public static List<Static_Code_Analysis_Rule__c> getRulesFrom(String recordId){
        try {
            return new ScaRulesSelector().bySettingId(recordId);            
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }
    }
}