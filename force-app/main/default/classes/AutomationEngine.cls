@SuppressWarnings('PMD.AvoidGlobalModifier')
global with sharing class AutomationEngine {
    private Map<Id, List<Automation_Event__c>> matcherResult;
    private String execution;

    private Map<Id, Automation_Rule__c> automationRulesById {
        get {
            if (automationRulesById == null) {
                automationRulesById = new Map<Id, Automation_Rule__c>(new AutomationRulesSelector().byIds(matcherResult.keySet()));
            }
            return automationRulesById;
        }
        set;
    }

    // Note: implict global constructor was released, so we need to keep explicit constructor here
    @SuppressWarnings('PMD.EmptyStatementBlock')
    global AutomationEngine() {
    }

    public AutomationEngine(Map<Id, List<Automation_Event__c>> matcherResult) {
        this.matcherResult = matcherResult;
        execution(AutomationRuleConstants.EXECUTION_IMMEDIATE);
    }

    public AutomationEngine execution(String execution) {
        this.execution = execution;
        return this;
    }

    @InvocableMethod(label='Execute Automation')
    global static List<AutomationEngineResponse> execute(List<AutomationEngineRequest> requests) {
        List<Automation_Event__c> automationEvents = getEvents(requests);
        Map<Id, List<Automation_Event__c>> matcherResult = new AutomationRuleMatcher(automationEvents).execute();
        return new AutomationEngine(matcherResult).execute();
    }

    public List<AutomationEngineResponse> execute() {
        List<AutomationConnector> automationConnectors = createConnectors();

        if (!automationConnectors.isEmpty()) {
            System.enqueueJob(new AutomationChain(automationConnectors));
        }

        return new List<AutomationEngineResponse>();
    }

    // PRIVATE

    private static List<Automation_Event__c> getEvents(List<AutomationEngineRequest> requests) {
        Set<Id> automationEventIds = new Set<Id>();
        for (AutomationEngineRequest request : requests) {
            automationEventIds.add(request.automationEventId);
        }

        return new AutomationEventsSelector().byId(automationEventIds);
    }

    private List<AutomationConnector> createConnectors() {
        List<AutomationConnector> result = new List<AutomationConnector>();

        for (Id automationRuleId : matcherResult.keySet()) {
            Automation_Rule__c automationRule = automationRulesById.get(automationRuleId);
            if (executionMatches(automationRule)) {
                List<Automation_Event__c> automationEventsForRule = matcherResult.get(automationRuleId);
                if (!automationEventsForRule.isEmpty()) {
                    AutomationConnector automationConnector = new AutomationConnectorGenerator(automationEventsForRule, automationRule).execute();
                    result.add(automationConnector);
                }
            }
        }

        return result;
    }

    private Boolean executionMatches(Automation_Rule__c automationRule) {
        return automationRule.Execution__c == execution;
    }

    // INNER CLASS

    global class AutomationEngineRequest extends EngineRequest {
        @InvocableVariable(label='Automation Event' required=true)
        global String automationEventId;
    }

    global class AutomationEngineResponse extends EngineResponse {
        @InvocableVariable(label='Status')
        global String status;
    }
}