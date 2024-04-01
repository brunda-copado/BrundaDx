public with sharing class PipelineInitialiserCtrl {
    @TestVisible
    private static final string PIPELINE_INITIALIZER = 'PipelineInitializer';

    // PUBLIC

    @AuraEnabled
    public static String getInitializationComponentName(Id pipelineId) {
        String result;

        try {
            List<Deployment_Flow__c> pipelines = [SELECT Id, Platform__c FROM Deployment_Flow__c WHERE Id = :pipelineId WITH USER_MODE];
            if (!pipelines.isEmpty()) {
                List<ExtensionKeyValueSetting__mdt> initializeComponentName = new ExtensionKeyValueSettingsSelector()
                    .byPlatformAndKey(pipelines[0]?.Platform__c, PIPELINE_INITIALIZER);
                result = !initializeComponentName.isEmpty() ? initializeComponentName[0].Value__c : '';
            }
        } catch (Exception ex) {
            throw new ApplicationException().auraHandled(ex);
        }

        return result;
    }
}