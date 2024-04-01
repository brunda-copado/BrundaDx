trigger AutomationRules on Automation_Rule__c (before delete) {
    fflib_SObjectDomain.triggerHandler(AutomationRules.class);
}