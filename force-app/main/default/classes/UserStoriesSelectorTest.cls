@IsTest
public with sharing class UserStoriesSelectorTest {
    // TODO: Deprecate these tests, selector classes should not have test classes associated.
    /* @IsTest
    private static void defaultFields() {
        // Exercise
        UserStoriesSelector selector = new UserStoriesSelector();
        List<SObjectField> metadataFields = selector.getSObjectFieldList();

        // Verify
        List<SObjectField> assertFields = new List<SObjectField>{ User_Story__c.Id, User_Story__c.Name, User_Story__c.Environment__c };
        System.assertEquals(assertFields, metadataFields, 'Fields returned does not match');
    }

    @IsTest
    private static void queryByIdWithIndexingEnabled() {
        // Exercise
        UserStoriesSelector selector = new UserStoriesSelector();
        Database.QueryLocator query = selector.byIdWithIndexingEnabled(new Set<Id>());

        // Verify
        String assertQuery = 'SELECT Environment__c, Id, Name FROM User_Story__c WHERE Id IN :ids AND Stop_Indexing_Metadata__c = false AND Project__r.Index_Metadata__c = true ORDER BY Name ASC NULLS FIRST';
        System.assertEquals(assertQuery.trim(), query.getQuery().trim(), 'Query is not correct');
    }

    @IsTest
    private static void queryWithIndexingEnabled() {
        // Exercise
        UserStoriesSelector selector = new UserStoriesSelector();
        Database.QueryLocator query = selector.withIndexingEnabled();

        // Verify
        String assertQuery = 'SELECT Environment__c, Id, Name FROM User_Story__c WHERE Stop_Indexing_Metadata__c = false AND Project__r.Index_Metadata__c = true ORDER BY Name ASC NULLS FIRST';
        System.assertEquals(assertQuery.trim(), query.getQuery().trim(), 'Query is not correct');
    }*/
}