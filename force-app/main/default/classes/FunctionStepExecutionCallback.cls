public with sharing class FunctionStepExecutionCallback implements MCCallBack {
    private static final Set<String> STATUS_VALUES = new Set<String>{ 'Success', 'Failed' };

    public void execute(Function__c function, Result__c result, String status) {
        if(!STATUS_VALUES.contains(status)) {
            return;
        }
        List<Deployment_Job__c> deploymentJobs = [SELECT Id, Status__c, Last_Result__c FROM Deployment_Job__c WHERE Id = :result.ParentId__c WITH SECURITY_ENFORCED LIMIT 1];
        for (Deployment_Job__c deploymentJobRecord : deploymentJobs) {
            deploymentJobRecord.Status__c = status;
            deploymentJobRecord.Last_Result__c = result.Id;
        }
        DML.safeUpdate(deploymentJobs, 'Could not update the status for a Deployment Job object on a Function execution ( FunctionStepExecutionCallback.updateDeploymentJobToUpdateDeploymentStatus class )');
    }

}