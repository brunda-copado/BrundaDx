@SuppressWarnings('PMD.AvoidHardcodingId')
@IsTest
public with sharing class TestAuthGrantService {

    private final static String DEV_HUB_ORG_ID = '00D1i00000095cEEAQ';
    private final static String SCRATCH_ORG_ID = 'a0c0X00000OHKBlQAP';

    @TestSetup
    static void makeData() {
        TestUtilities.enableLicenses(2, 2, 2, 2, 2, 30);
        ITestDefaults userCreation = new CopadoSetupTestDefaults.UserDefaults().createRunAsUsers().executeDML();
        User standardUser = userCreation.getRunAsUsers().get('Standard')[0];
        System.runAs(standardUser) {
            TestUtilities.assignLicense(String.valueOf(standardUser.Username), true, true, true, true, true);
            ITestDefaults orgCredentialDefaults = new CopadoSetupTestDefaults.OrgCredentialDefaults()
                .setFieldDefaults()
                .setFieldValue(Org__c.SObjectType, Org__c.Name, 'DevHub')
                .setFieldValue(Org__c.SObjectType, Org__c.Username__c, 'myDevhub@example.com')
                .setFieldValue(Org__c.SObjectType, Org__c.is_Developer_Hub_Org__c, true)
                .setFieldValue(Org__c.SObjectType, Org__c.Validated_Date__c, Datetime.now())
                .setFieldValue(Org__c.SObjectType, Org__c.SFDC_Org_ID__c, DEV_HUB_ORG_ID + '_' + UserInfo.getUserId())
                .setDataSize(Org__c.SObjectType, 1)
                .generateDefaults()
                .executeDML();
            // This update creates Environment related to the org credential.
            update (List<Org__c>) orgCredentialDefaults.getTestData(Org__c.SObjectType);
        }
    }
    /**
     * Having a scratch org created out of Copado, cli command (copado:auth:grant) is executed to create the org credential
     */
    @IsTest
    static void testCreateExternalScratchOrgInCopado() {
        User runAsUser = getRunasUserAndAssignLicense();
        System.runAs(runAsUser) {
            AuthGrantService authGrantInstance = new AuthGrantService();
            authGrantInstance.getInstance();

            AuthGrantService.AuthGrantWrapper authGrant = getAuthGrantInfo();

            Test.startTest();
            String response = executeApiCall(authGrant);
            AuthGrantService.AuthGrantResultWrapper responseInfo = (AuthGrantService.AuthGrantResultWrapper) JSON.deserialize(
                response,
                AuthGrantService.AuthGrantResultWrapper.class
            );
            Test.stopTest();
            System.assertEquals(CliSfDataWrapper.StatusResult.OK.name(), responseInfo.status, 'Status must be OK');
            System.assertEquals('ScratchOrg Credential created', responseInfo.message, 'Message does not match');

            List<Org__c> assertDevHub = [
                SELECT Id
                FROM Org__c
                WHERE Username__c = 'myDevhub@example.com' AND Environment__r.Org_ID__c = :DEV_HUB_ORG_ID AND is_Developer_Hub_Org__c = TRUE
                LIMIT 1
            ];
            List<Environment__c> assertEnvironment = [SELECT Id, Name, Type__c, Org_ID__c FROM Environment__c WHERE Org_ID__c = :SCRATCH_ORG_ID];
            List<Org__c> assertScratchOrg = [
                SELECT Id, Developer_Hub_Org__c, SFDC_Org_ID__c, Org_Type__c, Environment__c
                FROM Org__c
                WHERE UserName__c = 'test-acqffozptfsc@example.com'
            ];
            List<Attachment> assertAttachment = [SELECT Id, Name, ParentId FROM Attachment WHERE ParentId = :assertScratchOrg[0].Id];
            System.assertEquals(1, assertAttachment.size(), 'Should be an attachment');
            System.assertEquals(assertEnvironment[0].Id, responseInfo.environmentId, 'Environemt Id is not correct');
            System.assertEquals(assertScratchOrg[0].Id, responseInfo.orgCredentialId, 'Org Credential Id is not correct');

            System.assertEquals(1, assertEnvironment.size(), 'Environment assert list must have only 1 record or at least 1 record');
            System.assertEquals('My new Environment', assertEnvironment[0].Name, 'Environment Name is not correct');
            System.assertEquals(1, assertScratchOrg.size(), 'ScratchOrg assert list must have only 1 record or at least 1 record');
            System.assertEquals(assertDevHub[0].Id, assertScratchOrg[0].Developer_Hub_Org__c, 'DevHub is not the correct one');
            System.assertEquals(SCRATCH_ORG_ID + '_' + runAsUser.Id, assertScratchOrg[0].SFDC_Org_ID__c, 'SFDC unique id is not the correct');
            System.assertEquals(assertEnvironment[0].Id, assertScratchOrg[0].Environment__c, 'Environment is not the correct one');
        }
    }

    @IsTest
    static void testCreateExternalScratchOrgInCopadoWithInvalidScratchOrgExpirationDate() {
        // Setup
        User runAsUser = getRunasUserAndAssignLicense();
        System.runAs(runAsUser) {
            AuthGrantService authGrantInstance = new AuthGrantService();
            authGrantInstance.getInstance();

            AuthGrantService.AuthGrantWrapper authGrant = getAuthGrantInfo();
            authGrant.scratchOrgExpirationDate = 'undefined';

            // Exercise
            Test.startTest();
            String response = executeApiCall(authGrant);
            AuthGrantService.AuthGrantResultWrapper responseInfo = (AuthGrantService.AuthGrantResultWrapper) JSON.deserialize(
                response,
                AuthGrantService.AuthGrantResultWrapper.class
            );
            Test.stopTest();

            // Verify
            System.assertEquals(CliSfDataWrapper.StatusResult.OK.name(), responseInfo.status, 'Status must be OK');
            System.assertEquals('ScratchOrg Credential created', responseInfo.message, 'Message does not match');

            Org__c newScratchOrg = [
                SELECT Id, Developer_Hub_Org__c, SFDC_Org_ID__c, Org_Type__c, Environment__c, Scratch_Org_Expiration_Date__c
                FROM Org__c
                WHERE UserName__c = 'test-acqffozptfsc@example.com'
            ];
            System.assertEquals(responseInfo.orgCredentialId, newScratchOrg.Id, 'Org Credential Id is not correct');
            System.assertEquals(SCRATCH_ORG_ID + '_' + runAsUser.Id, newScratchOrg.SFDC_Org_ID__c, 'SFDC unique id is not the correct');
            System.assertEquals(null, newScratchOrg.Scratch_Org_Expiration_Date__c, 'Expiration Date should be null');
        }
    }

    /**
     * Check if a Scratchorg is created twice
     */
    @IsTest
    static void testCreateExternalScratchOrgInCopadoTwice() {
        System.runAs(getRunasUserAndAssignLicense()) {
            AuthGrantService authGrantInstance = new AuthGrantService();
            authGrantInstance.getInstance();

            AuthGrantService.AuthGrantWrapper authGrant = getAuthGrantInfo();

            executeApiCall(authGrant);

            Test.startTest();
            String response = executeApiCall(authGrant);
            CliSfDataWrapper responseInfo = (CliSfDataWrapper) JSON.deserialize(response, CliSfDataWrapper.class);
            System.assertEquals(CliSfDataWrapper.StatusResult.ERROR.name(), responseInfo.status, 'Status must be ERROR');
            System.assertEquals('This ScratchOrg already Exists', responseInfo.message, 'Message does not match');

            Test.stopTest();
        }
    }

    /**
     * Having a scratch org created out of Copado, cli command (copado:auth:grant) is executed to create the org credential
     * But Dev Hub does not exists in Copado App
     */
    @IsTest
    static void testCreateExternalScratchOrgInCopadoNoDevHub() {
        System.runAs(getRunasUserAndAssignLicense()) {
            AuthGrantService authGrantInstance = new AuthGrantService();
            authGrantInstance.getInstance();

            AuthGrantService.AuthGrantWrapper authGrant = getAuthGrantInfo();
            authGrant.devHubOrgId = '00D1i0000000000000';

            Test.startTest();
            String response = executeApiCall(authGrant);
            CliSfDataWrapper responseInfo = (CliSfDataWrapper) JSON.deserialize(response, CliSfDataWrapper.class);
            System.assertEquals(CliSfDataWrapper.StatusResult.ERROR.name(), responseInfo.status, 'Status must be ERROR');
            System.assertEquals('Dev Hub does not exist', responseInfo.message, 'Message does not match');

            Test.stopTest();
        }
    }

    /**
     * Having a scratch org created out of Copado, cli command (copado:auth:grant) is executed to create the org credential
     * But Auth Info is sent Blank.
     */
    @IsTest
    static void testCreateExternalScratchOrgInCopadoNoAuthInfo() {
        System.runAs(getRunasUserAndAssignLicense()) {
            AuthGrantService authGrantInstance = new AuthGrantService();
            authGrantInstance.getInstance();

            AuthGrantService.AuthGrantWrapper authGrant = getAuthGrantInfo();
            authGrant.authInfo = '';

            Test.startTest();
            String response = executeApiCall(authGrant);
            CliSfDataWrapper responseInfo = (CliSfDataWrapper) JSON.deserialize(response, CliSfDataWrapper.class);
            System.assertEquals(CliSfDataWrapper.StatusResult.ERROR.name(), responseInfo.status, 'Status must be ERROR');
            System.assertEquals('There is no auth info for this ScratchOrg', responseInfo.message, 'Message does not match');

            Test.stopTest();
        }
    }

    private static AuthGrantService.AuthGrantWrapper getAuthGrantInfo() {
        AuthGrantService.AuthGrantWrapper authGrant = new AuthGrantService.AuthGrantWrapper();
        authGrant.scratchOrgUserName = 'test-acqffozptfsc@example.com';
        authGrant.environmentName = 'My new Environment';
        authGrant.devHubUserName = 'myDevhub@example.com';
        authGrant.devHubOrgId = DEV_HUB_ORG_ID;
        authGrant.scratchOrgId = SCRATCH_ORG_ID;
        authGrant.scratchOrgExpirationDate = String.valueOf(Date.today() + 1);
        authGrant.authInfo = 'force://PlatformCLI::5Aep861DjCadqH163d89Tu7VXVYUPrSSpMuHkLHsvu1qb3IVRE.WmowW_8usKYXdjWJy1N7WF5J7YC0wdR2kS6a@customer-nosoftware-3294-dev-ed.cs82.my.salesforce.com/';
        return authGrant;
    }

    private static String executeApiCall(AuthGrantService.AuthGrantWrapper authGrant) {
        MockHttpResponseGenerator mockResponse = new MockHttpResponseGenerator(
            200,
            'Complete',
            '{"copadoJobId":"1458f75f-1c4f-4116-a92f-607fb3fb4bbc","ok":"Job has started!","status":"initializing"}',
            null
        );
        Test.setMock(HttpCalloutMock.class, mockResponse);

        CliProxy.CLIWrapper reqBody = new CliProxy.CLIWrapper();
        reqBody.mainService = 'auth';
        reqBody.subService = 'grant';
        reqBody.body = JSON.serialize(authGrant);
        RestResponse res = new RestResponse();
        RestContext.request = Test_CliProxy.commonRequest(JSON.serialize(reqBody));
        RestContext.response = res;
        return CliProxy.doPost();
    }

    private static User getRunasUserAndAssignLicense() {
        User standardUser = [SELECT Id, Username FROM User WHERE Username = 'test_user@myorg.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(standardUser.Username), true, true, false, false, false);
        return standardUser;
    }
}