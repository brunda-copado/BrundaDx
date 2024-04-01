@isTest
private class GlobalAPI_Test {
    @testSetup
    static void setupData() {
        FeatureManagement.setPackageIntegerValue('EE_Licenses_Enabled', 1);
        FeatureManagement.setPackageIntegerValue('CCM_Licenses_Enabled', 1);
        FeatureManagement.setPackageIntegerValue('CST_Licenses_Enabled', 1);
        FeatureManagement.setPackageIntegerValue('CAD_Licenses_Enabled', 1);
        FeatureManagement.setPackageIntegerValue('CCH_Licenses_Enabled', 1);
    }
    @isTest
    static void testMethodOne() {
        upsert TestUtilities.getTestSettings();
        Test.startTest();
        User newUser = new User(
            FirstName = 'Test',
            LastName = 'Copado',
            Email = 'copa@copado.com',
            Username = 'copa@copado.com.gaTest',
            Alias = 'Alias',
            CommunityNickname = 'copa',
            timezonesidkey = 'America/Los_Angeles',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = UserInfo.getProfileId(),
            LanguageLocaleKey = 'en_US'
        );
        insert newUser;
        GlobalAPI.UserLicense myLicense = new GlobalAPI.UserLicense(UserInfo.getUserId(), true, true, true, true, true);
        GlobalAPI.UserLicense myLicenseAlt = new GlobalAPI.UserLicense();
        myLicenseAlt.isCADenabled = true;
        myLicenseAlt.isCCHenabled = true;
        myLicenseAlt.isCCMenabled = true;
        myLicenseAlt.isCopadoEnabled = true;
        myLicenseAlt.isCSTenabled = true;
        myLicenseAlt.userId = newUser.Id;

        GlobalAPI globalAPIInstance = new GlobalAPI();
        globalAPIInstance.getLicenseInformation();
        List<GlobalAPI.UserLicense> licenses = (List<GlobalAPI.UserLicense>) globalAPIInstance.listCopadoLicenses();
        System.assertEquals(0, licenses.size());
        String res = globalAPIInstance.upsertCopadoLicense(UserInfo.getUserId(), myLicense);
        System.assertEquals('INSERTED', res);
        String res2 = globalAPIInstance.upsertCopadoLicense(UserInfo.getUserId(), myLicense);
        System.assertEquals('UPDATED', res2);

        new GlobalAPI.LicenseOperationResult(false, 'unknown Exception');

        globalAPIInstance.listCopadoLicenses();
        globalAPIInstance.deleteCopadoLicense(UserInfo.getUserId());
        globalAPIInstance.upsertCopadoLicense(myLicenseAlt);
        globalAPIInstance.upsertCopadoLicense(myLicenseAlt);
        Test.stopTest();
    }

