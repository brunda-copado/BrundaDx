@IsTest
private class SetPropertyParentsTest {
    @TestSetup
    private static void makeData() {
        TestUtilities.setTestSettingsEE();
    }

    @IsTest
    private static void createUserProperty() {
        // Exercise

        Test.startTest();
        System_Property__c property = new System_Property__c(
            API_Name__c = 'USER-PROPERTY',
            Value__c = 'USER-PROPERTY',
            User__c = UserInfo.getUserId()
        );
        insert property;
        Test.stopTest();

        // Verify

        property = getProperty(property.Id);
        System.assertEquals(UserInfo.getUserId(), property.User__c, 'The parent user does not match the current user.');
        System.assertEquals(property.User__c, property.ParentId__c, 'The value in User__c was not copied into the property\'s ParentId field.');
    }

    @IsTest
    private static void createGitProperty() {
        // Setup

        Git_Repository__c repository = new Git_Repository__c();
        insert repository;

        // Exercise

        Test.startTest();
        System_Property__c property = new System_Property__c(API_Name__c = 'USER-PROPERTY', Value__c = 'USER-PROPERTY', ParentId__c = repository.Id);
        insert property;
        Test.stopTest();

        // Verify

        property = getProperty(property.Id);
        System.assertEquals(
            repository.Id,
            property.ParentId__c,
            'The value in ParentId does not match the Git Repository Id for which it was created.'
        );
    }

    @IsTest
    private static void updatePropertyParent() {
        // Setup

        Git_Repository__c repository = new Git_Repository__c();
        insert repository;
        System_Property__c property = new System_Property__c(API_Name__c = 'USER-PROPERTY', Value__c = 'USER-PROPERTY', ParentId__c = repository.Id);
        insert property;

        // Exercise

        Test.startTest();
        property.User__c = UserInfo.getUserId();
        update property;
        Test.stopTest();

        // Verify

        property = getProperty(property.Id);
        System.assertEquals(UserInfo.getUserId(), property.User__c, 'The parent user does not match the current user.');
        System.assertEquals(property.User__c, property.ParentId__c, 'The ParentId field was not overriden by the new parent that was set (User__c).');
    }

    @IsTest
    private static void createGlobalProperty() {
        // Exercise

        Test.startTest();
        System_Property__c property = new System_Property__c(API_Name__c = 'GLOBAL-PROPERTY', Value__c = 'PROPERTY', Is_Global__c = true);
        insert property;
        Test.stopTest();

        // Verify

        property = getProperty(property.Id);
        System.assertEquals(property.API_Name__c, property.UID__c, 'The UID does not match the API Name of the property.');
        System.assertEquals(null, property.ParentId__c, 'The ParentId__c field contains a value.');
    }

    @IsTest
    private static void updateNonGlobalPropertyToGlobal() {
        // Setup
        System_Property__c property = new System_Property__c(
            API_Name__c = 'USER-PROPERTY',
            Value__c = 'USER-PROPERTY',
            User__c = UserInfo.getUserId()
        );
        insert property;

        // Exercise

        Test.startTest();
        property.Is_Global__c = true;
        update property;
        Test.stopTest();

        // Verify

        property = getProperty(property.Id);
        System.assertEquals(property.API_Name__c, property.UID__c, 'The UID does not match the API Name of the property.');
        System.assertEquals(property.User__c, property.ParentId__c, 'The values does not match.');
    }

    // HELPER

    private static System_Property__c getProperty(Id propertyId) {
        return [SELECT User__c, ParentId__c, UID__c, API_Name__c FROM System_Property__c WHERE Id = :propertyId];
    }
}