@IsTest
public with sharing class CustomConnectedAppTriggerHelper_TEST {
    @TestSetup
    static void setupData() {
        List<User> userList = TestDataFactory.createUsers();
        TestUtilities.enableLicenses(2, 2, 2, 2, 2, 2);
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Copado_User'];
        insert new PermissionSetAssignment(AssigneeId = userList[0].Id, PermissionSetId = ps.Id);
    }

    @IsTest
    static void createCustomConnectedAppEntry() {
        MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200, 'Complete', '', null);
        Test.setMock(HttpCalloutMock.class, fakeResponse);
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true, true);

        Custom_Connected_App_Info__c ccai;
        Test.startTest();
        System.runAs(sysUser) {
            ccai = new Custom_Connected_App_Info__c(
                Callback_URL__c = 'https://dev-app-api.copado.com/forcedotcomoauth2/callback',
                Name = 'Test_Connected_App',
                ClientId__c = 'TestClientId',
                ClientSecret__c = 'TestClientSecret',
                Connected_App_Id__c = '0H41n0000009TqZCAU'
            );
            insert ccai;
        }
        Test.stopTest();
        ccai = [SELECT Id, ClientId__c, ClientSecret__c FROM Custom_Connected_App_Info__c WHERE Name = 'Test_Connected_App'];
        System.assertEquals('***************', ccai.ClientId__c, 'Check CustomConnectedAppTriggerHelper!');
        System.assertEquals('***************', ccai.ClientSecret__c, 'Check CustomConnectedAppTriggerHelper!');
    }
}