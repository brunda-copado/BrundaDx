@isTest
public class WizardUtilsControllerTest {
	@TestSetup
    private static void setupDataDML() {
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        System.runAs(thisUser) {
            TestUtilities.getAllMultilicense();
            ITestDefaults userCreation = new CopadoSetupTestDefaults.UserDefaults().createRunAsUsers().executeDML();
        }
        User standardUser = getStandardUser();
        TestUtilities.assignLicense(standardUser.Username, true, true, true);
        TestUtilities.assignLicense(UserInfo.getUserName(), true, true, true, true, true);
    }
    
    @IsTest
    private static void testIsOrgValidationDisabled() {
        System.runAs(getStandardUser()) {
            WizardUtilsController controller = new WizardUtilsController();
            System.assertNotEquals(controller.token2, '');
            System.debug(controller.sessionId);
            System.assertNotEquals(controller.orgId, '');
            System.assertNotEquals(controller.userId, '');
        }
    }
    private static User getStandardUser() {
        User user = [SELECT Username FROM User WHERE Username = 'test_user@myorg.com'];
        return user;
    }
}