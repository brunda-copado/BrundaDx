public with sharing class FunctionExecutionQueueable implements Queueable, Database.AllowsCallouts {
    public final CalloutVariables requestVariable;
    public FunctionExecutionQueueable(CalloutVariables requestObject) {
        requestVariable = requestObject;
    }
    public void execute(QueueableContext context) {
        String namespace = FunctionExecutionQueueable.class.getName().substringBefore('FunctionExecutionQueueable').removeEnd('.').toLowerCase();

        List<RunCopadoFunction.InvocableVariables> variables = new List<RunCopadoFunction.InvocableVariables>();
        RunCopadoFunction.InvocableVariables firstSet = new RunCopadoFunction.InvocableVariables();
        firstSet.functionApiName = requestVariable.functionApiName;
        firstSet.parameters = requestVariable.parameters;
        firstSet.contextId = requestVariable.contextId;
        firstSet.resultCallback = (String.isNotBlank(namespace) ? namespace + '.' : '') + 'FunctionStepExecutionCallback';
        variables.add(firstSet);
        List<String> result = RunCopadoFunction.execute(variables);
    }

    public class CalloutVariables {
        public String contextId;
        public String functionApiName;
        public List<Parameter> parameters;
    }
}