@isTest
private with sharing class CopadoCredentialValidatorCtrlTest {
    @TestSetup
    static void setupData() {
        List<User> userList = TestDataFactory.createUsers();
        TestUtilities.enableLicenses(2, 2, 2, 2, 2, 2);
        FeatureManagement.setPackageIntegerValue('ADD_Licenses_Enabled', 2);
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Copado_User'];
        insert new PermissionSetAssignment(AssigneeId = userList[0].Id, PermissionSetId = ps.Id);
    }
    
    @IsTest
    static void validateCredentialRecordNoAuthentication() {
        User sysUser = assignLicense();
        
        System.runAs(sysUser) {
            //setup
            // Org Credential creation
            Org__c credential = TestDataFactory.createOrgCredentials('Credential', 'Production/Developer');
            insert credential;
            //execute
            Test.startTest();
            List<CopadoCredentialValidatorCtrl.ValidationResult> validationResults = CopadoCredentialValidatorCtrl.validate(
                credential.Id
            );
            Test.stopTest();
            //verify
            System.assertEquals(1, validationResults.size(), 'There is only one message');
            System.assertEquals(Label.ADD_AUTHENTICATION, validationResults[0].message, 'There is only one info message');
        }
    }
    
    @IsTest
    static void validateCredentialRecordSuccess() {
        User sysUser = assignLicense();
        
        System.runAs(sysUser) {
            //setup
            //Environment creation
            List<Environment__c> environments = TestDataFactory.createEnvironments(3);
            
            // Org Credential creation
            Org__c credential = TestDataFactory.createOrgCredentials('Credential', 'Production/Developer');
            credential.Oauth_Signature__c = 'test';
            credential.Environment__c = environments[0].Id;
            insert credential;
            //execute
            Test.startTest();
            String calloutResult = '{"organizationId":"00D0Y0000035k50UAA","OrganizationName":"Copado DEV-09","ProfileId":"00e0Y000001sonWQAQ","UserTimeZone":"Europe/Paris","Username":"ferhat@copado.com.dev-09","UserId":"0050Y000003PDuuQAG","OrganizationId":"00D0Y0000035k50UAA","UserEmail":"ferhat@copado.com","UserFullName":"Ferhat Özsavran"}';
            MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200, 'Complete', calloutResult, null);
            Test.setMock(HttpCalloutMock.class, fakeResponse);
            List<CopadoCredentialValidatorCtrl.ValidationResult> validationResults = CopadoCredentialValidatorCtrl.validate(
                credential.Id
            );
            Test.stopTest();
            //verify
            System.assertEquals(1, validationResults.size(), 'There is only one message');
            System.assertEquals(Label.OK_CREDENTIALS, validationResults[0].message, 'There is only one success message');
        }
    }
    
    @IsTest
    static void validateCredentialRecordWrongCredential() {
        User sysUser = assignLicense();
        
        System.runAs(sysUser) {
            //setup
            //Environment creation
            List<Environment__c> environments = TestDataFactory.createEnvironments(3);
            
            // Org Credential creation
            Org__c credential = TestDataFactory.createOrgCredentials('Credential', 'Production/Developer');
            credential.Oauth_Signature__c = 'test';
            credential.Environment__c = environments[0].Id;
            insert credential;
            
            // execute
            Test.startTest();
            String calloutResult = '{"OrganizationName":"Copado DEV-09","ProfileId":"00e0Y000001sonWQAQ","UserTimeZone":"Europe/Paris","Username":"ferhat@copado.com.dev-09","UserId":"0050Y000003PDuuQAG","OrganizationId":"00D0Y0000035k50UAA","UserEmail":"ferhat@copado.com","UserFullName":"Ferhat Özsavran"}';
            MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200, 'Complete', calloutResult, null);
            Test.setMock(HttpCalloutMock.class, fakeResponse);
            List<CopadoCredentialValidatorCtrl.ValidationResult> validationResults = CopadoCredentialValidatorCtrl.validate(
                credential.Id
            );
            Test.stopTest();
            
            //verify
            System.assertEquals(1, validationResults.size(), 'There is only one message');
            System.assertEquals(Label.WRONG_CREDENTIALS, validationResults[0].message, 'There is only one error message');
        }
    }
    
    @IsTest
    static void validateCredentialForNonSalesforceEnvironment() {
        
        User sysUser = assignLicense();
        
        System.runAs(sysUser) {
            //setup
            //Environment creation
            List<Environment__c> environments = TestDataFactory.createEnvironments(3);
            for (Environment__c environmentRecord : environments) {
                environmentRecord.Platform__c = 'Other';
            }
            update environments;
            
            // Org Credential creation
            List<Org__c> credentials = TestDataFactory.createOrgCredentials(3, sysUser.Username, environments);
            
            //execute
            Test.startTest();
            List<CopadoCredentialValidatorCtrl.ValidationResult> validationResults = CopadoCredentialValidatorCtrl.validate(
                credentials[0].Id
            );
            Test.stopTest();
            
            //verify
            System.assertEquals(1, validationResults.size(), 'There is only one message');
            System.assertEquals(Label.Non_Salesforce_Credential, validationResults[0].message, 'There is only one info message');
            
        }
    }
    
    @isTest
    private static void handleExceptions() {
        User sysUser = assignLicense();
        System.runAs(sysUser) {
            //Execute + Verify
            Test.startTest();
            Exception handledException;
            try{
                CopadoCredentialValidatorCtrl.validate('test');
            }catch(exception e){
                handledException = e;
            }
            
            Test.stopTest();
            System.assert(handledException != null, 'This is not a valid org id');
        }
    }
    
    
    private static User assignLicense(){
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true, true);
        return sysUser;
    }
}