public with sharing class InvocableDisablePrefetchedVolume {
    public class InvocableVariables {
        @InvocableVariable(label='Git Repository Id' required=true)
        public String repoId;
        @InvocableVariable(label='Pipeline Id' required=true)
        public String pipelineId;
    }


    @InvocableMethod(label='Disable Pre-Fetched Volume')
    public static void execute(List<InvocableVariables> variables) {
        Savepoint sp = Database.setSavepoint();

        try {
            fflib_SObjectDomain.getTriggerEvent(Functions.class).disableAll();
            fflib_SObjectDomain.getTriggerEvent(JobStepTrigger.class).disableAll();
            fflib_SObjectDomain.getTriggerEvent(JobTemplateTrigger.class).disableAll();
            List<String> actionNames = new List<String> { 'Commit', 'Promotion', 'PromotionDeployment'};
            List<PreFetchedVolumes__c> volumes = [SELECT Id FROM PreFetchedVolumes__c WHERE Pipeline_Id__c = :variables[0].pipelineId WITH SYSTEM_MODE];
            List<System_Property__c> systemProperties = [SELECT Id FROM System_Property__c WHERE ParentId__c = :variables[0].pipelineId AND API_Name__c = 'PreFetchedRepository' WITH USER_MODE];

            DML.deleteAsSystem(volumes, '');
            DML.deleteAsSystem(systemProperties, '');
            DML.deleteAsSystem(prefetchVolumeSteps(variables[0].pipelineId, actionNames), '');
            fflib_SObjectDomain.getTriggerEvent(Functions.class).enableAll();
            fflib_SObjectDomain.getTriggerEvent(JobStepTrigger.class).enableAll();
            fflib_SObjectDomain.getTriggerEvent(JobTemplateTrigger.class).enableAll();
        } catch (Exception ex) {
            Database.rollback(sp);
            throw new ApplicationException(ex.getMessage());
        }
    }


    private static List<JobStep__c> prefetchVolumeSteps(Id pipelineId, List<String> actionNames) {
        return [SELECT Id
                    FROM JobStep__c
                    WHERE Name = 'Use Prefetched Volume'
                        AND JobTemplate__c IN (
                                    SELECT Job_Template__c
                                    FROM Pipeline_Action__c
                                    WHERE Pipeline__c = :pipelineId
                                    AND Action__c IN :actionNames)
                    WITH USER_MODE];
    }
}