@IsTest
private class NewSnapshotIntermediaryControllerTest {
    @TestSetup
    private static void setupData() {
        TestUtilities.getAllMultilicense();
        User user = (User) new User_t()
            .assign(new PermissionSetAssignment_t().copadoUser())
            .assign(new PermissionSetAssignment_t().configureSnapshots())
            .persist();
        System.runAs(user) {
            new CopadoLicense().user(user).enableAll().persist();
        }
    }

    @IsTest
    private static void userHasSnapshotPermission() {
        System.runAs(getRunAsUser()) {
            // Setup
            Boolean userHasSnapshotPermission = false;

            // Exercise
            Test.startTest();
            userHasSnapshotPermission = NewSnapshotIntermediaryController.userHasSnapshotPermission();
            Test.stopTest();

            // Verify
            System.assertEquals(true, userHasSnapshotPermission, 'User has snapshot configure permission');
        }
    }

    @IsTest
    private static void getClassicURL() {
        System.runAs(getRunAsUser()) {
            // Setup
            String classicURL = '';

            // Exercise
            Test.startTest();
            classicURL = NewSnapshotIntermediaryController.getClassicURL();
            Test.stopTest();

            // Verify
            Pagereference pr = Page.EditGitBackup;
            String expectedURL = pr.getUrl();
            System.assertEquals(expectedURL, classicURL, 'Redirected to classic snapshot page');
        }
    }

    // HELPER

    private static User getRunAsUser() {
        return [SELECT Id FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1];
    }
}