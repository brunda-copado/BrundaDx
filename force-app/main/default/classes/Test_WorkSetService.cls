@IsTest
private class Test_WorkSetService {
    @TestSetup
    private static void setUpData() {
        List<User> users = TestDataFactory.createUsers();

        TestUtilities.enableLicenses(2, 2, 2, 2, 2);
        FeatureManagement.setPackageIntegerValue('CBM_Branches', 1);
        FeatureManagement.setPackageIntegerValue('CCM_Licenses_Enabled', 2);
        FeatureManagement.setPackageIntegerValue('EE_Licenses_Enabled', 2);

        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Copado_User'];
        insert new PermissionSetAssignment(AssigneeId = users[0].Id, PermissionSetId = ps.Id);
    }

    @IsTest
    private static void workSetWithInvalidFilterCriteria() {
        User u = [SELECT Id, Username FROM User WHERE Email = 'test1@test1.com'];
        TestUtilities.assignLicense(String.valueOf(u.Username), true, true, true, true, true);

        System.runAs(u) {
            WorkSetService.Request request = new WorkSetService.Request();
            request.criteria = 'Id';
            request.value = UserInfo.getOrganizationId();

            CliProxy.CLIWrapper reqBody = new CliProxy.CLIWrapper();
            reqBody.mainService = 'work';
            reqBody.subService = 'set';
            reqBody.body = JSON.serialize(request);

            RestContext.request = Test_CliProxy.commonRequest(JSON.serialize(reqBody));

            Test.startTest();
            String response = CliProxy.doPost();
            Test.stopTest();

            WorkSetService.Response resp = (WorkSetService.Response) JSON.deserialize(response, WorkSetService.Response.class);
            String expectedMessage = String.format(Label.NoUserStoryFound, new List<String>{ 'Id', UserInfo.getOrganizationId() });

            System.assertEquals(expectedMessage, resp.message);
            System.assertEquals(CliSfDataWrapper.StatusResult.ERROR.name(), resp.status);
        }
    }

    @IsTest
    private static void workSetSearchUS() {
        User u = [SELECT Id, Username FROM User WHERE Email = 'test1@test1.com'];
        TestUtilities.assignLicense(String.valueOf(u.Username), true, true, true, true, true);

        System.runAs(u) {
            List<Environment__c> environments = new List<Environment__c>{
                new Environment__c(Name = 'Environment 1'),
                new Environment__c(Name = 'Environment 2')
            };

            insert environments;

            Org__c credential = new Org__c();
            credential.Name = 'Credential 1';
            credential.Environment__c = environments[0].Id;
            insert credential;

            Deployment_Flow__c pipeline = new Deployment_Flow__c();
            pipeline.Name = 'MyPipeline';
            pipeline.Active__c = true;
            pipeline.Calculate_Based_on__c = 'User Story';
            insert pipeline;

            Deployment_Flow_Step__c connection = new Deployment_Flow_Step__c();
            connection.Deployment_Flow__c = pipeline.Id;
            connection.Branch__c = 'env1';
            connection.Source_Environment__c = environments[0].Id;
            connection.Destination_Environment__c = environments[1].Id;
            insert connection;

            User_Story__c us = new User_Story__c();
            us.Environment__c = environments[0].Id;
            insert us;

            mockRequest('Id', us.Id, credential.Name);

            Test.startTest();
            String response = CliProxy.doPost();
            Test.stopTest();

            WorkSetService.Response resp = (WorkSetService.Response) JSON.deserialize(response, WorkSetService.Response.class);

            System.assertEquals(CliSfDataWrapper.StatusResult.ERROR.name(), resp.status);
            System.assertEquals(Label.Org_Credential_Not_Included_In_Deployment_Flow, resp.message);
        }
    }

    @IsTest
    private static void workSetWithInvalidCredential() {
        User u = [SELECT Id, Username FROM User WHERE Email = 'test1@test1.com'];
        TestUtilities.assignLicense(String.valueOf(u.Username), true, true, true, true, true);

        System.runAs(u) {
            User_Story__c us = new User_Story__c();
            insert us;
            us = [SELECT Id, Name, Environment__c, Project__c FROM User_Story__c WHERE Id = :us.Id];

            mockRequest('Id', us.Id, 'Invalid Credential');

            Test.startTest();
            String response = CliProxy.doPost();
            Test.stopTest();

            WorkSetService.Response resp = (WorkSetService.Response) JSON.deserialize(response, WorkSetService.Response.class);

            System.assertEquals(Label.InvalidOrgCredential, resp.message);
            System.assertEquals(CliSfDataWrapper.StatusResult.ERROR.name(), resp.status);
        }
    }

