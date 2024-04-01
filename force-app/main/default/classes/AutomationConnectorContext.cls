@SuppressWarnings('PMD.AvoidGlobalModifier')
global class AutomationConnectorContext {
    /**
     * Automation_Event__c record with the information about the action which is triggering this automation.
     */
    global List<Automation_Event__c> automationEvents;
    /**
     * Name of the Apex/Flow callback that will be executed after the Automated Action is completed.
     */
    global String actionCallback;
    /**
     * Automation rule record with the information about the automation rule
     */
    global Automation_Rule__c automationRule;

    @SuppressWarnings('PMD.EmptyStatementBlock')
    global AutomationConnectorContext() {
    }
}