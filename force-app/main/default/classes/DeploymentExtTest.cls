@SuppressWarnings('PMD')
@IsTest
private with sharing class DeploymentExtTest {
    
    private static final string CCD_DISABLED_CAUSE_CONN_BEHAVIOR_EXIST_ON_PIPELINE = 'CCD shows as not enabled even though there is a connection behavior on the given pipeline.';
    private static final string DEST_ORG_INCORRECTLY_INIT = 'The destination org(s) were not correctly initialized.';

    @TestSetup
    static void setupData() {
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
    private static void testInitDestination() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true);

        System.runAs(sysUser) {
            // Connection Behavior creation
            Connection_Behavior__c connectionBehavior = TestDataFactory.createConnectionBehavior('Manual', 'Manual', 'Completed');
            insert connectionBehavior;

            // Quality Gate creation
            Quality_Gate__c qualityGate = TestDataFactory.createQualityGate(null, null, connectionBehavior.Id, null, null, 'Pull Request', '', 1);
            insert qualityGate;

            //Environment creation
            List<Environment__c> environments = new List<Environment__c>();
            for (Integer i = 0; i < 3; i++) {
                Environment__c environment = TestDataFactory.createEnvironments('Environment ' + i, 'Production/Developer');
                environment.Connection_Behavior__c = connectionBehavior.Id;
                environments.add(environment);
            }
            insert environments;

            // Org Credential creation
            List<Org__c> credentials = TestDataFactory.createOrgCredentials(3, sysUser.Username, environments);

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
            deploymentFlowStep1.Connection_Behavior_Override__c = connectionBehavior.Id;
            deploymentFlowStep1.Branch__c = 'dev1';
            Deployment_Flow_Step__c deploymentFlowStep2 = TestDataFactory.createDeploymentFlowStep(
                environments[1].Id,
                environments[2].Id,
                deploymentFlow.Id,
                ''
            );
            deploymentFlowStep2.Connection_Behavior_Override__c = connectionBehavior.Id;
            deploymentFlowStep1.Branch__c = 'dev2';
            insert new List<Deployment_Flow_Step__c>{ deploymentFlowStep1, deploymentFlowStep2 };

            // Project creation
            Project__c project = TestDataFactory.createProject('My project', deploymentFlow.Id, false);
            insert project;

            // Promotion creation
            Promotion__c promotion = TestDataFactory.createPromotion(
                project.Id,
                credentials[2].Id,
                environments[2].Id,
                credentials[1].Id,
                environments[1].Id,
                'Draft'
            );
            insert promotion;

            // Deployment creation
            String advancedDeploymentRecordTypeId = Schema.Sobjecttype.Deployment__c.getRecordTypeInfosByDeveloperName()
                .get('Advanced_multi_step')
                .getRecordTypeId();
            Deployment__c deployment = TestDataFactory.createDeployment('DEPLOYMENT_NAME', advancedDeploymentRecordTypeId, credentials[2].Id);
            deployment.Date__c = System.now();
            deployment.Deployment_command_sent__c = System.now();
            deployment.Schedule__c = 'Deploy now';
            deployment.Status__c = 'Pending';
            deployment.Promotion__c = promotion.Id;
            insert deployment;

            // Destination Org creation
            Destination_Org__c destinationOrg = TestDataFactory.createDestinationOrg(deployment.Id, credentials[1].Id);
            insert destinationOrg;

            PageReference thisPage = Page.Deployment;
            thisPage.getParameters().put('id', deployment.id);
            Test.setCurrentPage(thisPage);

            String requestString =
                '{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"' +
                credentials[0].sfdc_org_id__c +
                '","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":true,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mXSBAA2","roleId__is_set":true,"sessionSecondsValid__is_set":true,"sessionSecondsValid":7200,"userDefaultCurrencyIsoCode__is_set":true,"userDefaultCurrencyIsoCode":"GBP","userEmail__is_set":true,"userEmail":"pr@copado.com","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000QubcAAC","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copado.com.mainorg","userTimeZone__is_set":true,"userTimeZone":"Europe/London","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}';
            Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(requestString, null));

            Test.startTest();
            DeploymentExt ext = new DeploymentExt(new ApexPages.StandardController(deployment));
            System.assert(ext.destinations.size() == 1, DEST_ORG_INCORRECTLY_INIT);
            System.assert(ext.ccdEnabled, CCD_DISABLED_CAUSE_CONN_BEHAVIOR_EXIST_ON_PIPELINE);
            Test.stopTest();
        }
    }

    @IsTest
    private static void testController() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true);

        System.runAs(sysUser) {
            List<Org__c> orgs = new List<Org__c>();
            Org__c testFromOrg = TestMethodUtilities.createOrg('OrgName', 'Production', 'SFDC_OrgId', 'SFDC_TOKEN', 'USERNAME', System.now());
            orgs.add(testFromOrg);
            Org__c testToOrg = TestMethodUtilities.createOrg('OrgName2', 'Production', 'SFDC_OrgId2', 'SFDC_TOKEN2', 'USERNAME', System.now());
            Org__c testToOrg2 = TestMethodUtilities.createOrg('OrgName3', 'Production', 'SFDC_OrgId3', 'SFDC_TOKEN3', 'USERNAME', System.now());
            Org__c testToOrg3 = TestMethodUtilities.createOrg('OrgName4', 'Production', 'SFDC_OrgId4', 'SFDC_TOKEN4', 'USERNAME', System.now());
            Org__c testToOrg4 = TestMethodUtilities.createOrg('OrgName5', 'Production', 'SFDC_OrgId5', 'SFDC_TOKEN5', 'USERNAME', System.now());
            Org__c testToOrg5 = TestMethodUtilities.createOrg('OrgName6', 'Production', 'SFDC_OrgId6', 'SFDC_TOKEN6', 'USERNAME', System.now());
            orgs.add(testToOrg);
            orgs.add(testToOrg2);
            orgs.add(testToOrg3);
            orgs.add(testToOrg4);
            orgs.add(testToOrg5);

            insert orgs;

            Deployment__c testDeployment = TestMethodUtilities.create(
                'DEPLOYMENT_NAME',
                System.now(),
                System.now(),
                testFromOrg.Id,
                'Deploy now',
                'Scheduled'
            );
            insert testDeployment;
            List<Step__c> steps = new List<Step__c>();
            Step__c testStep = TestMethodUtilities.create('Step 1', 'attId', 'JSONString', testDeployment.Id, 0, 'Not started', 'MetaData');
            steps.add(testStep);
            for (Integer i = 0; i < 199; i++) {
                Step__c temp = TestMethodUtilities.create('Step ' + i, 'attId', 'JSONString', testDeployment.Id, 0, 'Not started', 'Manual Task');
                steps.add(temp);
            }
            insert steps;
            List<Destination_Org__c> destinationOrgs = new List<Destination_Org__c>();

            Destination_Org__c testDestOrg = TestMethodUtilities.create(testDeployment.Id, 'Draft', testFromOrg.Id);
            destinationOrgs.add(testDestOrg);

            Destination_Org__c testDestOrg2 = TestMethodUtilities.create(testDeployment.Id, 'Draft', testToOrg.Id);
            destinationOrgs.add(testDestOrg2);

            Destination_Org__c testDestOrg3 = TestMethodUtilities.create(testDeployment.Id, 'Draft', testToOrg2.Id);
            destinationOrgs.add(testDestOrg3);

            Destination_Org__c testDestOrg4 = TestMethodUtilities.create(testDeployment.Id, 'Draft', testToOrg3.Id);
            destinationOrgs.add(testDestOrg4);

            Destination_Org__c testDestOrg5 = TestMethodUtilities.create(testDeployment.Id, 'Draft', testToOrg4.Id);
            destinationOrgs.add(testDestOrg5);

            Destination_Org__c testDestOrg6 = TestMethodUtilities.create(testDeployment.Id, 'Draft', testToOrg5.Id);
            destinationOrgs.add(testDestOrg6);

            insert destinationOrgs;
            PageReference pref = Page.DeploymentWizard;
            pref.getParameters().put('id', testDeployment.id);
            Test.setCurrentPage(pref);

            String b =
                '{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"' +
                testFromOrg.sfdc_org_id__c +
                '","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":true,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mXSBAA2","roleId__is_set":true,"sessionSecondsValid__is_set":true,"sessionSecondsValid":7200,"userDefaultCurrencyIsoCode__is_set":true,"userDefaultCurrencyIsoCode":"GBP","userEmail__is_set":true,"userEmail":"pr@copado.com","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000QubcAAC","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copado.com.mainorg","userTimeZone__is_set":true,"userTimeZone":"Europe/London","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}';
            Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));

            Test.startTest();
            DeploymentExt ext = new DeploymentExt(new ApexPages.StandardController(testDeployment));
            System.assert(ext.destinations.size() > 1, DEST_ORG_INCORRECTLY_INIT);

            ext.saveDeployment();
            ext.addDestination();
            ext.saveDestination();
            ext.getJobsManagerMatchingKey();

            System.assert(ext.destinations.size() > 1, DEST_ORG_INCORRECTLY_INIT);

            // Save again with a destination Org
            ext.destinations[0] = testDestOrg2;
            ext.destinations[1] = testDestOrg3;
            ext.destinations[2] = testDestOrg4;
            ext.destinations[3] = testDestOrg5;
            ext.destinations[4] = testDestOrg6;

            ext.saveDestination();
            //ext.addMsgOk('a');
            //ext.addMsgError('a');
            ext.getDestinationsJson();
            ext.getStepsJson();
            ext.getDepJson();
            ext.getjsonMessagesQueue();
            ext.deleteDestOrg();
            ext.getHistoryVisible();

            System.assert(ext.destinations.size() > 1, DEST_ORG_INCORRECTLY_INIT);

            DeploymentExt.sortSteps(new List<String>{ testStep.Id });
            Id stepId = testStep.Id;
            DeploymentExt.deleteStep(testStep.Id);
            List<Step__c> stepList = [SELECT Id FROM Step__c WHERE Id = :stepId];
            System.assert(stepList.isEmpty(), 'Failed to delete selected step.');
            DeploymentExt.getisChatterEnabled();
            Test.stopTest();
        }
    }

    @IsTest
    private static void testSaveDestinationWithPromotion() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true);

        System.runAs(sysUser) {
            // Connection Behavior creation
            Connection_Behavior__c connectionBehavior = TestDataFactory.createConnectionBehavior('Manual', 'Manual', 'Completed');
            insert connectionBehavior;

            // Quality Gate creation
            Quality_Gate__c qualityGate = TestDataFactory.createQualityGate(null, null, connectionBehavior.Id, null, null, 'Pull Request', '', 1);
            insert qualityGate;

            //Environment creation
            List<Environment__c> environments = new List<Environment__c>();
            for (Integer i = 0; i < 3; i++) {
                Environment__c environment = TestDataFactory.createEnvironments('Environment ' + i, 'Production/Developer');
                environment.Connection_Behavior__c = connectionBehavior.Id;
                environments.add(environment);
            }
            insert environments;

            // Org Credential creation
            List<Org__c> credentials = TestDataFactory.createOrgCredentials(3, sysUser.Username, environments);

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
            deploymentFlowStep1.Connection_Behavior_Override__c = connectionBehavior.Id;
            deploymentFlowStep1.Branch__c = 'dev1';
            Deployment_Flow_Step__c deploymentFlowStep2 = TestDataFactory.createDeploymentFlowStep(
                environments[1].Id,
                environments[2].Id,
                deploymentFlow.Id,
                ''
            );
            deploymentFlowStep2.Connection_Behavior_Override__c = connectionBehavior.Id;
            deploymentFlowStep1.Branch__c = 'dev2';
            insert new List<Deployment_Flow_Step__c>{ deploymentFlowStep1, deploymentFlowStep2 };

            // Project creation
            Project__c project = TestDataFactory.createProject('My project', deploymentFlow.Id, false);
            insert project;

            // Promotion creation
            Promotion__c promotion = TestDataFactory.createPromotion(
                project.Id,
                credentials[2].Id,
                environments[2].Id,
                credentials[1].Id,
                environments[1].Id,
                'Draft'
            );
            insert promotion;

            // Deployment creation
            String advancedDeploymentRecordTypeId = Schema.Sobjecttype.Deployment__c.getRecordTypeInfosByDeveloperName()
                .get('Advanced_multi_step')
                .getRecordTypeId();
            Deployment__c deployment = TestDataFactory.createDeployment('DEPLOYMENT_NAME', advancedDeploymentRecordTypeId, credentials[2].Id);
            deployment.Date__c = System.now();
            deployment.Deployment_command_sent__c = System.now();
            deployment.Schedule__c = 'Deploy now';
            deployment.Status__c = 'Pending';
            deployment.Promotion__c = promotion.Id;
            insert deployment;

            // Destination Org creation
            Destination_Org__c destinationOrg = TestDataFactory.createDestinationOrg(deployment.Id, credentials[1].Id);
            insert destinationOrg;

            PageReference pref = Page.DeploymentWizard;
            pref.getParameters().put('id', deployment.Id);
            Test.setCurrentPage(pref);

            MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200, 'Complete', '{"example":"test"}', null);
            Test.setMock(HttpCalloutMock.class, fakeResponse);

            Test.startTest();
            DeploymentExt ext = new DeploymentExt(new ApexPages.StandardController(deployment));
            for (Destination_Org__c destination : ext.destinations) {
                destination.To_Org__c = destinationOrg.Id;
            }

            ext.saveDestination();
            System.assert(ext.destinations.size() == 1, DEST_ORG_INCORRECTLY_INIT);
            System.assert(ext.ccdEnabled, CCD_DISABLED_CAUSE_CONN_BEHAVIOR_EXIST_ON_PIPELINE);
            Test.stopTest();
        }
    }

    @IsTest
    private static void saveDestination() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true);

        System.runAs(sysUser) {
            List<Org__c> orgs = new List<Org__c>();
            Org__c testFromOrg = TestMethodUtilities.createOrg('OrgName', 'Production', 'SFDC_OrgId', 'SFDC_TOKEN', 'USERNAME', System.now());
            orgs.add(testFromOrg);
            Org__c testToOrg = TestMethodUtilities.createOrg('OrgName2', 'Production', 'SFDC_OrgId2', 'SFDC_TOKEN2', 'USERNAME', System.now());
            Org__c testToOrg2 = TestMethodUtilities.createOrg('OrgName3', 'Production', 'SFDC_OrgId3', 'SFDC_TOKEN3', 'USERNAME', System.now());
            Org__c testToOrg3 = TestMethodUtilities.createOrg('OrgName4', 'Production', 'SFDC_OrgId4', 'SFDC_TOKEN4', 'USERNAME', System.now());
            Org__c testToOrg4 = TestMethodUtilities.createOrg('OrgName5', 'Production', 'SFDC_OrgId5', 'SFDC_TOKEN5', 'USERNAME', System.now());
            Org__c testToOrg5 = TestMethodUtilities.createOrg('OrgName6', 'Production', 'SFDC_OrgId6', 'SFDC_TOKEN6', 'USERNAME', System.now());
            orgs.add(testToOrg);
            orgs.add(testToOrg2);
            orgs.add(testToOrg3);
            orgs.add(testToOrg4);
            orgs.add(testToOrg5);
            insert orgs;

            Deployment__c testDeployment = TestMethodUtilities.create(
                'DEPLOYMENT_NAME',
                System.now(),
                System.now(),
                testFromOrg.Id,
                'Deploy now',
                'Scheduled'
            );
            insert testDeployment;

            List<Step__c> steps = new List<Step__c>();
            Step__c testStep = TestMethodUtilities.create('Step 1', 'attId', 'JSONString', testDeployment.Id, 0, 'Not started', 'MetaData');
            steps.add(testStep);
            for (Integer i = 0; i < 199; i++) {
                Step__c temp = TestMethodUtilities.create('Step ' + i, 'attId', 'JSONString', testDeployment.Id, 0, 'Not started', 'Manual Task');
                steps.add(temp);
            }
            insert steps;

            List<Destination_Org__c> destinationOrgs = new List<Destination_Org__c>();
            Destination_Org__c testDestOrg = TestMethodUtilities.create(testDeployment.Id, 'Draft', testFromOrg.Id);
            destinationOrgs.add(testDestOrg);
            Destination_Org__c testDestOrg2 = TestMethodUtilities.create(testDeployment.Id, 'Draft', testToOrg.Id);
            destinationOrgs.add(testDestOrg2);
            Destination_Org__c testDestOrg3 = TestMethodUtilities.create(testDeployment.Id, 'Draft', testToOrg2.Id);
            destinationOrgs.add(testDestOrg3);
            Destination_Org__c testDestOrg4 = TestMethodUtilities.create(testDeployment.Id, 'Draft', testToOrg3.Id);
            destinationOrgs.add(testDestOrg4);
            Destination_Org__c testDestOrg5 = TestMethodUtilities.create(testDeployment.Id, 'Draft', testToOrg4.Id);
            destinationOrgs.add(testDestOrg5);
            Destination_Org__c testDestOrg6 = TestMethodUtilities.create(testDeployment.Id, 'Draft', testToOrg5.Id);
            destinationOrgs.add(testDestOrg6);
            insert destinationOrgs;

            PageReference pref = Page.DeploymentWizard;
            pref.getParameters().put('id', testDeployment.id);
            Test.setCurrentPage(pref);

            Test.startTest();
            DeploymentExt ext = new DeploymentExt(new ApexPages.StandardController(testDeployment));

            ext.addDestination();
            for (Destination_Org__c dOrgs : ext.destinations) {
                dOrgs.To_Org__c = testDestOrg.Id;
            }
            MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200, 'Complete', '{"example":"test"}', null);
            Test.setMock(HttpCalloutMock.class, fakeResponse);
            ext.saveDestination();
            System.assert(ext.destinations.size() > 1, DEST_ORG_INCORRECTLY_INIT);
            Test.stopTest();
        }
    }

    @IsTest
    private static void validateOrgAndSaveDestination() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true);

        System.runAs(sysUser) {
            List<Org__c> orgs = new List<Org__c>();
            Org__c testFromOrg = TestMethodUtilities.createOrg('OrgName', 'Production', 'SFDC_OrgId', 'SFDC_TOKEN', 'USERNAME', System.now());
            orgs.add(testFromOrg);
            Org__c testToOrg = TestMethodUtilities.createOrg('OrgName2', 'Production', 'SFDC_OrgId2', 'SFDC_TOKEN2', 'USERNAME', System.now());
            Org__c testToOrg2 = TestMethodUtilities.createOrg('OrgName3', 'Production', 'SFDC_OrgId3', 'SFDC_TOKEN3', 'USERNAME', System.now());
            Org__c testToOrg3 = TestMethodUtilities.createOrg('OrgName4', 'Production', 'SFDC_OrgId4', 'SFDC_TOKEN4', 'USERNAME', System.now());
            Org__c testToOrg4 = TestMethodUtilities.createOrg('OrgName5', 'Production', 'SFDC_OrgId5', 'SFDC_TOKEN5', 'USERNAME', System.now());
            Org__c testToOrg5 = TestMethodUtilities.createOrg('OrgName6', 'Production', 'SFDC_OrgId6', 'SFDC_TOKEN6', 'USERNAME', System.now());
            orgs.add(testToOrg);
            orgs.add(testToOrg2);
            orgs.add(testToOrg3);
            orgs.add(testToOrg4);
            orgs.add(testToOrg5);

            insert orgs;

            Deployment__c testDeployment = TestMethodUtilities.create(
                'DEPLOYMENT_NAME',
                System.now(),
                System.now(),
                testFromOrg.Id,
                'Deploy now',
                'Scheduled'
            );
            insert testDeployment;
            List<Step__c> steps = new List<Step__c>();
            Step__c testStep = TestMethodUtilities.create('Step 1', 'attId', 'JSONString', testDeployment.Id, 0, 'Not started', 'Git Promotion');
            steps.add(testStep);
            for (Integer i = 0; i < 199; i++) {
                Step__c temp = TestMethodUtilities.create('Step ' + i, 'attId', 'JSONString', testDeployment.Id, 0, 'Not started', 'Manual Task');
                steps.add(temp);
            }
            insert steps;

            List<Attachment> attachmentList = new List<Attachment>();
            Attachment att = new Attachment();
            att.Body = Blob.valueOf('{"flow_id" : "123456789" ,"target_branch" : "master"}');
            att.Name = 'Git-Promotion.json';
            att.ParentId = testStep.Id;
            attachmentList.add(att);
            insert attachmentList;

            List<Destination_Org__c> destinationOrgs = new List<Destination_Org__c>();

            Destination_Org__c testDestOrg = TestMethodUtilities.create(testDeployment.Id, 'Draft', testFromOrg.Id);
            destinationOrgs.add(testDestOrg);

            Destination_Org__c testDestOrg2 = TestMethodUtilities.create(testDeployment.Id, 'Draft', testToOrg.Id);
            destinationOrgs.add(testDestOrg2);

            Destination_Org__c testDestOrg3 = TestMethodUtilities.create(testDeployment.Id, 'Draft', testToOrg2.Id);
            destinationOrgs.add(testDestOrg3);

            Destination_Org__c testDestOrg4 = TestMethodUtilities.create(testDeployment.Id, 'Draft', testToOrg3.Id);
            destinationOrgs.add(testDestOrg4);

            Destination_Org__c testDestOrg5 = TestMethodUtilities.create(testDeployment.Id, 'Draft', testToOrg4.Id);
            destinationOrgs.add(testDestOrg5);

            Destination_Org__c testDestOrg6 = TestMethodUtilities.create(testDeployment.Id, 'Draft', testToOrg5.Id);
            destinationOrgs.add(testDestOrg6);

            insert destinationOrgs;
            PageReference pref = Page.DeploymentWizard;
            pref.getParameters().put('id', testDeployment.id);
            Test.setCurrentPage(pref);

            Test.startTest();
            DeploymentExt ext = new DeploymentExt(new ApexPages.StandardController(testDeployment));

            MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200, 'Complete', '{"example":"test"}', null);
            Test.setMock(HttpCalloutMock.class, fakeResponse);

            ext.validateFromOrg();
            String matchingKey = ext.getJobsManagerMatchingKey();
            System.assert(String.isBlank(matchingKey), 'Matching key was returned from jobs manager for an invalidated org.');
            Test.stopTest();
        }
    }

    @IsTest
    static void deployAllNonSalesforcePlatform() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true);

        System.runAs(sysUser) {
            //Environment creation
            List<Environment__c> environments = new List<Environment__c>();
            for (Integer i = 0; i < 3; i++) {
                Environment__c environment = TestDataFactory.createEnvironments('Environment ' + i, 'Production/Developer');
                environment.Platform__c = 'Other';
                environments.add(environment);
            }
            insert environments;

            // Git repository creation
            Git_Repository__c gitRepository = TestDataFactory.createGitRepository();
            insert gitRepository;

            // Deployment flow creation
            Deployment_Flow__c deploymentFlow = TestDataFactory.createDeploymentFlow('Deployment Flow', true, gitRepository.Id, false);
            deploymentFlow.Main_Branch__c = 'master';
            deploymentFlow.Platform__c = 'Other';
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

            // Org Credential creation
            List<Org__c> credentials = [
                SELECT Id, Name, Platform__c, Oauth_Signature__c, Validated_Date__c, Disable_Validation__c, SFDC_Org_ID__c
                FROM Org__c
                WHERE Platform__c = 'Other'
            ];
            for (Org__c org : credentials) {
                org.Username__c = UserInfo.getUserName();
                org.SFDC_Org_ID__c = UserInfo.getOrganizationId() + '_' + UserInfo.getUserId();
                org.Oauth_Signature__c = org.Name;
                org.Validated_Date__c = System.now();
                org.Disable_Validation__c = true;
                break;
            }
            update credentials;

            // Project creation
            Project__c project = TestDataFactory.createProject('My project', deploymentFlow.Id, false);
            insert project;

            // Promotion creation
            Promotion__c promotion = TestDataFactory.createPromotion(
                project.Id,
                credentials[2].Id,
                environments[2].Id,
                credentials[1].Id,
                environments[1].Id,
                'Draft'
            );
            insert promotion;

            // Deployment creation
            String advancedDeploymentRecordTypeId = Schema.Sobjecttype.Deployment__c.getRecordTypeInfosByDeveloperName()
                .get('Advanced_multi_step')
                .getRecordTypeId();
            Deployment__c deployment = TestDataFactory.createDeployment('DEPLOYMENT_NAME', advancedDeploymentRecordTypeId, credentials[2].Id);
            deployment.Date__c = System.now();
            deployment.Deployment_command_sent__c = System.now();
            deployment.Schedule__c = 'Deploy now';
            deployment.Status__c = 'Pending';
            deployment.Promotion__c = promotion.Id;
            insert deployment;

            // Destination Org creation
            Destination_Org__c destinationOrg = TestDataFactory.createDestinationOrg(deployment.Id, credentials[1].Id);
            insert destinationOrg;

            // Function creation
            Function__c function = new Function__c(
                Name = 'muleDeploy',
                API_Name__c = 'muleDeploy',
                Script__c = 'echo hello world $par1',
                Type__c = 'Custom',
                Parameters__c = '[{"name": "SourceDBName", "defaultValue": "{!$Source.Property.DBName}", "required": true},' +
                    '{"name": "DestinationDBProvider", "defaultValue": "{!$Destination.Property.DB-Provider}", "required": true},' +
                    '{"name": "PipelineUsername", "defaultValue": "{!$Pipeline.Property.Username}", "required": true},' +
                    '{"name": "UserEmail", "defaultValue": "{!$User.Property.Email}", "required": true},' +
                    '{"name": "LogLevel", "defaultValue": "ERROR", "required": false}]',
                Options__c = '[{"name": "gitUrl", "value": "xxxxxx", "sensitive": true},' +
                    '{"name": "gitUsername", "value": "", "sensitive": true},' +
                    '{"name": "gitPassword", "value": "", "sensitive": true},' +
                    '{"name": "branchName", "value": "", "sensitive": false}]',
                Callback_Type__c = 'ApexClass',
                ApexClass__c = namespacePrefix() + 'FunctionStepExecutionCallback'
            );
            insert function;

            // Step creation
            Step__c functionStep = TestDataFactory.createStep(
                deployment.Id,
                'Function',
                'Function',
                'Not started',
                1,
                null,
                '{"functionId":"' +
                function.Id +
                '","functionAPIName":"' +
                function.API_Name__c +
                '","functionParameters":[{"name":"SourceDBName","value":"11"},{"name":"DestinationDBProvider","value":"22"},{"name":"PipelineUsername","value":"33"},{"name":"UserEmail","value":"44"},{"name":"LogLevel","value":"ERROR"}]}'
            );
            insert new List<Step__c>{ functionStep };

            Personal_Settings__c ps = Personal_Settings__c.getInstance();
            if (String.isBlank(ps.API_Key__c)) {
                ps.API_Key__c = DeployAPI.encryptAPIKey('99999999999999999999');
                upsert ps;
            }

            Test.startTest();
            PageReference pReference = Page.Deployment;
            pReference.getParameters().put('id', deployment.Id);
            pReference.getParameters().put('gotoStep', 'deployNow');
            Test.setCurrentPage(pReference);

            DeploymentExt ext = new DeploymentExt(new ApexPages.StandardController(deployment));
            ext.deployment.Date__c = System.today().addDays(1);
            ext.deployment.Schedule__c = 'Deploy later';
            ext.deployment.Schedule__c = 'Deploy now';
            ext.deployment.Date__c = System.today().addDays(0);
            ext.confirmAll();
            ext.confirm();
            MockHttpResponseGenerator mockResponse = new MockHttpResponseGenerator(
                200,
                'Complete',
                '{"id": "123123123", "status": "pending", "messages": ["function received and Queued", "executin will start shortly"]}',
                null
            );
            Test.setMock(HttpCalloutMock.class, mockResponse);

            ext.deployCall();
            Integer messageCount = ext.getPageMessageSize();
            System.assertEquals(0, messageCount);
            System.assertEquals(true, ext.goToDeployment);

            Result__c result = new Result__c();
            result.Function__c = function.Id;
            result.Job_Type__c = 'function';
            insert result;

            EventBus.publish(
                new MC_Result__e(
                    ResultId__c = result.Id,
                    isFinished__c = true,
                    isSuccess__c = true,
                    Progress_Status__c = 'Job enqueued on the backend'
                )
            );

            Test.stopTest();
        }
    }

    private static String namespacePrefix() {
        return Settings.ns.replace('__', '.');
    }
}