    @IsTest
    private static void workSetWithCredential() {
        User u = [SELECT Id, Username FROM User WHERE Email = 'test1@test1.com'];
        TestUtilities.assignLicense(String.valueOf(u.Username), true, true, true, true, true);

        System.runAs(u) {
            List<Environment__c> environments = new List<Environment__c>{
                new Environment__c(Name = 'Environment 1'),
                new Environment__c(Name = 'Environment 2')
            };

            insert environments;

            Org__c credential = new Org__c();
            credential.Name = 'Credential 1';
            credential.Environment__c = environments[0].Id;
            insert credential;

            Deployment_Flow__c pipeline = new Deployment_Flow__c();
            pipeline.Name = 'MyPipeline';
            pipeline.Active__c = true;
            pipeline.Calculate_Based_on__c = 'User Story';
            insert pipeline;

            Deployment_Flow_Step__c connection = new Deployment_Flow_Step__c();
            connection.Deployment_Flow__c = pipeline.Id;
            connection.Branch__c = 'env1';
            connection.Source_Environment__c = environments[0].Id;
            connection.Destination_Environment__c = environments[1].Id;
            insert connection;

            Project__c prj = new Project__c();
            prj.Name = 'My Project';
            prj.Deployment_Flow__c = pipeline.Id;
            insert prj;

            User_Story__c us = new User_Story__c();
            us.Project__c = prj.Id;
            insert us;
            us = [SELECT Id, Name, Environment__c, Project__c FROM User_Story__c WHERE Id = :us.Id];

            mockRequest('Id', us.Id, credential.Name);

            Test.startTest();
            String response = CliProxy.doPost();
            Test.stopTest();

            WorkSetService.Response resp = (WorkSetService.Response) JSON.deserialize(response, WorkSetService.Response.class);

            System.assertEquals(CliSfDataWrapper.StatusResult.OK.name(), resp.status);

            System.assertEquals(null, resp.message);
            System.assertEquals('env1', resp.environmentBranch);

            System.assertEquals(us.Name, resp.userStory.Name);
            System.assertEquals(credential.Id, resp.userStory.Org_Credential__c);
        }
    }

    @IsTest
    private static void workSetUsWithoutEnvironment() {
        User u = [SELECT Id, Username FROM User WHERE Email = 'test1@test1.com'];
        TestUtilities.assignLicense(String.valueOf(u.Username), true, true, true, true, true);

        System.runAs(u) {
            User_Story__c userStory = new User_Story__c();
            insert userStory;
            mockRequest('Id', userStory.Id);

            Test.startTest();
            String response = CliProxy.doPost();
            Test.stopTest();

            CliSfDataWrapper resp = (CliSfDataWrapper) JSON.deserialize(response, CliSfDataWrapper.class);

            System.assertEquals(CliSfDataWrapper.StatusResult.ERROR.name(), resp.status);
            System.assertEquals(Label.Credential_Not_Included_in_User_Story, resp.message);
        }
    }

    @IsTest
    private static void workSetWithNoCliConfigFile() {
        User userRecord = [SELECT Id, Username FROM User WHERE Email = 'test1@test1.com'];
        TestUtilities.assignLicense(String.valueOf(userRecord.Username), true, true, true, true, true);

        System.runAs(userRecord) {
            //SETUP

            Credential credential1 = new Credential();
            Credential credential2 = new Credential();

            Environment dev1 = new Environment().name('dev1').type('Sandbox').platform('SFDX').add(credential1);
            Environment uat = new Environment().name('uat').type('Sandbox').platform('SFDX').add(credential2);

            new Pipeline()
                .active(true)
                .mainBranch('main')
                .setPlatform('SFDX')
                .add(new SystemProperty().apiName('vlocity_root_folder').value('Vlocity Test Folder'))
                .add(new Connection(dev1, uat).branch('dev1'))
                .add(new Project().add(new UserStory().credential(credential1).title('US-1')))
                .persist();

            User_Story__c usRecord = getUserStory('US-1');

            ExtensionKeyValueSettingsSelector.mock = new List<ExtensionKeyValueSetting__mdt>{
                new ExtensionKeyValueSetting__mdt(
                    Extension__r = new ExtensionPackageConfiguration__mdt(Platform__c = 'SFDX'),
                    Key__c = 'CliConfiguration',
                    Value__c = 'CliConfiguration'
                )
            };

            mockRequest('Name', usRecord.Name);

            //EXERCISE

            Test.startTest();
            String response = CliProxy.doPost();
            Test.stopTest();

            WorkSetService.Response resp = (WorkSetService.Response) JSON.deserialize(response, WorkSetService.Response.class);

            //VERIFY

            System.assertEquals(CliSfDataWrapper.StatusResult.OK.name(), resp.status);

            System.assertEquals(null, resp.message);
            System.assertEquals('dev1', resp.environmentBranch);
            System.assertEquals(usRecord.Name, resp.userStory.Name);
            System.assertEquals(null, resp.configFile);
        }
    }

