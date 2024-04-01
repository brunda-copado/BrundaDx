@IsTest
private class TestDeploymentTrigger {
    @TestSetup
    private static void setupData() {
        List<User> userList = TestDataFactory.createUsers();
        TestUtilities.enableLicenses(2, 2, 2, 2, 2);
        FeatureManagement.setPackageIntegerValue('CBM_Branches', 2);
        List<PermissionSet> permissionSets = [SELECT Id FROM PermissionSet WHERE Name IN ('Copado_User', 'Copado_Functions')];
        List<PermissionSetAssignment> assignments = new List<PermissionSetAssignment>();
        for (PermissionSet permissionSet : permissionSets) {
            assignments.add(new PermissionSetAssignment(AssigneeId = userList[0].Id, PermissionSetId = permissionSet.Id));
        }

        insert assignments;
    }
    private static testMethod void testBuildTaskUpdateSuccess() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true);

        System.runAs(sysUser) {
            Continuous_Integration__c continuousIntegration = TestDataFactory.createContinuousIntegration('My CI 1', true, 'Draft');
            insert new List<Continuous_Integration__c>{ continuousIntegration };

            Build_Task__c buildTask = TestDataFactory.createBuildTask(continuousIntegration, 1, 'Pending');
            insert new List<Build_Task__c>{ buildTask };

            //Environment creation
            List<Environment__c> environments = TestDataFactory.createEnvironments(3);

            // Org Credential creation
            List<Org__c> credentials = TestDataFactory.createOrgCredentials(3, sysUser.Username, environments);

            // Deployment creation
            String advancedDeploymentRecordTypeId = Schema.Sobjecttype.Deployment__c.getRecordTypeInfosByDeveloperName()
                .get('Advanced_multi_step')
                .getRecordTypeId();
            Deployment__c deployment = TestDataFactory.createDeployment('DEPLOYMENT_NAME', advancedDeploymentRecordTypeId, credentials[2].Id);
            deployment.Date__c = System.now();
            deployment.Deployment_command_sent__c = System.now();
            deployment.Schedule__c = 'Deploy now';
            deployment.Status__c = 'Scheduled';
            deployment.Build_Task__c = buildTask.Id;
            insert new List<Deployment__c>{ deployment };

            // Destination Org creation
            Destination_Org__c destinationOrg1 = TestDataFactory.createDestinationOrg(deployment.Id, credentials[1].Id);
            insert new List<Destination_Org__c>{ destinationOrg1 };

            // Step creation
            Step__c step = TestDataFactory.createStep(deployment.Id, 'Apex', 'Apex', 'Draft', 1, null, '{"testLevel":"NoTestRun","replacements":[]}');
            insert new List<Step__c>{ step };

            Test.startTest();
            Deployment_Job__c deploymentJob = [
                SELECT Id, Status__c, Step__r.Deployment__c
                FROM Deployment_Job__c
                WHERE Step__r.Deployment__c = :deployment.Id
            ];
            deploymentJob.Status__c = 'Success';
            update deploymentJob;
            Test.stopTest();

            List<Build_Task__c> buildTasks = [
                SELECT Id, Continuous_Integration__c, Status__c
                FROM Build_Task__c
                WHERE Continuous_Integration__c = :continuousIntegration.Id
            ];
            for (Build_Task__c buildTaskRecord : buildTasks) {
                if (buildTaskRecord.Continuous_Integration__c == continuousIntegration.Id) {
                    System.assertEquals('Success', buildTaskRecord.Status__c);
                }
            }
        }
    }
    private static testMethod void testBuildTaskUpdateFailed() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true);

        System.runAs(sysUser) {
            Continuous_Integration__c continuousIntegration = TestDataFactory.createContinuousIntegration('My CI 1', true, 'Draft');
            insert new List<Continuous_Integration__c>{ continuousIntegration };

            Build_Task__c buildTask = TestDataFactory.createBuildTask(continuousIntegration, 1, 'Pending');
            insert new List<Build_Task__c>{ buildTask };

            //Environment creation
            List<Environment__c> environments = TestDataFactory.createEnvironments(3);

            // Org Credential creation
            List<Org__c> credentials = TestDataFactory.createOrgCredentials(3, sysUser.Username, environments);

            // Deployment creation
            String advancedDeploymentRecordTypeId = Schema.Sobjecttype.Deployment__c.getRecordTypeInfosByDeveloperName()
                .get('Advanced_multi_step')
                .getRecordTypeId();
            Deployment__c deployment = TestDataFactory.createDeployment('DEPLOYMENT_NAME', advancedDeploymentRecordTypeId, credentials[2].Id);
            deployment.Date__c = System.now();
            deployment.Deployment_command_sent__c = System.now();
            deployment.Schedule__c = 'Deploy now';
            deployment.Status__c = 'Scheduled';
            deployment.Build_Task__c = buildTask.Id;
            insert new List<Deployment__c>{ deployment };

            // Destination Org creation
            Destination_Org__c destinationOrg1 = TestDataFactory.createDestinationOrg(deployment.Id, credentials[1].Id);
            insert new List<Destination_Org__c>{ destinationOrg1 };

            // Step creation
            Step__c step = TestDataFactory.createStep(deployment.Id, 'Apex', 'Apex', 'Draft', 1, null, '{"testLevel":"NoTestRun","replacements":[]}');
            insert new List<Step__c>{ step };

            Test.startTest();
            Deployment_Job__c deploymentJob = [
                SELECT Id, Status__c, Step__r.Deployment__c
                FROM Deployment_Job__c
                WHERE Step__r.Deployment__c = :deployment.Id
            ];
            deploymentJob.Status__c = 'Failed';
            update deploymentJob;
            Test.stopTest();

            List<Build_Task__c> buildTasks = [
                SELECT Id, Continuous_Integration__c, Status__c
                FROM Build_Task__c
                WHERE Continuous_Integration__c = :continuousIntegration.Id
            ];
            for (Build_Task__c buildTaskRecord : buildTasks) {
                if (buildTaskRecord.Continuous_Integration__c == continuousIntegration.Id) {
                    System.assertEquals('Failed', buildTaskRecord.Status__c);
                }
            }
        }
    }
    private static testMethod void testDeploymentHistory() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true);

        System.runAs(sysUser) {
            //Environment creation
            List<Environment__c> environments = TestDataFactory.createEnvironments(3);

            // Org Credential creation
            List<Org__c> credentials = TestDataFactory.createOrgCredentials(3, sysUser.Username, environments);

            Test.startTest();
            // Deployment creation
            String advancedDeploymentRecordTypeId = Schema.Sobjecttype.Deployment__c.getRecordTypeInfosByDeveloperName()
                .get('Advanced_multi_step')
                .getRecordTypeId();
            Deployment__c deployment = TestDataFactory.createDeployment('DEPLOYMENT_NAME', advancedDeploymentRecordTypeId, credentials[2].Id);
            deployment.Date__c = System.now();
            deployment.Deployment_command_sent__c = System.now();
            deployment.Schedule__c = 'Deploy now';
            deployment.Status__c = 'Scheduled';
            insert new List<Deployment__c>{ deployment };

            System.assertNotEquals(
                0,
                [
                    SELECT COUNT()
                    FROM Deployment_History__c
                    WHERE Deployment__c = :deployment.Id AND Deployment_Id__c = :deployment.id AND Event__c = 'Created' AND Object__c = 'Deployment'
                ]
            );

            deployment.From_Org__c = credentials[1].Id;
            deployment.Name = 'changed x';
            deployment.Status__c = 'In progress';
            deployment.Date__c = System.now();
            update deployment;

            System.assertNotEquals(
                0,
                [
                    SELECT COUNT()
                    FROM Deployment_History__c
                    WHERE
                        Deployment__c = :deployment.Id
                        AND Deployment_Id__c = :deployment.id
                        AND Event__c = 'Updated'
                        AND Object__c = 'Deployment'
                        AND Field__c = 'Deployment Name'
                ]
            );

            deployment.From_Org__c = null;
            update deployment;

            // Destination Org creation
            Destination_Org__c destinationOrg = TestDataFactory.createDestinationOrg(deployment.Id, credentials[1].Id);
            insert new List<Destination_Org__c>{ destinationOrg };

            // Step creation
            Step__c step = TestDataFactory.createStep(deployment.Id, 'Apex', 'Apex', 'Draft', 1, null, '{"testLevel":"NoTestRun","replacements":[]}');
            insert new List<Step__c>{ step };

            delete destinationOrg;
            delete deployment;

            System.assertNotEquals(
                0,
                [
                    SELECT COUNT()
                    FROM Deployment_History__c
                    WHERE Deployment_Id__c = :deployment.Id AND Event__c = 'Deleted' AND Object__c = 'Deployment'
                ]
            );
            Test.stopTest();
        }
    }
    private static testMethod void testCompletePromotions() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true);

        System.runAs(sysUser) {
            //Environment creation
            List<Environment__c> environments = TestDataFactory.createEnvironments(3);

            // Org Credential creation
            List<Org__c> credentials = TestDataFactory.createOrgCredentials(3, sysUser.Username, environments);

            // Git repository creation
            Git_Repository__c gitRepository = TestDataFactory.createGitRepository();
            insert gitRepository;

            // Deployment flow creation
            Deployment_Flow__c deploymentFlow = TestDataFactory.createDeploymentFlow('Deployment Flow', true, gitRepository.Id, false);
            deploymentFlow.Main_Branch__c = 'master';
            deploymentFlow.Platform__c = 'Salesforce';
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
            deploymentFlowStep1.Branch__c = 'dev2';
            insert new List<Deployment_Flow_Step__c>{ deploymentFlowStep1, deploymentFlowStep2 };

            // Project creation
            Project__c project = TestDataFactory.createProject('My project', deploymentFlow.Id, false);
            insert project;

            // User Story creation
            User_Story__c userStory = TestDataFactory.createUserStory('us-0000000', 'Approved', null, project.Id, null, credentials[0].Id);
            insert userStory;

            Test.startTest();
            String response = '{"isSuccess":true, "isFinished":true}';
            MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200, 'Complete', response, null);
            Test.setMock(HttpCalloutMock.class, fakeResponse);

            userStory.Promote_and_Deploy__c = true;
            update userStory;
            Promotion__c promotion = [SELECT Id FROM Promotion__c LIMIT 1];

            // Deployment creation
            String advancedDeploymentRecordTypeId = Schema.Sobjecttype.Deployment__c.getRecordTypeInfosByDeveloperName()
                .get('Advanced_multi_step')
                .getRecordTypeId();
            Deployment__c deployment = TestDataFactory.createDeployment('DEPLOYMENT_NAME', advancedDeploymentRecordTypeId, credentials[2].Id);
            deployment.Date__c = System.now();
            deployment.Deployment_command_sent__c = System.now();
            deployment.Schedule__c = 'Deploy now';
            deployment.Status__c = 'In progress';
            deployment.Promotion__c = promotion.Id;
            insert deployment;

            // Destination Org creation
            Destination_Org__c destinationOrg = TestDataFactory.createDestinationOrg(deployment.Id, credentials[2].Id);
            insert destinationOrg;

            // Step creation
            Step__c step = TestDataFactory.createStep(
                deployment.Id,
                'MetaData',
                'MetaData',
                'Pending',
                1,
                null,
                '{"testLevel":"NoTestRun","replacements":[]}'
            );
            insert step;

            Deployment_Job__c deploymentJob = [SELECT Id, Status__c FROM Deployment_Job__c LIMIT 1];
            System.assertEquals('Pending', deploymentJob.Status__c);
            deploymentJob.Status__c = 'Success';
            deploymentJob.Deployed__c = 100;
            update deploymentJob;

            // Verify that the Step and the Deployment are Completed Successfully
            System.assertEquals('Completed Successfully', [SELECT Status__c FROM Step__c LIMIT 1].Status__c);
            System.assertEquals('Completed Successfully', [SELECT Status__c FROM Deployment__c LIMIT 1].Status__c);

            // Verify that the Promotion is Completed Successfully and the User Story Environment is the target environment
            System.assertEquals('Completed', [SELECT Status__c FROM Promotion__c LIMIT 1].Status__c);
            System.assertEquals(environments[2].Id, [SELECT Environment__c FROM User_Story__c WHERE Id = :userStory.Id].Environment__c);
            Test.stopTest();
        }
    }
    @IsTest
    private static void testLatestDeploymentOnEnvironment() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true);

        System.runAs(sysUser) {
            List<Environment__c> environments = TestDataFactory.createEnvironments(2);
            List<Org__c> credentials = TestDataFactory.createOrgCredentials(2, 'latest-deployment@trigger.xyz', environments);

            // Deployment creation
            String metadataDeploymentRecordTypeId = Schema.Sobjecttype.Deployment__c.getRecordTypeInfosByName()
                .get('Metadata Deployment')
                .getRecordTypeId();
            Deployment__c firstDeployment = TestDataFactory.createDeployment(
                'ENVIRONMENT 1 to ENVIRONMENT 2 DEP 1',
                metadataDeploymentRecordTypeId,
                credentials[0].Id
            );
            firstDeployment.Status__c = 'Draft';
            insert firstDeployment;

            Destination_Org__c destOrg1 = TestDataFactory.createDestinationOrg(firstDeployment.Id, credentials[1].Id);
            insert destOrg1;

            Test.startTest();
            environments = [
                SELECT Id, Name, Latest_Deployment__c, Latest_Deployment_Status__c, Latest_Deployment__r.Status__c
                FROM Environment__c
                WHERE Id IN :environments
            ];

            System.assertEquals(null, environments[1].Latest_Deployment__c, 'Latest Deployment should not be updated for Draft status');

            firstDeployment.Status__c = 'In progress';
            update firstDeployment;

            environments = [
                SELECT Id, Name, Latest_Deployment__c, Latest_Deployment_Status__c, Latest_Deployment__r.Status__c
                FROM Environment__c
                WHERE Id IN :environments
            ];

            System.assertEquals(
                firstDeployment.Id,
                environments[1].Latest_Deployment__c,
                'Latest Deployment should be updated for in progress deployment'
            );
            System.assertEquals(
                'In progress',
                environments[1].Latest_Deployment_Status__c,
                'Latest Deployment Status should be updated when deployment status changes'
            );

            firstDeployment.Status__c = 'Completed Successfully';
            update firstDeployment;

            environments = [
                SELECT Id, Name, Latest_Deployment__c, Latest_Deployment_Status__c, Latest_Deployment__r.Status__c
                FROM Environment__c
                WHERE Id IN :environments
            ];

            System.assertEquals(
                'Completed Successfully',
                environments[1].Latest_Deployment_Status__c,
                'Latest Deployment Status should be updated when deployment status changes'
            );

            // Deployment creation
            Deployment__c secondDeployment = TestDataFactory.createDeployment(
                'ENVIRONMENT 1 to ENVIRONMENT 2 DEP 2',
                metadataDeploymentRecordTypeId,
                credentials[0].Id
            );
            secondDeployment.Status__c = 'Draft';
            insert secondDeployment;

            Destination_Org__c destOrg2 = TestDataFactory.createDestinationOrg(secondDeployment.Id, credentials[1].Id);
            insert destOrg2;

            environments = [
                SELECT Id, Name, Latest_Deployment__c, Latest_Deployment_Status__c, Latest_Deployment__r.Status__c
                FROM Environment__c
                WHERE Id IN :environments
            ];

            System.assertEquals(firstDeployment.Id, environments[1].Latest_Deployment__c, 'Latest Deployment should not change for Draft deployment');
            secondDeployment.Status__c = 'Scheduled';
            update secondDeployment;

            environments = [
                SELECT Id, Name, Latest_Deployment__c, Latest_Deployment_Status__c, Latest_Deployment__r.Status__c
                FROM Environment__c
                WHERE Id IN :environments
            ];

            System.assertNotEquals(
                secondDeployment.Id,
                environments[1].Latest_Deployment__c,
                'Latest Deployment should not change for Scheduled deployment'
            );

            secondDeployment.Status__c = 'Completed with Errors';
            update secondDeployment;

            environments = [
                SELECT Id, Name, Latest_Deployment__c, Latest_Deployment_Status__c, Latest_Deployment__r.Status__c
                FROM Environment__c
                WHERE Id IN :environments
            ];

            System.assertEquals(
                secondDeployment.Id,
                environments[1].Latest_Deployment__c,
                'Latest Deployment should be updated for Completed status deployment'
            );
            System.assertEquals(
                'Completed with Errors',
                environments[1].Latest_Deployment_Status__c,
                'Latest Deployment Status should be updated when deployment status changes'
            );

            secondDeployment.Paused__c = true;
            secondDeployment.Status__c = 'In progress';
            update secondDeployment;
            Test.stopTest();

            environments = [
                SELECT Id, Name, Latest_Deployment__c, Latest_Deployment_Status__c, Latest_Deployment__r.Status__c
                FROM Environment__c
                WHERE Id IN :environments
            ];

            System.assertEquals(
                'Paused',
                environments[1].Latest_Deployment_Status__c,
                'Latest Deployment Status should be updated when deployment status changes'
            );
        }
    }
    @IsTest
    private static void testPausedStatusOnDeployment() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true);

        System.runAs(sysUser) {
            List<Environment__c> environments = TestDataFactory.createEnvironments(2);
            List<Org__c> credentials = TestDataFactory.createOrgCredentials(2, 'latest-deployment@trigger.xyz', environments);
            Environment__c destination = environments[1];

            // Deployment creation
            String metadataDeploymentRecordTypeId = Schema.Sobjecttype.Deployment__c.getRecordTypeInfosByName()
                .get('Metadata Deployment')
                .getRecordTypeId();
            Deployment__c firstDeployment = TestDataFactory.createDeployment(
                'ENVIRONMENT 1 to ENVIRONMENT 2 DEP 1',
                metadataDeploymentRecordTypeId,
                credentials[0].Id
            );
            firstDeployment.Status__c = 'Draft';
            insert firstDeployment;

            Destination_Org__c destOrg1 = TestDataFactory.createDestinationOrg(firstDeployment.Id, credentials[1].Id);
            insert destOrg1;

            Step__c step1 = TestDataFactory.createStep(firstDeployment.Id, 'Step 1', 'MetaData', 'Not started', 1, null, '');
            Step__c step2 = TestDataFactory.createStep(
                firstDeployment.Id,
                'Step 2',
                'Manual Task',
                'Not started',
                2,
                null,
                '{"Perform_in_Destination_Orgs":true,"Perform_in_Source_Org":false,"Task_Description":"","Task_Owner":""}'
            );
            Step__c step3 = TestDataFactory.createStep(firstDeployment.Id, 'Step 3', 'Git MetaData', 'Not started', 3, null, '');
            List<Step__c> steps = new List<Step__c>{ step1, step2, step3 };
            insert steps;

            Deployment_Job__c depJob1 = new Deployment_Job__c(Step__c = step1.Id, Status__c = 'Pending', Destination_Org__c = destOrg1.Id);
            Deployment_Job__c depJob2 = new Deployment_Job__c(Step__c = step2.Id, Status__c = 'Pending', Destination_Org__c = destOrg1.Id);
            Deployment_Job__c depJob3 = new Deployment_Job__c(Step__c = step3.Id, Status__c = 'Pending', Destination_Org__c = destOrg1.Id);
            List<Deployment_Job__c> depJobs = new List<Deployment_Job__c>{ depJob1, depJob2, depJob3 };
            insert depJobs;

            firstDeployment.Status__c = 'Scheduled';
            update firstDeployment;

            Test.startTest();
            String response = '{"isSuccess":true, "isFinished":true}';
            MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200, 'Complete', response, null);
            Test.setMock(HttpCalloutMock.class, fakeResponse);

            depJobs[0].Status__c = 'In progress';
            update depJobs[0];

            steps[0].Status__c = 'In progress';
            update steps[0];

            destination = [
                SELECT Id, Name, Latest_Deployment__c, Latest_Deployment_Status__c, Latest_Deployment__r.Status__c
                FROM Environment__c
                WHERE Id = :destination.Id
            ];
            System.assertEquals(firstDeployment.Id, destination.Latest_Deployment__c, 'Latest Deployment should be populated');

            step1 = [SELECT Id, Status__c, Name FROM Step__c WHERE Id = :steps[0].Id];
            System.assertEquals('In progress', step1.Status__c, 'Metadata step with order 1 should be in progress');

            depJobs[0].Status__c = 'Success';
            update depJobs[0];

            Test.stopTest();
        }
    }
    @IsTest
    private static void testCheckonlyDeployment() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true);

        System.runAs(sysUser) {
            Test.startTest();
            //Environment creation
            List<Environment__c> environments = TestDataFactory.createEnvironments(3);

            // Org Credential creation
            List<Org__c> credentials = TestDataFactory.createOrgCredentials(3, sysUser.Username, environments);

            //Feature__c feature = new Feature__c(Name = 'Branch Management', Enabled__c = true, Quantity__c = 10);
            //insert feature;

            // Git repository creation
            Git_Repository__c gitRepository = TestDataFactory.createGitRepository();
            insert gitRepository;

            // Deployment flow creation
            Deployment_Flow__c deploymentFlow = TestDataFactory.createDeploymentFlow('Deployment Flow', true, gitRepository.Id, false);
            deploymentFlow.Main_Branch__c = 'master';
            deploymentFlow.Platform__c = 'Salesforce';
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
            deploymentFlowStep1.Branch__c = 'dev2';
            insert new List<Deployment_Flow_Step__c>{ deploymentFlowStep1, deploymentFlowStep2 };

            // Project creation
            Project__c project = TestDataFactory.createProject('My project', deploymentFlow.Id, false);
            insert project;

            // User Story creation
            User_Story__c userStory = TestDataFactory.createUserStory('us-0000000', 'Approved', null, project.Id, null, credentials[0].Id);
            insert userStory;

            String response = '{"isSuccess":true, "isFinished":true}';
            MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200, 'Complete', response, null);
            Test.setMock(HttpCalloutMock.class, fakeResponse);

            userStory.Promote_and_Deploy__c = true;
            update userStory;
            Promotion__c promotion = [SELECT Id FROM Promotion__c LIMIT 1];

            // Deployment creation
            String advancedDeploymentRecordTypeId = Schema.Sobjecttype.Deployment__c.getRecordTypeInfosByDeveloperName()
                .get('Advanced_multi_step')
                .getRecordTypeId();
            Deployment__c deployment = TestDataFactory.createDeployment('DEPLOYMENT_NAME', advancedDeploymentRecordTypeId, credentials[2].Id);
            deployment.Date__c = System.now();
            deployment.Deployment_command_sent__c = System.now();
            deployment.Schedule__c = 'Deploy now';
            deployment.Status__c = 'In progress';
            deployment.Promotion__c = promotion.Id;
            insert deployment;

            // Destination Org creation
            Destination_Org__c destinationOrg = TestDataFactory.createDestinationOrg(deployment.Id, credentials[2].Id);
            insert destinationOrg;

            // Step creation
            Step__c step1 = TestDataFactory.createStep(
                deployment.Id,
                'Step 1',
                'MetaData',
                'Not started',
                1,
                null,
                '{"testLevel":"NoTestRun","replacements":[]}'
            );
            step1.CheckOnly__c = true;
            insert new List<Step__c>{ step1 };

            List<Deployment_Job__c> deploymentJobs = [SELECT Id, Status__c FROM Deployment_Job__c WHERE Destination_Org__c = :destinationOrg.Id];
            Test.stopTest();
            deploymentJobs[0].Status__c = 'Success';
            deploymentJobs[0].Deployed__c = 100;
            update deploymentJobs;

            // Verify that the Deployment are Completed Successfully
            System.assertEquals(
                'Completed Successfully',
                [SELECT Status__c FROM Deployment__c WHERE Id = :deployment.Id]
                .Status__c,
                'Deployment status should be Completed successfully'
            );

            // Verify that the Promotion is Validated and the User Story Environment is not changed
            System.assertEquals(
                'Validated',
                [SELECT Status__c FROM Promotion__c WHERE Id = :promotion.Id]
                .Status__c,
                'Promition status should be validated for check only deployments'
            );
            System.assertEquals(
                environments[0].Id,
                [SELECT Environment__c FROM User_Story__c WHERE Id = :userStory.Id]
                .Environment__c,
                'Environment on user story should be unchanged for check only deployments'
            );
        }
    }
}