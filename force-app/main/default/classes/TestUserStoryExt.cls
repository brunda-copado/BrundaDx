@SuppressWarnings('PMD')
@IsTest
private with sharing class TestUserStoryExt {
    @TestSetup
    private static void setup() {
        User standardUser = setupUser();
        System.runAs(standardUser) {
            setupLicense();
        }
    }

    @IsTest
    private static void userStoryHeader() {
        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            // Setup
            TestUtilities tu = createDefaultTestData();

            // Exercise
            Test.startTest();
            Test.setCurrentPage(Page.UserStory);
            ApexPages.StandardController sc = new ApexPages.StandardController(tu.item('User_Story__c', 0));
            UserStoryExt controller = new UserStoryExt(sc);
            controller.getDeploymentFlowSteps();
            Test.stopTest();

            // Verify
            System.assertEquals(null, controller.userStoriesAheadBehindTitle);
        }
    }

    @IsTest
    private static void testRelatedAlerts() {
        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            // Setup
            TestUtilities tu = createNoChangesTestData();

            // Exercise
            Test.startTest();
            Test.setCurrentPage(Page.UserStory);
            UserStoryExt ext1 = new UserStoryExt(new ApexPages.StandardController(tu.item('User_Story__c', 0)));
            Test.stopTest();

            // Veritfy
            System.assertEquals(false, ext1.showLicenseError, 'There should not be any License error');
            System.assertEquals(true, testMethodUtilities.hasMessage(Label.COMMIT_NO_CHANGES));
        }
    }

    @IsTest
    private static void userStoryFields() {
        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            // Setup
            TestUtilities tu = createNoChangesTestData();

            // Exercise
            Test.startTest();
            Test.setCurrentPage(Page.UserStory);
            List<String> fields = new UserStoryExt(new ApexPages.StandardController(tu.item('User_Story__c', 0))).fields();
            Test.stopTest();

            // Veritfy
            System.assert(!fields.isEmpty(), 'There should be several controller fields added by the page.');
        }
    }

    @IsTest
    private static void testLicenseError() {
        // Setup
        TestUtilities tu = createNoChangesTestData();

        // Exercise
        Test.startTest();
        Test.setCurrentPage(Page.UserStory);
        UserStoryExt ext1 = new UserStoryExt(new ApexPages.StandardController(tu.item('User_Story__c', 0)));
        Test.stopTest();

        // Veritfy
        System.assertEquals(true, ext1.showLicenseError, 'There should be a License error');
    }

    @IsTest
    private static void errorInDataCommit() {
        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            // Setup
            createDataCommitsTestData();
            User_Story__c userStory = getUserStory();

            // Excercise
            Test.startTest();
            Test.setCurrentPage(Page.UserStory);
            new UserStoryExt(new ApexPages.StandardController(userStory));
            Test.stopTest();

            // Verify
            System.assertEquals(true, testMethodUtilities.hasMessage(Label.DataCommitNoChanges));
        }
    }

    private static TestUtilities createDefaultTestData() {
        TestUtilities tu = new TestUtilities();

        // Create current sprint record
        tu.insertSObject(
            'Sprint__c',
            new Map<String, Object>{ 'Name' => 'Sprint 2', 'Start_Date__c' => Date.today().addDays(-8), 'End_Date__c' => Date.today().addDays(8) }
        );

        // Create environments record
        tu.createSObject('Environment__c', new Map<String, Object>{ 'Name' => 'Dev1', 'org_id__c' => '000000000000000001' });
        tu.createSObject('Environment__c', new Map<String, Object>{ 'Name' => 'Dev2', 'org_id__c' => '000000000000000002' });
        tu.createSObject('Environment__c', new Map<String, Object>{ 'Name' => 'Int', 'org_id__c' => '000000000000000003' });
        tu.createSObject('Environment__c', new Map<String, Object>{ 'Name' => 'UAT', 'org_id__c' => '000000000000000004' });
        tu.createSObject('Environment__c', new Map<String, Object>{ 'Name' => 'Prod', 'org_id__c' => '000000000000000005' });
        insert new List<SObject>{
            tu.item('Environment__c', 0),
            tu.item('Environment__c', 1),
            tu.item('Environment__c', 2),
            tu.item('Environment__c', 3),
            tu.item('Environment__c', 4)
        };

        // Create org credentials record
        tu.createSObject(
            'Org__c',
            new Map<String, Object>{
                'Name' => 'OrgDev1',
                'Org_Type__c' => 'Sandbox',
                'SFDC_Org_ID__c' => '000000000000000001',
                'Token__c' => null,
                'Username__c' => null,
                'Validated_Date__c' => system.now(),
                'Environment__c' => tu.item('Environment__c', 0).Id
            }
        );
        tu.createSObject(
            'Org__c',
            new Map<String, Object>{
                'Name' => 'OrgDev2',
                'Org_Type__c' => 'Sandbox',
                'SFDC_Org_ID__c' => '000000000000000002',
                'Token__c' => null,
                'Username__c' => null,
                'Validated_Date__c' => System.now(),
                'Environment__c' => tu.item('Environment__c', 1).Id
            }
        );
        tu.createSObject(
            'Org__c',
            new Map<String, Object>{
                'Name' => 'OrgInt',
                'Org_Type__c' => 'Sandbox',
                'SFDC_Org_ID__c' => '000000000000000003',
                'Token__c' => null,
                'Username__c' => null,
                'Validated_Date__c' => System.now(),
                'Environment__c' => tu.item('Environment__c', 2).Id
            }
        );
        tu.createSObject(
            'Org__c',
            new Map<String, Object>{
                'Name' => 'OrgUAT',
                'Org_Type__c' => 'Sandbox',
                'SFDC_Org_ID__c' => '000000000000000004',
                'Token__c' => null,
                'Username__c' => null,
                'Validated_Date__c' => System.now(),
                'Environment__c' => tu.item('Environment__c', 3).Id
            }
        );
        tu.createSObject(
            'Org__c',
            new Map<String, Object>{
                'Name' => 'OrgProd',
                'Org_Type__c' => 'Production',
                'SFDC_Org_ID__c' => '000000000000000005',
                'Token__c' => null,
                'Username__c' => null,
                'Validated_Date__c' => System.now(),
                'Environment__c' => tu.item('Environment__c', 4).Id
            }
        );
        insert new List<SObject>{ tu.item('Org__c', 0), tu.item('Org__c', 1), tu.item('Org__c', 2), tu.item('Org__c', 3), tu.item('Org__c', 4) };

        // Create deployment flow record
        tu.insertSObject('Deployment_Flow__c', new Map<String, Object>{ 'Name' => 'Deployment Flow', 'Active__c' => true });

        // Create deployment flow steps record
        tu.createSObject(
            'Deployment_Flow_Step__c',
            new Map<String, Object>{
                'Source_Environment__c' => tu.item('Environment__c', 0).Id,
                'Destination_Environment__c' => tu.item('Environment__c', 2).Id,
                'Deployment_Flow__c' => tu.item('Deployment_Flow__c', 0).Id
            }
        );
        tu.createSObject(
            'Deployment_Flow_Step__c',
            new Map<String, Object>{
                'Source_Environment__c' => tu.item('Environment__c', 1).Id,
                'Destination_Environment__c' => tu.item('Environment__c', 2).Id,
                'Deployment_Flow__c' => tu.item('Deployment_Flow__c', 0).Id
            }
        );
        tu.createSObject(
            'Deployment_Flow_Step__c',
            new Map<String, Object>{
                'Source_Environment__c' => tu.item('Environment__c', 2).Id,
                'Destination_Environment__c' => tu.item('Environment__c', 3).Id,
                'Deployment_Flow__c' => tu.item('Deployment_Flow__c', 0).Id
            }
        );
        tu.createSObject(
            'Deployment_Flow_Step__c',
            new Map<String, Object>{
                'Source_Environment__c' => tu.item('Environment__c', 3).Id,
                'Destination_Environment__c' => tu.item('Environment__c', 4).Id,
                'Deployment_Flow__c' => tu.item('Deployment_Flow__c', 0).Id
            }
        );
        insert new List<SObject>{
            tu.item('Deployment_Flow_Step__c', 0),
            tu.item('Deployment_Flow_Step__c', 1),
            tu.item('Deployment_Flow_Step__c', 2),
            tu.item('Deployment_Flow_Step__c', 3)
        };

        // Create project record
        tu.insertSObject(
            'Project__c',
            new Map<String, Object>{ 'Name' => 'My project', 'Deployment_Flow__c' => tu.item('Deployment_Flow__c', 0).Id }
        );

        // Create 28 user story to fill sobjectlist
        tu.insertSObjects(
            'User_Story__c',
            28,
            new Map<String, Object>{
                'User_Story_Title__c' => 'us-0000000',
                'Status__c' => 'Approved',
                'Sprint__c' => tu.item('Sprint__c', 0).Id,
                'Story_Points_SFDC__c' => 2,
                'Project__c' => tu.item('Project__c', 0).Id,
                'Environment__c' => tu.item('Environment__c', 0).Id
            }
        );

        return tu;
    }

    private static TestUtilities createNoChangesTestData() {
        TestUtilities tu = new TestUtilities();
        tu.insertSObjects(
            'User_Story__c',
            1,
            new Map<String, Object>{ 'User_Story_Title__c' => 'Test No Changes', 'Status__c' => 'Approved', 'Story_Points_SFDC__c' => 2 }
        );

        tu.insertSObject(
            'Org__c',
            new Map<String, Object>{
                'Name' => 'OrgProdNoCommit',
                'Org_Type__c' => 'Production',
                'SFDC_Org_ID__c' => 'SFDC_OrgId56',
                'Token__c' => null,
                'Username__c' => null,
                'Validated_Date__c' => System.now()
            }
        );

        tu.insertSObjects('Git_Org_Commit__c', 1, new Map<String, Object>{ 'Status__c' => 'No changes', 'Org__c' => tu.item('Org__c', 0).Id });

        tu.insertSObjects(
            'User_Story_Commit__c',
            1,
            new Map<String, Object>{ 'User_Story__c' => tu.item('User_Story__c', 0).Id, 'Snapshot_Commit__c' => tu.item('Git_Org_Commit__c', 0).Id }
        );

        return tu;
    }

    private static void createDataCommitsTestData() {
        List<Environment__c> environments = TestDataFactory.createEnvironments(1);
        List<Org__c> orgs = TestDataFactory.createOrgCredentials(1, UserInfo.getUserName(), environments);
        for (Org__c org : orgs) {
            org.SFDC_Org_ID__c = UserInfo.getOrganizationId() + '_' + UserInfo.getUserId();
        }
        update orgs;
        User_Story__c userStory = TestDataFactory.createUserStory('test', null, null, null, null, orgs[0].Id);
        insert userStory;
        Data_Template__c dataTemplate = TestDataFactory.createDataTemplate('test', orgs.get(0).Id, 'Account', null, null, null, null, null);
        List<Data_Set__c> dataSets = new List<Data_Set__c>();
        List<Deployment__c> deployments = new List<Deployment__c>();
        for (Integer i = 0; i < 2; i++) {
            dataSets.add(new Data_Set__c(Name = 'Data Set ' + i, Data_Template__c = dataTemplate.Id));
            deployments.add(createDeployment(orgs[0].Id));
        }
        insert dataSets;
        insert deployments;
        for(Integer i = 0; i < deployments.size(); i++){
            deployments[i].Status__c = 'Completed with Errors';
        }
        update deployments;
        List<User_Story_Data_Commit__c> dataCommits = new List<User_Story_Data_Commit__c>();
        for (Integer i = 0; i < 2; i++) {
            Data_Set__c dataSet = dataSets[i];
            Deployment__c deployment = deployments[i];
            dataCommits.add(createDataCommit(userStory.Id, dataSet.Id, deployment.Id));
        }
        insert dataCommits;
    }

    private static Deployment__c createDeployment(Id orgId) {
        Deployment__c deployment = TestDataFactory.createDeployment(
            'generate data set',
            Schema.SObjectType.Deployment__c.getRecordTypeInfosByDeveloperName().get('Advanced_multi_step').getRecordTypeId(),
            orgId
        );
        deployment.Status__c = 'Completed with Errors';
        return deployment;
    }

    private static User_Story_Data_Commit__c createDataCommit(Id userStoryId, Id dataSetId, Id deploymentId) {
        User_Story_Data_Commit__c dataCommit = new User_Story_Data_Commit__c(
            User_Story__c = userStoryId,
            Data_Set__c = dataSetId,
            Execution_Job__c = deploymentId
        );
        return dataCommit;
    }

    private static User setupUser() {
        ITestDefaults userCreation = new CopadoSetupTestDefaults.UserDefaults().createRunAsUsers().executeDML();
        User standardUser = userCreation.getRunAsUsers().get('Standard')[0];
        return standardUser;
    }

    private static void setupLicense() {
        TestUtilities.enableLicenses(2, 2, 2, 2, 2, 2, 2);
        TestUtilities.assignLicense(String.valueOf(UserInfo.getUserName()), true, true, true, true, true, true);
    }

    private static User getStandardUser() {
        User standardUser = [
            SELECT Id
            FROM User
            WHERE ProfileId IN (SELECT Id FROM Profile WHERE Name = 'Standard User')
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        return standardUser;
    }

    private static User_Story__c getUserStory() {
        return [SELECT Id, Name, Platform__c FROM User_Story__c LIMIT 1];
    }
}