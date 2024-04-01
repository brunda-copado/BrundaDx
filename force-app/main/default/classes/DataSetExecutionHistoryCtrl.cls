public with sharing class DataSetExecutionHistoryCtrl {
    @AuraEnabled(cacheable=true)
    public static List<Step__c> getDeploymentSteps(Id recordId) {
        List<Step__c> steps = new StepsSelector().byParentId(new Set<Id>{ recordId });
        return steps;
    }
}