    @IsTest
    private static void workSetWithCliConfigFile() {
        User userRecord = [SELECT Id, Username FROM User WHERE Email = 'test1@test1.com'];
        TestUtilities.assignLicense(String.valueOf(userRecord.Username), true, true, true, true, true);

        System.runAs(userRecord) {
            //SETUP

            Credential credential1 = new Credential();
            Credential credential2 = new Credential();

            Environment dev1 = new Environment().name('dev1').type('Sandbox').platform('SFDX').add(credential1);
            Environment uat = new Environment().name('uat').type('Sandbox').platform('SFDX').add(credential2);

            new Pipeline()
                .active(true)
                .mainBranch('main')
                .setPlatform('SFDX')
                .add(new SystemProperty().apiName('vlocity_root_folder').value('Vlocity Test Folder'))
                .add(new SystemProperty().apiName('dynamic_expression_resolver').value('Expression Value'))
                .add(new Connection(dev1, uat).branch('dev1'))
                .add(new Project().add(new UserStory().credential(credential1).title('US-1')))
                .persist();

            User_Story__c usRecord = getUserStory('US-1');

            ExtensionKeyValueSettingsSelector.mock = new List<ExtensionKeyValueSetting__mdt>{
                new ExtensionKeyValueSetting__mdt(
                    Extension__r = new ExtensionPackageConfiguration__mdt(Platform__c = 'SFDX'),
                    Key__c = 'CliConfiguration',
                    Value__c = 'CliConfiguration'
                )
            };

            StaticResourcesSelector.mock = new List<StaticResource>{
                new StaticResource(Name = 'CliConfiguration', Body = Blob.valueOf(getConfigFile()))
            };

            mockRequest('Name', usRecord.Name);

            //EXERCISE

            Test.startTest();
            String response = CliProxy.doPost();
            Test.stopTest();

            WorkSetService.Response resp = (WorkSetService.Response) JSON.deserialize(response, WorkSetService.Response.class);

            //VERIFY

            System.assertEquals(CliSfDataWrapper.StatusResult.OK.name(), resp.status);

            System.assertEquals(null, resp.message);
            System.assertEquals('dev1', resp.environmentBranch);
            System.assertEquals(usRecord.Name, resp.userStory.Name);
            System.assertEquals(getResolvedConfigFile(), resp.configFile);
        }
    }

    // PRIVATE

    private static String getConfigFile() {
        return '{"Vlocity": {"rootfolder": "{$Context.Property.vlocity_root_folder}/**","defaultFolder": "vlocity/**"' +
            +'},"Category-X" : {"rootfolder" : "{$Context.Property.dynamic_expression_resolver}"},"SFDX": {"rootfolder": [],"config": {"filepath": "sfdx-project.json","property": "packageDirectories[].path"},' +
            +'"defaultFolder": "force-app","exclude": {"filePattern": ["**/__tests__/**", "**/.eslintrc.json", "**/jsconfig.json"]}' +
            +'},"Other": {"default": true}}';
    }

    private static String getResolvedConfigFile() {
        return '{"Vlocity": {"rootfolder": "Vlocity Test Folder/**","defaultFolder": "vlocity/**"' +
            +'},"Category-X" : {"rootfolder" : "Expression Value"},"SFDX": {"rootfolder": [],"config": {"filepath": "sfdx-project.json","property": "packageDirectories[].path"},' +
            +'"defaultFolder": "force-app","exclude": {"filePattern": ["**/__tests__/**", "**/.eslintrc.json", "**/jsconfig.json"]}' +
            +'},"Other": {"default": true}}';
    }

    private static User_Story__c getUserStory(String title) {
        return [SELECT Id, Name, Project__c, Platform__c, Org_Credential__c FROM User_Story__c WHERE User_Story_Title__c = :title];
    }

    private static void mockRequest(String name, String value) {
        String credentialName = null;
        mockRequest(name, value, credentialName);
    }

    private static void mockRequest(String name, String value, String credentialName) {
        WorkSetService.Request wrks = new WorkSetService.Request();
        wrks.value = value;
        wrks.criteria = name;
        wrks.credentialName = credentialName;

        CliProxy.CLIWrapper reqBody = new CliProxy.CLIWrapper();
        reqBody.mainService = 'work';
        reqBody.subService = 'set';
        reqBody.body = JSON.serialize(wrks);

        RestContext.request = Test_CliProxy.commonRequest(JSON.serialize(reqBody));
    }
}