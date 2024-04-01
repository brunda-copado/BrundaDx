public with sharing class DynamicComponentWrapperCtrl {
    @AuraEnabled
    public static String getComponentName(String recordId) {
        try {
            String result;

            Automation_Rule__c automationRule = new AutomationRulesSelector().byId(recordId);

            if (automationRule != null) {
                Type classType = getClassType(automationRule);
                if (classType != null) {
                    result = ((AutomationConnector) classType.newInstance()).getUIComponentName();
                }
            }

            return result;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    // PRIVATE

    private static Type getClassType(Automation_Rule__c automationRule) {
        String className = automationRule?.Automation_Connector__c == AutomationRuleConstants.AUTOMATION_CONNECTOR_CUSTOM
            ? automationRule?.Custom_Automation_Connector__c
            : automationRule?.Automation_Connector__c;
        return Type.forName(namespace(className), name(className));
    }

    private static String namespace(String name) {
        return name.contains('.') ? name.substringBefore('.') : '';
    }

    private static String name(String name) {
        return name.contains('.') ? name.substringAfter('.') : name;
    }
}