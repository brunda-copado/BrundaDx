public inherited sharing class DeploymentsSelector extends fflib_SObjectSelector {
    private String namespace = DeploymentsSelector.class.getName().substringBefore('DeploymentsSelector').removeEnd('.').toLowerCase();

    public SObjectType getSObjectType() {
        return Deployment__c.sObjectType;
    }

    public List<SObjectField> getSObjectFieldList() {
        return new List<SObjectField>{
            Deployment__c.Id,
            Deployment__c.Name,
            Deployment__c.From_Org__c,
            Deployment__c.Paused__c,
            Deployment__c.Status__c,
            Deployment__c.Active__c,
            Deployment__c.ApiName__c,
            Deployment__c.Build_Task__c,
            Deployment__c.RecordTypeId,
            Deployment__c.Promotion__c,
            Deployment__c.Description__c,
            Deployment__c.Date__c,
            Deployment__c.Rolled_Back_Deployment__c
        };
    }

    public DeploymentsSelector() {
        this(true);
    }

    public DeploymentsSelector(Boolean enforceFLS) {
        super(false, true, enforceFLS);
    }

    public List<Deployment__c> byId(List<Id> recordIds) {
        return (List<Deployment__c>) byId(new Set<Id>(recordIds));
    }

    public List<Deployment__c> byId(Set<Id> recordIds) {
        return (List<Deployment__c>) selectSObjectsById(recordIds);
    }

    public List<Deployment__c> templatesByName(Set<String> names) {
        @SuppressWarnings('PMD.UnusedLocalVariable')
        Id templateRecordTypeId = Schema.SObjectType.Deployment__c.getRecordTypeInfosByDeveloperName().get('Automation_Template').getRecordTypeId();

        return (List<Deployment__c>) Database.query(
            newQueryFactory(false, false, true).setCondition(Deployment__c.Name + ' IN :names AND RecordTypeId = :templateRecordTypeId').toSOQL()
        );
    }

    public List<Deployment__c> byIdWithSteps(Set<Id> recordIds) {
        fflib_QueryFactory query = newQueryFactory().setCondition('Id IN :recordIds');
        String stepRelationship = Settings.ns + 'Steps__r';

        query.subselectQuery(stepRelationship)
            .selectFields(new StepsSelector().getFields())
            .addOrdering('Order__c', fflib_QueryFactory.SortOrder.ASCENDING);

        return (List<Deployment__c>) Database.query(query.toSOQL());
    }

    public Map<Id, Deployment__c> deploymentByIds(List<Deployment__c> records) {
        fflib_QueryFactory query = selectFields().setCondition('Id IN :records');

        namespace = String.isNotBlank(namespace) ? namespace + '__' : namespace;

        new StepsSelector().addQueryFactorySubselect(query, namespace + 'Steps__r');

        query.subselectQuery(namespace + 'Destination_Orgs__r')
            .setCondition('To_Org__r.Environment__c != null')
            .selectFields(new DestinationOrgsSelector().getRelationalFields());

        return new Map<Id, Deployment__c>((List<Deployment__c>) Database.query(query.toSOQL()));
    }

    public List<Deployment__c> byNameWithSteps(Set<String> names) {
        fflib_QueryFactory query = newQueryFactory().setCondition('ApiName__c IN :names');
        namespace = String.isNotBlank(namespace) ? namespace + '__' : namespace;

        query.subselectQuery(namespace + 'Steps__r')
            .selectFields(new StepsSelector().getFields())
            .addOrdering('Order__c', fflib_QueryFactory.SortOrder.ASCENDING);

        return (List<Deployment__c>) Database.query(query.toSOQL());
    }

    public Deployment__c byPromotionId(Id promotionId) {
        fflib_QueryFactory query = newQueryFactory()
            .setCondition(Deployment__c.Promotion__c + ' = :promotionId')
            .addOrdering('CreatedDate', fflib_QueryFactory.SortOrder.DESCENDING);

        List<Deployment__c> result = (List<Deployment__c>) Database.query(query.toSOQL());

        return (result.isEmpty() ? null : result[0]);
    }

    public fflib_QueryFactory selectFields() {
        return newQueryFactory()
            .selectField('Build_Task__r.Continuous_Integration__r.Post_Success_Deployment_Jobs__c')
            .selectField('Build_Task__r.Continuous_Integration__r.Post_Failed_Deployment_Jobs__c')
            .selectField('From_Org__r.Name')
            .selectField('From_Org__r.Environment__r.Platform__c')
            .selectField('From_Org__r.Environment__r.Org_ID__c');
    }
}