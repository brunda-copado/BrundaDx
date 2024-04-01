@IsTest
private class SensitiveSystemPropertiesTest {
    @IsTest
    private static void insertSensitiveProperty() {
        // Setup & Exercise
        System_Property__c property = (System_Property__c) new SystemProperty()
            .value('Secret Value')
            .apiName('CheckValue')
            .sensitive(true)
            .parent(UserInfo.getUserId())
            .persist();

        // Verify
        Assert.areEqual('Secret Value', new SystemPropertiesSelector().byUID(uid(property)).Value__c, 'Property value should be decrypted correctly');
        Assert.areEqual(
            '<HIDDEN>',
            [SELECT Value__c FROM System_Property__c WHERE Id = :property.Id]
            .Value__c,
            'Property value should be hidden for sensitive properties.'
        );
    }

    @IsTest
    private static void insertSensitivePropertyWithoutValue() {
        // Setup & Exercise

        Exception expectedException;
        try {
            new SystemProperty().apiName('CheckValue').sensitive(true).parent(UserInfo.getUserId()).persist();
        } catch (Exception ex) {
            expectedException = ex;
        }

        // Verify
        Assert.isNotNull(expectedException, 'There is no exception');
        Assert.isTrue(expectedException.getMessage().contains(Label.ValueRequiredForSystemProperty), 'Exception messages do not match');
    }

    @IsTest
    private static void updateSensitiveProperty() {
        // Setup
        System_Property__c property = (System_Property__c) new SystemProperty()
            .value('Secret Value')
            .apiName('CheckValue')
            .sensitive(true)
            .parent(UserInfo.getUserId())
            .persist();

        // Exercise
        Test.startTest();
        property.Value__c = 'Updated Value';
        update property;
        Test.stopTest();

        // Verify
        Assert.areEqual(
            'Updated Value',
            new SystemPropertiesSelector().byUID(uid(property)).Value__c,
            'Property value should be decrypted correctly'
        );
        Assert.areEqual(
            '<HIDDEN>',
            [SELECT Value__c FROM System_Property__c WHERE Id = :property.Id]
            .Value__c,
            'Property value should be hidden for sensitive properties.'
        );
    }

    private static String uid(System_Property__c property) {
        return property.ParentId__c + '-' + property.API_Name__c;
    }
}