public inherited sharing class UserStoriesSelector extends fflib_SObjectSelector {
    private static final String INDEXING_ENABLED = 'Stop_Indexing_Metadata__c = false AND Project__r.Index_Metadata__c = true AND (Platform__c = NULL OR Platform__c = \'Salesforce\')';

    // CONSTRUCTOR

    public UserStoriesSelector() {
        this(true, true);
    }

    public UserStoriesSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(false, enforceCRUD, enforceFLS, false);
    }

    // PUBLIC

    public SObjectType getSObjectType() {
        return User_Story__c.sObjectType;
    }

    public List<SObjectField> getSObjectFieldList() {
        return new List<SObjectField>{
            User_Story__c.Name,
            User_Story__c.Environment__c,
            User_Story__c.Org_Credential__c,
            User_Story__c.User_Story_Title__c,
            User_Story__c.Project__c,
            User_Story__c.Release__c,
            User_Story__c.Latest_Commit_Date__c,
            User_Story__c.Base_Branch__c,
            User_Story__c.US_Feature__c,
            User_Story__c.Minimum_Apex_Code_Coverage__c,
            User_Story__c.Platform__c,
            User_Story__c.Exclude_From_CBM__c,
            User_Story__c.Stop_Indexing_Metadata__c,
            User_Story__c.Promote_Change__c
        };
    }

    public List<User_Story__c> byId(Set<Id> recordIds) {
        return selectSObjectsById(recordIds);
    }

    public List<User_Story__c> byIds(Set<Id> ids) {
        return Database.query(selectFields().setCondition('Id IN :ids').toSOQL());
    }

    public List<User_Story__c> byIdsForMulticloud(Set<Id> ids) {
        return Database.query(selectMulticloudFields().setCondition('Id IN :ids').toSOQL());
    }

    public Map<Id, User_Story__c> byUserStoryIds(Set<Id> ids) {
        return new Map<Id, User_Story__c>(byIds(ids));
    }

    public Database.QueryLocator byIdWithIndexingEnabled(Set<Id> ids) {
        return Database.getQueryLocator(newQueryFactory().setCondition('Id IN :ids AND ' + INDEXING_ENABLED).toSOQL());
    }

    public Database.QueryLocator withIndexingEnabled() {
        return Database.getQueryLocator(newQueryFactory().setCondition(INDEXING_ENABLED).toSOQL());
    }

    public List<User_Story__c> byPromotionId(Set<Id> promotions) {
        Set<Id> stories = (Set<Id>) getFieldValues(
            new PromotedUserStoriesSelector().byPromotionId(promotions),
            Promoted_User_Story__c.User_Story__c,
            Set<Id>.class,
            false
        );
        return byIds(stories);
    }

    public List<User_Story__c> byBundlePackageVersions(Set<Id> versions) {
        Set<Id> stories = (Set<Id>) getFieldValues(
            new BundledStorySelector().byPackageVersion(versions),
            Bundled_Story__c.User_Story__c,
            Set<Id>.class,
            false
        );
        return byId(stories);
    }

    public List<User_Story__c> byIdsWithBundleJunctionsInStatus(Set<Id> ids, Set<String> status) {
        fflib_QueryFactory query = newQueryFactory().setCondition(User_Story__c.Id + ' IN :ids');

        new BundledStorySelector().addQueryFactorySubselect(query).setCondition('Package_Version__r.Status__c IN :status');

        return Database.query(query.toSOQL());
    }

    @SuppressWarnings('PMD.ExcessiveParameterList')
    public Object getFieldValues(List<SObject> records, SObjectField field, Type resultType, Boolean includeNullValues) {
        Set<Object> result = new Set<Object>();

        for (SObject record : records) {
            Object fieldValue = record.get(field);
            if (fieldValue != null || includeNullValues) {
                result.add(fieldValue);
            }
        }

        return JSON.deserialize(JSON.serialize(result), resultType);
    }

    // PRIVATE

    private fflib_QueryFactory selectFields() {
        return newQueryFactory()
            .selectFields(
                new List<String>{
                    'Release__r.Base_Branch__c',
                    'Project__r.Deployment_Flow__r.Main_Branch__c',
                    'Project__r.Deployment_Flow__c',
                    'Project__r.Deployment_Flow__r.Git_Repository__c',
                    'Release__r.Project__r.Deployment_Flow__c',
                    'Release__r.Project__c',
                    'Org_Credential__r.Validated_Date__c',
                    'Sprint__r.Start_Date__c',
                    'US_Feature__r.Application__c'
                }
            );
    }

    // Note: separated method including fields that require the user to have copado_job_engine permission set assigned
    private fflib_QueryFactory selectMulticloudFields() {
        return newQueryFactory()
            .selectFields(
                new List<String>{
                    'Release__r.Base_Branch__c',
                    'Project__r.Deployment_Flow__r.Main_Branch__c',
                    'Project__r.Deployment_Flow__c',
                    'Project__r.Deployment_Flow__r.Git_Repository__c',
                    'Release__r.Project__r.Deployment_Flow__c',
                    'Release__r.Project__r.Deployment_Flow__r.Main_Branch__c',
                    'Release__r.Project__c',
                    'US_Feature__r.Application__c',
                    'Org_Credential__r.Validated_Date__c',
                    'Sprint__r.Start_Date__c'
                }
            );
    }
}