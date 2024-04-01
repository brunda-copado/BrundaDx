public inherited sharing class ArtifactVersionsSelector extends fflib_SObjectSelector {
    // CONSTRUCTOR

    public ArtifactVersionsSelector() {
        this(true, true);
    }

    public ArtifactVersionsSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(false, enforceCRUD, enforceFLS, false);
    }

    // PUBLIC

    public Schema.SObjectType getSObjectType() {
        return Artifact_Version__c.sObjectType;
    }

    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{
            Artifact_Version__c.Name,
            Artifact_Version__c.User_Story__c,
            Artifact_Version__c.Status__c
        };
    }

    public List<Artifact_Version__c> byIds(Set<Id> ids) {
        return Database.query(
            newQueryFactory()
                .selectField('Artifact__c')
                .selectField('Artifact__r.Pipeline__r.Platform__c')
                .setCondition(Artifact_Version__c.Id + ' IN :ids')
                .toSOQL()
        );
    }
}