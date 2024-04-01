public with sharing class CopadoAlertCommunicatorCtrl {
    
    @AuraEnabled
    public static List<UIDesignHelper.AlertWrapper> getAlerts(String recordId,String communicationId){
        List<UIDesignHelper.AlertWrapper> alerts = new List<UIDesignHelper.AlertWrapper>();   
        if(communicationId.equalsIgnoreCase(System.Label.UserStoryAlertCommunicationId)){
            alerts.addAll(AddWarningOnUserStoryController.getUserStoryDependenciesBlockingAlerts(recordId));
        }
        return alerts;
    }
}