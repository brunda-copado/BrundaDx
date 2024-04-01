public with sharing class FindPipeline {
    // PUBLIC

    public Id fromObject(Promotion__c promotion) {
        return String.isNotBlank(promotion.Project__r.Deployment_Flow__c)
            ? promotion.Project__r.Deployment_Flow__c
            : String.isNotBlank(promotion.Release__r.Project__r.Deployment_Flow__c) ? promotion.Release__r.Project__r.Deployment_Flow__c : null;
    }

    public Id fromObject(User_Story__c userStory) {
        return String.isNotBlank(userStory.Project__r.Deployment_Flow__c)
            ? userStory.Project__r.Deployment_Flow__c
            : String.isNotBlank(userStory.Release__r.Project__r.Deployment_Flow__c) ? userStory.Release__r.Project__r.Deployment_Flow__c : null;
    }

    public Id fromObject(JobStep__c jobStep) { 
        return String.isNotBlank(jobStep.JobExecution__r.Pipeline__c) ? jobStep.JobExecution__r.Pipeline__c : fromObject(jobStep.UserStory__r);
    }
}