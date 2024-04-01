@IsTest
private class CancelUserStoryBundleTest {
    @IsTest
    private static void cancel() {
        System.runAs(getRunAsUser()) {
            // Setup

            User_Story__c usb = cancelUSB();

            // Exercise

            update usb;

            // Verify

            usb = story('Utility').get(0);
            System.assertEquals(true, usb.Stop_Indexing_Metadata__c, 'Stop Indexing Metadata field should be true.');
            System.assertEquals(true, usb.Exclude_From_CBM__c, 'Exclude from CBM field should be true.');

            List<User_Story__c> us = story('User_Story');
            System.assertEquals(false, us.get(0).Stop_Indexing_Metadata__c, 'Stop Indexing Metadata field should be false.');
            System.assertEquals(false, us.get(1).Exclude_From_CBM__c, 'Exclude from CBM field should be false.');

            Artifact_Version__c bundle = [
                SELECT Status__c, (SELECT Id FROM Bundled_Stories__r)
                FROM Artifact_Version__c
                WHERE User_Story__c = :usb.Id
                LIMIT 1
            ];
            System.assertEquals('Cancelled', bundle.Status__c, 'Bundle should be Cancelled.');
            System.assert(bundle.Bundled_Stories__r.isEmpty(), 'Bundle Stories junction should be deleted.');
        }
    }

    @IsTest
    private static void cancelPackageVersion() {
        System.runAs(getRunAsUser()) {
            // Setup

            Artifact_Version__c usbPackage = cancelUSBPackage();

            // Exercise

            update usbPackage;

            // Verify

            User_Story__c usb = story('Utility').get(0);
            System.assertEquals(true, usb.Stop_Indexing_Metadata__c, 'Stop Indexing Metadata field should be true.');
            System.assertEquals(true, usb.Exclude_From_CBM__c, 'Exclude from CBM field should be true.');
            System.assertEquals(Label.Bundle_Cancellation_Reason, usb.Cancellation_Reason__c, 'Cancellation Reason should be provided.');

            List<User_Story__c> us = story('User_Story');
            System.assertEquals(false, us.get(0).Stop_Indexing_Metadata__c, 'Stop Indexing Metadata field should be false.');
            System.assertEquals(false, us.get(1).Exclude_From_CBM__c, 'Exclude from CBM field should be false.');

            Artifact_Version__c bundle = [
                SELECT Status__c, (SELECT Id FROM Bundled_Stories__r)
                FROM Artifact_Version__c
                WHERE User_Story__c = :usb.Id
                LIMIT 1
            ];
            System.assertEquals('Cancelled', bundle.Status__c, 'Bundle should be Cancelled.');
            System.assert(bundle.Bundled_Stories__r.isEmpty(), 'Bundle Stories junction should be deleted.');
        }
    }

    @IsTest
    private static void noSyncOnCancel() {
        System.runAs(getRunAsUser()) {
            // Setup

            User_Story__c usb = cancelUSB();
            usb.Promote_Change__c = true;

            // Exercise

            update usb;

            // Verify

            List<User_Story__c> us = story('User_Story');
            System.assertNotEquals(true, us.get(0).Promote_Change__c, 'Fields should not sync.');
            System.assertNotEquals('Cancelled', us.get(1).Status__c, 'Fields should not sync.');
        }
    }

    @IsTest
    private static void statusUpdateAfterCancel() {
        System.runAs(getRunAsUser()) {
            // Setup

            User_Story__c usb = cancelUSB();
            update usb;

            // Exercise

            usb.Status__c = 'Draft';
            update usb;

            // Verify

            usb = story('Utility').get(0);
            System.assertEquals('Draft', usb.Status__c, 'Status should change successfully.');
        }
    }

    // HELPER

    @TestSetup
    private static void testSetup() {
        User user = (User) new User_t().assign(new PermissionSetAssignment_t().copadoUser()).persist();
        System.runAs(user) {
            new CopadoLicense().user(user).enableAll().persist();
            createData();
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

    private static User_Story__c cancelUSB() {
        User_Story__c usb = story('Utility').get(0);
        usb.Status__c = 'Cancelled';
        usb.Cancellation_Reason__c = 'Cancelled';

        return usb;
    }

    private static Artifact_Version__c cancelUSBPackage() {
        Artifact_Version__c usbPackage = [SELECT Id, Status__c FROM Artifact_Version__c LIMIT 1];
        usbPackage.Status__c = 'Cancelled';

        return usbPackage;
    }

    private static List<User_Story__c> story(String recordType) {
        return [
            SELECT Status__c, Cancellation_Reason__c, Stop_Indexing_Metadata__c, Exclude_From_CBM__c, Promote_Change__c
            FROM User_Story__c
            WHERE RecordType.DeveloperName = :recordType
        ];
    }

    private static User getRunAsUser() {
        return [SELECT Id FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1];
    }
}