@IsTest
private with sharing class CredentialsHandlersTest {
    @TestSetup
    static void setupData() {
        List<User> userList = TestDataFactory.createUsers();
        TestUtilities.enableLicenses(2, 2, 2, 2, 2, 2);
        FeatureManagement.setPackageIntegerValue('ADD_Licenses_Enabled', 2);
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Copado_User'];
        insert new PermissionSetAssignment(AssigneeId = userList[0].Id, PermissionSetId = ps.Id);
    }

    @IsTest
    static void doAuthenticateForNewProductionCredential() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true, true);

        System.runAs(sysUser) {
            // Org Credential creation
            Org__c credential = TestDataFactory.createOrgCredentials('Credential', 'Production/Developer');
            insert credential;

            Test.startTest();
            String oauthURL = CredentialRedirectionHandler.createDoOauthAndReturnApiURL(credential.Id);
            System.assertNotEquals('', oauthURL, 'URL is generated successfully and redirected');
            Test.stopTest();
        }
    }

    @IsTest
    static void doAuthenticateForNewSandboxCredential() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true, true);

        System.runAs(sysUser) {
            // Org Credential creation
            Org__c credential = TestDataFactory.createOrgCredentials('Credential', 'Sandbox');
            insert credential;

            Test.startTest();
            String oauthURL = CredentialRedirectionHandler.createDoOauthAndReturnApiURL(credential.Id);
            System.assertNotEquals('', oauthURL, 'URL is generated successfully and redirected');
            Test.stopTest();
        }
    }

    @IsTest
    static void doAuthenticateForNewCustomDomainCredential() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true, true);

        System.runAs(sysUser) {
            // Org Credential creation
            Org__c credential = TestDataFactory.createOrgCredentials('Credential', 'Custom Domain');
            credential.Custom_Domain__c = 'Test';
            insert credential;

            Test.startTest();
            String oauthURL = CredentialRedirectionHandler.createDoOauthAndReturnApiURL(credential.Id);
            System.assertNotEquals('', oauthURL, 'URL is generated successfully and redirected');
            Test.stopTest();
        }
    }

    @IsTest
    static void openAnyCredentialRecord() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true, true);

        System.runAs(sysUser) {
            //Environment creation
            List<Environment__c> environments = TestDataFactory.createEnvironments(3);

            // Org Credential creation
            List<Org__c> credentials = TestDataFactory.createOrgCredentials(3, sysUser.Username, environments);

            Test.startTest();
            String actualPageReferenceURL = CredentialRedirectionHandler.createOpenOrgURL(credentials[0].Id);

            PageReference expectedPageReference = Page.ScratchOrgOpen;
            expectedPageReference.getParameters().put('id', credentials[0].Id);
            expectedPageReference.setRedirect(true);
            System.assertEquals(expectedPageReference.getURL(), actualPageReferenceURL, 'URL is generated successfully and redirected');
            Test.stopTest();
        }
    }

    @IsTest
    static void openDXOperationForCredentialRecord() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true, true);

        System.runAs(sysUser) {
            //Environment creation
            List<Environment__c> environments = TestDataFactory.createEnvironments(3);

            // Org Credential creation
            List<Org__c> credentials = TestDataFactory.createOrgCredentials(3, sysUser.Username, environments);

            Test.startTest();
            String actualPageReferenceURL = CredentialRedirectionHandler.createDXOperationPageURL(credentials[0].Id);

            PageReference expectedPageReference = Page.DXOperation;
            expectedPageReference.getParameters().put('id', credentials[0].Id);
            expectedPageReference.setRedirect(true);
            System.assertEquals(expectedPageReference.getURL(), actualPageReferenceURL, 'URL is generated successfully and redirected');
            Test.stopTest();
        }
    }

    @IsTest
    static void validateCredentialRecordNoAuthentication() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true, true);

        System.runAs(sysUser) {
            // Org Credential creation
            Org__c credential = TestDataFactory.createOrgCredentials('Credential', 'Production/Developer');
            insert credential;

            Test.startTest();
            List<CredentialRecordPageHandler.ValidationResult> validationResults = CredentialRecordPageHandler.validateOrgAndReturnResultWrapper(
                credential.Id
            );
            System.assertEquals(1, validationResults.size(), 'There is only one message');
            System.assertEquals('action:info', validationResults[0].iconName, 'Info icon will be used');
            System.assertEquals(Label.AUTHENTICATION, validationResults[0].message, 'There is only one info message');
            Test.stopTest();
        }
    }

    @IsTest
    static void validateCredentialRecordSuccess() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true, true);

        System.runAs(sysUser) {
            //Environment creation
            List<Environment__c> environments = TestDataFactory.createEnvironments(3);

            // Org Credential creation
            Org__c credential = TestDataFactory.createOrgCredentials('Credential', 'Production/Developer');
            credential.Oauth_Signature__c = 'test';
            credential.Environment__c = environments[0].Id;
            insert credential;

            Test.startTest();
            String calloutResult = '{"organizationId":"00D0Y0000035k50UAA","OrganizationName":"Copado DEV-09","ProfileId":"00e0Y000001sonWQAQ","UserTimeZone":"Europe/Paris","Username":"ferhat@copado.com.dev-09","UserId":"0050Y000003PDuuQAG","OrganizationId":"00D0Y0000035k50UAA","UserEmail":"ferhat@copado.com","UserFullName":"Ferhat Özsavran"}';
            MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200, 'Complete', calloutResult, null);
            Test.setMock(HttpCalloutMock.class, fakeResponse);
            List<CredentialRecordPageHandler.ValidationResult> validationResults = CredentialRecordPageHandler.validateOrgAndReturnResultWrapper(
                credential.Id
            );
            System.assertEquals(1, validationResults.size(), 'There is only one message');
            System.assertEquals('action:approval', validationResults[0].iconName, 'Success icon will be used');
            System.assertEquals(Label.OK_CREDENTIALS, validationResults[0].message, 'There is only one success message');
            Test.stopTest();
        }
    }

    @IsTest
    static void validateCredentialRecordWrongCredential() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true, true);

        System.runAs(sysUser) {
            //Environment creation
            List<Environment__c> environments = TestDataFactory.createEnvironments(3);

            // Org Credential creation
            Org__c credential = TestDataFactory.createOrgCredentials('Credential', 'Production/Developer');
            credential.Oauth_Signature__c = 'test';
            credential.Environment__c = environments[0].Id;
            insert credential;

            Test.startTest();
            String calloutResult = '{"OrganizationName":"Copado DEV-09","ProfileId":"00e0Y000001sonWQAQ","UserTimeZone":"Europe/Paris","Username":"ferhat@copado.com.dev-09","UserId":"0050Y000003PDuuQAG","OrganizationId":"00D0Y0000035k50UAA","UserEmail":"ferhat@copado.com","UserFullName":"Ferhat Özsavran"}';
            MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200, 'Complete', calloutResult, null);
            Test.setMock(HttpCalloutMock.class, fakeResponse);
            List<CredentialRecordPageHandler.ValidationResult> validationResults = CredentialRecordPageHandler.validateOrgAndReturnResultWrapper(
                credential.Id
            );
            System.assertEquals(1, validationResults.size(), 'There is only one message');
            System.assertEquals('action:close', validationResults[0].iconName, 'Error icon will be used');
            System.assertEquals(Label.WRONG_CREDENTIALS, validationResults[0].message, 'There is only one error message');
            Test.stopTest();
        }
    }

    @IsTest
    static void validateCredentialForNonSalesforceEnvironment() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true, true);

        System.runAs(sysUser) {
            //Environment creation
            List<Environment__c> environments = TestDataFactory.createEnvironments(3);
            for (Environment__c environmentRecord : environments) {
                environmentRecord.Platform__c = 'Other';
            }
            update environments;

            // Org Credential creation
            List<Org__c> credentials = TestDataFactory.createOrgCredentials(3, sysUser.Username, environments);

            Test.startTest();
            List<CredentialRecordPageHandler.ValidationResult> validationResults = CredentialRecordPageHandler.validateOrgAndReturnResultWrapper(
                credentials[0].Id
            );
            System.assertEquals(1, validationResults.size(), 'There is only one message');
            System.assertEquals('action:info', validationResults[0].iconName, 'Info icon will be used');
            System.assertEquals(Label.Non_Salesforce_Credential, validationResults[0].message, 'There is only one info message');
            Test.stopTest();
        }
    }

    @IsTest
    static void getMetadataTypesForCredential() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true, true);

        System.runAs(sysUser) {
            //Environment creation
            List<Environment__c> environments = TestDataFactory.createEnvironments(3);

            // Org Credential creation
            List<Org__c> credentials = TestDataFactory.createOrgCredentials(3, sysUser.Username, environments);

            Test.startTest();
            String calloutResult = '["InstalledPackage","CustomLabels","CustomLabel","StaticResource","Scontrol","Certificate","LightningMessageChannel","LightningComponentBundle","AuraDefinitionBundle","ApexComponent","ApexPage","Queue","InboundNetworkConnection","OutboundNetworkConnection"]';
            MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200, 'Complete', calloutResult, null);
            Test.setMock(HttpCalloutMock.class, fakeResponse);

            List<String> metadataTypes = CredentialRecordPageHandler.getMetadataTypesForGivenCredentialId(credentials[0].Id);
            System.assertEquals(14, metadataTypes.size(), 'There are 14 different metadata types');
            Test.stopTest();
        }
    }

    @IsTest
    static void populateMetadataUrlForGrid() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true, true);

        System.runAs(sysUser) {
            //Environment creation
            List<Environment__c> environments = TestDataFactory.createEnvironments(3);

            // Org Credential creation
            Org__c credential = TestDataFactory.createOrgCredentials('Credential', 'Production/Developer');
            credential.Oauth_Signature__c = 'test';
            credential.Environment__c = environments[0].Id;
            insert credential;

            Test.startTest();
            PageReference pReference = Page.viewOrg;
            Test.setCurrentPage(pReference);
            ApexPages.StandardController sc = new ApexPages.StandardController(credential);
            EditOrg controller = new EditOrg(sc);
            System.assertNotEquals('', controller.metadata_url, 'Metadata url is populated');
            Test.stopTest();
        }
    }

    @IsTest
    static void apexTestCallForCredential() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true, true);

        System.runAs(sysUser) {
            //Environment creation
            List<Environment__c> environments = TestDataFactory.createEnvironments(3);

            // Org Credential creation
            Org__c credential = TestDataFactory.createOrgCredentials('Credential', 'Production/Developer');
            credential.Oauth_Signature__c = 'test';
            credential.Environment__c = environments[0].Id;
            insert credential;

            Test.startTest();
            String calloutResult = '{"organizationId":"00D0Y0000035k50UAA","OrganizationName":"Copado DEV-09","ProfileId":"00e0Y000001sonWQAQ","UserTimeZone":"Europe/Paris","Username":"ferhat@copado.com.dev-09","UserId":"0050Y000003PDuuQAG","OrganizationId":"00D0Y0000035k50UAA","UserEmail":"ferhat@copado.com","UserFullName":"Ferhat Özsavran"}';
            MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200, 'Complete', calloutResult, null);
            Test.setMock(HttpCalloutMock.class, fakeResponse);

            List<InvokeApexTestCallForCredential.InvocableVariables> variables = new List<InvokeApexTestCallForCredential.InvocableVariables>();
            InvokeApexTestCallForCredential.InvocableVariables firstSet = new InvokeApexTestCallForCredential.InvocableVariables();
            firstSet.credentialId = credential.Id;
            variables.add(firstSet);
            InvokeApexTestCallForCredential.execute(variables);
            System.assertNotEquals(null, credential.Id, 'Credential is not null');
            Test.stopTest();
        }
    }

    @IsTest
    static void staticCodeAnalysisForCredential() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true, true);

        System.runAs(sysUser) {
            //Environment creation
            List<Environment__c> environments = TestDataFactory.createEnvironments(3);

            // Org Credential creation
            Org__c credential = TestDataFactory.createOrgCredentials('Credential', 'Production/Developer');
            credential.Oauth_Signature__c = 'test';
            credential.Environment__c = environments[0].Id;
            insert credential;

            Test.startTest();
            String calloutResult = '{"organizationId":"00D0Y0000035k50UAA","OrganizationName":"Copado DEV-09","ProfileId":"00e0Y000001sonWQAQ","UserTimeZone":"Europe/Paris","Username":"ferhat@copado.com.dev-09","UserId":"0050Y000003PDuuQAG","OrganizationId":"00D0Y0000035k50UAA","UserEmail":"ferhat@copado.com","UserFullName":"Ferhat Özsavran"}';
            MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200, 'Complete', calloutResult, null);
            Test.setMock(HttpCalloutMock.class, fakeResponse);

            List<InvokeStaticCodeAnalysisForCredential.InvocableVariables> variables = new List<InvokeStaticCodeAnalysisForCredential.InvocableVariables>();
            InvokeStaticCodeAnalysisForCredential.InvocableVariables firstSet = new InvokeStaticCodeAnalysisForCredential.InvocableVariables();
            firstSet.credentialId = credential.Id;
            variables.add(firstSet);
            try {
                InvokeStaticCodeAnalysisForCredential.execute(variables);
            } catch (Exception e) {
                System.assertEquals(e.getMessage(), Label.SCA_SETTINGS_NOT_FOUND, 'Setting is not configured');
            }
            System.assertNotEquals(null, credential.Id, 'Credential is not null');
            Test.stopTest();
        }
    }

    @IsTest
    static void complianceScanNotFoundForCredential() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true, true);

        System.runAs(sysUser) {
            //Environment creation
            List<Environment__c> environments = TestDataFactory.createEnvironments(3);

            // Org Credential creation
            Org__c credential = TestDataFactory.createOrgCredentials('Credential', 'Production/Developer');
            credential.Oauth_Signature__c = 'test';
            credential.Environment__c = environments[0].Id;
            insert credential;

            Test.startTest();
            String calloutResult = '{"organizationId":"00D0Y0000035k50UAA","OrganizationName":"Copado DEV-09","ProfileId":"00e0Y000001sonWQAQ","UserTimeZone":"Europe/Paris","Username":"ferhat@copado.com.dev-09","UserId":"0050Y000003PDuuQAG","OrganizationId":"00D0Y0000035k50UAA","UserEmail":"ferhat@copado.com","UserFullName":"Ferhat Özsavran"}';
            MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200, 'Complete', calloutResult, null);
            Test.setMock(HttpCalloutMock.class, fakeResponse);

            List<InvokeComplianceScanForCredential.InvocableVariables> variables = new List<InvokeComplianceScanForCredential.InvocableVariables>();
            InvokeComplianceScanForCredential.InvocableVariables firstSet = new InvokeComplianceScanForCredential.InvocableVariables();
            firstSet.credentialId = credential.Id;
            variables.add(firstSet);
            try {
                InvokeComplianceScanForCredential.execute(variables);
            } catch (Exception e) {
                System.assertEquals(e.getMessage(), Label.COMPLIANCE_SETTING_NOT_FOUND, 'Setting is not configured');
            }
            Test.stopTest();
        }
    }

    @IsTest
    static void complianceScanForCredential() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true, true);

        System.runAs(sysUser) {
            Compliance_Rule_Group__c complianceSetting = new Compliance_Rule_Group__c();
            insert complianceSetting;

            //Environment creation
            List<Environment__c> environments = TestDataFactory.createEnvironments(3);
            for (Environment__c environmentRecord : environments) {
                environmentRecord.Compliance_Rule_Group__c = complianceSetting.Id;
            }
            update environments;

            // Org Credential creation
            Org__c credential = TestDataFactory.createOrgCredentials('Credential', 'Production/Developer');
            credential.Oauth_Signature__c = 'test';
            credential.Environment__c = environments[0].Id;
            insert credential;

            Test.startTest();
            String calloutResult = '{"organizationId":"00D0Y0000035k50UAA","OrganizationName":"Copado DEV-09","ProfileId":"00e0Y000001sonWQAQ","UserTimeZone":"Europe/Paris","Username":"ferhat@copado.com.dev-09","UserId":"0050Y000003PDuuQAG","OrganizationId":"00D0Y0000035k50UAA","UserEmail":"ferhat@copado.com","UserFullName":"Ferhat Özsavran"}';
            MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200, 'Complete', calloutResult, null);
            Test.setMock(HttpCalloutMock.class, fakeResponse);

            List<InvokeComplianceScanForCredential.InvocableVariables> variables = new List<InvokeComplianceScanForCredential.InvocableVariables>();
            InvokeComplianceScanForCredential.InvocableVariables firstSet = new InvokeComplianceScanForCredential.InvocableVariables();
            firstSet.credentialId = credential.Id;
            variables.add(firstSet);
            InvokeComplianceScanForCredential.execute(variables);
            System.assertNotEquals(null, credential.Id, 'Record is not null');
            Test.stopTest();
        }
    }
}