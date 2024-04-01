public inherited sharing class StageConnectionsSelector extends fflib_SObjectSelector {
    // CTOR

    public StageConnectionsSelector() {
        this(true, true);
    }

    public StageConnectionsSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(false, enforceCRUD, enforceFLS, false);
    }

    // PUBLIC

    public SObjectType getSObjectType() {
        return Stage_Connection__c.sObjectType;
    }

    public List<SObjectField> getSObjectFieldList() {
        return new List<SObjectField>{
            Stage_Connection__c.Id,
            Stage_Connection__c.Name,
            Stage_Connection__c.Pipeline__c,
            Stage_Connection__c.Stage__c,
            Stage_Connection__c.Next_Stage_Connection__c
        };
    }

    public Map<Id, List<Stage_Connection__c>> byPipeline(Set<Id> pipelines) {
        Map<Id, List<Stage_Connection__c>> result = new Map<Id, List<Stage_Connection__c>>();

        for (Id pipelineId : pipelines) {
            result.put(pipelineId, new List<Stage_Connection__c>());
        }

        List<Stage_Connection__c> connections = (List<Stage_Connection__c>) Database.query(
            newQueryFactory().setCondition('Pipeline__c IN :pipelines').toSOQL()
        );

        for (Stage_Connection__c connection : connections) {
            result.get(connection.Pipeline__c).add(connection);
        }

        return result;
    }

    public Map<Id, List<Stage_Connection__c>> byStage(Set<Id> stageIds) {
        Map<Id, List<Stage_Connection__c>> result = new Map<Id, List<Stage_Connection__c>>();

        for (Id stageId : stageIds) {
            result.put(stageId, new List<Stage_Connection__c>());
        }

        List<Stage_Connection__c> connections = (List<Stage_Connection__c>) Database.query(
            newQueryFactory().setCondition('Stage__c IN :stageIds').toSOQL()
        );

        for (Stage_Connection__c connection : connections) {
            result.get(connection.Stage__c).add(connection);
        }

        return result;
    }
}