@IsTest
private with sharing class RollbackWizardExtTest {
    @TestSetup
    private static void setupData() {
        List<User> userList = TestDataFactory.createUsers();
        TestUtilities.enableLicenses(2, 2, 2, 2, 2);
        FeatureManagement.setPackageIntegerValue('CBM_Branches', 2);
        List<PermissionSet> permissionSets = [SELECT Id FROM PermissionSet WHERE Name IN ('Copado_User', 'Copado_Functions', 'Copado_Job_Engine')];
        List<PermissionSetAssignment> assignments = new List<PermissionSetAssignment>();
        for (PermissionSet permissionSet : permissionSets) {
            assignments.add(new PermissionSetAssignment(AssigneeId = userList[0].Id, PermissionSetId = permissionSet.Id));
        }
        insert assignments;
    }

    @IsTest
    private static void givenCompletedPromotionWhenRollbackThenCreateDeployment() {
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

            ContentVersion cv = createContentVersion('Rollback Index',step.Id);
            insert cv;

            // Exercise

            Test.startTest();

            PageReference pReference = Page.RollbackWizard;
            pReference.getParameters().put('id', promotion.Id);
            Test.setCurrentPage(pReference);

            ApexPages.StandardController sc = new ApexPages.StandardController(promotion);
            RollbackWizardExt controller = new RollbackWizardExt(sc);
            PageReference redirectedPage = controller.redirectToCorrectPage();

            Test.stopTest();

            // Verify

            String generalHeader = controller.deploymentInterface.getStepGeneralHeader();
            System.assertEquals('Rollback', generalHeader, 'Deployment handler should be Rollback (beta)');

            Deployment__c rollbackDeployment = [SELECT Name FROM Deployment__c WHERE Rolled_Back_Deployment__c = :deployment.Id];
            System.assertEquals('Rollback DEPLOYMENT_NAME', rollbackDeployment.Name, 'Rollback deployment name mismatches');

            PageReference expectedPage = Page.RollbackWizardStart;
            expectedPage.getParameters().put('id', rollbackDeployment.Id);
            System.assert(redirectedPage.getUrl().toLowerCase().contains(expectedPage.getUrl().toLowerCase()), 'Unexpected redirection URL');
        }
    }

    private static User getAdminUserWithLicense() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true, true);
        return sysUser;
    }
    
    private static ContentVersion createContentVersion(String title, Id stepId){
        ContentVersion cv = new ContentVersion();
            cv.Title = title;
            cv.PathOnClient = title;
            cv.VersionData = Blob.valueOf(
                '[{"t":"ApexClass","n":"DemoClass","b":"Gabriel Serrano","d":"2020-09-15","cb":"Gabriel Serrano","cd":"2020-08-04","r":false,"cmm":"updated","snapshotCommitId":"a0M1n00001QD11mEAD"}]'
            );
            cv.FirstPublishLocationId = stepId;
        return cv;
    }
}