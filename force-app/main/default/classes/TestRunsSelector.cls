public inherited sharing class TestRunsSelector extends fflib_SObjectSelector {
    public SObjectType getSObjectType() {
        return Test_Run__c.sObjectType;
    }

    public List<SObjectField> getSObjectFieldList() {
        return new List<SObjectField>{
            Test_Run__c.Id,
            Test_Run__c.Name,
            Test_Run__c.Status__c,
            Test_Run__c.Test_Script__c,
            Test_Run__c.Test__c,
            Test_Run__c.Tester__c,
            Test_Run__c.Type__c,
            Test_Run__c.User_Story__c
        };
    }

    public List<Test_Run__c> byTestId(Id testId) {
        return Database.query(
            selectFields().setCondition('Test__c = :testId').setOrdering('CreatedDate', fflib_QueryFactory.SortOrder.DESCENDING).toSOQL()
        );
    }

    public List<Test_Run__c> createdAfterbyTestId(Id testId, Datetime filterTime) {
        return Database.query(
            selectFields()
                .setCondition('Test__c = :testId AND LastModifiedDate > :filterTime')
                .setOrdering('CreatedDate', fflib_QueryFactory.SortOrder.DESCENDING)
                .toSOQL()
        );
    }

    // PRIVATE

    private fflib_QueryFactory selectFields() {
        return newQueryFactory().selectFields(new List<String>{ 'User_Story__r.Name' });
    }
}