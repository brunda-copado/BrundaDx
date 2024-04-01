@isTest
private with sharing class FflibExtensionTest {
    @isTest
    private static void testSetAllLookupFields() {
        //Setup
        TestFflib_SObjectSelector selector = new TestFflib_SObjectSelector(false, false);
        fflib_QueryFactory query = selector.newQueryFactory();

        //Exercise
        
        selector.setLookupFields(query);

        // Verify

        System.assert(
            query.fields.contains('Account.Name'),
            'Lookup field are not included in query.'
        );
    }

    @isTest
    private static void testSetSingleLookupFields() {
        //Setup
        TestFflib_SObjectSelector selector = new TestFflib_SObjectSelector(false, false);
        fflib_QueryFactory query = selector.newQueryFactory();

        //Exercise
        
        selector.setLookupFields(query, 'Account');

        // Verify

        System.assert(
            query.fields.contains('Account.Name'),
            'Lookup field are not included in query.'
        );
    }

    private class TestFflib_SObjectSelector extends FFLIBExtension {
        private TestFflib_SObjectSelector(Boolean enforceCRUD, Boolean enforceFLS) {
            super(false, enforceCRUD, enforceFLS, false);
        }

        private List<Schema.SObjectField> getSObjectFieldList() {
            return new List<Schema.SObjectField>{
                Contact.FirstName,
                Contact.Id,
                Contact.LastName,
                Contact.AccountId
            };
        }

        private Schema.SObjectType getSObjectType() {
            return Contact.sObjectType;
        }

        private Map<String, List<Schema.SObjectField>> getSObjectLookupFieldMap() {
            return new Map<String, List<Schema.SObjectField>>{
                'Account' => new List<Schema.SObjectField>{ Account.Name }
            };
        }
    }
}