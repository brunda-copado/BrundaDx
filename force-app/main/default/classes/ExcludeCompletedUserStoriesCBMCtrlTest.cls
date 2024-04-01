@SuppressWarnings('PMD')
@isTest
public with sharing class ExcludeCompletedUserStoriesCBMCtrlTest {
    
    @TestSetup
    private static void setUp() {

        List<User> userList = TestDataFactory.createUsers();
        TestUtilities.enableLicenses(2, 2, 2, 2, 2, 2);
        List<PermissionSet> permissionSets = [SELECT Id FROM PermissionSet WHERE Name IN ('Copado_User')];
        List<PermissionSetAssignment> assignments = new List<PermissionSetAssignment>();
        for (PermissionSet permissionSet : permissionSets) {
            assignments.add(new PermissionSetAssignment(AssigneeId = userList[0].Id, PermissionSetId = permissionSet.Id));
        }
        insert assignments; 
    }

    private static testMethod void getCompletedUserStoriesTest() {
        
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true);
        
        System.runAs(sysUser) {

            // SETUP

            createData();
            Id pipelineId = [SELECT Id FROM Deployment_Flow__c WHERE Name = 'MyPipeline' LIMIT 1]?.Id;
            List<User_Story__c> userStories = [SELECT Id, Exclude_From_CBM__c, Stop_Indexing_Metadata__c FROM User_Story__c LIMIT 2];
            String body = '["'+userStories[0].Id+'","'+userStories[1].Id+'"]';

            // EXCERCISE

            Test.startTest();
                Integer userStoriesBeforeUpdate = ExcludeCompletedUserStoriesCBMCtrl.getCompletedUserStories(pipelineId).size();
                ExcludeCompletedUserStoriesCBMCtrl.getCompletedUserStories(pipelineId);
                ExcludeCompletedUserStoriesCBMCtrl.updateUserStoryFields(body, String.valueOf(pipelineId));
                Integer userStoriesAfterUpdate = ExcludeCompletedUserStoriesCBMCtrl.getCompletedUserStories(pipelineId).size();
            Test.stopTest();

            //VERIFY

            System.assertEquals(userStoriesBeforeUpdate != 0, true);
            // exclude fields once set to true, will not show up in datatable UI.
            System.assertEquals(userStoriesAfterUpdate == 0, true);
        }
    }

    // HELPER
    private static void createData() {
       
        Git_Repository__c repository = TestDataFactory.createGitRepository();
        insert repository;

        Environment__c devEnvironment = TestDataFactory.createEnvironments('Dev1', 'Production/Developer');
        Environment__c uatEnvironment = TestDataFactory.createEnvironments('Uat', 'Production/Developer');
        insert new List<Environment__c>{ devEnvironment, uatEnvironment };

        List<Org__c> credential = TestDataFactory.createOrgCredentials(2, 'name@example.com', new List<Environment__c>{ devEnvironment, uatEnvironment });

        JobTemplate__c jobTemplate = TestDataFactory.createJobTemplate('Promotion', 'PromotionAPIName', 1, '[{ "name": "volumeEnabled", "value": "false" }]');
        insert jobTemplate;

        Deployment_Flow__c pipeline = TestDataFactory.createDeploymentFlow('MyPipeline',true, repository.Id, true);
        pipeline.Platform__c = 'Salesforce';
        insert pipeline;

        Deployment_Flow_Step__c connection1 = TestDataFactory.createDeploymentFlowStep(devEnvironment.Id, uatEnvironment.Id, pipeline.Id, '');
        insert connection1;
        Deployment_Flow_Step__c connection2 = TestDataFactory.createDeploymentFlowStep(uatEnvironment.Id, devEnvironment.Id, pipeline.Id, '');
        insert connection2;

        Project__c project = TestDataFactory.createProject('MyProject', pipeline.Id, false);
        insert project;

        Sprint__c sprint = new Sprint__c(Name='TestRun_v1');
        insert sprint;

        User_Story__c story1 = TestDataFactory.createUserStory('My Story One','Draft', sprint.Id, project.Id, devEnvironment.Id, credential[0].Id);
        User_Story__c story2 = TestDataFactory.createUserStory('My Story Two','Draft', sprint.Id, project.Id, uatEnvironment.Id, credential[1].Id);
        insert new List<User_Story__c>{ story1, story2 };

        Promotion__c promotion = TestDataFactory.createPromotion(project.Id, credential[0].Id, devEnvironment.Id, credential[1].Id, uatEnvironment.Id, 'Completed');
        insert promotion;

        Promoted_User_Story__c promotedStory1 = new Promoted_User_Story__c( User_Story__c = story1.Id, Promotion__c = promotion.Id, Status__c = 'Active');
        Promoted_User_Story__c promotedStory2 = new Promoted_User_Story__c( User_Story__c = story2.Id, Promotion__c = promotion.Id, Status__c = 'Active');
        insert new List<Promoted_User_Story__c>{ promotedStory1, promotedStory2 };
    }
}