public with sharing class ExecuteFunction implements Queueable, Database.AllowsCallouts {
    private final String payload;
    private final String resultId;
    private Function__c function;
    private String contextId;

    public ExecuteFunction(String payload, String resultId) {
        this.payload = payload;
        this.resultId = resultId;
    }

    public ExecuteFunction function(Function__c function) {
        this.function = function;
        return this;
    }

    public ExecuteFunction contextId(String contextId) {
        this.contextId = contextId;
        return this;
    }

    public void execute(QueueableContext ctx) {
        try {
            new FunctionCallout(resultId).isStandard(function.Type__c == 'Standard').payload(payload).build().request().parseResponse();
        } catch (Exception ex) {
            new ExecuteFunctionException(ex).resultId(resultId).contextId(contextId).function(function).updateResult().updateContext();
        }
    }

    private class ExecuteFunctionException extends CopadoFunctionException {
    }
}