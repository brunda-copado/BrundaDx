@isTest
public with sharing class MockTestReadinessLogic implements TestReadinessInterface{
    //PUBLIC

    public void execute(List<Test__c> tests) {
        if(!tests.isEmpty()){
            tests[0].ReadyToRun__c = true;
            Utilities.Secure_DML(tests[0], Utilities.DML_Action.INS, Schema.SObjectType.Test__c);
        }
    }
}