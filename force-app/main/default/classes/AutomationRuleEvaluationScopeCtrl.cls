public with sharing class AutomationRuleEvaluationScopeCtrl {
    @AuraEnabled(cacheable=true)
    public static EvaluationScopeData getData(String recordId) {
        EvaluationScopeData result = new EvaluationScopeData();

        Automation_Rule__c automationRule = new AutomationRulesSelector().byId(recordId);

        PipelineDescriptor pipelineDescriptor = new PipelineDescriptor(automationRule.Pipeline__c);
        result.stagesById = pipelineDescriptor.stages();
        result.environmentsById = pipelineDescriptor.environments();

        result.currentStages = automationRule.Stage__c;
        result.currentEnvironments = automationRule.Environment__c;
        result.currentExcludedEnvironments = automationRule.Excluded_Environments__c;

        result.userHasPermission = Schema.SObjectType.Automation_Rule__c.isUpdateable() &&
            Schema.sObjectType.Automation_Rule__c.fields.Stage__c.isUpdateable() &&
            Schema.sObjectType.Automation_Rule__c.fields.Environment__c.isUpdateable() &&
            Schema.sObjectType.Automation_Rule__c.fields.Excluded_Environments__c.isUpdateable();
        return result;
    }

    @AuraEnabled
    public static Boolean isAutomationRuleAccessible() {
        return Schema.SObjectType.Automation_Rule__c.isAccessible() && Schema.sObjectType.Automation_Rule__c.fields.Source_Action__c.isAccessible();
    }

    public with sharing class EvaluationScopeData {
        @AuraEnabled
        public Map<Id, PipelineDescriptor.Stage> stagesById;
        @AuraEnabled
        public Map<Id, Environment__c> environmentsById;
        @AuraEnabled
        public String currentStages;
        @AuraEnabled
        public String currentEnvironments;
        @AuraEnabled
        public String currentExcludedEnvironments;
        @AuraEnabled
        public Boolean userHasPermission = false;
    }
}