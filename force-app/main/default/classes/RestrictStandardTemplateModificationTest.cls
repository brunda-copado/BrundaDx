@IsTest
private class RestrictStandardTemplateModificationTest {

    @isTest
    private static void createWithSettingDisabled() {
        // Setup
        Exception expectedException = null;


        // Exercise
        try {
            insert new JobTemplate__c(Name = 'Sample', Version__c = 1, Type__c = 'Standard');
        }
        catch (Exception ex) {
            expectedException = ex;
        }


        // Verify
        System.assertNotEquals(null, expectedException);
        System.assert(expectedException.getMessage().contains(Label.StandardTemplateModificationNotAllowed));
    }


    @isTest
    private static void changeStandardToCustomWithSettingDisabled() {
        // Setup
        Exception expectedException = null;
        Settings__c setting = new Settings__c(SetupOwnerId=UserInfo.getOrganizationId(), Enable_Standard_Job_Template_Edit__c = true);
        insert setting;

        JobTemplate__c template = new JobTemplate__c(Name = 'Sample', Version__c = 1, Type__c = 'Standard');
        insert template;

        setting.Enable_Standard_Job_Template_Edit__c = false;
        update setting;


        // Exercise
        try {
            template.Type__c = 'Custom';
            update template;
        }
        catch (Exception ex) {
            expectedException = ex;
        }


        // Verify
        System.assertNotEquals(null, expectedException);
        System.assert(expectedException.getMessage().contains(Label.StandardTemplateModificationNotAllowed));
    }

    @isTest
    private static void createWithSettingEnabled() {
        // Setup
        Exception expectedException = null;
        insert new Settings__c(SetupOwnerId=UserInfo.getOrganizationId(), Enable_Standard_Job_Template_Edit__c = true);


        // Exercise
        try {
            insert new JobTemplate__c(Name = 'Sample', Version__c = 1, Type__c = 'Standard');
        }
        catch (Exception ex) {
            expectedException = ex;
        }


        // Verify
        System.assertEquals(null, expectedException);
    }


    @isTest
    private static void updateWithSettingDisabled() {
        // Setup
        Exception expectedException = null;
        JobTemplate__c template = new JobTemplate__c(Name = 'Sample', Version__c = 1);
        insert template;


        // Exercise
        try {
            template.Type__c = 'Standard';
            update template;
        }
        catch (Exception ex) {
            expectedException = ex;
        }


        // Verify
        System.assertNotEquals(null, expectedException);
        System.assert(expectedException.getMessage().contains(Label.StandardTemplateModificationNotAllowed));
    }


    @isTest
    private static void deleteWithSettingDisabled() {
        // Setup
        Exception expectedException = null;
        Settings__c setting = new Settings__c(SetupOwnerId=UserInfo.getOrganizationId(), Enable_Standard_Job_Template_Edit__c = true);
        insert setting;

        JobTemplate__c template = new JobTemplate__c(Name = 'Sample', Version__c = 1, Type__c = 'Standard');
        insert template;

        setting.Enable_Standard_Job_Template_Edit__c = false;
        update setting;


        // Exercise
        try {
            delete template;
        }
        catch (Exception ex) {
            expectedException = ex;
        }


        // Verify
        System.assertNotEquals(null, expectedException);
        System.assert(expectedException.getMessage().contains(Label.StandardTemplateModificationNotAllowed));
    }
}