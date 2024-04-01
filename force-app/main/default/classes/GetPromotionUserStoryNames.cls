@SuppressWarnings('PMD.AvoidGlobalModifier')
global with sharing class GetPromotionUserStoryNames {
    global class InvocableVariables {
        @InvocableVariable(label='Promotion Id' required=true)
        global String promotionId;

        @InvocableVariable(label='Job Id' required=true)
        global String jobId;
    }

    @InvocableMethod(label='Collect Promotion Data')
    global static List<String> execute(List<InvocableVariables> variables) {
        Map<String, Object> result = new Map<String, Object>();

        result.put('user_stories', userStoryNames(variables[0].promotionId));
        result.put('target_branch', targetBranch(variables[0].jobId));

        return new List<String>{ JSON.serialize(result) };
    }

    // PRIVATE

    private static String targetBranch(Id jobId) {
        Deployment_Job__c job = [SELECT Id, Source_Id__c, Destination_Id__c, Pipeline_Id__c FROM Deployment_Job__c WHERE Id = :jobId];

        Map<Id, String> branchByEnvironment = PromoteChangesExtension.getEnvsAndBranchesOfDeploymentFlow(job.Pipeline_Id__c);

        return branchByEnvironment.get(job.Destination_Id__c);
    }

    private static String userStoryNames(Id promotionId) {
        List<String> result = new List<String>();

        for (User_Story__c userStory : new UserStoriesSelector().byPromotionId(new Set<Id>{ promotionId })) {
            result.add(userStory.Name);
        }

        return String.join(result, ',');
    }
}