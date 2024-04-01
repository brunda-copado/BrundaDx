@IsTest
public with sharing class PipelineAction extends DomainBuilder {
    public PipelineAction() {
        super(Pipeline_Action__c.SObjectType);
    }

    public PipelineAction pipeline(Pipeline pipeline) {
        setParent(Pipeline_Action__c.Pipeline__c, pipeline);
        return this;
    }

    public PipelineAction pipeline(Id pipeline) {
        set(Pipeline_Action__c.Pipeline__c, pipeline);
        return this;
    }

    public PipelineAction environment(Environment environment) {
        setParent(Pipeline_Action__c.Environment__c, environment);
        return this;
    }

    public PipelineAction environment(Id environment) {
        set(Pipeline_Action__c.Environment__c, environment);
        return this;
    }

    public PipelineAction template(JobTemplate template) {
        setParent(Pipeline_Action__c.Job_Template__c, template);
        return this;
    }

    public PipelineAction template(Id template) {
        set(Pipeline_Action__c.Job_Template__c, template);
        return this;
    }

    public PipelineAction action(String action) {
        return (PipelineAction) set(Pipeline_Action__c.Action__c, action);
    }

    public PipelineAction default() {
        return (PipelineAction) set(Pipeline_Action__c.Default__c, true);
    }
}