public inherited sharing class TestsSelector extends fflib_SObjectSelector {
    private static final String BY_PARENT_CONDITION = '(User_Story__c IN :parentIds OR Feature__c IN :parentIds OR Application__c IN :parentIds OR Promotion__c IN :parentIds)';

    public List<SObjectField> getSObjectFieldList() {
        return new List<SObjectField>{
            Test__c.Id,
            Test__c.Name,
            Test__c.Reference__c,
            Test__c.Type__c,
            Test__c.User_Story__c,
            Test__c.Configuration__c,
            Test__c.ExtensionConfiguration__c,
            Test__c.LatestJobExecution__c,
            Test__c.AcceptanceCriteria__c,
            Test__c.ReadyToRun__c
        };
    }

    public SObjectType getSObjectType() {
        return Test__c.sObjectType;
    }

    public List<Test__c> byIds(Set<Id> ids) {
        return (List<Test__c>) Database.query(
            newQueryFactory()
                .setEnforceFLS(true)
                .selectField('ExtensionConfiguration__r.ExtensionTool__c')
                .selectField('LatestJobExecution__r.Name')
                .selectField('LatestJobExecution__r.Status__c')
                .selectField('User_Story__r.Environment__c')
                .selectField('User_Story__r.Project__r.Deployment_Flow__c')
                .selectField('User_Story__r.Release__r.Project__r.Deployment_Flow__c')
                .setCondition('Id IN :ids')
                .toSOQL()
        );
    }

    @SuppressWarnings('PMD.UnusedLocalVariable')
    public List<Test__c> byParentAndAutomaticallyExecutableTests(Id parentId) {
        // PMD returns parentIds as unusedvariable but it is being used in BY_PARENT_CONDITION final string
        Set<Id> parentIds = new Set<Id>{ parentId };
        String condition = BY_PARENT_CONDITION + ' AND (ExtensionConfiguration__r.Active__c = true AND ReadyToRun__c = true)';

        // @Note: Manual Tests is the only picklist value we have for Extension Tool, and are not automatically executable.
        // Therefore, to also test automatic execution, we need to disable this filter explicitly for Manual Tests.
        if (!Test.isRunningTest()) {
            condition += ' AND ExtensionConfiguration__r.ExtensionTool__c != \'Manual Tests\'';
        }

        return (List<Test__c>) Database.query(
            newQueryFactory().setEnforceFLS(true).selectField('ExtensionConfiguration__r.ExtensionTool__c').setCondition(condition).toSOQL()
        );
    }

    public List<Test__c> byParents(Set<Id> parentIds) {
        String byParentsCondition = 'Id IN :parentIds OR User_Story__c IN :parentIds OR Feature__c IN :parentIds OR Application__c IN :parentIds OR Promotion__c IN :parentIds';

        return (List<Test__c>) Database.query(
            newQueryFactory()
            .setEnforceFLS(true)
            .selectField('ExtensionConfiguration__r.ExtensionTool__c')
            .selectField('User_Story__r.Environment__c')
            .selectField('User_Story__r.Project__r.Deployment_Flow__c')
            .selectField('User_Story__r.Release__r.Project__r.Deployment_Flow__c')
            .setCondition(byParentsCondition).toSOQL()
        );
    }

    public List<Test__c> byParentWithLatestResult(Id parentId) {
        return byParentWithLatestResult(new Set<Id>{ parentId });
    }

    public List<Test__c> byParentWithLatestResult(Set<Id> parentIds) {
        fflib_QueryFactory query = newQueryFactory()
            .setEnforceFLS(true)
            .selectField('ExtensionConfiguration__r.ExtensionTool__c')
            .selectField('ExtensionConfiguration__r.Active__c')
            .setCondition(BY_PARENT_CONDITION);
        String resultRelationship = Settings.ns + 'Results__r';

        query.subselectQuery(resultRelationship)
            .selectFields(new ResultsSelector().getSObjectFieldList())
            .addOrdering('Start_Time__c', fflib_QueryFactory.SortOrder.DESCENDING, true)
            .setLimit(1);
        return (List<Test__c>) Database.query(query.toSOQL());
    }

    public List<Test__c> byIdsWithLatestResult(List<Id> ids) {
        fflib_QueryFactory query = newQueryFactory()
            .setEnforceFLS(true)
            .selectField('ExtensionConfiguration__r.ExtensionTool__c')
            .setCondition('Id IN :ids');
        String resultRelationship = Settings.ns + 'Results__r';

        query.subselectQuery(resultRelationship)
            .selectFields(new ResultsSelector().getSObjectFieldList())
            .addOrdering('Start_Time__c', fflib_QueryFactory.SortOrder.DESCENDING, true)
            .setLimit(1);
        return (List<Test__c>) Database.query(query.toSOQL());
    }
}