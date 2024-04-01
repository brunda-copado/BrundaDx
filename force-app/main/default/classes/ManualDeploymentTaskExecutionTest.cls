@IsTest
private class ManualDeploymentTaskExecutionTest {
    @TestSetup
    private static void setupData() {
        List<User> userList = TestDataFactory.createUsers();
        TestUtilities.enableLicenses(10, 10, 10, 10, 10);
        FeatureManagement.setPackageIntegerValue('CBM_Branches', 10);
        List<PermissionSet> permissionSets = [SELECT Id FROM PermissionSet WHERE Name IN ('Copado_User', 'Copado_Functions', 'Copado_Job_Engine')];
        List<PermissionSetAssignment> assignments = new List<PermissionSetAssignment>();
        for (PermissionSet permissionSet : permissionSets) {
            assignments.add(new PermissionSetAssignment(AssigneeId = userList[0].Id, PermissionSetId = permissionSet.Id));
        }
        insert assignments;
    }

    private static testMethod void executeDeploymentTaskWithSpecificEnvironment() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true);

        System.runAs(sysUser) {
            // Org Credential creation
            List<Org__c> credentials = TestDataFactory.createOrgCredentials(4, sysUser.Username);

            for (integer i = 0; i < credentials.size(); i++) {
                credentials[i].SFDC_Org_ID__c = UserInfo.getOrganizationId().substring(0, UserInfo.getOrganizationId().length() - 1) + i + '_' + UserInfo.getUserId();
                credentials[i].Oauth_Signature__c = credentials[i].Name;
                credentials[i].Validated_Date__c = System.now();
                credentials[i].Disable_Validation__c = true;
            }
            update credentials;

            List<Environment__c> environments = [SELECT Id, Name, Org_ID__c FROM Environment__c];
            System.assertEquals(4, environments.size());

            // Git repository creation
            Git_Repository__c gitRepository = TestDataFactory.createGitRepository();
            insert gitRepository;

            // Deployment flow creation
            Deployment_Flow__c deploymentFlow = TestDataFactory.createDeploymentFlow('Deployment Flow', true, gitRepository.Id, false);
            deploymentFlow.Main_Branch__c = 'master';
            insert deploymentFlow;

            // Deployment flow steps creation
            Deployment_Flow_Step__c deploymentFlowStep1 = TestDataFactory.createDeploymentFlowStep(
                environments[0].Id,
                environments[2].Id,
                deploymentFlow.Id,
                ''
            );
            deploymentFlowStep1.Branch__c = 'dev1';
            Deployment_Flow_Step__c deploymentFlowStep2 = TestDataFactory.createDeploymentFlowStep(
                environments[1].Id,
                environments[2].Id,
                deploymentFlow.Id,
                ''
            );
            deploymentFlowStep2.Branch__c = 'dev2';
            Deployment_Flow_Step__c deploymentFlowStep3 = TestDataFactory.createDeploymentFlowStep(
                environments[2].Id,
                environments[3].Id,
                deploymentFlow.Id,
                ''
            );
            deploymentFlowStep3.Branch__c = 'int';
            insert new List<Deployment_Flow_Step__c>{ deploymentFlowStep1, deploymentFlowStep2, deploymentFlowStep3 };

            // Project creation
            Project__c project = TestDataFactory.createProject('My project', deploymentFlow.Id, false);
            insert project;

            // User Story creation
            User_Story__c userStory = TestDataFactory.createUserStory('us-0000000', 'Approved', null, project.Id, null, credentials[0].Id);
            insert userStory;

            // Deployment Task creation
            Deployment_Task__c deploymentTask = TestDataFactory.createDeploymentTask('Test Task', 1, 'Manual Task', 'Draft', userStory.Id);
            deploymentTask.dataJSON__c = '{"Perform_in_Source_Org":false,"Perform_in_Destination_Orgs":true,"Task_Description":"test asdasd","Task_Owner":"' + UserInfo.getUserId() + '","Notify_Task_Owner":"Email","Apply_to":"Specific Environments in Pipeline","Disable_Task_for_Back_Promotions":true,"Selected_Environments":["' + environments[3].Id + '"]}';
            deploymentTask.Apply_to__c = 'Specific Environments in Pipeline';
            deploymentTask.Disable_Task_for_Back_Promotions__c = true;
            insert deploymentTask;

            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock('{}', null));
            userStory.Promote_and_Deploy__c = true;
            update userStory;
            

            List<Promotion__c> promotions = [SELECT Id, Name, Source_Org_Credential__c, Destination_Org_Credential__c FROM Promotion__c];
            System.assertEquals(1, promotions.size(), 'There is only one promotion');
            List<AggregateResult> promotedUserStories = [SELECT COUNT(Id) promotedUserStoryCount FROM Promoted_User_Story__c];
            System.assertEquals(1, promotedUserStories[0].get('promotedUserStoryCount'), 'There is only one promoted user story');

            // Deployment creation
            String advancedDeploymentRecordTypeId = Schema.Sobjecttype.Deployment__c.getRecordTypeInfosByDeveloperName()
                .get('Advanced_multi_step')
                .getRecordTypeId();
            Deployment__c deployment = TestDataFactory.createDeployment('DEPLOYMENT_NAME', advancedDeploymentRecordTypeId, promotions[0].Source_Org_Credential__c);
            deployment.Date__c = System.now();
            deployment.Deployment_command_sent__c = System.now();
            deployment.Schedule__c = 'Deploy now';
            deployment.Status__c = 'Pending';
            deployment.Promotion__c = promotions[0].Id;
            insert deployment;

            // Destination Org creation
            Destination_Org__c destinationOrg = TestDataFactory.createDestinationOrg(deployment.Id, promotions[0].Destination_Org_Credential__c);
            insert destinationOrg;

            // Step creation
            String dataJson = '{"Perform_in_Source_Org":false,"Perform_in_Destination_Orgs":true,"Task_Description":"test asdasd","Task_Owner":"' + UserInfo.getUserId() + '","Notify_Task_Owner":"Email","Apply_to":"Specific Environments in Pipeline","Disable_Task_for_Back_Promotions":true,"Selected_Environments":["' + environments[3].Id + '"]}';
            Step__c step = TestDataFactory.createStep(deployment.Id, 'Step 2', 'Manual Task', 'Not Started', 1, null, dataJson);
            insert step;

            List<Deployment_Job__c> deploymentJobs = [SELECT Id, Name, Status__c FROM Deployment_Job__c];
            System.assertEquals(1, deploymentJobs.size(), 'There is only one job');

            deploymentJobs[0].Status__c = 'In Progress';
            update deploymentJobs;
            Test.stopTest();
            
            deploymentJobs = [SELECT Id, Name, Status__c FROM Deployment_Job__c WHERE Status__c = 'Success'];
            System.assertEquals(1, deploymentJobs.size(), 'There is only one completed job');

            String attachmentName = deploymentJobs[0].Id + '.json';
            List<Attachment> attachments = [SELECT Id FROM Attachment WHERE ParentId = :deploymentJobs[0].Id AND Name = :attachmentName];
            System.assertEquals(1, attachments.size(), 'There is only one attachment with completed message');

        }
    }

    private static void setupTestData(List<Org__c> credentials, List<Environment__c> environments) {
        // Git repository creation
        Git_Repository__c gitRepository = TestDataFactory.createGitRepository();
        insert gitRepository;

        // Deployment flow creation
        Deployment_Flow__c deploymentFlow = TestDataFactory.createDeploymentFlow('Deployment Flow', true, gitRepository.Id, false);
        deploymentFlow.Main_Branch__c = 'master';
        insert deploymentFlow;

        // Deployment flow steps creation
        Deployment_Flow_Step__c deploymentFlowStep1 = TestDataFactory.createDeploymentFlowStep(
            environments[0].Id,
            environments[2].Id,
            deploymentFlow.Id,
            ''
        );
        deploymentFlowStep1.Branch__c = 'dev1';
        Deployment_Flow_Step__c deploymentFlowStep2 = TestDataFactory.createDeploymentFlowStep(
            environments[1].Id,
            environments[2].Id,
            deploymentFlow.Id,
            ''
        );
        deploymentFlowStep2.Branch__c = 'dev2';
        Deployment_Flow_Step__c deploymentFlowStep3 = TestDataFactory.createDeploymentFlowStep(
            environments[2].Id,
            environments[3].Id,
            deploymentFlow.Id,
            ''
        );
        deploymentFlowStep3.Branch__c = 'int';
        insert new List<Deployment_Flow_Step__c>{ deploymentFlowStep1, deploymentFlowStep2, deploymentFlowStep3 };

        // Project creation
        Project__c project = TestDataFactory.createProject('My project', deploymentFlow.Id, false);
        insert project;

        // User Story creation
        User_Story__c userStory = TestDataFactory.createUserStory('us-0000000', 'Approved', null, project.Id, null, credentials[0].Id);
        insert userStory;

        // Deployment Task creation
        Deployment_Task__c deploymentTask = TestDataFactory.createDeploymentTask('Test Task', 1, 'Manual Task', 'Draft', userStory.Id);
        deploymentTask.dataJSON__c = '{"Perform_in_Source_Org":false,"Perform_in_Destination_Orgs":true,"Task_Description":"test asdasd","Task_Owner":"' + UserInfo.getUserId() + '","Notify_Task_Owner":"Email","Apply_to":"All Environments in Pipeline","Disable_Task_for_Back_Promotions":true, "Selected_Environments":[]}';
        deploymentTask.Apply_to__c = 'All Environments in Pipeline';
        deploymentTask.Disable_Task_for_Back_Promotions__c = true;
        insert deploymentTask;
    }
    @isTest
    static void executeBackPromotionDeploymentTaskForAllEnvironment() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true);

        System.runAs(sysUser) {
            // Org Credential creation
            List<Org__c> credentials = TestDataFactory.createOrgCredentials(4, sysUser.Username);
    
            for (integer i = 0; i < credentials.size(); i++) {
                credentials[i].SFDC_Org_ID__c = UserInfo.getOrganizationId().substring(0, UserInfo.getOrganizationId().length() - 1) + i + '_' + UserInfo.getUserId();
                credentials[i].Oauth_Signature__c = credentials[i].Name;
                credentials[i].Validated_Date__c = System.now();
                credentials[i].Disable_Validation__c = true;
            }
            update credentials;
            List<Environment__c> environments = [SELECT Id, Name, Org_ID__c FROM Environment__c];
        	System.assertEquals(4, environments.size());
            setupTestData(credentials, environments);
            
            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock('{}', null));
            Project__c project = [Select id from Project__c];
            Promotion__c testBackPromotion1 = CMTestMethodUtilities.createPromotion(project.Id, environments[2].Id);
            testBackPromotion1.Source_Environment__c = environments[2].Id;
            testBackPromotion1.Destination_Environment__c = environments[1].Id;
            testBackPromotion1.Source_Org_Credential__c = credentials[2].Id;
            testBackPromotion1.Destination_Org_Credential__c = credentials[1].Id;
            testBackPromotion1.Back_Promotion__c = true;
            insert testBackPromotion1;
            
            User_Story__c userStory = [Select id from User_Story__c];
            Promoted_User_Story__c backPromotedUserStory1b = new Promoted_User_Story__c(
            User_Story__c = userStory.Id,
            Promotion__c = testBackPromotion1.Id
            );
            insert backPromotedUserStory1b;

            List<AggregateResult> promotedUserStories = [SELECT COUNT(Id) promotedUserStoryCount FROM Promoted_User_Story__c];
            System.assertEquals(1, promotedUserStories[0].get('promotedUserStoryCount'), 'There is only one promoted user story');

            // Deployment creation
            String advancedDeploymentRecordTypeId = Schema.Sobjecttype.Deployment__c.getRecordTypeInfosByDeveloperName()
                .get('Advanced_multi_step')
                .getRecordTypeId();
            Deployment__c deployment = TestDataFactory.createDeployment('DEPLOYMENT_NAME', advancedDeploymentRecordTypeId, testBackPromotion1.Source_Org_Credential__c);
            deployment.Date__c = System.now();
            deployment.Deployment_command_sent__c = System.now();
            deployment.Schedule__c = 'Deploy now';
            deployment.Status__c = 'Pending';
            deployment.Promotion__c = testBackPromotion1.Id;
            insert deployment;

            // Destination Org creation
            Destination_Org__c destinationOrg = TestDataFactory.createDestinationOrg(deployment.Id, testBackPromotion1.Destination_Org_Credential__c);
            insert destinationOrg;

            // Step creation
            String dataJson = '{"Perform_in_Source_Org":false,"Perform_in_Destination_Orgs":true,"Task_Description":"test asdasd","Task_Owner":"' + UserInfo.getUserId() + '","Notify_Task_Owner":"Email","Apply_to":"All Environments in Pipeline","Disable_Task_for_Back_Promotions":true,"Selected_Environments":[]}';
            Step__c step = TestDataFactory.createStep(deployment.Id, 'Step 2', 'Manual Task', 'Not Started', 1, null, dataJson);
            insert step;

            List<Deployment_Job__c> deploymentJobs = [SELECT Id, Step__c, Name, Status__c, Pipeline_Id__c FROM Deployment_Job__c];
            System.assertEquals(1, deploymentJobs.size(), 'There is only one job');

            deploymentJobs[0].Status__c = 'In Progress';
            update deploymentJobs;
            Test.stopTest();

            String attachmentName = deploymentJobs[0].Id + '.json';
            List<Attachment> attachments = [SELECT Id FROM Attachment WHERE ParentId = :deploymentJobs[0].Id AND Name = :attachmentName];
            System.assertEquals(1, attachments.size(), 'Attachment created with auto-completed status');

        }
    }

    private static testMethod void executeDeploymentTaskForAllEnvironment() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true);

        System.runAs(sysUser) {
            // Org Credential creation
            List<Org__c> credentials = TestDataFactory.createOrgCredentials(4, sysUser.Username);
            for (integer i = 0; i < credentials.size(); i++) {
                credentials[i].SFDC_Org_ID__c = UserInfo.getOrganizationId().substring(0, UserInfo.getOrganizationId().length() - 1) + i + '_' + UserInfo.getUserId();
                credentials[i].Oauth_Signature__c = credentials[i].Name;
                credentials[i].Validated_Date__c = System.now();
                credentials[i].Disable_Validation__c = true;
            }
            update credentials;

            List<Environment__c> environments = [SELECT Id, Name, Org_ID__c FROM Environment__c];
            System.assertEquals(4, environments.size());

            // Git repository creation
            Git_Repository__c gitRepository = TestDataFactory.createGitRepository();
            insert gitRepository;

            // Deployment flow creation
            Deployment_Flow__c deploymentFlow = TestDataFactory.createDeploymentFlow('Deployment Flow', true, gitRepository.Id, false);
            deploymentFlow.Main_Branch__c = 'master';
            insert deploymentFlow;

            // Deployment flow steps creation
            Deployment_Flow_Step__c deploymentFlowStep1 = TestDataFactory.createDeploymentFlowStep(
                environments[0].Id,
                environments[2].Id,
                deploymentFlow.Id,
                ''
            );
            deploymentFlowStep1.Branch__c = 'dev1';
            Deployment_Flow_Step__c deploymentFlowStep2 = TestDataFactory.createDeploymentFlowStep(
                environments[1].Id,
                environments[2].Id,
                deploymentFlow.Id,
                ''
            );
            deploymentFlowStep2.Branch__c = 'dev2';
            Deployment_Flow_Step__c deploymentFlowStep3 = TestDataFactory.createDeploymentFlowStep(
                environments[2].Id,
                environments[3].Id,
                deploymentFlow.Id,
                ''
            );
            deploymentFlowStep3.Branch__c = 'int';
            insert new List<Deployment_Flow_Step__c>{ deploymentFlowStep1, deploymentFlowStep2, deploymentFlowStep3 };

            // Project creation
            Project__c project = TestDataFactory.createProject('My project', deploymentFlow.Id, false);
            insert project;

            // User Story creation
            User_Story__c userStory = TestDataFactory.createUserStory('us-0000000', 'Approved', null, project.Id, null, credentials[0].Id);
            insert userStory;

            // Deployment Task creation
            Deployment_Task__c deploymentTask = TestDataFactory.createDeploymentTask('Test Task', 1, 'Manual Task', 'Draft', userStory.Id);
            deploymentTask.dataJSON__c = '{"Perform_in_Source_Org":false,"Perform_in_Destination_Orgs":true,"Task_Description":"test asdasd","Task_Owner":"' + UserInfo.getUserId() + '","Notify_Task_Owner":"Email","Apply_to":"All Environments in Pipeline","Disable_Task_for_Back_Promotions":true,"Selected_Environments":[]}';
            deploymentTask.Apply_to__c = 'All Environments in Pipeline';
            deploymentTask.Disable_Task_for_Back_Promotions__c = true;
            insert deploymentTask;

            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock('{}', null));
            userStory.Promote_and_Deploy__c = true;
            update userStory;
            

            List<Promotion__c> promotions = [SELECT Id, Name, Source_Org_Credential__c, Destination_Org_Credential__c FROM Promotion__c];
            System.assertEquals(1, promotions.size(), 'There is only one promotion');
            List<AggregateResult> promotedUserStories = [SELECT COUNT(Id) promotedUserStoryCount FROM Promoted_User_Story__c];
            System.assertEquals(1, promotedUserStories[0].get('promotedUserStoryCount'), 'There is only one promoted user story');

            // Deployment creation
            String advancedDeploymentRecordTypeId = Schema.Sobjecttype.Deployment__c.getRecordTypeInfosByDeveloperName()
                .get('Advanced_multi_step')
                .getRecordTypeId();
            Deployment__c deployment = TestDataFactory.createDeployment('DEPLOYMENT_NAME', advancedDeploymentRecordTypeId, promotions[0].Source_Org_Credential__c);
            deployment.Date__c = System.now();
            deployment.Deployment_command_sent__c = System.now();
            deployment.Schedule__c = 'Deploy now';
            deployment.Status__c = 'Pending';
            deployment.Promotion__c = promotions[0].Id;
            insert deployment;

            // Destination Org creation
            Destination_Org__c destinationOrg = TestDataFactory.createDestinationOrg(deployment.Id, promotions[0].Destination_Org_Credential__c);
            insert destinationOrg;

            // Step creation
            String dataJson = '{"Perform_in_Source_Org":false,"Perform_in_Destination_Orgs":true,"Task_Description":"test asdasd","Task_Owner":"' + UserInfo.getUserId() + '","Notify_Task_Owner":"Email","Apply_to":"All Environments in Pipeline","Disable_Task_for_Back_Promotions":true,"Selected_Environments":[]}';
            Step__c step = TestDataFactory.createStep(deployment.Id, 'Step 2', 'Manual Task', 'Not Started', 1, null, dataJson);
            insert step;

            List<Deployment_Job__c> deploymentJobs = [SELECT Id, Name, Status__c, Destination_Org__r.To_Org__r.Environment__c, Pipeline_Id__c FROM Deployment_Job__c];
            System.assertEquals(1, deploymentJobs.size(), 'There is only one job');
            deploymentJobs[0].Status__c = 'In Progress';
            update deploymentJobs;
            Test.stopTest();

            deploymentJobs = [SELECT Id, Name, Status__c FROM Deployment_Job__c WHERE Status__c = 'In Progress'];
            System.assertEquals(1, deploymentJobs.size(), 'There is only one not completed job');

            String attachmentName = deploymentJobs[0].Id + '.json';
            List<Attachment> attachments = [SELECT Id FROM Attachment WHERE ParentId = :deploymentJobs[0].Id AND Name = :attachmentName];
            System.assertEquals(0, attachments.size(), 'There is none attachment with completed message');

        }
    }

    private static testMethod void executeDeploymentTaskForOldRecords() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true);

        System.runAs(sysUser) {
            // Org Credential creation
            List<Org__c> credentials = TestDataFactory.createOrgCredentials(4, sysUser.Username);

            for (integer i = 0; i < credentials.size(); i++) {
                credentials[i].SFDC_Org_ID__c = UserInfo.getOrganizationId().substring(0, UserInfo.getOrganizationId().length() - 1) + i + '_' + UserInfo.getUserId();
                credentials[i].Oauth_Signature__c = credentials[i].Name;
                credentials[i].Validated_Date__c = System.now();
                credentials[i].Disable_Validation__c = true;
            }
            update credentials;

            List<Environment__c> environments = [SELECT Id, Name, Org_ID__c FROM Environment__c];
            System.assertEquals(4, environments.size());

            // Git repository creation
            Git_Repository__c gitRepository = TestDataFactory.createGitRepository();
            insert gitRepository;

            // Deployment flow creation
            Deployment_Flow__c deploymentFlow = TestDataFactory.createDeploymentFlow('Deployment Flow', true, gitRepository.Id, false);
            deploymentFlow.Main_Branch__c = 'master';
            insert deploymentFlow;

            // Deployment flow steps creation
            Deployment_Flow_Step__c deploymentFlowStep1 = TestDataFactory.createDeploymentFlowStep(
                environments[0].Id,
                environments[2].Id,
                deploymentFlow.Id,
                ''
            );
            deploymentFlowStep1.Branch__c = 'dev1';
            Deployment_Flow_Step__c deploymentFlowStep2 = TestDataFactory.createDeploymentFlowStep(
                environments[1].Id,
                environments[2].Id,
                deploymentFlow.Id,
                ''
            );
            deploymentFlowStep2.Branch__c = 'dev2';
            Deployment_Flow_Step__c deploymentFlowStep3 = TestDataFactory.createDeploymentFlowStep(
                environments[2].Id,
                environments[3].Id,
                deploymentFlow.Id,
                ''
            );
            deploymentFlowStep3.Branch__c = 'int';
            insert new List<Deployment_Flow_Step__c>{ deploymentFlowStep1, deploymentFlowStep2, deploymentFlowStep3 };

            // Project creation
            Project__c project = TestDataFactory.createProject('My project', deploymentFlow.Id, false);
            insert project;

            // User Story creation
            User_Story__c userStory = TestDataFactory.createUserStory('us-0000000', 'Approved', null, project.Id, null, credentials[0].Id);
            insert userStory;

            // Deployment Task creation
            Deployment_Task__c deploymentTask = TestDataFactory.createDeploymentTask('Test Task', 1, 'Manual Task', 'Draft', userStory.Id);
            deploymentTask.dataJSON__c = '{"Perform_in_Source_Org":false,"Perform_in_Destination_Orgs":true,"Task_Description":"test asdasd","Task_Owner":"' + UserInfo.getUserId() + '","Notify_Task_Owner":"Email"}';
            insert deploymentTask;

            Test.startTest();
            Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock('{}', null));
            userStory.Promote_and_Deploy__c = true;
            update userStory;
            

            List<Promotion__c> promotions = [SELECT Id, Name, Source_Org_Credential__c, Destination_Org_Credential__c FROM Promotion__c];
            System.assertEquals(1, promotions.size(), 'There is only one promotion');
            List<AggregateResult> promotedUserStories = [SELECT COUNT(Id) promotedUserStoryCount FROM Promoted_User_Story__c];
            System.assertEquals(1, promotedUserStories[0].get('promotedUserStoryCount'), 'There is only one promoted user story');

            // Deployment creation
            String advancedDeploymentRecordTypeId = Schema.Sobjecttype.Deployment__c.getRecordTypeInfosByDeveloperName()
                .get('Advanced_multi_step')
                .getRecordTypeId();
            Deployment__c deployment = TestDataFactory.createDeployment('DEPLOYMENT_NAME', advancedDeploymentRecordTypeId, promotions[0].Source_Org_Credential__c);
            deployment.Date__c = System.now();
            deployment.Deployment_command_sent__c = System.now();
            deployment.Schedule__c = 'Deploy now';
            deployment.Status__c = 'Pending';
            deployment.Promotion__c = promotions[0].Id;
            insert deployment;

            // Destination Org creation
            Destination_Org__c destinationOrg = TestDataFactory.createDestinationOrg(deployment.Id, promotions[0].Destination_Org_Credential__c);
            insert destinationOrg;

            // Step creation
            String dataJson = '{"Perform_in_Source_Org":false,"Perform_in_Destination_Orgs":true,"Task_Description":"test asdasd","Task_Owner":"' + UserInfo.getUserId() + '","Notify_Task_Owner":"Email"}';
            Step__c step = TestDataFactory.createStep(deployment.Id, 'Step 2', 'Manual Task', 'Not Started', 1, null, dataJson);
            insert step;

            List<Deployment_Job__c> deploymentJobs = [SELECT Id, Name, Status__c FROM Deployment_Job__c];
            System.assertEquals(1, deploymentJobs.size(), 'There is only one job');

            deploymentJobs[0].Status__c = 'In Progress';
            update deploymentJobs;
            Test.stopTest();

            deploymentJobs = [SELECT Id, Name, Status__c FROM Deployment_Job__c WHERE Status__c = 'In Progress'];
            System.assertEquals(1, deploymentJobs.size(), 'There is only one not completed job');

            String attachmentName = deploymentJobs[0].Id + '.json';
            List<Attachment> attachments = [SELECT Id FROM Attachment WHERE ParentId = :deploymentJobs[0].Id AND Name = :attachmentName];
            System.assertEquals(0, attachments.size(), 'There is none attachment with completed message');

        }
    }
}