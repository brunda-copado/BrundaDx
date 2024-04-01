@IsTest
private class AutoCreateTestsTest {
    @TestSetup
    private static void setup() {
        TestUtilities.getAllMultilicense();
        User user = (User) new User_t().assign(new PermissionSetAssignment_t().copadoUser()).persist();
        System.runAs(user) {
            new CopadoLicense().user(user).enableAll().persist();
            createData();
        }
    }

    @IsTest
    private static void autoCreateForPromotion() {
        System.runAs(getRunAsUser()) {
            // Setup
            ExtensionConfiguration__c extensionConfiguration = getExtensionConfiguration();
            TestTool__mdt testTool = createTestTool();

            Promotion__c promotion = (Promotion__c) new Promotion()
                .projectId([SELECT Id FROM Project__c LIMIT 1].Id)
                .sourceEnvId([SELECT Id FROM Environment__c WHERE Name = 'dev1' LIMIT 1].Id)
                .persist();
            Id promotionId = promotion.Id;

            // Exercise
            Test.startTest();
            Test__c autoCreatedTest = new AutoCreateTests(
                    promotionId,
                    promotionId.getSobjectType().getDescribe(SObjectDescribeOptions.DEFERRED).getLocalName()
                )
                .execute(extensionConfiguration.Id, testTool);
            Test.stopTest();

            // Verify
            System.assertEquals(promotionId, autoCreatedTest.Promotion__c, 'Promotion Id should match');
        }
    }

    @IsTest
    private static void autoCreateForApplication() {
        System.runAs(getRunAsUser()) {
            // Setup
            ExtensionConfiguration__c extensionConfiguration = getExtensionConfiguration();
            TestTool__mdt testTool = createTestTool();

            Application__c application = new Application__c();
            insert application;
            Id applicationId = application.Id;

            // Exercise
            Test.startTest();
            Test__c autoCreatedTest = new AutoCreateTests(
                    applicationId,
                    applicationId.getSobjectType().getDescribe(SObjectDescribeOptions.DEFERRED).getLocalName()
                )
                .execute(extensionConfiguration.Id, testTool);
            Test.stopTest();

            // Verify
            System.assertEquals(applicationId, autoCreatedTest.Application__c, 'Application Id should match');
        }
    }

    @IsTest
    private static void autoCreateForFeature() {
        System.runAs(getRunAsUser()) {
            // Setup
            ExtensionConfiguration__c extensionConfiguration = getExtensionConfiguration();
            TestTool__mdt testTool = createTestTool();

            Application_Feature__c feature = new Application_Feature__c();
            insert feature;
            Id featureId = feature.Id;

            // Exercise
            Test.startTest();
            Test__c autoCreatedTest = new AutoCreateTests(
                    featureId,
                    featureId.getSobjectType().getDescribe(SObjectDescribeOptions.DEFERRED).getLocalName()
                )
                .execute(extensionConfiguration.Id, testTool);
            Test.stopTest();

            // Verify
            System.assertEquals(featureId, autoCreatedTest.Feature__c, 'Feature Id should match');
        }
    }

    @IsTest
    private static void autoCreateForUserStoryCommit() {
        System.runAs(getRunAsUser()) {
            // Setup
            ExtensionConfiguration__c extensionConfiguration = getExtensionConfiguration();
            TestTool__mdt testTool = createTestTool();

            User_Story_Commit__c usCommit = createUserStoryCommit();
            Id usCommitId = usCommit.Id;
            Id userStoryId = usCommit.User_Story__c;

            // Exercise
            Test.startTest();
            Test__c autoCreatedTest = new AutoCreateTests(
                    usCommitId,
                    usCommitId.getSobjectType().getDescribe(SObjectDescribeOptions.DEFERRED).getLocalName()
                )
                .execute(extensionConfiguration.Id, testTool);
            Test.stopTest();

            // Verify
            System.assertEquals(userStoryId, autoCreatedTest.User_Story__c, 'User Story Id should match');
        }
    }

    @IsTest
    private static void autoCreateForOther() {
        System.runAs(getRunAsUser()) {
            // Setup
            ExtensionConfiguration__c extensionConfiguration = getExtensionConfiguration();
            TestTool__mdt testTool = createTestTool();

            Project__c project = [SELECT Id FROM Project__c LIMIT 1];
            Id projectId = project.Id;

            // Exercise
            Test.startTest();
            Test__c autoCreatedTest = new AutoCreateTests(
                    projectId,
                    projectId.getSobjectType().getDescribe(SObjectDescribeOptions.DEFERRED).getLocalName()
                )
                .execute(extensionConfiguration.Id, testTool);
            Test.stopTest();

            // Verify
            System.assertEquals(projectId, autoCreatedTest.Parent_Id__c, 'Parent Id should match');
        }
    }

    private static User getRunAsUser() {
        return [SELECT Id FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1];
    }

    private static void createData() {
        insert new ExtensionConfiguration__c(
            Name = 'Extension Configuration 1',
            ExtensionApplication__c = 'Test',
            ExtensionTool__c = 'Manual Tests',
            Active__c = true
        );

        Credential dev1Credential = new Credential();
        Environment dev1 = new Environment().name('dev1').type('Sandbox').platform('Other').add(dev1Credential);
        Credential intCredential = new Credential();
        Environment integration = new Environment().name('int').type('Sandbox').platform('Other').add(intCredential);

        new Pipeline()
            .active(true)
            .mainBranch('main')
            .setPlatform('Other')
            .add(new Connection(dev1, integration).branch('dev1'))
            .add(new Project().add(new UserStory().credential(dev1Credential).add(new UserStoryMetadata().name('TestClass').type('ApexClass'))))
            .persist();
    }

    private static TestTool__mdt createTestTool() {
        TestTool__mdt mockTestTool = new TestTool__mdt(
            MasterLabel = 'None',
            JobTemplate__c = 'None',
            TestType__c = 'Mock Type',
            Automate_Test_Readiness__c = true,
            Test_Readiness_Logic__c = 'MockTestReadinessLogic'
        );
        return mockTestTool;
    }

    private static User_Story_Commit__c createUserStoryCommit() {
        Id orgId = [SELECT Id FROM Org__c WHERE Environment__r.Name = 'dev1' LIMIT 1].Id;
        Git_Repository__c repo = new Git_Repository__c();
        repo.Name = 'Test repo';
        insert repo;
        Git_Backup__c gitBackup = new Git_Backup__c();
        gitBackup.Name = 'Test backup';
        gitBackup.Git_Repository__c = repo.Id;
        gitBackup.Org__c = orgId;
        insert gitBackup;
        Git_Org_Commit__c gitOrgCommit = new Git_Org_Commit__c();
        gitOrgCommit.Commit_Id__c = 'Bundle Metadata';
        gitOrgCommit.Commit_Date__c = Date.today();
        gitOrgCommit.Git_Backup__c = gitBackup.Id;
        gitOrgCommit.Org__c = orgId;
        gitOrgCommit.Status__c = 'Complete';
        gitOrgCommit.Git_Operation__c = 'Commit Files';
        insert gitOrgCommit;
        User_Story_Commit__c usCommit = new User_Story_Commit__c(
            User_Story__c = [SELECT Id FROM User_Story__c LIMIT 1]
            .Id,
            Snapshot_Commit__c = gitOrgCommit.Id
        );
        insert usCommit;
        return usCommit;
    }

    private static ExtensionConfiguration__c getExtensionConfiguration() {
        return [SELECT Id FROM ExtensionConfiguration__c LIMIT 1];
    }
}