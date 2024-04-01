public inherited sharing class PipelineSelector extends fflib_SObjectSelector {
    // CONSTRUCTOR

    public PipelineSelector() {
        this(true);
    }

    public PipelineSelector(Boolean enforceFLS) {
        super(false, true, enforceFLS, false);
    }

    // PUBLIC

    public List<SObjectField> getSObjectFieldList() {
        return new List<SObjectField>{
            Deployment_Flow__c.Active__c,
            Deployment_Flow__c.Block_Commits__c,
            Deployment_Flow__c.Git_Repository__c,
            Deployment_Flow__c.Main_Branch__c,
            Deployment_Flow__c.Platform__c
        };
    }

    public SObjectType getSObjectType() {
        return Deployment_Flow__c.sObjectType;
    }

    public List<Deployment_Flow__c> byId(Set<Id> ids) {
        return Database.query(newQueryFactory().setCondition('Id IN :ids').toSOQL());
    }

    public List<Deployment_Flow__c> byIdsWithChilds(Set<Id> ids) {
        fflib_QueryFactory pipelineQueryFactory = newQueryFactory();
        new DeploymentFlowStepsSelector().addQueryFactorySubselect(pipelineQueryFactory);

        return Database.query(pipelineQueryFactory.setCondition('Id IN :ids').toSOQL());
    }
}