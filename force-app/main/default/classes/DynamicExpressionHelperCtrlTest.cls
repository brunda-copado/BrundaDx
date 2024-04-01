@isTest
private class DynamicExpressionHelperCtrlTest {
    @TestSetup
    private static void setupData() {
        TestUtilities.getAllMultilicense();

        User user = (User) new User_t()
            .alias('user')
            .assign(new PermissionSetAssignment_t().copadoUser())
            .assign(new PermissionSetAssignment_t().jobEngine())
            .assign(new PermissionSetAssignment_t().functions())
            .persist();

        System.runAs(user) {
            new CopadoLicense().user(user).enableAll().persist();
        }
    }

    @IsTest
    private static void executeAsStandardUser() {
        System.runAs(getStdUser()) {
            //Exercise

            Test.startTest();
            List<String> results = DynamicExpressionHelperCtrl.getApexExpressionOptions();
            Test.stopTest();

            // Verify

            Assert.isFalse(results.isEmpty(), 'There are classes implementing the said interface.');
        }
    }

    //HELPER

    private static User getStdUser() {
        return [SELECT Id, Email FROM User WHERE Profile.Name = 'Standard User' AND Alias = 'user' ORDER BY CreatedDate DESC LIMIT 1];
    }
}