public with sharing class AutomationRuleConfigureCtrl {
    
    @AuraEnabled
    public static String getAutomatedAction(String className) {
        try {
            Type classType = Type.forName(namespace(className), name(className));
            AutomationConnector automationConnector = (AutomationConnector) classType.newInstance();
            return automationConnector.getAutomatedActionName();
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }
    }

    @AuraEnabled
    public static Boolean isAutomationRuleEditable() {
        return Schema.SObjectType.Automation_Rule__c.isUpdateable() && Schema.sObjectType.Automation_Rule__c.fields.Automation_Connector__c.isUpdateable();
    }

    @AuraEnabled
    public static Boolean isAutomationRuleAccessible() {
        return Schema.SObjectType.Automation_Rule__c.isAccessible() && Schema.sObjectType.Automation_Rule__c.fields.Source_Action__c.isAccessible();
    }

    // PRIVATE

    private static String namespace(String name) {
        return name.contains('.') ? name.substringBefore('.') : '';
    }

    private static String name(String name) {
        return name.contains('.') ? name.substringAfter('.') : name;
    }

}