public inherited sharing class DestinationOrgsSelector extends fflib_SObjectSelector {
    private String namespace = DestinationOrgsSelector.class.getName().substringBefore('DestinationOrgsSelector').removeEnd('.').toLowerCase();

    public SObjectType getSObjectType() {
        return Destination_Org__c.sObjectType;
    }

    public List<SObjectField> getSObjectFieldList() {
        return new List<SObjectField>{ Destination_Org__c.Id, Destination_Org__c.Deployment__c, Destination_Org__c.To_Org__c };
    }

    public DestinationOrgsSelector() {
        this(true);
    }

    public DestinationOrgsSelector(Boolean enforceFLS) {
        super(false, true, enforceFLS);
    }

    public List<Destination_Org__c> byId(List<Id> recordIds) {
        return (List<Destination_Org__c>) byId(new Set<Id>(recordIds));
    }

    public List<Destination_Org__c> byId(Set<Id> recordIds) {
        return (List<Destination_Org__c>) selectSObjectsById(recordIds);
    }

    public List<Destination_Org__c> byDeploymentId(List<Id> deploymentIds) {
        return (List<Destination_Org__c>) byDeploymentId(new Set<Id>(deploymentIds));
    }

    public List<Destination_Org__c> byDeploymentId(Set<Id> deploymentIds) {
        fflib_QueryFactory query = newQueryFactory().setCondition('Deployment__c IN :deploymentIds');

        fflib_SObjectSelector deploymentsSlector = new DeploymentsSelector();
        namespace = String.isNotBlank(namespace) ? namespace + '__' : namespace;
        deploymentsSlector.configureQueryFactoryFields(query, namespace + 'Deployment__r');

        return (List<Destination_Org__c>) Database.query(query.toSOQL());
    }

    public List<String> getRelationalFields() {
        return new List<String>{
            'Deployment__r.Status__c',
            'To_Org__r.Environment__c',
            'To_Org__r.Environment__r.Latest_Deployment__c',
            'To_Org__r.Environment__r.Latest_Deployment_Status__c',
            'To_Org__r.Environment__r.Run_all_tests__c'
        };
    }
}