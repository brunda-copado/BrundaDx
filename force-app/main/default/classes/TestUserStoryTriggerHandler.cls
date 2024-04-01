@SuppressWarnings('PMD.CyclomaticComplexity,PMD.ApexAssertionsShouldIncludeMessage,PMD.ApexUnitTestClassShouldHaveAsserts')
@IsTest
private class TestUserStoryTriggerHandler {
    private static final String STANDARD_USER_QUERY = 'SELECT Username FROM User WHERE Username = \'test_user@myorg.com\' LIMIT 1';
    @TestSetup
    private static void setupData() {
        TestUtilities.enableLicenses(2, 2, 2, 2, 2, 30);
        ITestDefaults userCreation = new CopadoSetupTestDefaults.UserDefaults().createRunAsUsers();
        userCreation.executeDML();

        TestUtilities.getAllMultilicense();
        User user = (User) new User_t()
            .alias('TestUsr1')
            .assign(new PermissionSetAssignment_t().copadoUser())
            .assign(new PermissionSetAssignment_t().jobEngine())
            .assign(new PermissionSetAssignment_t().executeAutomations())
            .assign(new PermissionSetAssignment_t().qualityGatesAdmin())
            .persist();
        System.runAs(user) {
            new CopadoLicense().user(user).enableAll().persist();
        }
    }

    @isTest
    private static void testBeforeInsert() {
        User currentUser = Database.query(STANDARD_USER_QUERY);
        TestUtilities.assignLicense(currentUser.Username, true, true, true, true, true);
        System.runAs(currentUser) {
            Project__c testProject = CMTestMethodUtilities.createProject('my project');
            insert testProject;

            Sprint__c testSprint = CMTestMethodUtilities.createSprint('my sprint');
            testSprint.Project__c = testProject.Id;
            insert testSprint;

            List<User_Story__c> userStories = new List<User_Story__c>();
            for (Integer i = 0; i < 20; i++) {
                User_Story__c testUserStory = CMTestMethodUtilities.createUserStory('test');
                testUserStory.Sprint__c = testSprint.Id;
                testUserStory.Project__c = null;
                testUserStory.Story_Points_Other__c = 3;
                testUserStory.Planned_Points_Other__c = 2;
                userStories.add(testUserStory);
            }

            Test.startTest();
            insert userStories;
            Test.stopTest();

            for (User_Story__c u : [SELECT Id, Project__c FROM User_Story__c]) {
                system.assertEquals(testProject.Id, u.Project__c);
            }

            Sprint__c sprint = [SELECT Id, Planned_Velocity__c FROM Sprint__c WHERE Id = :testSprint.Id LIMIT 1];
            system.assertEquals(sprint.Planned_Velocity__c, 100);
        }
    }

    @isTest
    private static void testBeforeInsertBulk() {
        User currentUser = Database.query(STANDARD_USER_QUERY);
        TestUtilities.assignLicense(currentUser.Username, true, true, true, true, true);
        System.runAs(currentUser) {
            Project__c testProject = CMTestMethodUtilities.createProject('my project');
            insert testProject;

            List<Sprint__c> sprints = new List<Sprint__c>();
            for (Integer i = 0; i < 5; i++) {
                Sprint__c testSprint = CMTestMethodUtilities.createSprint('my sprint');
                testSprint.Project__c = testProject.Id;
                sprints.add(testSprint);
            }
            insert sprints;

            List<User_Story__c> userStories = new List<User_Story__c>();
            for (Sprint__c eachSprint : sprints) {
                for (Integer i = 0; i < 20; i++) {
                    User_Story__c testUserStory = CMTestMethodUtilities.createUserStory('test');
                    testUserStory.Sprint__c = eachSprint.Id;
                    testUserStory.Project__c = null;
                    testUserStory.Story_Points_Other__c = 3;
                    userStories.add(testUserStory);
                }
            }

            Test.startTest();
            insert userStories;
            Test.stopTest();

            for (User_Story__c u : [SELECT Id, Project__c FROM User_Story__c]) {
                System.assertEquals(testProject.Id, u.Project__c, 'Project Should be assigned');
            }

            for (Sprint__c sprint : [SELECT Id, Planned_Velocity__c FROM Sprint__c]) {
                System.assertEquals(sprint.Planned_Velocity__c, 60, 'Planned Velocity not updated correctly');
            }
        }
    }

    @isTest
    private static void testBeforeUpdate() {
        User currentUser = Database.query(STANDARD_USER_QUERY);
        TestUtilities.assignLicense(currentUser.Username, true, true, true, true, true);

        System.runAs(currentUser) {
            Project__c testProject = CMTestMethodUtilities.createProject('my project');
            insert testProject;

            Sprint__c testSprint = CMTestMethodUtilities.createSprint('my sprint');
            testSprint.Project__c = testProject.Id;
            insert testSprint;

            Sprint__c newSprint = CMTestMethodUtilities.createSprint('my new sprint');
            newSprint.Project__c = testProject.Id;
            insert newSprint;

            List<User_Story__c> userStories = new List<User_Story__c>();
            for (Integer i = 0; i < 20; i++) {
                User_Story__c testUserStory = CMTestMethodUtilities.createUserStory('test');
                testUserStory.Sprint__c = null;
                testUserStory.Project__c = null;
                userStories.add(testUserStory);
            }
            insert userStories;

            Integer counter = 0;
            for (User_Story__c u : userStories) {
                u.Sprint__c = testSprint.Id;
                u.Project__c = null;
                u.Story_Points_Other__c = 3;
                u.Planned_Points_Other__c = 2;
                if (counter < 10) {
                    u.Status__c = 'Completed';
                    counter++;
                }
            }

            Test.startTest();
            update userStories;

            for (User_Story__c u : [SELECT Id, Project__c FROM User_Story__c]) {
                system.assertEquals(testProject.Id, u.Project__c);
            }

            Sprint__c sprint = [SELECT Id, Planned_Velocity__c, Actual_Velocity__c FROM Sprint__c WHERE Id = :testSprint.Id LIMIT 1];
            system.assertEquals(sprint.Planned_Velocity__c, 100);
            system.assertEquals(sprint.Actual_Velocity__c, 50);

            List<User_Story__c> userStoriesToUpdate = new List<User_Story__c>();
            for (User_Story__c u : userStories) {
                u.Sprint__c = newSprint.Id;
                userStoriesToUpdate.add(u);
            }

            update userStoriesToUpdate;
            Test.stopTest();
            Set<Id> sprintIds = new Set<Id>{ testSprint.Id, newSprint.Id };

            List<Sprint__c> sprintRecords = [
                SELECT Id, Planned_Velocity__c, Actual_Velocity__c
                FROM Sprint__c
                WHERE Id IN :sprintIds
                ORDER BY Id ASC
            ];
            system.assertEquals(sprintRecords[0].Planned_Velocity__c, 0);
            system.assertEquals(sprintRecords[0].Actual_Velocity__c, 0);

            system.assertEquals(sprintRecords[1].Planned_Velocity__c, 100);
            system.assertEquals(sprintRecords[1].Actual_Velocity__c, 50);
        }
    }

