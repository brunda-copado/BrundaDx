public with sharing class AutomationRuleActivationCtrl {
    
    @AuraEnabled
    public static void activateAutomationRule(Id automationRuleId) {
        try {
            new ActivateAutomationRule(new Set<Id> {automationRuleId}).execute();
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }
    }

    @AuraEnabled
    public static List<Automation_Rule__c> getDuplicatedAutomationRule(Id automationRuleId) {
        return new AutomationRuleDuplicatesChecker(
            new AutomationRulesSelector().byIds(new Set<Id> {automationRuleId})
        ).execute();
    }

}