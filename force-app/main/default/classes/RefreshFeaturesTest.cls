@IsTest
private class RefreshFeaturesTest {
    @TestSetup
    private static void setupData() {
        TestUtilities.getAllMultilicense();
        User user = (User) new User_t()
            .assign(new PermissionSetAssignment_t().copadoUser())
            .assign(new PermissionSetAssignment_t().functions())
            .assign(new PermissionSetAssignment_t().jobEngine())
            .assign(new PermissionSetAssignment_t().qualityGatesAdmin())
            .persist();
        System.runAs(user) {
            new CopadoLicense().user(user).enableAll().persist();
        }
    }

    @IsTest
    static void refreshCopadoInstallation() {
        String b = '{"ok":"Features refreshed correctly","isSuccess":true,"isFinished":true}';
        User user = getRunAsUser();

        System.runAs(user) {
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));
            List<RefreshFeatures.Response> responseMessages = RefreshFeatures.execute(
                new List<RefreshFeatures.Request>{ new RefreshFeatures.Request() }
            );

            Test.stopTest();

            System.assertEquals('Features refreshed correctly', responseMessages[0].message, 'Features refreshed correctly');
        }
    }

    private static User getRunAsUser() {
        return [SELECT Id, Email FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1];
    }
}