public with sharing class AutomationConnectorGenerator {
    private List<Automation_Event__c> automationEvents;
    private Automation_Rule__c automationRule;

    // CONSTRUCTOR

    public AutomationConnectorGenerator(List<Automation_Event__c> automationEvents, Automation_Rule__c automationRule) {
        this.automationEvents = automationEvents;
        this.automationRule = automationRule;
    }

    // PUBLIC

    public AutomationConnector execute() {
        Type classType = getClassType(automationRule);
        if (classType == null) {
            String error = String.format(Label.AutomationConnectorNotFound, new List<String>{ automationRule.Id });
            throw new ApplicationException(error);
        }
        AutomationConnector result = (AutomationConnector) classType.newInstance();
        AutomationConnectorContext context = new AutomationConnectorContext();
        context.automationEvents = automationEvents;
        context.actionCallback = automationRule.Automated_Action_Callback__c;
        context.automationRule = automationRule;
        result.context = context;
        return result;
    }

    // PRIVATE

    private Type getClassType(Automation_Rule__c automationRule) {
        String className = automationRule.Automation_Connector__c == AutomationRuleConstants.AUTOMATION_CONNECTOR_CUSTOM
            ? automationRule.Custom_Automation_Connector__c
            : automationRule.Automation_Connector__c;
        return Type.forName(namespace(className), name(className));
    }

    private String namespace(String name) {
        return name.contains('.') ? name.substringBefore('.') : '';
    }

    private String name(String name) {
        return name.contains('.') ? name.substringAfter('.') : name;
    }
}