public with sharing class PromotionsSelector extends fflib_SObjectSelector {
    private String namespace = PromotionsSelector.class.getName().substringBefore('PromotionsSelector').removeEnd('.').toLowerCase();
    // CONSTRUCTOR

    public PromotionsSelector() {
        this(true, true);
    }

    public PromotionsSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(false, enforceCRUD, enforceFLS, false);
    }

    // PUBLIC

    public SObjectType getSObjectType() {
        return Promotion__c.sObjectType;
    }

    public List<SObjectField> getSObjectFieldList() {
        return new List<SObjectField>{
            Promotion__c.Id,
            Promotion__c.OwnerId,
            Promotion__c.Name,
            Promotion__c.Status__c,
            Promotion__c.Destination_Org_Credential__c,
            Promotion__c.Destination_Environment__c,
            Promotion__c.Source_Org_Credential__c,
            Promotion__c.Source_Environment__c,
            Promotion__c.Release__c,
            Promotion__c.Project__c,
            Promotion__c.Back_Promotion__c,
            Promotion__c.Platform__c,
            Promotion__c.Last_Deployment_Execution_Id__c,
            Promotion__c.Last_Promotion_Execution_Id__c
        };
    }

    public List<Promotion__c> byIds(Set<Id> ids) {
        return selectSObjectsById(ids);
    }

    public List<Promotion__c> promotionsByIds(Set<Id> recordIds) {
        fflib_QueryFactory query = selectFields().setCondition('Id IN :recordIds');
        namespace = String.isNotBlank(namespace) ? namespace + '__' : namespace;
        new PromotedUserStoriesSelector().addQueryFactorySubselect(query, namespace + 'Promoted_User_Stories__r');
        return Database.query(query.toSOQL());
    }

    public List<Promotion__c> promotionsWithRelationalFieldsByIds(Set<Id> recordIds) {
        fflib_QueryFactory query = selectFields().setCondition('Id IN :recordIds');
        return Database.query(query.toSOQL());
    }

    public List<Promotion__c> promotionsDetailsForPromoteAndDeployActions(Set<Id> recordIds) {
        fflib_QueryFactory query = selectFieldsForPromoteAction().setCondition('Id IN :recordIds');
        namespace = String.isNotBlank(namespace) ? namespace + '__' : namespace;
        new PromotedUserStoriesSelector().addQueryFactorySubselect(query, namespace + 'Promoted_User_Stories__r');
        return Database.query(query.toSOQL());
    }

    // PRIVATE

    private fflib_QueryFactory selectFields() {
        return newQueryFactory()
            .selectFields(
                new List<String>{
                    'Project__r.Deployment_Flow__c',
                    'Project__r.Deployment_Flow__r.Active__c',
                    'Project__r.Deployment_Flow__r.Git_Repository__c',
                    'Project__r.Deployment_Flow__r.Main_Branch__c',
                    'Project__r.Deployment_Flow__r.Platform__c',
                    'Release__r.Project__r.Deployment_Flow__c',
                    'Release__r.Project__r.Deployment_Flow__r.Active__c',
                    'Release__r.Project__r.Deployment_Flow__r.Git_Repository__c',
                    'Release__r.Project__r.Deployment_Flow__r.Main_Branch__c',
                    'Release__r.Project__r.Deployment_Flow__r.Platform__c',
                    'Destination_Org_Credential__r.Environment__c',
                    'Destination_Environment__r.Name',
                    'Destination_Environment__r.Platform__c'
                }
            );
    }

    private fflib_QueryFactory selectFieldsForPromoteAction() {
        return newQueryFactory()
            .selectFields(
                new List<String>{
                    'Destination_Environment__r.Name',
                    'Source_Environment__r.Name',
                    'Project__r.Deployment_Flow__c',
                    'Project__r.Deployment_Flow__r.Platform__c',
                    'Project__r.Deployment_Flow__r.Order_by__c',
                    'Release__r.Project__r.Deployment_Flow__c',
                    'Release__r.Project__r.Deployment_Flow__r.Platform__c',
                    'Release__r.Project__r.Deployment_Flow__r.Order_by__c',
                    'Release__r.Version__c',
                    'Destination_Environment__r.Platform__c',
                    'Order_by__c'
                }
            );
    }
}