public inherited sharing class StepsSelector extends fflib_SObjectSelector {
    private String namespace = StepsSelector.class.getName().substringBefore('StepsSelector').removeEnd('.').toLowerCase();

    public SObjectType getSObjectType() {
        return Step__c.sObjectType;
    }

    public List<SObjectField> getSObjectFieldList() {
        return new List<SObjectField>{
            Step__c.Id,
            Step__c.Name,
            Step__c.Deployment__c,
            Step__c.dataJSON__c,
            Step__c.Type__c,
            Step__c.Manual_Task_Notified__c,
            Step__c.CheckOnly__c,
            Step__c.Status__c,
            Step__c.Read_Only__c,
            Step__c.Branch__c,
            Step__c.Git_Repository__c,
            Step__c.Commit_Name__c,
            Step__c.Commit_Id__c
        };
    }

    public StepsSelector() {
        this(true);
    }

    public StepsSelector(Boolean enforceFLS) {
        super(false, true, enforceFLS);
    }

    public List<Step__c> byId(List<Id> recordIds) {
        return (List<Step__c>) byId(new Set<Id>(recordIds));
    }

    public List<Step__c> byDeploymentIdFilteringTypes(List<Id> deploymentIds, List<String> types) {
        String condition = Step__c.Deployment__c + ' IN :deploymentIds';
        if (!types.isEmpty()) {
            condition += ' AND ' + Step__c.Type__c + ' IN :types';
        }

        fflib_QueryFactory query = newQueryFactory().setCondition(condition);
        return (List<Step__c>) Database.query(query.toSOQL());
    }

    public List<Step__c> byId(Set<Id> recordIds) {
        fflib_QueryFactory query = newQueryFactory().setCondition('Id IN :recordIds');

        fflib_SObjectSelector deploymentsSlector = new DeploymentsSelector();
        namespace = String.isNotBlank(namespace) ? namespace + '__' : namespace;
        deploymentsSlector.configureQueryFactoryFields(query, namespace + 'Deployment__r');

        return (List<Step__c>) Database.query(query.toSOQL());
    }

    public List<Step__c> byParentId(Set<Id> recordIds) {
        Set<String> prefixes = new Set<String>();
        for (Id recordId : recordIds) {
            prefixes.add(recordId.getSobjectType().getDescribe().getKeyPrefix() + '%');
        }
        fflib_QueryFactory query = newQueryFactory()
            .setCondition(Step__c.ParentId__c + ' LIKE :prefixes AND ' + Step__c.ParentId__c + ' IN :recordIds')
            .setOrdering(
                Schema.sObjectType.Step__c.fields.Deployment__c.getRelationshipName() +
                '.' +
                Deployment__c.Date__c,
                fflib_QueryFactory.SortOrder.DESCENDING,
                true
            );

        fflib_SObjectSelector deploymentsSlector = new DeploymentsSelector();
        deploymentsSlector.configureQueryFactoryFields(query, Schema.sObjectType.Step__c.fields.Deployment__c.getRelationshipName());

        return (List<Step__c>) Database.query(query.toSOQL());
    }

    public List<String> getFields() {
        return new List<String>{
            'Name',
            'Deployment__c',
            'dataJSON__c',
            'Type__c',
            'Manual_Task_Notified__c',
            'CheckOnly__c',
            'Status__c',
            'Read_Only__c',
            'Order__c',
            'Automated_Behaviour__c'
        };
    }
}