@IsTest
private class TestCreditComp {

    @TestSetup
    private static void setup() {
        user();
        data();
    }

    @IsTest
    private static void testSuccess() {
        System.runAs( standardUser() ) {

            // Setup

            FeatureManagement.setPackageIntegerValue('CustomFunctionCreditUsage', 100);
            FeatureManagement.setPackageIntegerValue('CustomFunctionHardCreditLimit', 1000);
            String body = '{"customerOrg":{"Name":"Copado Ltd","orgId":"00Db0000000KFgoEAG","autoRecharge":true,"credits":425,"id":995},"userInfo":{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"currencySymbol":"€","orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDefaultCurrencyIsoCode":"EUR","orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"00Db0000000KFgoEAG","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":false,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mWB2AAM","roleId__is_set":true,"sessionSecondsValid__is_set":true,"sessionSecondsValid":7200,"userDefaultCurrencyIsoCode__is_set":true,"userEmail__is_set":true,"userEmail":"pr@copado.com","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000hMqqAAE","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copado.com.basepackage","userTimeZone__is_set":true,"userTimeZone":"Europe/Paris","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}}';
            Test.setMock(HttpCalloutMock.class, new TestHttpCalloutMock(body, null));

            // Exercise

            Test.startTest();
            CreditsCompController con = new CreditsCompController();
            Test.stopTest();

            // Verify

            System.assertEquals(false, con.showError);
            System.assertEquals('', con.errorMessage);
            System.assertEquals(900, con.functionCredits);
        }
    }


    @IsTest
    static void testInitError() {
        System.runAs( standardUser() ) {

            // Setup

            Test.setMock(HttpCalloutMock.class, new TestHttpCalloutMock('{}', null));

            // Exercise

            Test.startTest();
            CreditsCompController con = new CreditsCompController();
            Test.stopTest();

            // Verify

            System.assertEquals(true, con.showError);
            System.assertEquals('System.NullPointerException: Attempt to de-reference a null object', con.errorMessage);
        }
    }


    @IsTest
    private static void testLicenseManagerPageReference() {
        System.runAs( standardUser() ) {
            
            // Exercise

            CreditsCompController con = new CreditsCompController();

            // Verify

            System.assertEquals(
                con.getLicenseManagerReference().getUrl(),
                new Pagereference('/lightning/n/' + Settings.ns + 'License_Manager').setRedirect(true).getUrl()
            );
        }
    }

    // HELPER

    private static void data() {
        System.runAs( standardUser() ) {
            insert TestUtilities.getTestSettings();
            Environment__c envDev = (Environment__c) new Environment()
                .name('Dev1 Environment')
                .type('Sandbox')
                .persist();

            String orgId = UserInfo.getOrganizationId() + '_' + UserInfo.getUserId();
            Org__c orgDev = CMTestMethodUtilities.createOrg('MyOrgDev1', 'Sandbox', orgId, null, null, System.now(), envDev.Id);
            insert orgDev;
        }
    }


    private static void user() {
        TestUtilities.getAllMultilicense();

        User u = (User) new User_t()
            .assign( new PermissionSetAssignment_t().copadoUser() )
            .persist();

        System.runAs(u) {
            new CopadoLicense().user(u).enableAll().persist();
        }
    }


    private static User standardUser() {
        return [SELECT Id FROM User WHERE Profile.Name = 'Standard User' AND UserName LIKE '%@test%.org' ORDER BY CreatedDate DESC LIMIT 1];
    }
}