public with sharing class GenerateAutomationEvent {
    private Automation_Event__c automationEvent;

    public GenerateAutomationEvent(String actionName, String actionStatus, String pipelineId) {
        this.automationEvent = new Automation_Event__c();
        this.automationEvent.Action_Name__c = actionName;
        this.automationEvent.Action_Status__c = actionStatus;
        this.automationEvent.Pipeline_Id__c = pipelineId;
    }

    @SuppressWarnings('PMD.ExcessiveParameterList')
    public GenerateAutomationEvent(String actionName, String actionStatus, String pipelineId, String actionResult) {
        this.automationEvent = new Automation_Event__c();
        this.automationEvent.Action_Name__c = actionName;
        this.automationEvent.Action_Status__c = actionStatus;
        this.automationEvent.Action_Result__c = actionResult;
        this.automationEvent.Pipeline_Id__c = pipelineId;
    }

    public GenerateAutomationEvent(String actionName, JobExecution__c job, String actionResult) {
        this(actionName, job.Status__c, job.Pipeline__c, actionResult);
        this.automationEvent.Environment_Id__c = job.Destination__c;
        this.automationEvent.Stage_Id__c = getStage(job.Destination__c);
        this.automationEvent.Job_Execution_Id__c = job.Id;
    }

    public GenerateAutomationEvent setEnvironment(Id environmentId) {
        this.automationEvent.Environment_Id__c = environmentId;
        this.automationEvent.Stage_Id__c = getStage(environmentId);
        return this;
    }

    public GenerateAutomationEvent setPayload(String payload) {
        this.automationEvent.Payload__c = payload;
        return this;
    }

    public Automation_Event__c execute() {
        DML.safeInsert(
            this.automationEvent,
            'Could not insert the Automation Event object on the ' +
            this.automationEvent.Action_Name__c +
            ' action ( GenerateAutomationEvent.createEvent class )'
        );
        return this.automationEvent;
    }

    // PRIVATE

    private Id getStage(Id environmentId) {
        return String.isNotBlank(environmentId) ? new PipelineDescriptor(this.automationEvent.Pipeline_Id__c).getStageId(environmentId) : null;
    }
}