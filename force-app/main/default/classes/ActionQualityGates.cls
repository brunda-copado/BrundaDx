public with sharing class ActionQualityGates {
    private String actionName;
    private String platform;
    private String templateName;
    private String pipelineId;
    private String environmentId;
    private List<User_Story_Metadata__c> metadataChanges;

    // @Note: contextIds is always User Stories Ids.
    //  When the Quality Gate condition is matched, then it may be transformed into Feature or Application Ids
    //  depending on Quality_Gate_Rule_Condition__c.Tests_From__c picklist value. For more info, check QualityGate.cls logic.
    private List<Id> contextIds;

    // CONSTRUCTOR

    public ActionQualityGates(String actionName) {
        this.actionName = actionName;
    }

    // PUBLIC

    public ActionQualityGates platform(String platform) {
        this.platform = platform;
        return this;
    }

    public ActionQualityGates templateName(String value) {
        this.templateName = value;
        return this;
    }

    public ActionQualityGates pipelineId(String pipelineId) {
        this.pipelineId = pipelineId;
        return this;
    }

    public ActionQualityGates environmentId(String environmentId) {
        this.environmentId = environmentId;
        return this;
    }

    public ActionQualityGates contextIdsFromUs(List<Id> userStoryIds) {
        this.contextIds = userStoryIds;
        return this;
    }

    public ActionQualityGates contextIdsFromUs(User_Story__c userStory) {
        this.contextIds = new List<Id>{ userStory.Id };
        return this;
    }

    public ActionQualityGates metadataChanges(List<User_Story_Metadata__c> metadataChanges) {
        this.metadataChanges = metadataChanges;
        return this;
    }

    public ActionQualityGates metadataChanges(List<CommitAction.Change> changes) {
        this.metadataChanges = getMetadataRecords(changes);
        return this;
    }

    public QualityGate.Response getSteps() {
        QualityGate.Request qualityGateRequest = new QualityGate.Request();
        qualityGateRequest.action = actionName;
        qualityGateRequest.platform = platform;
        qualityGateRequest.templateName = templateName;
        qualityGateRequest.environmentId = environmentId;
        qualityGateRequest.pipelineId = pipelineId;
        qualityGateRequest.contextIds = contextIds;
        qualityGateRequest.metadataChanges = metadataChanges;
        return new QualityGate(qualityGateRequest).getSteps();
    }

    // PRIVATE

    private List<User_Story_Metadata__c> getMetadataRecords(List<CommitAction.Change> changes) {
        List<User_Story_Metadata__c> result = new List<User_Story_Metadata__c>();
        for (CommitAction.Change change : changes) {
            result.add(new User_Story_Metadata__c(ModuleDirectory__c = change.m, Type__c = change.t, Metadata_API_Name__c = change.n));
        }
        return result;
    }
}