    @isTest
    private static void testWithEnvironment() {
        User currentUser = Database.query(STANDARD_USER_QUERY);
        TestUtilities.assignLicense(currentUser.Username, true, true, true, true, true);

        System.runAs(currentUser) {
            Environment__c env1 = new Environment__c(Name = 'Dev Environment');
            env1.Minimum_Apex_Test_Coverage__c = 85;
            insert env1;

            Org__c testOrg1 = CMTestMethodUtilities.createOrg('MyOrg1', 'Production', 'SFDC_OrgId', null, null, system.now(), env1.Id);
            insert testOrg1;

            Project__c testProject = CMTestMethodUtilities.createProject('my project');
            insert testProject;

            Sprint__c testSprint = CMTestMethodUtilities.createSprint('my sprint');
            testSprint.Project__c = testProject.Id;
            insert testSprint;

            User_Story__c testUserStory = CMTestMethodUtilities.createUserStory('test');
            testUserStory.Sprint__c = testSprint.Id;
            testUserStory.Org_Credential__c = testOrg1.Id;
            insert testUserStory;
            testUserStory = [SELECT Id, Minimum_Apex_Code_Coverage__c FROM User_Story__c WHERE Id = :testUserStory.Id];
            System.assertEquals(85, testUserStory.Minimum_Apex_Code_Coverage__c);

            testUserStory.Minimum_Apex_Code_Coverage__c = 50;
            update testUserStory;
            testUserStory = [SELECT Id, Minimum_Apex_Code_Coverage__c FROM User_Story__c WHERE Id = :testUserStory.Id];
            System.assertEquals(85, testUserStory.Minimum_Apex_Code_Coverage__c);

            testUserStory.Minimum_Apex_Code_Coverage__c = 95;
            update testUserStory;
            testUserStory = [SELECT Id, Minimum_Apex_Code_Coverage__c FROM User_Story__c WHERE Id = :testUserStory.Id];
            System.assertEquals(95, testUserStory.Minimum_Apex_Code_Coverage__c);
        }
    }

