@isTest
public with sharing class MockRunTestsActionCallback implements TestsStepCallback {
    public void execute(Id resultId, String status) {
        Result__c mockResult = new Result__c(Id = resultId, Job_Type__c = 'Mock Run Tests Result', Description__c = 'Mock Run Tests Description');
        Utilities.Secure_DML(mockResult, Utilities.DML_Action.UPS, schema.SObjectType.Result__c);
    }
}