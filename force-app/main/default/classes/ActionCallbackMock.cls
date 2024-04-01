@IsTest
public with sharing class ActionCallbackMock implements JobExecutionCallback {
    public void execute(JobExecution__c job, String status) {
        insert new Result__c(ParentId__c = job.Id, Job_Type__c = 'Integration', Result_Data__c = 'Action Callback executed');
    }
}