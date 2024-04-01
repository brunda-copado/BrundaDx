@IsTest
private with sharing class RelatedListCtrlTest {
    @IsTest
    private static void fetchRelatedListConfig() {
        // Setup
        Account acc = new Account(Name = 'test');
        insert acc;
        Contact cnt = new Contact(LastName = 'test', AccountId = acc.Id);
        insert cnt;

        // Exercise
        RelatedListConfig config = RelatedListCtrl.fetchRelatedListConfig(acc.Id, 'Contact', null);

        // Verify
        System.assertEquals(config.childListName, 'Contacts', 'Child list name does not match');
        System.assertNotEquals(config.sobjectLabel, null, 'Object label should not be null');
        System.assertNotEquals(config.sobjectLabelPlural, null, 'Object plural label should not be null');
        System.assertNotEquals(config.childObjectApiName, null, 'Object api name should not be null');

        

        // If Contact does not have its own tab in the org it will be null so it can not be asserted
        // System.assertNotEquals(config.iconName, null, 'Contacts icon should not be null');
    }
}