    @isTest
    private static void deployPromotedUserStory() {
        User currentUser = Database.query(STANDARD_USER_QUERY);
        TestUtilities.assignLicense(currentUser.Username, true, true, true, true, true);

        System.runAs(currentUser) {
            Test.startTest();
            Deployment_Flow__c flow = CMTestMethodUtilities.createCCMFlow('Standard flow', true);
            insert flow;

            Project__c testProject = CMTestMethodUtilities.createProject('test project');
            testProject.Deployment_Flow__c = flow.Id;
            insert testProject;

            Environment__c env1 = new Environment__c(Name = 'UAT Environment');
            Environment__c env2 = new Environment__c(Name = 'Production Environment');
            insert new List<Environment__c>{ env1, env2 };

            Org__c testOrg1 = CMTestMethodUtilities.createOrg('MyOrg1', 'Production', 'SFDC_OrgId', null, null, system.now(), env1.Id);
            Org__c testOrg2 = CMTestMethodUtilities.createOrg('MyOrg2', 'Production', 'SFDC_OrgId2', null, null, system.now(), env2.Id);
            insert new List<Org__c>{ testOrg1, testOrg2 };

            Deployment_Flow_Step__c dfs = CMTestMethodUtilities.createFlowStep(env1.Id, env2.Id, flow.Id);
            insert dfs;

            List<User_Story__c> userStories = new List<User_Story__c>();
            for (Integer i = 0; i < 20; i++) {
                User_Story__c testUserStory = CMTestMethodUtilities.createUserStory('test');
                testUserStory.Sprint__c = null;
                testUserStory.Project__c = testProject.Id;
                userStories.add(testUserStory);
            }
            insert userStories;

            Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock('{}', null));
            for (User_Story__c usItem : userStories) {
                usItem.Promote_and_Deploy__c = true;
            }
            update userStories;

            List<Promotion__c> promoResult = [SELECT Id, Name FROM Promotion__c];
            system.assertEquals(1, promoResult.size());

            List<Promoted_User_Story__c> pus = [
                SELECT Id, Name, User_Story__r.Name
                FROM Promoted_User_Story__c
                WHERE Promotion__c = :promoResult[0].Id
            ];
            system.assertEquals(20, pus.size());
            system.assertEquals('Promoted User Story: ' + pus[0].User_Story__r.Name, pus[0].Name);
            Test.stopTest();
        }
    }

    @IsTest
    private static void testSetChildPromotedUserStoriesAsOutdated() {
        User currentUser = Database.query(STANDARD_USER_QUERY);
        TestUtilities.assignLicense(String.valueOf(currentUser.Username), true, true, true, true, true);

        System.runAs(currentUser) {
            ITestDefaults environmentDefaults = new CCDFullCycleTestDefaults.EnvironmentDefaults()
                .setFieldDefaults()
                .setFieldValue(Environment__c.SObjectType, Environment__c.Name, 'Production Environment')
                .setDataSize(Environment__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.EnvironmentDefaults.class)
                .setFieldValue(Environment__c.SObjectType, Environment__c.Name, 'Staging Environment')
                .setFieldValue(Environment__c.SObjectType, Environment__c.Type__c, 'Sandbox')
                .setDataSize(Environment__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.EnvironmentDefaults.class)
                .setFieldValue(Environment__c.SObjectType, Environment__c.Name, 'Dev1 Environment')
                .setFieldValue(Environment__c.SObjectType, Environment__c.Type__c, 'Sandbox')
                .setDataSize(Environment__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.EnvironmentDefaults.class)
                .setFieldValue(Environment__c.SObjectType, Environment__c.Name, 'Dev2 Environment')
                .setFieldValue(Environment__c.SObjectType, Environment__c.Type__c, 'Sandbox')
                .setDataSize(Environment__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.EnvironmentDefaults.class)
                .setFieldValue(Environment__c.SObjectType, Environment__c.Name, 'Dev3 Environment')
                .setFieldValue(Environment__c.SObjectType, Environment__c.Type__c, 'Sandbox')
                .setDataSize(Environment__c.SObjectType, 1)
                .generateDefaults()
                .executeDML();

            Environment__c productionEnvironment = new Environment__c();
            Environment__c stagingEnvironment = new Environment__c();
            Environment__c dev1Environment = new Environment__c();
            Environment__c dev2Environment = new Environment__c();
            Environment__c dev3Environment = new Environment__c();

            for (Environment__c env : (List<Environment__c>) environmentDefaults.getTestData(Environment__c.SObjectType)) {
                switch on env.Name {
                    when 'Production Environment 0' {
                        productionEnvironment = env;
                    }
                    when 'Staging Environment 0' {
                        stagingEnvironment = env;
                    }
                    when 'Dev1 Environment 0' {
                        dev1Environment = env;
                    }
                    when 'Dev2 Environment 0' {
                        dev2Environment = env;
                    }
                    when 'Dev3 Environment 0' {
                        dev3Environment = env;
                    }
                }
            }

            ITestDefaults orgCredentialDefaults = new CCDFullCycleTestDefaults.OrgCredentialDefaults()
                .setFieldDefaults()
                .setFieldValue(Org__c.SObjectType, Org__c.Name, 'prod')
                .setFieldValue(Org__c.SObjectType, Org__c.Environment__c, productionEnvironment.Id)
                .setDataSize(Org__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.OrgCredentialDefaults.class)
                .setFieldValue(Org__c.SObjectType, Org__c.Name, 'staging')
                .setFieldValue(Org__c.SObjectType, Org__c.Environment__c, stagingEnvironment.Id)
                .setDataSize(Org__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.OrgCredentialDefaults.class)
                .setFieldValue(Org__c.SObjectType, Org__c.Name, 'dev1')
                .setFieldValue(Org__c.SObjectType, Org__c.Environment__c, dev1Environment.Id)
                .setDataSize(Org__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.OrgCredentialDefaults.class)
                .setFieldValue(Org__c.SObjectType, Org__c.Name, 'dev2')
                .setFieldValue(Org__c.SObjectType, Org__c.Environment__c, dev2Environment.Id)
                .setDataSize(Org__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.OrgCredentialDefaults.class)
                .setFieldValue(Org__c.SObjectType, Org__c.Name, 'dev3')
                .setFieldValue(Org__c.SObjectType, Org__c.Environment__c, dev3Environment.Id)
                .setDataSize(Org__c.SObjectType, 1)
                .generateDefaults()
                .executeDML();

            Org__c productionOrg = new Org__c();
            Org__c stagingOrg = new Org__c();
            Org__c dev1Org = new Org__c();
            Org__c dev2Org = new Org__c();
            Org__c dev3Org = new Org__c();

            for (Org__c org : (List<Org__c>) orgCredentialDefaults.getTestData(Org__c.SObjectType)) {
                switch on org.Name {
                    when 'prod 0' {
                        productionOrg = org;
                    }
                    when 'staging 0' {
                        stagingOrg = org;
                    }
                    when 'dev1 0' {
                        dev1Org = org;
                    }
                    when 'dev2 0' {
                        dev2Org = org;
                    }
                    when 'dev3 0' {
                        dev3Org = org;
                    }
                }
            }

            ITestDefaults gitRepositoryDefaults = new CCDFullCycleTestDefaults.GitRepositoryDefaults()
                .setFieldDefaults()
                .setDataSize(Git_Repository__c.SObjectType, 1)
                .includeDefaults(CCDFullCycleTestDefaults.PipelineDefaults.class)
                .setDataSize(Deployment_Flow__c.SObjectType, 1)
                .setSObjectRelation(
                    Deployment_Flow__c.SObjectType,
                    Git_Repository__c.SObjectType,
                    new Map<Schema.SObjectField, Integer>{ Deployment_Flow__c.Git_Repository__c => 1 }
                )
                .includeDefaults(CCDFullCycleTestDefaults.ProjectDefaults.class)
                .setDataSize(Project__c.SObjectType, 1)
                .setSObjectRelation(
                    Project__c.SObjectType,
                    Deployment_Flow__c.SObjectType,
                    new Map<Schema.SObjectField, Integer>{ Project__c.Deployment_Flow__c => 1 }
                )
                .includeDefaults(CCDFullCycleTestDefaults.UserStoryDefaults.class)
                .setDataSize(User_Story__c.SObjectType, 1)
                .setFieldValue(User_Story__c.SObjectType, User_Story__c.Environment__c, stagingEnvironment.Id)
                .setFieldValue(User_Story__c.SObjectType, User_Story__c.Org_Credential__c, stagingOrg.Id)
                .setSObjectRelation(
                    User_Story__c.SObjectType,
                    Project__c.SObjectType,
                    new Map<Schema.SObjectField, Integer>{ User_Story__c.Project__c => 1 }
                )
                .generateDefaults()
                .executeDML();

            Deployment_Flow__c pipelineSetting = (Deployment_Flow__c) gitRepositoryDefaults.getTestData(Deployment_Flow__c.SObjectType)[0];

            ITestDefaults pipelineConnectionDefaults = new CCDFullCycleTestDefaults.PipelineConnectionDefaults()
                .setFieldDefaults()
                .setDataSize(Deployment_Flow_Step__c.SObjectType, 1)
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Source_Environment__c, dev1Environment.Id)
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Destination_Environment__c, stagingEnvironment.Id)
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Branch__c, 'dev1')
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Deployment_Flow__c, pipelineSetting.Id)
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.PipelineConnectionDefaults.class)
                .setDataSize(Deployment_Flow_Step__c.SObjectType, 1)
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Source_Environment__c, dev2Environment.Id)
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Destination_Environment__c, stagingEnvironment.Id)
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Branch__c, 'dev2')
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Deployment_Flow__c, pipelineSetting.Id)
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.PipelineConnectionDefaults.class)
                .setDataSize(Deployment_Flow_Step__c.SObjectType, 1)
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Source_Environment__c, dev3Environment.Id)
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Destination_Environment__c, stagingEnvironment.Id)
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Branch__c, 'dev3')
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Deployment_Flow__c, pipelineSetting.Id)
                .generateDefaults()
                .includeDefaults(CCDFullCycleTestDefaults.PipelineConnectionDefaults.class)
                .setDataSize(Deployment_Flow_Step__c.SObjectType, 1)
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Source_Environment__c, stagingEnvironment.Id)
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Destination_Environment__c, productionEnvironment.Id)
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Branch__c, 'int')
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Deployment_Flow__c, pipelineSetting.Id)
                .generateDefaults();

            pipelineConnectionDefaults.executeDML();

            Project__c project = (Project__c) gitRepositoryDefaults.getTestData(Project__c.SObjectType)[0];

            User_Story__c userStory = (User_Story__c) gitRepositoryDefaults.getTestData(User_Story__c.SObjectType)[0];

            Test.startTest();

            ITestDefaults promotion1Defaults = new CCDFullCycleTestDefaults.PromotionDefaults()
                .setFieldDefaults()
                .setFieldValue(Promotion__c.SObjectType, Promotion__c.Project__c, project.Id)
                .setFieldValue(Promotion__c.SObjectType, Promotion__c.Source_Org_Credential__c, dev1Org.Id)
                .setFieldValue(Promotion__c.SObjectType, Promotion__c.Source_Environment__c, dev1Environment.Id)
                .setDataSize(Promotion__c.SObjectType, 1)
                .includeDefaults(CCDFullCycleTestDefaults.PromotedUserStoryDefaults.class)
                .setDataSize(Promoted_User_Story__c.SObjectType, 1)
                .setFieldValue(Promoted_User_Story__c.SObjectType, Promoted_User_Story__c.User_Story__c, userStory.Id)
                .setSObjectRelation(
                    Promoted_User_Story__c.SObjectType,
                    Promotion__c.SObjectType,
                    new Map<Schema.SObjectField, Integer>{ Promoted_User_Story__c.Promotion__c => 1 }
                )
                .generateDefaults()
                .executeDML();

            Promoted_User_Story__c promotedUserStory = (Promoted_User_Story__c) promotion1Defaults.getTestData(Promoted_User_Story__c.SObjectType)[0];
            System.assertEquals(stagingEnvironment.Id, userStory.Environment__c, 'User story environment should be staging');
            System.assertEquals(
                'Active',
                [SELECT Status__c FROM Promoted_User_Story__c WHERE Id = :promotedUserStory.Id]
                .Status__c,
                'Promoted user story status should be Active'
            );

            userStory.Org_Credential__c = dev1Org.Id;
            userStory.Environment__c = dev1Environment.Id;
            update userStory;
            Test.stopTest();

            System.assertEquals(dev1Environment.Id, userStory.Environment__c, 'User story environment should be dev1');
            System.assertEquals(
                PromotionConstants.STATUS_OUTDATED,
                [SELECT Status__c FROM Promoted_User_Story__c WHERE Id = :promotedUserStory.Id]
                .Status__c,
                'Promoted user story status should be Outdated'
            );
        }
    }

    @IsTest
    private static void testPlatformChildPromotedUserStoriesAsOutdated() {
        User currentUser = Database.query(STANDARD_USER_QUERY);
        TestUtilities.assignLicense(String.valueOf(currentUser.Username), true, true, true, true, true);

        System.runAs(currentUser) {
            // Setup
            Credential dev1Credential = new Credential();
            Environment dev1 = new Environment().name('dev1').type('Sandbox').platform('Other').add(dev1Credential);
            Environment dev2 = new Environment().name('dev2').type('Sandbox').platform('Other').add(new Credential());
            Credential intCredential = new Credential();
            Environment integration = new Environment().name('int').type('Sandbox').platform('Other').add(intCredential);

            new Pipeline()
                .mainBranch('main')
                .setPlatform('Other')
                .add(new Connection(dev1, integration).branch('dev1'))
                .add(new Connection(dev2, integration).branch('dev2'))
                .add(new Project().add(new UserStory().credential(dev1Credential).add(new UserStoryMetadata().name('TestClass').type('ApexClass'))))
                .persist();

            Project__c project = [SELECT Id FROM Project__c];
            User_Story__c userStory = [SELECT Id, Environment__c FROM User_Story__c WHERE Environment__c = :dev1.Id LIMIT 1];

            Promotion__c promotion = (Promotion__c) new Promotion().projectId(project.Id).sourceEnvId(dev1.Id).status('Completed').persist();
            PromotedUserStoriesDatatableController.addSelectedUserStoriesToPromotion(promotion.Id, new List<Id>{ userStory.Id });

            UserStories.bypassTrigger = true;
            userStory.Org_Credential__c = intCredential.Id;
            userStory.Environment__c = integration.Id;
            update userStory;
            UserStories.bypassTrigger = false;

            userStory = [SELECT Id, Environment__c FROM User_Story__c WHERE Environment__c = :integration.Id LIMIT 1];
            System.assertEquals(integration.Id, userStory.Environment__c, 'User story environment should be int');

            Promotion__c backPromotion = (Promotion__c) new Promotion()
                .projectId(project.Id)
                .sourceEnvId(integration.Id)
                .destinationEnvId(dev2.Id)
                .status('Draft')
                .backPromotion(true)
                .persist();
            PromotedUserStoriesDatatableController.addSelectedUserStoriesToPromotion(backPromotion.Id, new List<Id>{ userStory.Id });

            // Exercise
            Test.startTest();
            userStory.Org_Credential__c = dev1Credential.Id;
            userStory.Environment__c = dev1.Id;
            update userStory;
            Test.stopTest();

            // Verify
            System.assertEquals(dev1.Id, userStory.Environment__c, 'User story environment should be dev1');
            System.assertEquals(
                PromotionConstants.STATUS_OUTDATED,
                [SELECT Status__c FROM Promoted_User_Story__c WHERE Promotion__c = :promotion.Id]
                .Status__c,
                'Promoted user story status should be Outdated'
            );

            System.assertEquals(
                PromotionConstants.STATUS_OUTDATED,
                [SELECT Status__c FROM Promoted_User_Story__c WHERE Promotion__c = :backPromotion.Id]
                .Status__c,
                'Back Promoted user story status should be Outdated'
            );

            System.assertEquals(
                PromotionConstants.STATUS_CANCELLED,
                [SELECT Status__c FROM Promotion__c WHERE Id = :backPromotion.Id]
                .Status__c,
                'Back Promotion Status should be Cancelled'
            );
        }
    }

    @isTest
    private static void updatedBundleChildStory() {
        User u = getRunAsUser();
        System.runAs(u) {
            TestUtilities.assignLicense(u.Username, true, true, true, true, true);

            // Setup
            setup();
            bundlingJob();

            // Exercise
            User_Story__c bundle = fetchStoriesByRecordType('Utility').get(0);
            bundle.Status__c = 'Rejected';
            update bundle;

            //Verify
            User_Story__c us = fetchStoriesByRecordType('User_Story').get(0);
            System.assertEquals('Rejected', us.Status__c);
        }
    }

    @isTest
    private static void undoBundlingOnCancel() {
        User u = getRunAsUser();
        System.runAs(u) {
            TestUtilities.assignLicense(u.Username, true, true, true, true, true);

            // Setup
            setup();
            bundlingJob();

            // Exercise
            User_Story__c bundle = fetchStoriesByRecordType('Utility').get(0);
            bundle.Status__c = 'Cancelled';
            bundle.Cancellation_Reason__c = 'Cancelled';
            update bundle;

            //Verify
            bundle = fetchStoriesByRecordType('Utility').get(0);
            System.assertEquals(true, bundle.Stop_Indexing_Metadata__c);

            User_Story__c s = fetchStoriesByRecordType('User_Story').get(0);
            System.assertEquals(false, s.Stop_Indexing_Metadata__c);

            Artifact_Version__c v = [
                SELECT Id, Status__c, (SELECT Id FROM Bundled_Stories__r)
                FROM Artifact_Version__c
                WHERE User_Story__c = :bundle.Id
                LIMIT 1
            ];
            System.assertEquals('Cancelled', v.Status__c);
            System.assert(v.Bundled_Stories__r.isEmpty());
        }
    }

    @isTest
    private static void validateBundleChildCancellation() {
        User u = getRunAsUser();
        Exception expectedException = null;

        System.runAs(u) {
            TestUtilities.assignLicense(u.Username, true, true, true, true, true);

            // Setup

            setup();
            bundlingJob();

            User_Story__c s = fetchStoriesByRecordType('User_Story').get(0);
            s.Status__c = 'Cancelled';
            s.Cancellation_Reason__c = 'Cancelled';

            // Exercise

            try {
                update s;
            } catch (Exception ex) {
                expectedException = ex;
            }
        }
    }

    @isTest
    private static void allowUpdateAfterBundleCancel() {
        User u = getRunAsUser();
        System.runAs(u) {
            TestUtilities.assignLicense(u.Username, true, true, true, true, true);

            // Setup
            setup();
            bundlingJob();
            User_Story__c s = fetchStoriesByRecordType('Utility').get(0);
            s.Status__c = 'Cancelled';
            s.Cancellation_Reason__c = 'Cancelled';
            update s;

            // Exercise
            s.Status__c = 'Approved';
            update s;

            //Verify
            User_Story__c bundle = fetchStoriesByRecordType('Utility').get(0);
            System.assertEquals('Approved', bundle.Status__c);
        }
    }

    @isTest
    private static void testUserStoryDependencies() {
        User currentUser = Database.query(STANDARD_USER_QUERY);
        TestUtilities.assignLicense(currentUser.Username, true, true, true, true, true);
        System.runAs(currentUser) {
            TestUtilities tu = new TestUtilities();
            // Setup

            tu.insertSObject('Team__c', new Map<String, Object>{ 'Name' => 'Team1', 'Active__c' => true });
            tu.insertSObject('Team__c', new Map<String, Object>{ 'Name' => 'Team2', 'Active__c' => true });
            Id team1Id = tu.item('Team__c', 0).Id;
            Id team2Id = tu.item('Team__c', 1).Id;

            Project__c testProject = CMTestMethodUtilities.createProject('my project');
            insert testProject;

            Sprint__c testSprint = CMTestMethodUtilities.createSprint('my sprint');
            testSprint.Project__c = testProject.Id;
            insert testSprint;

            Release__c testRelease = CMTestMethodUtilities.createRelease('my release');
            insert testRelease;

            Release__c testReleaseForUpdate = CMTestMethodUtilities.createRelease('my release');
            insert testReleaseForUpdate;

            List<User_Story__c> userStories = new List<User_Story__c>();
            List<User_Story__c> userStoriesToDelete = new List<User_Story__c>();
            for (Integer i = 0; i < 10; i++) {
                User_Story__c testUserStory = CMTestMethodUtilities.createUserStory('test');
                testUserStory.Sprint__c = testSprint.Id;
                testUserStory.Project__c = null;
                testUserStory.Team__c = team1Id;
                testUserStory.Story_Points_Other__c = 3;
                testUserStory.Release__c = testRelease.Id;
                userStories.add(testUserStory);
            }
            insert userStories;
            List<Team_Dependency__c> userStoryDependencies = new List<Team_Dependency__c>();
            for (Integer i = 0; i < 5; i++) {
                Team_Dependency__c testTeamDepency = new Team_Dependency__c();
                testTeamDepency.Provider_User_Story__c = userStories.get(i).Id;
                testTeamDepency.Dependent_User_Story__c = userStories.get(5 + i).Id;
                userStoryDependencies.add(testTeamDepency);
            }
            insert userStoryDependencies;
            userStoriesToDelete.add(userStories[0]);
            userStoriesToDelete.add(userStories[6]);

            // Exercise

            // Exercise

            Test.startTest();
            userStories.get(0).Release__c = testReleaseForUpdate.Id;
            userStories.get(0).Status__c = 'Completed';
            userStories.get(5).Release__c = testReleaseForUpdate.Id;
            userStories.get(0).Team__c = team2Id;
            userStories.get(5).Team__c = team2Id;
            update userStories;
            Test.stopTest();

            // Verify

            Team_Dependency__c updatedDependency = [
                SELECT Id, Dependency_Status__c, Release__c, Child_User_Story_Release__c, Provider_Team__c, Dependent_Team__c
                FROM Team_Dependency__c
                WHERE Provider_User_Story__c = :userStories.get(0).Id
                LIMIT 1
            ];

            System.assertEquals(testReleaseForUpdate.Id, updatedDependency.Release__c, 'Dependency Parent US Release should match');
            System.assertEquals(testReleaseForUpdate.Id, updatedDependency.Child_User_Story_Release__c, 'Dependency Child US Release should match');
            System.assertEquals(team2Id, updatedDependency.Provider_Team__c, 'Dependency Parent US Team should match');
            System.assertEquals(team2Id, updatedDependency.Dependent_Team__c, 'Dependency Child US Team should match');
            System.assertEquals('Completed', updatedDependency.Dependency_Status__c, 'Depedency Status should be completed');

            delete userStoriesToDelete;
            List<Team_Dependency__c> updatedDependencies = [
                SELECT Id, Dependency_Status__c, Release__c, Child_User_Story_Release__c
                FROM Team_Dependency__c
                WHERE Provider_User_Story__c = :userStories.get(0).Id OR Provider_User_Story__c = :userStories.get(1).Id
            ];
            System.assertEquals(0, updatedDependencies.size(), 'All related Dependencies should be deleted');
            System.assertEquals(0, updatedDependencies.size(), 'All related Dependencies should be deleted');
        }

    }

    @isTest
    private static void promoteAndDeployMCUserStory() {
        System.runAs(getUser()) {
            // Setup
            new JobTemplate().name('JOB_TEMPLATE_PROMOTION').mockAutomation('Promotion').add(new JobStep().order(1).type('Function')).persist();

            Credential dev1Credential = new Credential();
            Environment dev1 = new Environment().name('dev1').type('Sandbox').platform('Other').add(dev1Credential);
            Credential intCredential = new Credential();
            Environment integration = new Environment().name('int').type('Sandbox').platform('Other').add(intCredential);
            new Pipeline()
                .setPlatform('Other')
                .add(new Connection(dev1, integration).branch('dev1'))
                .add(new Project().add(new UserStory().credential(dev1Credential).add(new UserStoryMetadata().name('TestClass').type('ApexClass'))))
                .persist();

            User_Story__c userStory = [SELECT Id FROM User_Story__c LIMIT 1];

            // Exercise

            Test.startTest();
            userStory.Promote_and_Deploy__c = true;
            update userStory;
            Test.stopTest();

            // Verify
            List<Promotion__c> promotions = [SELECT Id, Destination_Environment__c FROM Promotion__c];
            System.assertEquals(1, promotions.size(), 'A promotion should be created');
            Environment__c intEnv = [SELECT Id FROM Environment__c WHERE Name = 'int'];
            System.assertEquals(intEnv.Id, promotions[0].Destination_Environment__c, 'Destination environment should match');
        }
    }

    @isTest
    private static void promoteAndDeployMCUserStoriesWithDifferentProject() {
        System.runAs(getUser()) {
            // Setup
            new JobTemplate().name('JOB_TEMPLATE_PROMOTION').mockAutomation('Promotion').add(new JobStep().order(1).type('Function')).persist();

            Credential dev1Credential = new Credential();
            Environment dev1 = new Environment().name('dev1').type('Sandbox').platform('Other').add(dev1Credential);
            Credential intCredential = new Credential();
            Environment integration = new Environment().name('int').type('Sandbox').platform('Other').add(intCredential);
            new Pipeline()
                .setPlatform('Other')
                .add(new Connection(dev1, integration).branch('dev1'))
                .add(new Project().add(new UserStory().credential(dev1Credential).add(new UserStoryMetadata().name('TestClass').type('ApexClass'))))
                .add(new Project().add(new UserStory().credential(dev1Credential).add(new UserStoryMetadata().name('TestClass').type('ApexClass'))))
                .persist();

            List<User_Story__c> userStories = [SELECT Id FROM User_Story__c];
            for (User_Story__c userStory : userStories) {
                userStory.Promote_and_Deploy__c = true;
            }

            Exception expectedException;

            // Exercise

            Test.startTest();
            try {
                update userStories;
            } catch (Exception ex) {
                expectedException = ex;
            }

            Test.stopTest();

            // Verify
            System.assertNotEquals(null, expectedException, 'An exception should be thrown');
        }
    }

    @isTest
    private static void promoteAndDeployMCUserStoriesWithDifferentEnvironments() {
        System.runAs(getUser()) {
            // Setup
            new JobTemplate().name('JOB_TEMPLATE_PROMOTION').mockAutomation('Promotion').add(new JobStep().order(1).type('Function')).persist();

            Credential dev1Credential = new Credential();
            Environment dev1 = new Environment().name('dev1').type('Sandbox').platform('Other').add(dev1Credential);
            Credential intCredential = new Credential();
            Environment integration = new Environment().name('int').type('Sandbox').platform('Other').add(intCredential);
            new Pipeline()
                .setPlatform('Other')
                .add(new Connection(dev1, integration).branch('dev1'))
                .add(
                    new Project()
                        .add(new UserStory().credential(dev1Credential).add(new UserStoryMetadata().name('TestClass').type('ApexClass')))
                        .add(new UserStory().credential(intCredential).add(new UserStoryMetadata().name('TestClass').type('ApexClass')))
                )
                .persist();

            List<User_Story__c> userStories = [SELECT Id FROM User_Story__c];
            for (User_Story__c userStory : userStories) {
                userStory.Promote_and_Deploy__c = true;
            }

            Exception expectedException;

            // Exercise

            Test.startTest();
            try {
                update userStories;
            } catch (Exception ex) {
                expectedException = ex;
            }

            Test.stopTest();

            // Verify
            System.assertNotEquals(null, expectedException, 'An exception should be thrown');
            String errorMessage = expectedException.getMessage();
            System.assert(errorMessage.contains(Label.ERROR_PROMOTION_DIFFERENT_PROJECT_OR_ENVIRONMENT), 'Wrong error message: ' + errorMessage);
        }
    }

    @IsTest
    private static void promoteExcludedUserStories() {
        System.runAs(getUser()) {
            // Setup
            new Pipeline()
                .setPlatform('Other')
                .add(new Project().add(new UserStory().credential(new Credential(new Environment().name('dev1').type('Sandbox').platform('Other')))));

            new Pipeline()
                .setPlatform('Salesforce')
                .add(
                    new Project()
                        .add(new UserStory().credential(new Credential(new Environment().name('dev1').type('Sandbox').platform('Salesforce'))))
                )
                .persist();

            User_Story__c userStoryDOP = [SELECT Id FROM User_Story__c WHERE Platform__c = 'Other' LIMIT 1];
            User_Story__c userStorySF = [SELECT Id FROM User_Story__c WHERE Platform__c = 'Salesforce' LIMIT 1];

            userStoryDOP.Exclude_From_CBM__c = true;
            userStorySF.Exclude_From_CBM__c = true;

            update new List<User_Story__c>{ userStorySF, userStoryDOP };

            // Exercise
            Exception expectedException1;
            Exception expectedException2;
            Exception expectedException3;
            Test.startTest();
            try {
                userStoryDOP.Promote_Change__c = true;
                update userStoryDOP;
            } catch (Exception ex) {
                expectedException1 = ex;
            }
            try {
                userStoryDOP.Promote_and_Deploy__c = true;
                update userStoryDOP;
            } catch (Exception ex) {
                expectedException2 = ex;
            }
            try {
                userStorySF.Promote_Change__c = true;
                update userStorySF;
            } catch (Exception ex) {
                expectedException3 = ex;
            }
            Test.stopTest();

            // Verify
            System.assertNotEquals(null, expectedException1, 'An exception should be thrown');
            System.assertNotEquals(null, expectedException2, 'An exception should be thrown');
            System.assertEquals(null, expectedException3, 'Existing behavior should not change');
            System.assertEquals(StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION, expectedException1.getDmlType(0), 'Exception type does not match.');
            System.assertEquals(StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION, expectedException2.getDmlType(0), 'Exception type does not match.');
        }
    }

    @IsTest
    private static void submitUserStories() {
        System.runAs(getUser()) {
            // Setup
            createPipelineAndAutomationRule();
            User_Story__c userStory = getUserStory();
            Exception exceptedException;

            // Exercise
            Test.startTest();

            try {
                userStory.Org_Credential__c = null;
                userStory.Environment__c = null;
                userStory.Promote_Change__c = true;
                update userStory;
            } catch (Exception ex) {
                exceptedException = ex;
            }

            System.assertNotEquals(null, exceptedException, 'An exception should be thrown');

            userStory = getUserStory();
            userStory.User_Story_Title__c = 'Include Title';
            userStory.Promote_Change__c = true;
            update userStory;

            Test.stopTest();

            // Verify
            List<Automation_Event__c> events = [SELECT Id, Action_Name__c, Payload__c FROM Automation_Event__c LIMIT 1];
            System.assertEquals(ActionConstants.SUBMIT_USER_STORIES, events[0].Action_Name__c, 'Event should be created with source Action');
            System.assertEquals(true, events[0].Payload__c != null, 'Payload should exist');
        }
    }

    // HELPER

    private static User getRunAsUser() {
        TestDataFactory.createUsers();
        User copadoUser = [SELECT Id, Username FROM User WHERE Email = 'test2@test2.com' LIMIT 1];

        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Copado_User'];
        insert new PermissionSetAssignment(AssigneeId = copadoUser.Id, PermissionSetId = ps.Id);

        return copadoUser;
    }

    private static List<User_Story__c> fetchStoriesByRecordType(String developerName) {
        return [SELECT Id, Status__c, Stop_Indexing_Metadata__c FROM User_Story__c WHERE RecordType.DeveloperName = :developerName];
    }

    private static void setup() {
        Org__c orgCred = TestDataFactory.createOrgCredentials('myUsrName', null, 'Sandbox');
        orgCred.Default_Credential__c = true;
        orgCred.SFDC_Org_ID__c = '00D1i00000095cEEAQ_0050X000007h8hTQAQ_6';
        insert orgCred;

        update orgCred;

        Environment__c env = [SELECT Id FROM Environment__c LIMIT 1];

        Git_Repository__c repo = TestDataFactory.createGitRepository();
        insert repo;

        Git_Backup__c snapshot = TestDataFactory.createGitBackup('SnapShot1', orgCred.Id, repo.Id);
        insert snapshot;

        Deployment_Flow__c pipeline = TestDataFactory.createDeploymentFlow('Test Pipeline', true, repo.Id, false);
        insert pipeline;

        Project__c project = TestDataFactory.createProject('test project', pipeline.Id, false);
        insert project;

        List<User_Story__c> userStories = TestDataFactory.createUserStories(2, 'US', 'Approved', null, project.Id, env.Id, orgCred.Id, 'User_Story');
        insert userStories;
    }

    private static void bundlingJob() {
        List<Artifact__c> pkg = TestDataFactory.createPackages(1, 'pkg', 'User_Story_Bundle');
        insert pkg;

        List<Artifact_Version__c> version = TestDataFactory.createPackageVersions(1, 'pkgVersion', pkg.get(0).Id);
        insert version;

        List<User_Story__c> stories = [
            SELECT Id, Status__c, Project__c, Environment__c, Org_Credential__c
            FROM User_Story__c
            WHERE RecordType.DeveloperName = 'User_Story'
        ];
        List<Bundled_Story__c> bundledStories = TestDataFactory.createBundledStories(version.get(0).Id, stories);
        insert bundledStories;

        List<User_Story__c> bundleStory = TestDataFactory.createUserStories(
            1,
            'USB',
            'Approved',
            null,
            stories[0].Project__c,
            stories[0].Environment__c,
            stories[0].Org_Credential__c,
            'Utility'
        );
        bundleStory.get(0).Is_Bundle__c = true;
        insert bundleStory;

        version.get(0).User_Story__c = bundleStory.get(0).Id;
        update version;
    }

    private static User getUser() {
        return [SELECT Id FROM User WHERE Profile.Name = 'Standard User' AND Alias = 'TestUsr1' ORDER BY CreatedDate DESC LIMIT 1];
    }

    private static Deployment_Flow__c getPipeline() {
        return [SELECT Id FROM Deployment_Flow__c LIMIT 1];
    }

    private static User_Story__c getUserStory() {
        return [SELECT Id, User_Story_Title__c, Project__c, Environment__c, Promote_Change__c FROM User_Story__c WHERE Platform__c = 'Other' LIMIT 1];
    }

    private static Automation_Rule__c createPipelineAndAutomationRule() {
        Credential dev1Credential = new Credential();
        Environment dev1 = new Environment().name('dev1').type('Sandbox').platform('Other').add(dev1Credential);
        Environment dev2 = new Environment().name('dev2').type('Sandbox').platform('Other').add(new Credential());
        Credential intCredential = new Credential();
        Environment integration = new Environment().name('int').type('Sandbox').platform('Other').add(intCredential);

        new Pipeline()
            .mainBranch('main')
            .setPlatform('Other')
            .add(new Connection(dev1, integration).branch('dev1'))
            .add(new Connection(dev2, integration).branch('dev2'))
            .add(new Project().add(new UserStory().credential(dev1Credential).add(new UserStoryMetadata().name('TestClass').type('ApexClass'))))
            .persist();

        Automation_Rule__c automationRule = (Automation_Rule__c) new AutomationRule()
            .pipeline(getPipeline().Id)
            .active()
            .sourceAction(ActionConstants.SUBMIT_USER_STORIES)
            .automatedAction(ActionConstants.PROMOTION)
            .sourceActionStatus(AutomationRuleConstants.SOURCE_ACTION_STATUS_SUCCESSFUL)
            .connector(AutomationRuleConstants.AUTOMATION_CONNECTOR_CUSTOM)
            .execution(AutomationRuleConstants.EXECUTION_IMMEDIATE)
            .filterCriteria(getFilterCriteria())
            .persist();
        return automationRule;
    }

    private static String getFilterCriteria() {
        String objectName = Schema.SObjectType.User_Story__c.getName();
        return '{"mainObject":"' +
            objectName +
            '","isCustom":true,"whereCondition":"User_Story_Title__c != null AND Team__c = null AND Close_Date__c = null"}';
    }
}