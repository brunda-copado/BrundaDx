/**
 * This controller was created in order to have a Picklist field with its values
 * onto a Visualforce Component, since Component's don't accept standardController
 */
public with sharing class ManualTaskComponentController {

    public Deployment_Task__c task { get; set; }
    public String userStoryId { get; set; }

    public ManualTaskComponentController() {
        task = new Deployment_Task__c();
    }

    public List<SelectOption> getAllEnvironmentsInPipeline() {
        List<SelectOption> environmentNames = new List<SelectOption>();
        String pipelineId = '';
        for (User_Story__c userStoryRecord : new UserStoriesSelector().byIds(new Set<Id>{userStoryId})) {
            pipelineId = userStoryRecord.Project__r.Deployment_Flow__c != null ? userStoryRecord.Project__r.Deployment_Flow__c : '';
            pipelineId = userStoryRecord.Release__r.Project__r.Deployment_Flow__c != null ? userStoryRecord.Release__r.Project__r.Deployment_Flow__c : pipelineId;
        }
        Set<Id> environmentIds = new Set<Id>();
        for(Deployment_Flow_Step__c pipelineConnection : new DeploymentFlowStepsSelector().byPipeline(new Set<Id>{pipelineId}).get(pipelineId)){
            if(!environmentIds.contains(pipelineConnection.Source_Environment__c)) {
                environmentNames.add(new SelectOption(pipelineConnection.Source_Environment__c,pipelineConnection.Source_Environment__r.Name));
                environmentIds.add(pipelineConnection.Source_Environment__c);
            } 
            if(!environmentIds.contains(pipelineConnection.Destination_Environment__c)) {
                environmentNames.add(new SelectOption(pipelineConnection.Destination_Environment__c,pipelineConnection.Destination_Environment__r.Name));
                environmentIds.add(pipelineConnection.Destination_Environment__c);
            }
        }
        return environmentNames;
    }

    public List<SelectOption> getSelectedEnvironments() {
        return new List<SelectOption>();
    }
}