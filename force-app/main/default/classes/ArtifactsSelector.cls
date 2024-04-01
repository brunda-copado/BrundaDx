public with sharing class ArtifactsSelector extends FflibExtension {
    // CONSTRUCTOR

    public ArtifactsSelector() {
        this(true, true);
    }

    public ArtifactsSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(false, enforceCRUD, enforceFLS, false);
    }

    // PUBLIC

    public Schema.SObjectType getSObjectType() {
        return Artifact__c.sObjectType;
    }

    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{ Artifact__c.Name };
    }

    public Map<String, List<Schema.SObjectField>> getSObjectLookupFieldMap() {
        return new Map<String, List<Schema.SObjectField>>{
            'Pipeline__r' => new List<Schema.SObjectField>{
                Deployment_Flow__c.Platform__c,
                Deployment_Flow__c.Git_Repository__c
            }
        };
    }

    public List<Artifact__c> byIds(Set<Id> ids) {
        fflib_QueryFactory query = newQueryFactory().setCondition(Artifact__c.Id + ' IN :ids');

        setLookupFields(query, 'Pipeline__r');

        return Database.query(query.toSOQL());
    }
}