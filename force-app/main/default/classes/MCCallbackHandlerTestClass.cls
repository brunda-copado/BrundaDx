// note: prepend Copado namespace when implementing the interface from an installed package: copado.MCCallback
@isTest
public with sharing class MCCallbackHandlerTestClass implements MCCallBack {
    public void execute(Function__c function, Result__c result, String status) {
        result.Result_Data__c = resultData(status);

        update Security.stripInaccessible(AccessType.UPDATABLE, new List<Result__c>{ result }).getRecords();
    }

    private String resultData(String status) {
        String result = '';

        switch on status {
            when 'In Progress' {
                result = 'Processing request...';
            }
            when 'Success' {
                result = 'Function execution completed. See details attached.';
            }
            when 'Failed' {
                result = 'Function execution failed. See details attached.';
            }
            when else {
                result = 'Function execution not started or cancelled.';
            }
        }

        return result;
    }
}