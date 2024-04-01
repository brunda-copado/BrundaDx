public class AutomationChain implements Finalizer, Queueable, Database.AllowsCallouts {
    private static final String ACTION_CONNECT = 'CONNECT';
    private static final String ACTION_EXECUTE = 'EXECUTE';

    private List<AutomationChainElement> automationChainElements = new List<AutomationChainElement>{};
    private AutomationChainElement currentElement;

    public AutomationChain(List<AutomationConnector> automationConnectors) {
        for (AutomationConnector automationConnector : automationConnectors) {
            this.automationChainElements.add(new AutomationChainElement(automationConnector));
        }
    }

    public void execute(QueueableContext context) {
        System.attachFinalizer(this);

        this.currentElement = this.automationChainElements[0];
        this.automationChainElements.remove(0);

        if (this.currentElement.runConnect) {
            List<AutomationConnector> nextAutomationConnectors = this.currentElement.automationConnector.getConnectors(
                this.currentElement.automationConnector.context
            );
            addAutomationChainElements(nextAutomationConnectors);
        } else {
            this.currentElement.jobExecutionId = this.currentElement.automationConnector.executeAutomation();
        }
    }

    public void execute(FinalizerContext context) {
        if (!this.automationChainElements.isEmpty()) {
            System.enqueueJob(this);
        }

        List<Automation_Event__c> events = fillEventLogs(this.currentElement.automationConnector.context.automationEvents, context);

        DML.safeUpdate(events, 'Could not update the Automation Event object on the Automation Execution ( AutomationChain.execute class )');
    }

    // PRIVATE

    private void addAutomationChainElements(List<AutomationConnector> automationConnectors) {
        for (Integer i = 0; i < automationConnectors.size(); i++) {
            AutomationChainElement element = new AutomationChainElement(automationConnectors[i]).skipConnect();
            if (i < this.automationChainElements.size()) {
                this.automationChainElements.add(i, element);
            } else {
                this.automationChainElements.add(element);
            }
        }
    }

    private List<Automation_Event__c> fillEventLogs(List<Automation_Event__c> events, FinalizerContext context) {
        Set<Id> eventIds = new Set<Id>();
        for (Automation_Event__c event : events) {
            eventIds.add(event.Id);
        }
        List<Automation_Event__c> results = new AutomationEventsSelector().byId(eventIds);

        for (Automation_Event__c result : results) {
            String action = this.currentElement.runConnect ? ACTION_CONNECT : ACTION_EXECUTE;
            String logMessage = context.getAsyncApexJobId() + ' - ' + action + ': ';

            if (context.getResult() == ParentJobResult.SUCCESS) {
                result = this.currentElement.automationConnector.success(result);
                logMessage += ParentJobResult.SUCCESS;
            } else {
                result = this.currentElement.automationConnector.error(result);
                logMessage += context.getException()?.getMessage();
            }

            if (String.isNotBlank(this.currentElement.jobExecutionId)) {
                result.Target_Action_Job_Execution_Ids__c = concat(
                    result.Target_Action_Job_Execution_Ids__c,
                    this.currentElement.jobExecutionId,
                    ', '
                );
                logMessage += ' (' + this.currentElement.jobExecutionId + ')';
            }

            if (action == ACTION_EXECUTE) {
                result.Target_Action_Number__c++;
            }

            result.Log__c = concat(result.Log__c, logMessage, ' / ');
        }
        return results;
    }

    private String concat(String text, String message, String separator) {
        String result = String.isBlank(text) ? '' : text;
        result += String.isNotEmpty(result) ? separator : '';
        result += message;
        return result;
    }

    // INNER CLASS

    private class AutomationChainElement {
        private AutomationConnector automationConnector;
        private String jobExecutionId;
        private Boolean runConnect;

        private AutomationChainElement(AutomationConnector automationConnector) {
            this.automationConnector = automationConnector;
            this.runConnect = true;
        }

        private AutomationChainElement skipConnect() {
            this.runConnect = false;
            return this;
        }
    }
}