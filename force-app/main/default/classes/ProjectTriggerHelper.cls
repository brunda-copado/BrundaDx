public with sharing class ProjectTriggerHelper {
    public static boolean indexMedadataChangedFlag = false;
    private static Set<Id> projectIdsToEnableMC = new Set<Id>();
    private static Set<Id> projectIdsToDisableMC = new Set<Id>();

    private static Map<Id, Deployment_Flow__c> pipelineById = new Map<Id, Deployment_Flow__c>();

    public static void runIndexMetadataJob() {
        if (indexMedadataChangedFlag) {
            Database.executebatch(new IndexMetadataJob(), 50);
        }
        if (!projectIdsToEnableMC.isEmpty()) {
            Database.executeBatch(new IndexMetadataJobMC().projects(projectIdsToEnableMC).startIndexing());
        }
        if (!projectIdsToDisableMC.isEmpty()) {
            Database.executeBatch(new IndexMetadataJobMC().projects(projectIdsToDisableMC).stopIndexing());
        }
    }

    public static void checkIndexMedadataChanged(Project__c oldProject, Project__c newProject) {
        if (platformProject(newProject)) {
            if (!oldProject.Index_Metadata__c && newProject.Index_Metadata__c) {
                projectIdsToEnableMC.add(newProject.Id);
            } else if (oldProject.Index_Metadata__c && !newProject.Index_Metadata__c) {
                projectIdsToDisableMC.add(newProject.Id);
            }
        } else {
            if ((oldProject.Index_Metadata__c != newProject.Index_Metadata__c) && newProject.Index_Metadata__c == true) {
                indexMedadataChangedFlag = true;
            }
        }
    }

    public static void getPlatforms() {
        if (Trigger.isDelete) {
            return;
        }
        Set<Id> pipelineIds = new Set<Id>();
        for (SObject so : Trigger.new) {
            Project__c project = (Project__c) so;
            if (String.isNotBlank(project.Deployment_Flow__c)) {
                pipelineIds.add(project.Deployment_Flow__c);
            }
        }
        pipelineById = new Map<Id, Deployment_Flow__c>([SELECT Platform__c FROM Deployment_Flow__c WHERE Id IN :pipelineIds]);
    }

    private static Boolean platformProject(Project__c project) {
        Deployment_Flow__c pipeline = pipelineById.get(project.Deployment_Flow__c);
        return pipeline != null && String.isNotBlank(pipeline.Platform__c) && pipeline.Platform__c != 'Salesforce';
    }
}