public with sharing class DataSetJobExecutionsCtrl {
    @AuraEnabled
    public static List<Id> getJobExecutionIds(String dataSetId) {
        try{
            Set<Id> deploymentIds = new Set<Id>();
            List<Step__c> steps = new StepsSelector().byParentId(new Set<Id>{ dataSetId });
            for(Step__c step : steps){
                deploymentIds.add(step.Deployment__c);
            }
            return new List<Id>(
                new Map<Id, JobExecution__c>(
                        [SELECT Id FROM JobExecution__c WHERE ParentId__c = :dataSetId OR Deployment__c IN :deploymentIds WITH USER_MODE]
                    )
                    .keySet()
            );
        }
        catch(Exception ex){
            throw new ApplicationException().auraHandled(ex);
        }
    }
}