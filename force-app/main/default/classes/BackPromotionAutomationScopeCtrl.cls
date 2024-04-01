public with sharing class BackPromotionAutomationScopeCtrl {
    @AuraEnabled
    public static EvaluationScopeData getData(String recordId) {
        EvaluationScopeData result = new EvaluationScopeData();

        Automation_Rule__c automationRule = new AutomationRulesSelector().byId(recordId);

        result.environmentsById = new PipelineDescriptor(automationRule?.Pipeline__c).allButFinalEnvironments();

        if (automationRule?.Config_Json__c != null) {
            JsonData configJson = (JsonData) JSON.deserialize(automationRule.Config_Json__c, JsonData.class);
            if (configJson.excludedEnvironmentsForBackPromotion != null) {
                result.currentExcludedEnvironmentsForBp = String.join(configJson.excludedEnvironmentsForBackPromotion, ',');
            }
        }

        result.userHasPermission =
            Schema.SObjectType.Automation_Rule__c.isUpdateable() && Schema.sObjectType.Automation_Rule__c.fields.Config_Json__c.isUpdateable();

        return result;
    }

    @AuraEnabled
    public static Boolean isAutomationRuleAccessible() {
        return Schema.SObjectType.Automation_Rule__c.isAccessible() &&
            Schema.sObjectType.Automation_Rule__c.fields.Automated_Action__c.isAccessible();
    }

    // INNER

    public with sharing class EvaluationScopeData {
        @AuraEnabled
        public Map<Id, Environment__c> environmentsById;
        @AuraEnabled
        public String currentExcludedEnvironmentsForBp;
        @AuraEnabled
        public Boolean userHasPermission = false;
    }

    // PRIVATE

    private class JsonData {
        private List<String> excludedEnvironmentsForBackPromotion = new List<String>();
    }
}