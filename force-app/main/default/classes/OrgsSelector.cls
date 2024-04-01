public inherited sharing class OrgsSelector extends fflib_SObjectSelector {
    // CONSTRUCTOR

    public OrgsSelector() {
        this(true);
    }

    public OrgsSelector(Boolean enforceFLS) {
        super(false, true, enforceFLS, false);
    }

    // PUBLIC

    public SObjectType getSObjectType() {
        return Org__c.sObjectType;
    }

    public List<SObjectField> getSObjectFieldList() {
        return new List<SObjectField>{
            Org__c.Id,
            Org__c.Name,
            Org__c.Platform__c,
            Org__c.Disable_Validation__c,
            Org__c.Metadata_Types__c,
            Org__c.Oauth_Signature__c,
            Org__c.Org_Type__c,
            Org__c.Validated_Status__c,
            Org__c.Validated_Date__c,
            Org__c.Test_Frequency__c,
            Org__c.Environment__c
        };
    }

    public List<Org__c> byId(List<Id> recordIds) {
        return byId(new Set<Id>(recordIds));
    }

    public List<Org__c> byId(Set<Id> recordIds) {
        return (List<Org__c>) selectSObjectsById(recordIds);
    }

    public List<Org__c> bySfdcOrgId(List<String> sfdcOrgIds) {
        return bySfdcOrgId(new Set<String>(sfdcOrgIds));
    }

    public List<Org__c> bySfdcOrgId(Set<String> sfdcOrgIds) {
        fflib_QueryFactory query = newQueryFactory().setCondition('SFDC_Org_ID__c IN :sfdcOrgIds');
        return (List<Org__c>) Database.query(query.toSOQL());
    }

    public Map<Id, Org__c> credentialsById(Set<String> credentialIds) {
        fflib_QueryFactory query = selectFields().setCondition('Id IN :credentialIds');
        return new Map<Id, Org__c>((List<Org__c>) Database.query(query.toSOQL()));
    }

    public List<Org__c> byEnvironmentAndIsDefault(Set<Id> environment, Boolean isDefault) {
        fflib_QueryFactory query = newQueryFactory()
            .setCondition('Environment__c IN :environment AND Default_Credential__c = :isDefault')
            .setOrdering(Org__c.CreatedDate, fflib_QueryFactory.SortOrder.DESCENDING)
            .addOrdering(Org__c.CreatedDate, fflib_QueryFactory.SortOrder.DESCENDING);
        return Database.query(query.toSOQL());
    }

    // PRIVATE

    private fflib_QueryFactory selectFields() {
        return newQueryFactory().selectField('Environment__r.Org_ID__c').selectField('Environment__r.Platform__c');
    }
}