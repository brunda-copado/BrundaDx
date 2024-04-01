@IsTest
private class ValidateUserStoryBundleTest {

    @IsTest
    private static void cancelChildUS() {
        Exception expectedException = null;

        System.runAs( getRunAsUser() ) {

            // Setup

            createData();

            User_Story__c us = story('User_Story').get(0);
            us.Status__c = 'Cancelled';
            us.Cancellation_Reason__c = 'Cancelled';

            // Exercise

            try {
                update us;
            } catch (Exception ex) {
                expectedException = ex;
            }

            // Verify

            System.assert(expectedException.getMessage().contains(Label.USB_ERROR_CHILD_CANCELLATION), 'Exception should be thrown.');
        }
    }


    @IsTest
    private static void regularUpdates() {
        Exception expectedException = null;

        System.runAs( getRunAsUser() ) {

            // Setup

            createData();

            User_Story__c us = story('User_Story').get(0);
            us.Status__c = 'Draft';
            us.Promote_Change__c = true;

            // Exercise

            try {
                update us;
            } catch (Exception ex) {
                expectedException = ex;
            }

            // Verify

            System.assertEquals(null, expectedException, 'Exception should not be thrown.');
        }
    }

    // HELPER

    @TestSetup
    private static void testSetup() {
        TestDataFactory.createUsers();
        User u = getRunAsUser();

        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Copado_User'];
        insert new PermissionSetAssignment(AssigneeId = u.Id, PermissionSetId = ps.Id);

        System.runAs(u) {
            TestUtilities.assignLicense(u.Username, true, true, true, true, true);
        }
    }


    private static void createData() {
        List<User_Story__c> stories = TestDataFactory.createUserStories(2, 'US', 'Approved', null, null, null, null, 'User_Story');
        insert stories;

        List<User_Story__c> usb = TestDataFactory.createUserStories(1, 'USB', 'Approved', null, null, null, null, 'Utility');
        usb.get(0).Is_Bundle__c = true;
        insert usb;

        List<Artifact__c> pkg = TestDataFactory.createPackages(1, 'pkg', 'User_Story_Bundle');
        insert pkg;

        List<Artifact_Version__c> bundle = TestDataFactory.createPackageVersions(1, 'pkgVersion', pkg.get(0).Id);
        bundle.get(0).User_Story__c = usb.get(0).Id;
        insert bundle;

        List<Bundled_Story__c> bundledStories = TestDataFactory.createBundledStories(bundle.get(0).Id, stories);
        insert bundledStories;
    }


    private static List<User_Story__c> story(String recordType) {
        return [SELECT Id FROM User_Story__c WHERE RecordType.DeveloperName = :recordType];
    }


    private static User getRunAsUser() {
        return [SELECT Id, Username FROM User WHERE Email = 'test2@test2.com' LIMIT 1];
    }
}