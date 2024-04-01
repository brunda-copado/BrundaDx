public with sharing class AutomationRuleDeactivationCtrl {
    
    @AuraEnabled
    public static void deactivateAutomationRule(Id automationRuleId) {
        try {
            new DeactivateAutomationRule(new Set<Id> {automationRuleId}).execute();
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }
    }

}