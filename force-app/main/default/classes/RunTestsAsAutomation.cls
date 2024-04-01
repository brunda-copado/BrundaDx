public with sharing class RunTestsAsAutomation implements Queueable {
    private List<Id> testIds = new List<Id>();
    private Id deploymentJobId;

    public RunTestsAsAutomation(List<Id> testIds, Id deploymentJobId) {
        this.testIds = testIds;
        this.deploymentJobId = deploymentJobId;
    }

    public void execute(QueueableContext context) {
        List<Test__c> tests = new TestsSelector().byIds(new Set<Id>(testIds));
        new RunTestsInExtension(tests).executeAsAutomation(deploymentJobId);
    }
}