    @isTest
    static void testSensitiveInfoUpsert() {
        TestUtilities.enableLicenses(2, 2, 2, 2, 2, 30);
        ITestDefaults userCreation = new CopadoSetupTestDefaults.UserDefaults().createRunAsUsers().executeDML();

        User adminUser = userCreation.getRunAsUsers().get('Admin')[0];
        User standardUser = userCreation.getRunAsUsers().get('Standard')[0];
        System.runAs(adminUser) {
            TestUtilities.assignLicense(String.valueOf(adminUser.Username), true, true, true, true, true);
            ITestDefaults environmentDefaults = new CopadoSetupTestDefaults.EnvironmentDefaults()
                .setFieldDefaults()
                .setFieldValue(Environment__c.SObjectType, Environment__c.Name, 'Production')
                .setDataSize(Environment__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CopadoSetupTestDefaults.EnvironmentDefaults.class)
                .setFieldValue(Environment__c.SObjectType, Environment__c.Name, 'Staging')
                .setDataSize(Environment__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CopadoSetupTestDefaults.EnvironmentDefaults.class)
                .setFieldValue(Environment__c.SObjectType, Environment__c.Name, 'Dev1')
                .setFieldValue(Environment__c.SObjectType, Environment__c.OwnerId, standardUser.Id)
                .setDataSize(Environment__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CopadoSetupTestDefaults.EnvironmentDefaults.class)
                .setFieldValue(Environment__c.SObjectType, Environment__c.Name, 'Dev2')
                .setFieldValue(Environment__c.SObjectType, Environment__c.OwnerId, standardUser.Id)
                .setDataSize(Environment__c.SObjectType, 1)
                .generateDefaults()
                .executeDML();

            Environment__c productionEnvironment = new Environment__c();
            Environment__c stagingEnvironment = new Environment__c();
            Environment__c dev1Environment = new Environment__c();
            Environment__c dev2Environment = new Environment__c();

            for (Environment__c env : (List<Environment__c>) environmentDefaults.getTestData(Environment__c.SObjectType)) {
                switch on env.Name {
                    when 'Production 0' {
                        productionEnvironment = env;
                    }
                    when 'Staging 0' {
                        stagingEnvironment = env;
                    }
                    when 'Dev1 0' {
                        dev1Environment = env;
                    }
                    when 'Dev2 0' {
                        dev2Environment = env;
                    }
                }
            }

            // This data depends on certain specific records. That's why is splitted.
            ITestDefaults orgCredentialDefaults = new CopadoSetupTestDefaults.OrgCredentialDefaults()
                .setFieldDefaults()
                .setFieldValue(Org__c.SObjectType, Org__c.Name, 'Production')
                .setFieldValue(Org__c.SObjectType, Org__c.Environment__c, productionEnvironment.Id)
                .setFieldValue(Org__c.SObjectType, Org__c.Default_Credential__c, true)
                .setDataSize(Org__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CopadoSetupTestDefaults.OrgCredentialDefaults.class)
                .setFieldValue(Org__c.SObjectType, Org__c.Name, 'Staging')
                .setFieldValue(Org__c.SObjectType, Org__c.Environment__c, stagingEnvironment.Id)
                .setFieldValue(Org__c.SObjectType, Org__c.Default_Credential__c, true)
                .setDataSize(Org__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CopadoSetupTestDefaults.OrgCredentialDefaults.class)
                .setFieldValue(Org__c.SObjectType, Org__c.Name, 'Dev1')
                .setFieldValue(Org__c.SObjectType, Org__c.OwnerId, standardUser.Id)
                .setFieldValue(Org__c.SObjectType, Org__c.Environment__c, dev1Environment.Id)
                .setFieldValue(Org__c.SObjectType, Org__c.Default_Credential__c, true)
                .setDataSize(Org__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CopadoSetupTestDefaults.OrgCredentialDefaults.class)
                .setFieldValue(Org__c.SObjectType, Org__c.Name, 'Dev2')
                .setFieldValue(Org__c.SObjectType, Org__c.OwnerId, standardUser.Id)
                .setFieldValue(Org__c.SObjectType, Org__c.Environment__c, dev2Environment.Id)
                .setFieldValue(Org__c.SObjectType, Org__c.Default_Credential__c, true)
                .setDataSize(Org__c.SObjectType, 1)
                .generateDefaults()
                .executeDML();

            Org__c productionOrg = new Org__c();
            Org__c stagingOrg = new Org__c();
            Org__c dev1Org = new Org__c();
            Org__c dev2Org = new Org__c();

            for (Org__c org : (List<Org__c>) orgCredentialDefaults.getTestData(Org__c.SObjectType)) {
                switch on org.Name {
                    when 'Production 0' {
                        productionOrg = org;
                    }
                    when 'Staging 0' {
                        stagingOrg = org;
                    }
                    when 'Dev1 0' {
                        dev1Org = org;
                    }
                    when 'Dev2 0' {
                        dev2Org = org;
                    }
                }
            }

            // This data depends on certain specific records. That's why is splitted.
            ITestDefaults pipelineDefaults = new CopadoUserStoryTestDefaults.PipelineDefaults()
                .setFieldDefaults()
                .includeDefaults(CopadoUserStoryTestDefaults.ProjectDefaults.class)
                .includeDefaults(CopadoUserStoryTestDefaults.GitRepositoryDefaults.class)
                .setSObjectRelation(
                    Deployment_Flow__c.SObjectType,
                    Git_Repository__c.SObjectType,
                    new Map<Schema.SObjectField, Integer>{ Deployment_Flow__c.Git_Repository__c => 1 }
                )
                .setSObjectRelation(
                    Project__c.SObjectType,
                    Deployment_Flow__c.SObjectType,
                    new Map<Schema.SObjectField, Integer>{ Project__c.Deployment_Flow__c => 1 }
                )
                .setDataSize(Git_Repository__c.SObjectType, 1)
                .setDataSize(Deployment_Flow__c.SObjectType, 1)
                .setDataSize(Project__c.SObjectType, 1)
                .generateDefaults()
                .executeDML();

            Git_Repository__c gitRepository = (Git_Repository__c) pipelineDefaults.getTestData(Git_Repository__c.SObjectType)[0];

            GlobalAPI.authenticateGitRepository(gitRepository.Id, 'username', 'password');
            Sensitive_Information__c sensitiveInformationForGitRepository = Sensitive_Information__c.getValues(gitRepository.Id);
            System.assertEquals(gitRepository.Id, sensitiveInformationForGitRepository.Name, 'sensitive information is created with given repo id');
            System.assertEquals(
                'username',
                sensitiveInformationForGitRepository.Username__c,
                'sensitive information username is equal to given repo username'
            );
            System.assertEquals(
                'password',
                DeployAPI.decryptAPIKey(sensitiveInformationForGitRepository.Password__c),
                'sensitive information password is equal to given repo password'
            );

            sensitiveInformationForGitRepository.Extra_Header__c = DeployAPI.encryptAPIKey('key1:value1\nkey2:value2\nkey3:value3');
            update sensitiveInformationForGitRepository;

            GlobalAPI.updateExtraHeader(gitRepository.Id, 'key2','updateValue2');
            Sensitive_Information__c updatedInformation = [SELECT Id, Extra_Header__c FROM Sensitive_Information__c WHERE Id = :sensitiveInformationForGitRepository.Id];
            String header = DeployAPI.decryptAPIKey(updatedInformation.Extra_Header__c);
            System.assertEquals(true, header.contains('updateValue2'), 'something is wrong in GlobalAPI class updateExtraHeader method!');
        }
    }

