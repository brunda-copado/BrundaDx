public inherited sharing class DeploymentTasksSelector extends fflib_SObjectSelector {
    public List<SObjectField> getSObjectFieldList() {
        return new List<SObjectField>{
            Deployment_Task__c.Id,
            Deployment_Task__c.Name,
            Deployment_Task__c.Notify_Task_Owner__c,
            Deployment_Task__c.Order__c,
            Deployment_Task__c.Perform_Manual_Task__c,
            Deployment_Task__c.Perform_in_Destination_Orgs__c,
            Deployment_Task__c.Perform_in_Source_Org__c,
            Deployment_Task__c.Status__c,
            Deployment_Task__c.Task_Description__c,
            Deployment_Task__c.Type__c,
            Deployment_Task__c.User_Story__c,
            Deployment_Task__c.dataJSON__c
        };
    }

    public SObjectType getSObjectType() {
        return Deployment_Task__c.sObjectType;
    }

    public Deployment_Task__c byId(Id recordId) {
        List<Deployment_Task__c> result = byIds(new Set<Id>{ recordId });

        return result.isEmpty() ? null : result[0];
    }

    public List<Deployment_Task__c> byIds(Set<Id> ids) {
        return selectSObjectsById(ids);
    }

    public List<Deployment_Task__c> byStories(Set<Id> ids) {
        return (List<Deployment_Task__c>) Database.query(
            newQueryFactory().setEnforceFLS(true).setCondition(Deployment_Task__c.User_Story__c + ' IN :ids').toSOQL()
        );
    }

    public Map<Id, List<Deployment_Task__c>> byUserStory(Set<Id> ids) {
        Map<Id, List<Deployment_Task__c>> result = new Map<Id, List<Deployment_Task__c>>();
        for (Deployment_Task__c deploymentTask : byStories(ids)) {
            Id userStoryId = deploymentTask.User_Story__c;
            if (!result.containsKey(userStoryId)) {
                result.put(userStoryId, new List<Deployment_Task__c>());
            }
            result.get(userStoryId).add(deploymentTask);
        }
        return result;
    }
}