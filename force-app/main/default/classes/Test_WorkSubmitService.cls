@IsTest
public with sharing class Test_WorkSubmitService {
    @TestSetup
    public static void setUpData() {
        List<User> userList = TestDataFactory.createUsers();

        TestUtilities.enableLicenses(2, 2, 2, 2, 2);
        FeatureManagement.setPackageIntegerValue('CBM_Branches', 1);
        FeatureManagement.setPackageIntegerValue('CCM_Licenses_Enabled', 2);
        FeatureManagement.setPackageIntegerValue('EE_Licenses_Enabled', 2);

        // To be able to create Quality Gate Rules: we need Configure_AQF permissions.
        List<PermissionSetAssignment> assignments = new List<PermissionSetAssignment>();
        List<PermissionSet> permissionSets = [
            SELECT Id, Name
            FROM PermissionSet
            WHERE Name IN ('Copado_User', 'Copado_Functions', 'Copado_Job_Engine', 'Configure_AQF')
        ];
        for (PermissionSet permissionSet : permissionSets) {
            assignments.add(new PermissionSetAssignment(AssigneeId = userList[1].Id, PermissionSetId = permissionSet.Id));
            if (permissionSet.Name == 'Copado_User') {
                assignments.add(new PermissionSetAssignment(AssigneeId = userList[0].Id, PermissionSetId = permissionSet.Id));
            }
        }
        insert assignments;

        System.runAs(userList[0]) {
            TestUtilities.assignLicense(String.valueOf(userList[0].Username), true, true, true, true, true);
            TestUtilities.assignLicense(String.valueOf(userList[1].Username), true, true, true, true, true);
        }
    }

    @IsTest
    public static void submitPromote() {
        System.runAs(getAdminUser()) {
            createTestData();

            User_Story__c anUserStory = new User_Story__c();
            anUserStory.Environment__c = [SELECT Id FROM Environment__c WHERE Name = 'Environment 1'].Id;
            anUserStory.Project__c = [SELECT Id FROM Project__c LIMIT 1].Id;
            insert anUserStory;

            Test.startTest();
            WorkSubmitService.SubmitServiceWrapper wrks = new WorkSubmitService.SubmitServiceWrapper();
            wrks.usId = anUserStory.Id;
            CliProxy.CLIWrapper reqBody = new CliProxy.CLIWrapper();
            reqBody.mainService = 'work';
            reqBody.subService = 'submit';
            reqBody.operation = 'promote';
            reqBody.body = JSON.serialize(wrks);
            RestResponse res = new RestResponse();
            RestContext.request = Test_CliProxy.commonRequest(JSON.serialize(reqBody));
            RestContext.response = res;
            String response = CliProxy.doPost();
            Test.stopTest();

            WorkSubmitService.WorkSubmitDataWrapper resp = (WorkSubmitService.WorkSubmitDataWrapper) JSON.deserialize(
                response,
                WorkSubmitService.WorkSubmitDataWrapper.class
            );

            System.assertEquals(CliSfDataWrapper.StatusResult.OK.name(), resp.status, 'Status does not match');
            System.assertEquals(null, resp.message, 'Message is not null');
            System.assertEquals(true, resp.userStory.Promote_Change__c, 'Promote change is false');
            System.assertEquals(anUserStory.Environment__c, resp.userStory.Environment__c, 'Environment does not match');
            System.assertEquals(anUserStory.Project__c, resp.userStory.Project__c, 'Project does not match');
        }
    }

    @IsTest
    public static void submitDeploy() {
        System.runAs(getAdminUser()) {
            createTestData();

            List<Environment__c> environmentList = [SELECT Id FROM Environment__c ORDER BY Name];

            List<Org__c> orgCredList = new List<Org__c>{
                new Org__c(
                    Environment__c = environmentList[0].Id,
                    Name = 'Cred1 Env1',
                    Org_Type__c = 'Production/Developer',
                    Validated_Date__c = System.Date.today(),
                    Default_Credential__c = true
                ),
                new Org__c(
                    Environment__c = environmentList[1].Id,
                    Name = 'Cred2 Env2',
                    Org_Type__c = 'Production/Developer',
                    Validated_Date__c = System.Date.today(),
                    Default_Credential__c = true
                )
            };
            insert orgCredList;

            User_Story__c anUserStory = new User_Story__c();
            anUserStory.Environment__c = environmentList[0].Id;
            anUserStory.Project__c = [SELECT Id FROM Project__c LIMIT 1].Id;
            anUserStory.Org_Credential__c = orgCredList[0].Id;
            insert anUserStory;

            Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock('{}', null));

            Test.startTest();
            WorkSubmitService.SubmitServiceWrapper wrks = new WorkSubmitService.SubmitServiceWrapper();
            wrks.usId = anUserStory.Id;
            CliProxy.CLIWrapper reqBody = new CliProxy.CLIWrapper();
            reqBody.mainService = 'work';
            reqBody.subService = 'submit';
            reqBody.operation = 'deploy';
            reqBody.body = JSON.serialize(wrks);
            RestResponse res = new RestResponse();
            RestContext.request = Test_CliProxy.commonRequest(JSON.serialize(reqBody));
            RestContext.response = res;
            String response = CliProxy.doPost();
            Test.stopTest();

            WorkSubmitService.WorkSubmitDataWrapper resp = (WorkSubmitService.WorkSubmitDataWrapper) JSON.deserialize(
                response,
                WorkSubmitService.WorkSubmitDataWrapper.class
            );

            System.assertEquals(CliSfDataWrapper.StatusResult.OK.name(), resp.status, 'Status does not match');
            System.assertEquals(null, resp.message, 'Message is not null');
            System.assertEquals(true, resp.userStory.Promote_and_Deploy__c, 'Promote and deploy is false');
            System.assertEquals(anUserStory.Environment__c, resp.userStory.Environment__c, 'Environment does not match');
            System.assertEquals(anUserStory.Project__c, resp.userStory.Project__c, 'Project does not match');
        }
    }

    @IsTest
    public static void submitPromoteDeployError() {
        System.runAs(getAdminUser()) {
            createTestData();

            User_Story__c anUserStory = new User_Story__c();
            anUserStory.Environment__c = [SELECT Id FROM Environment__c WHERE Name = 'Environment 1'].Id;
            anUserStory.Project__c = [SELECT Id FROM Project__c LIMIT 1].Id;
            insert anUserStory;

            Test.startTest();
            WorkSubmitService.SubmitServiceWrapper wrks = new WorkSubmitService.SubmitServiceWrapper();
            wrks.usId = anUserStory.Id;
            CliProxy.CLIWrapper reqBody = new CliProxy.CLIWrapper();
            reqBody.mainService = 'work';
            reqBody.subService = 'submit';
            reqBody.operation = 'deploy';
            reqBody.body = JSON.serialize(wrks);
            RestResponse res = new RestResponse();
            RestContext.request = Test_CliProxy.commonRequest(JSON.serialize(reqBody));
            RestContext.response = res;
            String response = CliProxy.doPost();
            Test.stopTest();

            WorkSubmitService.WorkSubmitDataWrapper resp = (WorkSubmitService.WorkSubmitDataWrapper) JSON.deserialize(
                response,
                WorkSubmitService.WorkSubmitDataWrapper.class
            );

            System.assertEquals(CliSfDataWrapper.StatusResult.ERROR.name(), resp.status, resp);
            System.assertNotEquals(null, resp.message, 'No response message');
        }
    }

    @IsTest
    public static void submitValidateForClassic() {
        System.runAs(getAdminUser()) {
            createTestData();

            List<Environment__c> environmentList = [SELECT Id FROM Environment__c ORDER BY Name];

            List<Org__c> orgCredList = new List<Org__c>{
                new Org__c(
                    Environment__c = environmentList[0].Id,
                    Name = 'Cred1 Env1',
                    Org_Type__c = 'Production/Developer',
                    Validated_Date__c = System.Date.today(),
                    Default_Credential__c = true
                ),
                new Org__c(
                    Environment__c = environmentList[1].Id,
                    Name = 'Cred2 Env2',
                    Org_Type__c = 'Production/Developer',
                    Validated_Date__c = System.Date.today(),
                    Default_Credential__c = true
                )
            };
            insert orgCredList;

            User_Story__c anUserStory = new User_Story__c();
            anUserStory.Environment__c = environmentList[0].Id;
            anUserStory.Project__c = [SELECT Id FROM Project__c LIMIT 1].Id;
            anUserStory.Org_Credential__c = orgCredList[0].Id;
            insert anUserStory;

            Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock('{}', null));

            Test.startTest();
            WorkSubmitService.SubmitServiceWrapper wrks = new WorkSubmitService.SubmitServiceWrapper();
            wrks.usId = anUserStory.Id;
            CliProxy.CLIWrapper reqBody = new CliProxy.CLIWrapper();
            reqBody.mainService = 'work';
            reqBody.subService = 'submit';
            reqBody.operation = 'validate';
            reqBody.body = JSON.serialize(wrks);
            RestResponse res = new RestResponse();
            RestContext.request = Test_CliProxy.commonRequest(JSON.serialize(reqBody));
            RestContext.response = res;
            String response = CliProxy.doPost();
            Test.stopTest();

            WorkSubmitService.WorkSubmitDataWrapper resp = (WorkSubmitService.WorkSubmitDataWrapper) JSON.deserialize(
                response,
                WorkSubmitService.WorkSubmitDataWrapper.class
            );

            User_Story__c finalUserStory = [
                SELECT Id, Name, Last_Validation_Promotion__c, (SELECT Id, Name FROM Promoted_User_Stories__r)
                FROM User_Story__c
                WHERE Id = :anUserStory.Id
                LIMIT 1
            ];

            System.assertEquals(CliSfDataWrapper.StatusResult.OK.name(), resp.status, resp);
            System.assertNotEquals(null, resp.message, 'No response message');

            System.assertNotEquals(null, finalUserStory.Last_Validation_Promotion__c, 'Last Validation Promotion is null');
            System.assert(!finalUserStory.Promoted_User_Stories__r.isEmpty(), 'Promoted User Story is empty');
        }
    }

    @IsTest
    public static void submitValidateForMultiCloud() {
        System.runAs(getStandardUser()) {
            new JobTemplate()
                .name('JOB_TEMPLATE_PROMOTION')
                .mockAutomation('Promotion')
                .volumeOptions('[{ "name": "volumeEnabled", "value": "false" }]')
                .add(new JobStep().order(1).type('Function').configJson('{"functionName":"mulePromotion","parameters":[]}'))
                .persist();

            createMCData();

            User_Story__c anUserStory = [SELECT Id FROM User_Story__C];

            TestUtilities.getAllMultilicense();

            Test.startTest();
            WorkSubmitService.SubmitServiceWrapper wrks = new WorkSubmitService.SubmitServiceWrapper();
            wrks.usId = anUserStory.Id;
            CliProxy.CLIWrapper reqBody = new CliProxy.CLIWrapper();
            reqBody.mainService = 'work';
            reqBody.subService = 'submit';
            reqBody.operation = 'validate';
            reqBody.body = JSON.serialize(wrks);
            RestResponse res = new RestResponse();
            RestContext.request = Test_CliProxy.commonRequest(JSON.serialize(reqBody));
            RestContext.response = res;
            String response = CliProxy.doPost();
            Test.stopTest();

            WorkSubmitService.WorkSubmitDataWrapper resp = (WorkSubmitService.WorkSubmitDataWrapper) JSON.deserialize(
                response,
                WorkSubmitService.WorkSubmitDataWrapper.class
            );

            List<Promoted_User_Story__c> promotedUserStoryList = [
                SELECT Promotion__c
                FROM Promoted_User_Story__c
                WHERE User_Story__c = :anUserStory.Id
            ];
            System.assertEquals(1, promotedUserStoryList.size(), 'A Promoted User Story should be created');

            String expectedMessage = String.format(
                Label.PROMOTION_RECORD_CREATED_FOR_USER_STORY,
                new List<String>{ promotedUserStoryList[0].Promotion__c, anUserStory.Id }
            );
            System.assertEquals(CliSfDataWrapper.StatusResult.OK.name(), resp.status, resp);
            System.assertEquals(expectedMessage, resp.message, 'Response message does not match');
            System.assertNotEquals(null, resp.jobExecutionId, 'Response User Story is not correct');
        }
    }

    @IsTest
    public static void submitValidateForMultiPlatformWithoutProject() {
        System.runAs(getStandardUser()) {
            new JobTemplate()
                .name('JOB_TEMPLATE_PROMOTION')
                .mockAutomation('Promotion')
                .volumeOptions('[{ "name": "volumeEnabled", "value": "false" }]')
                .add(new JobStep().order(1).type('Function').configJson('{"functionName":"mulePromotion","parameters":[]}'))
                .persist();

            new Pipeline().setPlatform('Other').add(new Project().add(new UserStory()).add(new Release())).persist();

            User_Story__c anUserStory = [SELECT Id FROM User_Story__C];
            Release__c aRelease = [SELECT Id FROM Release__c];
            anUserStory.Project__c = null;
            anUserStory.Release__c = aRelease.Id;
            update anUserStory;

            Test.startTest();

            TestUtilities.getAllMultilicense();

            WorkSubmitService.SubmitServiceWrapper wrks = new WorkSubmitService.SubmitServiceWrapper();
            wrks.usId = anUserStory.Id;
            CliProxy.CLIWrapper reqBody = new CliProxy.CLIWrapper();
            reqBody.mainService = 'work';
            reqBody.subService = 'submit';
            reqBody.operation = 'validate';
            reqBody.body = JSON.serialize(wrks);
            RestResponse res = new RestResponse();
            RestContext.request = Test_CliProxy.commonRequest(JSON.serialize(reqBody));
            RestContext.response = res;
            String response = CliProxy.doPost();
            Test.stopTest();

            WorkSubmitService.WorkSubmitDataWrapper resp = (WorkSubmitService.WorkSubmitDataWrapper) JSON.deserialize(
                response,
                WorkSubmitService.WorkSubmitDataWrapper.class
            );

            System.assertEquals(CliSfDataWrapper.StatusResult.ERROR.name(), resp.status, resp);
            System.assertNotEquals(null, resp.message, 'Error message is empty');
        }
    }

    @IsTest
    public static void submitDeployForMultiCloud() {
        System.runAs(getStandardUser()) {
            new JobTemplate()
                .name('JOB_TEMPLATE_PROMOTION')
                .mockAutomation('Promotion')
                .volumeOptions('[{ "name": "volumeEnabled", "value": "false" }]')
                .add(new JobStep().order(1).type('Function').configJson('{"functionName":"mulePromotion","parameters":[]}'))
                .persist();

            createMCData();

            User_Story__c anUserStory = [SELECT Id FROM User_Story__C];

            TestUtilities.getAllMultilicense();

            Test.startTest();
            WorkSubmitService.SubmitServiceWrapper wrks = new WorkSubmitService.SubmitServiceWrapper();
            wrks.usId = anUserStory.Id;
            CliProxy.CLIWrapper reqBody = new CliProxy.CLIWrapper();
            reqBody.mainService = 'work';
            reqBody.subService = 'submit';
            reqBody.operation = 'deploy';
            reqBody.body = JSON.serialize(wrks);
            RestResponse res = new RestResponse();
            RestContext.request = Test_CliProxy.commonRequest(JSON.serialize(reqBody));
            RestContext.response = res;
            String response = CliProxy.doPost();
            Test.stopTest();

            WorkSubmitService.WorkSubmitDataWrapper resp = (WorkSubmitService.WorkSubmitDataWrapper) JSON.deserialize(
                response,
                WorkSubmitService.WorkSubmitDataWrapper.class
            );

            List<Promoted_User_Story__c> promotedUserStoryList = [
                SELECT Promotion__c
                FROM Promoted_User_Story__c
                WHERE User_Story__c = :anUserStory.Id
            ];
            System.assertEquals(1, promotedUserStoryList.size(), 'A Promoted User Story should be created');

            System.assertEquals(CliSfDataWrapper.StatusResult.OK.name(), resp.status, resp);
            System.assertEquals(anUserStory.Id, resp.userStory.Id, 'Response User Story is not correct');
            System.assertNotEquals(null, resp.jobExecutionId, 'Response User Story is not correct');
            System.assertEquals(true, resp.userStory.Promote_and_Deploy__c, 'Promote and deploy is false');
        }
    }

    private static void createTestData() {
        List<Environment__c> environmentList = new List<Environment__c>{
            new Environment__c(Name = 'Environment 1'),
            new Environment__c(Name = 'Environment 2')
        };
        insert environmentList;

        Deployment_Flow__c newPipeline = new Deployment_Flow__c(Name = 'MyPipeline', Active__c = true, Calculate_Based_on__c = 'User Story');
        insert newPipeline;

        List<Deployment_Flow_Step__c> pipelineEnvList = new List<Deployment_Flow_Step__c>{
            new Deployment_Flow_Step__c(
                Deployment_Flow__c = newPipeline.Id,
                Branch__c = 'env1',
                Source_Environment__c = environmentList[0].Id,
                Destination_Environment__c = environmentList[1].Id
            ),
            new Deployment_Flow_Step__c(Deployment_Flow__c = newPipeline.Id, Branch__c = 'env2')
        };
        insert pipelineEnvList;

        Project__c newProject = new Project__c(Name = 'My Project', Deployment_Flow__c = newPipeline.Id);
        insert newProject;
    }

    private static void createMCData() {
        Credential dev1Credential = new Credential();
        Environment dev1 = new Environment().name('dev1').type('Sandbox').platform('Other').add(dev1Credential);
        Credential intCredential = new Credential();
        Environment integration = new Environment().name('int').type('Sandbox').platform('Other').add(intCredential);
        new Pipeline()
            .setPlatform('Other')
            .add(new Connection(dev1, integration).branch('dev1'))
            .add(new Project().add(new UserStory().credential(dev1Credential).add(new UserStoryMetadata().name('TestClass').type('ApexClass'))))
            .persist();
    }

    private static User getAdminUser() {
        return [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' ORDER BY CreatedDate DESC LIMIT 1];
    }

    private static User getStandardUser() {
        return [SELECT Id FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1];
    }
}