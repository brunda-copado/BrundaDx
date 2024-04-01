@SuppressWarnings('PMD.AvoidGlobalModifier')
global virtual class AutomationConnector {
    /*
     * AutomationConnectorContext object contains information from Source Action.
     */
    global AutomationConnectorContext context;

    @SuppressWarnings('PMD.EmptyStatementBlock')
    global AutomationConnector() {
    }

    /*
     * Get the connector instance(s) prepared to execute the Automated Action(s). Configure several instances of the connector in case you need to execute the Automated Action multiple times.
     * It is important that you set the same context you have in this connector on all your connectors in case they need to execute the action. If you only need to execute one action, return a list with this instance.
     * @param context: relevant data for this connector, including the Automation Event that triggers the automation, the Source Action result and the Automated Action callback.
     * @see AutomationConnectorContext
     * @return List<AutomationConnector> List of connectors configured to execute the Automated Action.
     */
    global virtual List<AutomationConnector> getConnectors(AutomationConnectorContext context) {
        return new List<AutomationConnector>{ this };
    }

    /*
     * This method executes the Automated Action based on the configuration of the connector.
     * @return String which contains the Id of the Job Execution that performs the Automated Action.
     */
    global virtual String executeAutomation() {
        return null;
    }

    /*
     * The name that will appear for the Automated Action in the UI when configuring an Automation Rule using this connector.
     * @return String which contains the name of the Automated Action that this connector is executing.
     */
    global virtual String getAutomatedActionName() {
        return '';
    }

    /*
     * The lightning component that will appear on the UI for the Automated Action when configuring an Automation Rule using this connector.
     * @return String which contains the name of the lightning component with namespace that this connector needs to render.
     */
    global virtual String getUIComponentName() {
        return '';
    }

    public virtual Automation_Event__c success(Automation_Event__c event) {
        return event;
    }

    public virtual Automation_Event__c error(Automation_Event__c event) {
        return event;
    }
}