@IsTest
public with sharing class StageConnection extends DomainBuilder {
    public StageConnection() {
        super(Stage_Connection__c.SObjectType);
    }

    public StageConnection pipelineId(Id pipelineId) {
        set(Stage_Connection__c.Pipeline__c, pipelineId);
        return this;
    }

    public StageConnection stageId(Id stageId) {
        set(Stage_Connection__c.Stage__c, stageId);
        return this;
    }

    public StageConnection nextStageConnectionId(Id nextStageConnectionId) {
        set(Stage_Connection__c.Next_Stage_Connection__c, nextStageConnectionId);
        return this;
    }

    public StageConnection stage(Stage stage) {
        setParent(Stage_Connection__c.Stage__c, stage);
        return this;
    }
}