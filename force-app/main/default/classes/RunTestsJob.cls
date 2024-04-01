public with sharing class RunTestsJob implements Database.Batchable<sObject> {
    public List<Test__c> tests = new List<Test__c>();
    public Id environmentId;

    //CTOR
    public RunTestsJob(List<Test__c> testsContext, Id envId) {
        tests = testsContext;
        environmentId = envId;
    }

    //PUBLIC

    public List<Test__c> start(Database.BatchableContext context) {
        return tests;
    }

    public void execute(Database.BatchableContext context, List<Test__c> listOfTests) {
        for (Test__c test : listOfTests) {
            system.enqueueJob(new RunTestQueueable(test, environmentId)); //NOPMD
        }
    }

    @SuppressWarnings('PMD.EmptyStatementBlock')
    public void finish(Database.BatchableContext context) {
    }
}