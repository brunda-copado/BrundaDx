public with sharing class ActionTemplate {
    private String actionName;
    private Id pipelineId;
    private Id environmentId;
    private Boolean templateRequired;

    // CONSTRUCTOR

    public ActionTemplate(String actionName) {
        this.actionName = actionName;
        this.templateRequired = true;
    }

    // PUBLIC

    public ActionTemplate userStory(User_Story__c userStory) {
        this.pipelineId = userStoryPipeline(userStory);
        this.environmentId = userStoryEnvironment(userStory);
        return this;
    }

    public ActionTemplate promotion(Promotion__c promotion) {
        this.pipelineId = promotionPipeline(promotion);
        this.environmentId = promotionEnvironment(promotion);
        return this;
    }

    public ActionTemplate package(Artifact__c pkg) {
        this.pipelineId = packagePipeline(pkg);
        return this;
    }

    public ActionTemplate pipeline(Deployment_Flow__c pipeline) {
        this.pipelineId = pipeline.Id;
        return this;
    }

    public ActionTemplate gitSnapshot(Git_Backup__c gitSnapshot) {
        this.pipelineId = gitSnapshotPipeline(gitSnapshot);
        this.environmentId = gitSnapshotEnvironment(gitSnapshot);
        return this;
    }

    public ActionTemplate templateRequired(Boolean templateRequired) {
        this.templateRequired = templateRequired;
        return this;
    }

    public String getApiName() {
        String result;

        // Note: it is important that this selector returns the list ordered by non-default actions first in order to consider overrides first
        for (Pipeline_Action__c action : new PipelineActionsSelector().forActionTemplate(actionName, pipelineId)) {
            if (isEnvironmentOverride(action) && !environmentOverrideMatches(action, environmentId)) {
                continue;
            }
            result = action.Job_Template__r.ApiName__c;
            break;
        }

        if (templateRequired && String.isBlank(result)) {
            throw new ApplicationException(Label.Error_No_Action_Template_Defined);
        }

        return result;
    }

    // PRIVATE

    private Id userStoryPipeline(User_Story__c userStory) {
        Id result;

        if (String.isNotBlank(userStory?.Project__r?.Deployment_Flow__c)) {
            result = userStory.Project__r.Deployment_Flow__c;
        } else if (String.isNotBlank(userStory?.Release__r?.Project__r.Deployment_Flow__c)) {
            result = userStory.Release__r.Project__r.Deployment_Flow__c;
        }

        return result;
    }

    private Id promotionPipeline(Promotion__c promotion) {
        Id result;

        if (String.isNotBlank(promotion?.Project__r?.Deployment_Flow__c)) {
            result = promotion.Project__r.Deployment_Flow__c;
        } else if (String.isNotBlank(promotion?.Release__r?.Project__r.Deployment_Flow__c)) {
            result = promotion.Release__r.Project__r.Deployment_Flow__c;
        }

        return result;
    }

    private Id packagePipeline(Artifact__c pkg) {
        return pkg?.Pipeline__c;
    }

    private Id gitSnapshotPipeline(Git_Backup__c gitSnapshot) {
        return gitSnapshot?.Pipeline__c;
    }

    private Id userStoryEnvironment(User_Story__c userStory) {
        return userStory?.Environment__c;
    }

    private Id promotionEnvironment(Promotion__c promotion) {
        return promotion?.Destination_Environment__c;
    }
    private Id gitSnapshotEnvironment(Git_Backup__c gitSnapshot) {
        return gitSnapshot?.Org__r.Environment__c;
    }

    private Boolean isEnvironmentOverride(Pipeline_Action__c action) {
        return action.Default__c == false && String.isNotBlank(action.Environment__c);
    }

    private Boolean environmentOverrideMatches(Pipeline_Action__c action, Id environmentId) {
        return action.Environment__c == environmentId;
    }
}