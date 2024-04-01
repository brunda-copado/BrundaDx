@isTest
private class ActivateManualTestsCtrlTest {
    @isTest
    private static void verifyActivateOnSuccessResponse() {
        System.runAs(getRunAsUser()) {
            //Setup
            ExtensionConfiguration__c extensionConfig = getExtensionConfiguration();
            extensionConfig.AcceptanceCriteria__c = '[{"testerScope":"Group","tester":{"icon":"standard:groups","id":"00G09000003gbdNEAQ","sObjectType":"Group","subtitle":"Group • Test","title":"Test","titleFormatted":"Test","subtitleFormatted":"Group • Test"},"type":"Required","minimumTesters":"2","editableTesters":true},{"testerScope":"User","tester":{"icon":"standard:user","id":"0050900000299hdAAA","sObjectType":"User","subtitle":"User • Manuel Moya","title":"Manuel Moya","titleFormatted":"<strong>Man</strong>uel Moya","subtitleFormatted":"User • <strong>Man</strong>uel Moya"},"type":"Optional","minimumTesters":1,"editableTesters":false}]';
            update extensionConfig;

            //Exercise
            Boolean result = ActivateManualTestsCtrl.activate(extensionConfig.Id);

            // Verify
            extensionConfig = getExtensionConfiguration();
            System.assertEquals(true, result, 'Expected activation to be true');
            System.assertEquals(true, extensionConfig.Active__c, 'Expected ' + true + ' and found ' + extensionConfig.Active__c);
        }
    }

    @isTest
    private static void verifyActivateWithoutAc() {
        System.runAs(getRunAsUser()) {
            //Setup
            ExtensionConfiguration__c extensionConfig = getExtensionConfiguration();

            //Exercise
            Boolean result = ActivateManualTestsCtrl.activate(extensionConfig.Id);

            // Verify
            extensionConfig = getExtensionConfiguration();
            System.assertEquals(false, result, 'Expected activation to be false');
            System.assertEquals(false, extensionConfig.Active__c, 'Expected ' + false + ' and found ' + extensionConfig.Active__c);
        }
    }

    @TestSetup
    private static void setup() {
        TestUtilities.getAllMultilicense();
        User user = (User) new User_t().assign(new PermissionSetAssignment_t().copadoUser()).persist();
        System.runAs(user) {
            new CopadoLicense().user(user).enableAll().persist();
            createExtensionConfiguration('Test Extension Configuration');
        }
    }

    private static User getRunAsUser() {
        return [SELECT Name FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1];
    }

    private static ExtensionConfiguration__c createExtensionConfiguration(String name) {
        ExtensionConfiguration__c extensionConfig = new ExtensionConfiguration__c(
            Name = name,
            ExtensionTool__c = 'Manual Tests',
            ExtensionApplication__c = 'Test'
        );
        insert extensionConfig;
        return extensionConfig;
    }

    private static ExtensionConfiguration__c getExtensionConfiguration() {
        return new ExtensionConfigurationsSelector().selectAll().get(0);
    }
}