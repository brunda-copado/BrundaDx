public with sharing class RunTestQueueable implements Queueable {
    private Test__c test;
    private Id environmentId;
    List<RunTestsAction.Request> requests = new List<RunTestsAction.Request>();

    //CTOR

    public RunTestQueueable(Test__c testContext, Id envId) {
        test = testContext;
        environmentId = envId;
    }

    //PUBLIC

    public void execute(QueueableContext ctx) {
        requests.add(
            new RunTestsAction.Request()
                .tool(test.ExtensionConfiguration__r.ExtensionTool__c)
                .context(new List<Id>{ test.Id })
                .environment((String) environmentId)
                .acceptanceCriteria(test.AcceptanceCriteria__c)
        );
        RunTestsAction.execute(requests);
    }
}