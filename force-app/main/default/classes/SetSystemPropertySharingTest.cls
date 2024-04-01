@IsTest
private class SetSystemPropertySharingTest {

    @IsTest
    private static void executeWithIsPublicEnabledOnCreate() {
        // Setup & Exercise
        System_Property__c property = (System_Property__c) new SystemProperty()
                                            .value('Public property')
                                            .apiName('PublicProperty')
                                            .sensitive(false)
                                            .isPublic(true)
                                            .parent(UserInfo.getUserId())
                                            .persist();


        // Verify
        Assert.areEqual(1, [SELECT count() FROM System_Property__Share WHERE ParentId = :property.Id AND RowCause = :Schema.System_Property__Share.RowCause.isPublic__c]);

    }


    @IsTest
    private static void executeWithIsPublicDisabledOnCreate() {
        // Setup & Exercise
        System_Property__c property = (System_Property__c) new SystemProperty()
                                            .value('Public property')
                                            .apiName('PublicProperty')
                                            .sensitive(false)
                                            .isPublic(false)
                                            .parent(UserInfo.getUserId())
                                            .persist();


        // Verify
        Assert.areEqual(0, [SELECT count() FROM System_Property__Share WHERE ParentId = :property.Id AND RowCause = :Schema.System_Property__Share.RowCause.isPublic__c]);

    }


    @IsTest
    private static void executeWithIsPublicEnabledOnUpdate() {
        // Setup
        System_Property__c property = (System_Property__c) new SystemProperty()
                                            .value('Public property')
                                            .apiName('PublicProperty')
                                            .sensitive(false)
                                            .parent(UserInfo.getUserId())
                                            .persist();


        // Exercise
        property.Is_Public__c = true;
        update property;


        // Verify
        Assert.areEqual(1, [SELECT count() FROM System_Property__Share WHERE ParentId = :property.Id AND RowCause = :Schema.System_Property__Share.RowCause.isPublic__c]);

    }


    @IsTest
    private static void executeWithIsPublicDisabledOnUpdate() {
        // Setup
        System_Property__c property = (System_Property__c) new SystemProperty()
                                            .value('Public property')
                                            .apiName('PublicProperty')
                                            .sensitive(false)
                                            .isPublic(true)
                                            .parent(UserInfo.getUserId())
                                            .persist();


        // Exercise
        property.Is_Public__c = false;
        update property;


        // Verify
        Assert.areEqual(0, [SELECT count() FROM System_Property__Share WHERE ParentId = :property.Id AND RowCause = :Schema.System_Property__Share.RowCause.isPublic__c]);

    }
}