    @IsTest
    private static void getRecentChanges() {
        Environment__c env = new Environment__c(Name = 'UAT Environment', Type__c = 'Production');
        insert env;
        Org__c org = CMTestMethodUtilities.createOrg('MyOrg1', 'Production', 'SFDC_OrgId', null, null, System.now(), env.Id);
        insert org;

        insert new Attachment(Name = 'MetaData', Body = Blob.valueOf('[{"n": "ExampleTest", "t": "ApexClass"}]'), ParentId = org.Id);

        String fixedResponse =
            '{' +
            '"statusCode" : 200,' +
            '"content" : "{' +
            '\\"records\\" : [' +
            '{' +
            '\\"CreatedDate\\": \\"2021-02-07T01:41:26.000+0000\\",' +
            '\\"CreatedBy\\": {' +
            '\\"Name\\": \\"User User\\"' +
            '},' +
            '\\"LastModifiedDate\\": \\"2021-02-07T01:41:26.000+0000\\",' +
            '\\"LastModifiedBy\\": {' +
            '\\"Name\\": \\"User User\\"' +
            '},' +
            '\\"IsNameObsolete\\": false,' +
            '\\"MemberName\\": \\"asdfas\\",' +
            '\\"MemberType\\": \\"Profile\\"' +
            '}' +
            ']' +
            '}"' +
            '}';

        MockHttpResponseGenerator mockResponse = new MockHttpResponseGenerator(200, 'Complete', fixedResponse, null);
        Test.setMock(HttpCalloutMock.class, mockResponse);

        Test.startTest();
        GlobalAPI apiCls = new GlobalAPI();
        List<Object> recentChanges = apiCls.getRecentChanges(org.Id);
        Test.stopTest();

        String content = (String) ((Map<String, Object>) JSON.deserializeUntyped(fixedResponse)).get('content');
        List<Object> expectedRecords = (List<Object>) ((Map<String, Object>) JSON.deserializeUntyped(content)).get('records');
        System.assertEquals(expectedRecords.size(), recentChanges.size(), 'Recent changes result should match');
    }

    @IsTest
    private static void getCopadoServerUrl() {
        // SETUP
        upsert TestUtilities.getTestSettings();

        // EXECUTE
        Test.startTest();
        String serverUrl = new GlobalAPI().getCopadoServerUrl();
        Test.stopTest();

        // VERIFY
        System.assertEquals('test.com', serverUrl, 'Server url is not correct');
    }

    @IsTest
    private static void proxyOrgRequest() {
        // Setup
        GlobalAPI.ProxyOrgRequest request = new GlobalAPI.ProxyOrgRequest();
        request.endPointUrlService = '/services/data/v53.0/tooling/query/?q=SELECT+Name+FROM+SourceMember';
        request.orgCredentialId = 'orgId';
        request.logLabelIdentifier = 'test';
        request.requestType = HttpMethod.GET.name();

        GlobalAPI.ProxyOrgResponse mockResponse = new GlobalAPI.ProxyOrgResponse();
        mockResponse.statusCode = 200;
        mockResponse.content = '{"records":[]}';
        new HttpMock().post('/json/v1/proxyOrgRequest/', mockResponse, 200).mock();

        // Exercise
        Test.startTest();
        GlobalAPI.ProxyOrgResponse response = new GlobalAPI().proxyOrgRequest(request);
        Test.stopTest();

        // Verify
        System.assertEquals(200, response.statusCode, 'Response status code should match');
    }

    @IsTest
    private static void proxyOrgRequestSoap() {
        // Setup
        GlobalAPI.ProxyOrgRequest request = new GlobalAPI.ProxyOrgRequest();
        request.endPointUrlService = '/services/Soap/m/53.0';
        request.orgCredentialId = 'orgId';
        request.logLabelIdentifier = 'test';
        request.requestType = HttpMethod.GET.name();
        request.requestPayload = '<envelope></envelope>';

        GlobalAPI.ProxyOrgResponse mockResponse = new GlobalAPI.ProxyOrgResponse();
        mockResponse.statusCode = 200;
        mockResponse.content = '<records></records>';
        new HttpMock().post('/json/v1/proxyOrgRequest/soap', mockResponse, 200).mock();

        // Exercise
        Test.startTest();
        GlobalAPI.ProxyOrgResponse response = new GlobalAPI().proxyOrgRequestSoap(request);
        Test.stopTest();

        // Verify
        System.assertEquals(200, response.statusCode, 'Response status code should match');
    }
}