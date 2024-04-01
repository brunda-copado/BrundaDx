@IsTest
private with sharing class RollbackWizardStartExtTest {
    @TestSetup
    private static void setupData() {
        List<User> userList = TestDataFactory.createUsers();
        TestUtilities.enableLicenses(2, 2, 2, 2, 2);
        FeatureManagement.setPackageIntegerValue('CBM_Branches', 2);
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Copado_User'];
        insert new PermissionSetAssignment(AssigneeId = userList[0].Id, PermissionSetId = ps.Id);
    }

    @IsTest
    private static void givenRollbackDeploymentWhenConditionsAreMetThenCheckIsAvailable() {
        User sysUser = getAdminUserWithLicense();

        System.runAs(sysUser) {
            // Setup

            List<Environment__c> environments = new List<Environment__c>();
            for (Integer i = 0; i < 3; i++) {
                Environment__c environment = TestDataFactory.createEnvironments('Environment ' + i, 'Production/Developer');
                environment.Enable_Rollback__c = true;
                environments.add(environment);
            }
            insert environments;

            List<Org__c> credentials = TestDataFactory.createOrgCredentials(3, sysUser.Username, environments);

            Git_Repository__c gitRepository = TestDataFactory.createGitRepository();
            insert gitRepository;

            Deployment_Flow__c deploymentFlow = TestDataFactory.createDeploymentFlow('Deployment Flow', true, gitRepository.Id, false);
            deploymentFlow.Main_Branch__c = 'master';
            insert deploymentFlow;

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

            Project__c project = TestDataFactory.createProject('My project', deploymentFlow.Id, false);
            insert project;

            Promotion__c promotion = TestDataFactory.createPromotion(
                project.Id,
                credentials[2].Id,
                environments[2].Id,
                credentials[1].Id,
                environments[1].Id,
                'Completed'
            );
            insert promotion;

            String advancedDeploymentRecordTypeId = Schema.Sobjecttype.Deployment__c.getRecordTypeInfosByDeveloperName()
                .get('Advanced_multi_step')
                .getRecordTypeId();
            Deployment__c deployment = TestDataFactory.createDeployment('DEPLOYMENT_NAME', advancedDeploymentRecordTypeId, credentials[2].Id);
            deployment.Date__c = System.now();
            deployment.Deployment_command_sent__c = System.now();
            deployment.Schedule__c = 'Deploy now';
            deployment.Status__c = 'Completed successfully';
            deployment.Promotion__c = promotion.Id;
            insert deployment;

            Destination_Org__c destinationOrg = TestDataFactory.createDestinationOrg(deployment.Id, credentials[1].Id);
            insert destinationOrg;

            Step__c step = TestDataFactory.createStep(deployment.Id, 'Step 1', 'Git Promotion', 'Completed Successfully', 1, null, null);
            insert step;

            ContentVersion cv = new ContentVersion();
            cv.Title = 'Rollback Index';
            cv.PathOnClient = 'Rollback Index';
            cv.VersionData = Blob.valueOf(
                '[{"t":"ApexClass","n":"DemoClass","b":"Gabriel Serrano","d":"2020-09-15","cb":"Gabriel Serrano","cd":"2020-08-04","r":false,"cmm":"updated","snapshotCommitId":"a0M1n00001QD11mEAD"}]'
            );
            cv.FirstPublishLocationId = step.Id;
            insert cv;

            Deployment__c rollbackDeployment = TestDataFactory.createDeployment('Rollback DEPLOYMENT_NAME', advancedDeploymentRecordTypeId, null);
            rollbackDeployment.Date__c = System.now();
            rollbackDeployment.Deployment_command_sent__c = System.now();
            rollbackDeployment.Schedule__c = 'Deploy now';
            rollbackDeployment.Status__c = 'Draft';
            rollbackDeployment.Rolled_Back_Deployment__c = deployment.Id;
            insert rollbackDeployment;

            Destination_Org__c rollbackDestinationOrg = TestDataFactory.createDestinationOrg(rollbackDeployment.Id, credentials[1].Id);
            insert rollbackDestinationOrg;

            // Exercise

            Test.startTest();

            PageReference pReference = Page.RollbackWizardStart;
            pReference.getParameters().put('id', rollbackDeployment.Id);
            Test.setCurrentPage(pReference);

            ApexPages.StandardController sc = new ApexPages.StandardController(rollbackDeployment);
            RollbackWizardStartExt controller = new RollbackWizardStartExt(sc);
            PageReference redirectedNextPage = controller.saveAndGoToNextStep();
            PageReference redirectedPreviousPage = controller.goToPreviousStep();

            Test.stopTest();

            // Verify

            List<DeploymentHelper.SourceWrapper> steps = controller.sourceList;
            System.assertEquals(1, steps.size(), 'Steps list should contain exactly 1 step');
            System.assert(steps[0].rollbackAvailable, 'Step should be available for rollback');

            PageReference expectedPage = Page.DW_SelectChanges;
            expectedPage.getParameters().put('id', rollbackDeployment.Id);
            System.assert(redirectedNextPage.getUrl().toLowerCase().contains(expectedPage.getUrl().toLowerCase()), 'Unexpected redirection URL');
            System.assert(redirectedPreviousPage.getUrl().toLowerCase().contains(pReference.getUrl().toLowerCase()), 'Unexpected redirection URL');
        }
    }

    @IsTest
    private static void givenRollbackDeploymentWhenStepIsValidationThenCheckIsNotAvailable() {
        User sysUser = getAdminUserWithLicense();

        System.runAs(sysUser) {
            // Setup

            List<Environment__c> environments = new List<Environment__c>();
            for (Integer i = 0; i < 3; i++) {
                Environment__c environment = TestDataFactory.createEnvironments('Environment ' + i, 'Production/Developer');
                environment.Enable_Rollback__c = true;
                environments.add(environment);
            }
            insert environments;

            List<Org__c> credentials = TestDataFactory.createOrgCredentials(3, sysUser.Username, environments);

            Git_Repository__c gitRepository = TestDataFactory.createGitRepository();
            insert gitRepository;

            Deployment_Flow__c deploymentFlow = TestDataFactory.createDeploymentFlow('Deployment Flow', true, gitRepository.Id, false);
            deploymentFlow.Main_Branch__c = 'master';
            insert deploymentFlow;

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

            Project__c project = TestDataFactory.createProject('My project', deploymentFlow.Id, false);
            insert project;

            Promotion__c promotion = TestDataFactory.createPromotion(
                project.Id,
                credentials[2].Id,
                environments[2].Id,
                credentials[1].Id,
                environments[1].Id,
                'Completed'
            );
            insert promotion;

            String advancedDeploymentRecordTypeId = Schema.Sobjecttype.Deployment__c.getRecordTypeInfosByDeveloperName()
                .get('Advanced_multi_step')
                .getRecordTypeId();
            Deployment__c deployment = TestDataFactory.createDeployment('DEPLOYMENT_NAME', advancedDeploymentRecordTypeId, credentials[2].Id);
            deployment.Date__c = System.now();
            deployment.Deployment_command_sent__c = System.now();
            deployment.Schedule__c = 'Deploy now';
            deployment.Status__c = 'Completed successfully';
            deployment.Promotion__c = promotion.Id;
            insert deployment;

            Destination_Org__c destinationOrg = TestDataFactory.createDestinationOrg(deployment.Id, credentials[1].Id);
            insert destinationOrg;

            Step__c step = TestDataFactory.createStep(deployment.Id, 'Step 1', 'Git Promotion', 'Completed Successfully', 1, null, null);
            step.checkOnly__c = true;
            insert step;

            ContentVersion cv = new ContentVersion();
            cv.Title = 'Rollback Index';
            cv.PathOnClient = 'Rollback Index';
            cv.VersionData = Blob.valueOf(
                '[{"t":"ApexClass","n":"DemoClass","b":"Gabriel Serrano","d":"2020-09-15","cb":"Gabriel Serrano","cd":"2020-08-04","r":false,"cmm":"updated","snapshotCommitId":"a0M1n00001QD11mEAD"}]'
            );
            cv.FirstPublishLocationId = step.Id;
            insert cv;

            Deployment__c rollbackDeployment = TestDataFactory.createDeployment('Rollback DEPLOYMENT_NAME', advancedDeploymentRecordTypeId, null);
            rollbackDeployment.Date__c = System.now();
            rollbackDeployment.Deployment_command_sent__c = System.now();
            rollbackDeployment.Schedule__c = 'Deploy now';
            rollbackDeployment.Status__c = 'Draft';
            rollbackDeployment.Rolled_Back_Deployment__c = deployment.Id;
            insert rollbackDeployment;

            Destination_Org__c rollbackDestinationOrg = TestDataFactory.createDestinationOrg(rollbackDeployment.Id, credentials[1].Id);
            insert rollbackDestinationOrg;

            // Exercise

            Test.startTest();

            PageReference pReference = Page.RollbackWizardStart;
            pReference.getParameters().put('id', rollbackDeployment.Id);
            Test.setCurrentPage(pReference);

            ApexPages.StandardController sc = new ApexPages.StandardController(rollbackDeployment);
            RollbackWizardStartExt controller = new RollbackWizardStartExt(sc);
            controller.saveAndGoToNextStep();

            Test.stopTest();

            // Verify

            List<DeploymentHelper.SourceWrapper> steps = controller.sourceList;
            System.assertEquals(0, steps.size(), 'Steps list should be empty');
            System.assert(controller.pageMessagesMap.get('error').contains(Label.RollbackNoEligibleSteps));
        }
    }

    private static User getAdminUserWithLicense() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true, true);
        return sysUser;
    }
}