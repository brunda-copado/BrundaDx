public with sharing class AutomationRules extends fflib_SObjectDomain {

    public AutomationRules(List<Automation_Rule__c> records) {
        super(records);
    }
    
    public override void onBeforeDelete() {
        validateAutomationRuleIsNotActive(records);
    }

    // PRIVATE

    private void validateAutomationRuleIsNotActive(List<Automation_Rule__c> automationRules) {
        for(Automation_Rule__c automationRule : automationRules) {
            if(automationRule.Active__c) {
                automationRule.addError(Label.ActiveAutomatioRuleCannotBeDeleted);
            }
        }
    }

    // INNER

    public class Constructor implements fflib_SObjectDomain.IConstructable {
        public fflib_SObjectDomain construct(List<SObject> records) {
            return new AutomationRules(records);
        }
    }

}