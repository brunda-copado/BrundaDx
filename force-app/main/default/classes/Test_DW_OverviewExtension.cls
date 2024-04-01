@SuppressWarnings('PMD')
@IsTest
private with sharing class Test_DW_OverviewExtension {
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

    /**
     *  Open the DW_Overview page and click on "Back" button
     */
    @IsTest
    private static void overviewBack() {
        User sysUser = getAdminUserWithLicense();

        System.runAs(sysUser) {
            Test.startTest();
            //Environment creation
            List<Environment__c> envList = TestDataFactory.createEnvironments(3);

            // Org Credential creation
            List<Org__c> orgList = TestDataFactory.createOrgCredentials(3, sysUser.Username, envList);

            // Deployment creation
            String metadataDeploymentRecordTypeId = Schema.Sobjecttype.Deployment__c.getRecordTypeInfosByName()
                .get('Metadata Deployment')
                .getRecordTypeId();
            Deployment__c deployment = TestDataFactory.createDeployment('Test Dev 1', metadataDeploymentRecordTypeId, orgList[2].Id);
            deployment.Deployment_Last_Step__c = 'DW_Overview';
            insert deployment;

            // Destination Org creation
            Destination_Org__c destinationOrg = TestDataFactory.createDestinationOrg(deployment.Id, orgList[1].Id);
            insert destinationOrg;

            // Step creation
            Step__c step = TestDataFactory.createStep(deployment.Id, 'Step 1', 'Rollback', 'Not Started', 1, null, '');
            insert step;

            // Attachment creation
            String attBody = '[{"n":"Test_AccountTrigger","s":true,"d":"2018-05-07","b":"Ferhat Ozsavran","cd":"2017-11-13","cb":"Ferhat Ozsavran","r":false,"t":"ApexClass"},{"n":"AccountTriggerHandler","s":true,"d":"2018-03-06","b":"Ferhat Ozsavran","cd":"2017-11-13","cb":"Ferhat Ozsavran","r":false,"t":"ApexClass"},{"n":"AccountTrigger","s":true,"d":"2018-02-19","b":"Ferhat Ozsavran","cd":"2017-11-13","cb":"Ferhat Ozsavran","r":false,"t":"ApexTrigger"}]';
            Attachment att = TestDataFactory.createAttachment('MetaData', step.Id, attBody);
            insert att;

            PageReference pReference = Page.DW_Overview;
            pReference.getParameters().put('id', deployment.Id);
            pReference.getParameters().put('MetadataPreselectionId', att.Id);
            Test.setCurrentPage(pReference);

            ApexPages.StandardController sc = new ApexPages.StandardController(deployment);
            DW_OverviewExtension controller = new DW_OverviewExtension(sc);
            System.assertEquals(deployment.Id, controller.deployment.Id);
            System.assertEquals(att.Id, controller.attId);
            System.assertEquals(step.Id, controller.stepId, 'There should be 1 related step');
            System.assertEquals(metadataDeploymentRecordTypeId, controller.deployment.RecordTypeId);
            System.assertEquals(6, controller.pagesList.size());
            System.assertEquals(6, controller.stepsList.size());
            System.assertEquals(0, controller.pageMessagesMap.size());
            System.assertNotEquals(null, controller.deploymentInterface);
            System.assertEquals(3, controller.currentStepValue);

            String generalHeader = controller.deploymentInterface.getStepGeneralHeader();
            System.assertEquals(generalHeader, Label.New_Deployment);

            List<SelectOption> optionList = controller.getTestLevels();
            System.assertEquals(4, optionList.size());

            Boolean enableButtons = controller.getEnableButtons();
            System.assertEquals(true, enableButtons);
            System.assertEquals(0, controller.pageMessagesMap.size());

            Destination_Org__c dOrg = controller.getDestinationOrg();
            System.assertEquals(destinationOrg.Id, dOrg.Id);

            PageReference returnedPage = controller.goToPreviousStep();
            PageReference expectedPage = Page.DW_SelectChanges;
            expectedPage.getParameters().put('id', controller.deployment.Id);
            Boolean urlContains = returnedPage.getUrl().toLowerCase().contains(expectedPage.getUrl().toLowerCase());
            System.assertEquals(true, urlContains);

            Test.stopTest();
        }
    }

    /**
     * Open the DW_Overview page and click on "Back" button
     */
    @IsTest
    private static void overviewBackForDataDeployment() {
        User sysUser = getAdminUserWithLicense();

        System.runAs(sysUser) {
            Test.startTest();
            //Environment creation
            List<Environment__c> envList = TestDataFactory.createEnvironments(3);

            // Org Credential creation
            List<Org__c> orgList = TestDataFactory.createOrgCredentials(3, sysUser.Username, envList);

            Data_Template__c dt = TestDataFactory.createDataTemplate(
                'Main Account Template FO',
                'Account',
                '1 OR (2 AND (3 OR 4 OR 5) AND 6)',
                orgList[2].Id
            );
            Data_Template__c dt1 = TestDataFactory.createDataTemplate('FO Copado', 'FO_Copado__c', '1 OR (2 AND (3 OR 4 OR 5) AND 6)', orgList[2].Id);
            Data_Template__c dt2 = TestDataFactory.createDataTemplate('Parent Account', 'Account', '1 OR (2 AND (3 OR 4 OR 5) AND 6)', orgList[2].Id);
            Data_Template__c dt3 = TestDataFactory.createDataTemplate('Contact', 'Contact', '1 OR (2 AND (3 OR 4 OR 5) AND 6)', orgList[2].Id);
            Data_Template__c dt4 = TestDataFactory.createDataTemplate(
                'Opportunity',
                'Opportunity',
                '1 OR (2 AND (3 OR 4 OR 5) AND 6)',
                orgList[2].Id
            );

            insert new List<Data_Template__c>{ dt, dt1, dt2, dt3, dt4 };

            // Deployment creation
            String dataDeploymentRecordTypeId = Schema.Sobjecttype.Deployment__c.getRecordTypeInfosByName().get('Data Deployment').getRecordTypeId();
            Deployment__c deployment = TestDataFactory.createDeployment('Test Dev 1', dataDeploymentRecordTypeId, orgList[2].Id);
            deployment.Deployment_Last_Step__c = 'DW_Overview';
            insert deployment;

            // Destination Org creation
            Destination_Org__c destinationOrg = TestDataFactory.createDestinationOrg(deployment.Id, orgList[1].Id);
            insert destinationOrg;

            DeploymentHelper.StepAttachmentDetails sad = new DeploymentHelper.StepAttachmentDetails();
            sad.dataTemplateId = dt.Id;

            // Step creation
            Step__c step = TestDataFactory.createStep(deployment.Id, 'Step 1', 'Data Template', 'Not Started', 1, null, JSON.serialize(sad));
            insert step;

            // Attachment creation
            Attachment att3 = TestDataFactory.createAttachment('Data Template', step.Id, JSON.serialize(sad));

            String newAttBody = Test_DataTemplateSetupExtension.updateAttachmentBodyForNewTemplateIds(
                dt.Id,
                dt1.Id,
                dt2.Id,
                dt3.Id,
                dt4.Id,
                orgList[2].Id
            );

            Attachment att = TestDataFactory.createAttachment('Template Detail', dt.Id, newAttBody);
            Attachment att1 = TestDataFactory.createAttachment(
                'ADD_Describe_Global_Result',
                orgList[2].Id,
                Test_DataTemplateSetupExtension.orgJobResponse
            );
            Attachment att2 = TestDataFactory.createAttachment(
                'ADD_Describe_SObject_Result',
                dt.Id,
                Test_DataTemplateSetupExtension.objectJobResponseAfterRefresh
            );

            insert new List<Attachment>{ att, att1, att2, att3 };

            PageReference pReference = Page.DW_Overview;
            pReference.getParameters().put('id', deployment.Id);
            Test.setCurrentPage(pReference);

            ApexPages.StandardController sc = new ApexPages.StandardController(deployment);
            DW_OverviewExtension controller = new DW_OverviewExtension(sc);
            System.assertEquals(deployment.Id, controller.deployment.Id);
            System.assertEquals(dataDeploymentRecordTypeId, controller.deployment.RecordTypeId);
            System.assertEquals(7, controller.pagesList.size());
            System.assertEquals(7, controller.stepsList.size());
            System.assertEquals(0, controller.pageMessagesMap.size());
            System.assertNotEquals(null, controller.deploymentInterface);
            System.assertEquals(4, controller.currentStepValue);

            String generalHeader = controller.deploymentInterface.getStepGeneralHeader();
            System.assertEquals(generalHeader, Label.New_Data_Deployment);

            Integer relationCount = controller.getTotalRelationCount();
            System.assertEquals(3, relationCount);

            List<SelectOption> optionList = controller.getTestLevels();
            System.assertEquals(4, optionList.size());

            Boolean enableButtons = controller.getEnableButtons();
            System.assertEquals(true, enableButtons);
            System.assertEquals(0, controller.pageMessagesMap.size());

            Destination_Org__c dOrg = controller.getDestinationOrg();
            System.assertEquals(destinationOrg.Id, dOrg.Id);

            String overrideFilterText = controller.getOverrideFilterText();
            System.assertEquals(Label.No, overrideFilterText);

            PageReference returnedPage = controller.goToPreviousStep();
            PageReference expectedPage = Page.DW_OverrideFilters;
            expectedPage.getParameters().put('id', controller.deployment.Id);
            Boolean urlContains = returnedPage.getUrl().toLowerCase().contains(expectedPage.getUrl().toLowerCase());
            System.assertEquals(true, urlContains);

            ApexPages.currentPage().getParameters().put('relTemplateId', dt.Id);
            PageReference relatedTemplate = controller.openRelationTemplate();

            Test.stopTest();
        }
    }

    /**
     * Open the DW_Overview page and click on "Save & Close" button
     */
    @IsTest
    private static void overviewSaveAndClose() {
        User sysUser = getAdminUserWithLicense();

        System.runAs(sysUser) {
            Test.startTest();
            //Environment creation
            List<Environment__c> envList = TestDataFactory.createEnvironments(3);

            // Org Credential creation
            List<Org__c> orgList = TestDataFactory.createOrgCredentials(3, sysUser.Username, envList);

            // Deployment creation
            String metadataDeploymentRecordTypeId = Schema.Sobjecttype.Deployment__c.getRecordTypeInfosByName()
                .get('Metadata Deployment')
                .getRecordTypeId();
            Deployment__c deployment = TestDataFactory.createDeployment('Test Dev 1', metadataDeploymentRecordTypeId, orgList[2].Id);
            deployment.Deployment_Last_Step__c = 'DW_Overview';
            insert deployment;

            // Destination Org creation
            Destination_Org__c destinationOrg = TestDataFactory.createDestinationOrg(deployment.Id, orgList[1].Id);
            insert destinationOrg;

            // Step creation
            Step__c step = TestDataFactory.createStep(deployment.Id, 'Step 1', 'MetaData', 'Not Started', 1, null, '');
            insert step;

            // Attachment creation
            String attBody = '[{"n":"Test_AccountTrigger","s":true,"d":"2018-05-07","b":"Ferhat Ozsavran","cd":"2017-11-13","cb":"Ferhat Ozsavran","r":false,"t":"ApexClass"},{"n":"AccountTriggerHandler","s":true,"d":"2018-03-06","b":"Ferhat Ozsavran","cd":"2017-11-13","cb":"Ferhat Ozsavran","r":false,"t":"ApexClass"},{"n":"AccountTrigger","s":true,"d":"2018-02-19","b":"Ferhat Ozsavran","cd":"2017-11-13","cb":"Ferhat Ozsavran","r":false,"t":"ApexTrigger"}]';
            Attachment att = TestDataFactory.createAttachment('MetaData', step.Id, attBody);
            insert att;

            PageReference pReference = Page.DW_Overview;
            pReference.getParameters().put('id', deployment.Id);
            pReference.getParameters().put('MetadataPreselectionId', att.Id);
            Test.setCurrentPage(pReference);

            ApexPages.StandardController sc = new ApexPages.StandardController(deployment);
            DW_OverviewExtension controller = new DW_OverviewExtension(sc);
            System.assertEquals(deployment.Id, controller.deployment.Id);
            System.assertEquals(att.Id, controller.attId);
            System.assertEquals(metadataDeploymentRecordTypeId, controller.deployment.RecordTypeId);
            System.assertEquals(6, controller.pagesList.size());
            System.assertEquals(6, controller.stepsList.size());
            System.assertEquals(0, controller.pageMessagesMap.size());
            System.assertNotEquals(null, controller.deploymentInterface);
            System.assertEquals(3, controller.currentStepValue);

            String generalHeader = controller.deploymentInterface.getStepGeneralHeader();
            System.assertEquals(generalHeader, Label.New_Deployment);

            List<SelectOption> optionList = controller.getTestLevels();
            System.assertEquals(4, optionList.size());

            Boolean enableButtons = controller.getEnableButtons();
            System.assertEquals(true, enableButtons);
            System.assertEquals(0, controller.pageMessagesMap.size());

            Destination_Org__c dOrg = controller.getDestinationOrg();
            System.assertEquals(destinationOrg.Id, dOrg.Id);

            PageReference returnedPage = controller.saveAndCloseStep();
            String url = String.format('/{0}/o', new List<String>{ SObjectType.Deployment__c.getKeyPrefix() });
            PageReference expectedPage = new PageReference(url);
            System.assertEquals(expectedPage.getUrl(), returnedPage.getUrl());

            List<Step__c> steList = [SELECT dataJson__c FROM Step__c WHERE Deployment__c = :controller.deployment.Id LIMIT 1];
            String dataJson = steList[0].dataJson__c;
            System.assert(String.isNotBlank(dataJson));

            Test.stopTest();
        }
    }

    /**
     * Open the DW_Overview page and click on "Validate Deployment" button
     */
    @IsTest
    private static void overviewValidateDeploymentErrorAtCredits() {
        User sysUser = getAdminUserWithLicense();

        System.runAs(sysUser) {
            //Environment creation
            List<Environment__c> envList = TestDataFactory.createEnvironments(3);

            // Org Credential creation
            List<Org__c> orgList = TestDataFactory.createOrgCredentials(3, sysUser.Username, envList);

            // Deployment creation
            String metadataDeploymentRecordTypeId = Schema.Sobjecttype.Deployment__c.getRecordTypeInfosByName()
                .get('Metadata Deployment')
                .getRecordTypeId();
            Deployment__c deployment = TestDataFactory.createDeployment('Test Dev 1', metadataDeploymentRecordTypeId, orgList[2].Id);
            deployment.Deployment_Last_Step__c = 'DW_Overview';
            insert deployment;

            // Destination Org creation
            Destination_Org__c destinationOrg = TestDataFactory.createDestinationOrg(deployment.Id, orgList[1].Id);
            insert destinationOrg;

            // Step creation
            Step__c step = TestDataFactory.createStep(deployment.Id, 'Step 1', 'MetaData', 'Not Started', 1, null, '');
            insert step;

            // Attachment creation
            String attBody = '[{"n":"Test_AccountTrigger","s":true,"d":"2018-05-07","b":"Ferhat Ozsavran","cd":"2017-11-13","cb":"Ferhat Ozsavran","r":false,"t":"ApexClass"},{"n":"AccountTriggerHandler","s":true,"d":"2018-03-06","b":"Ferhat Ozsavran","cd":"2017-11-13","cb":"Ferhat Ozsavran","r":false,"t":"ApexClass"},{"n":"AccountTrigger","s":true,"d":"2018-02-19","b":"Ferhat Ozsavran","cd":"2017-11-13","cb":"Ferhat Ozsavran","r":false,"t":"ApexTrigger"}]';
            Attachment att = TestDataFactory.createAttachment('MetaData', step.Id, attBody);
            insert att;

            PageReference pReference = Page.DW_Overview;
            pReference.getParameters().put('id', deployment.Id);
            pReference.getParameters().put('MetadataPreselectionId', att.Id);
            Test.setCurrentPage(pReference);

            ApexPages.StandardController sc = new ApexPages.StandardController(deployment);
            DW_OverviewExtension controller = new DW_OverviewExtension(sc);
            System.assertEquals(deployment.Id, controller.deployment.Id);
            System.assertEquals(att.Id, controller.attId);
            System.assertEquals(metadataDeploymentRecordTypeId, controller.deployment.RecordTypeId);
            System.assertEquals(6, controller.pagesList.size());
            System.assertEquals(6, controller.stepsList.size());
            System.assertEquals(0, controller.pageMessagesMap.size());
            System.assertNotEquals(null, controller.deploymentInterface);
            System.assertEquals(3, controller.currentStepValue);

            String generalHeader = controller.deploymentInterface.getStepGeneralHeader();
            System.assertEquals(generalHeader, Label.New_Deployment);

            List<SelectOption> optionList = controller.getTestLevels();
            System.assertEquals(4, optionList.size());

            Boolean enableButtons = controller.getEnableButtons();
            System.assertEquals(true, enableButtons);
            System.assertEquals(0, controller.pageMessagesMap.size());

            Destination_Org__c dOrg = controller.getDestinationOrg();
            System.assertEquals(destinationOrg.Id, dOrg.Id);

            Test.startTest();
            pReference.getParameters().put('actionName', 'validation');
            controller.confirmDeployment();
            System.assertEquals(1, controller.pageMessagesMap.size());
            for (String severity : controller.pageMessagesMap.keySet()) {
                System.assertEquals('error', severity);
                for (Object obj : controller.pageMessagesMap.get(severity)) {
                    System.assertEquals('Methods defined as TestMethod do not support Web service callouts', obj);
                }
            }
            Test.stopTest();
        }
    }

    /**
     * Open the DW_Overview page and click on "Validate Deployment" button
     */
    @IsTest
    private static void overviewValidateDeploymentNotEnoughCredit() {
        User sysUser = getAdminUserWithLicense();

        System.runAs(sysUser) {
            //Environment creation
            List<Environment__c> envList = TestDataFactory.createEnvironments(3);

            // Org Credential creation
            List<Org__c> orgList = TestDataFactory.createOrgCredentials(3, sysUser.Username, envList);

            // Deployment creation
            String metadataDeploymentRecordTypeId = Schema.Sobjecttype.Deployment__c.getRecordTypeInfosByName()
                .get('Metadata Deployment')
                .getRecordTypeId();
            Deployment__c deployment = TestDataFactory.createDeployment('Test Dev 1', metadataDeploymentRecordTypeId, orgList[2].Id);
            deployment.Deployment_Last_Step__c = 'DW_Overview';
            insert deployment;

            // Destination Org creation
            Destination_Org__c destinationOrg = TestDataFactory.createDestinationOrg(deployment.Id, orgList[1].Id);
            insert destinationOrg;

            // Step creation
            Step__c step = TestDataFactory.createStep(deployment.Id, 'Step 1', 'MetaData', 'Not Started', 1, null, '');
            insert step;

            // Attachment creation
            String attBody = '[{"n":"Test_AccountTrigger","s":true,"d":"2018-05-07","b":"Ferhat Ozsavran","cd":"2017-11-13","cb":"Ferhat Ozsavran","r":false,"t":"ApexClass"},{"n":"AccountTriggerHandler","s":true,"d":"2018-03-06","b":"Ferhat Ozsavran","cd":"2017-11-13","cb":"Ferhat Ozsavran","r":false,"t":"ApexClass"},{"n":"AccountTrigger","s":true,"d":"2018-02-19","b":"Ferhat Ozsavran","cd":"2017-11-13","cb":"Ferhat Ozsavran","r":false,"t":"ApexTrigger"}]';
            Attachment att = TestDataFactory.createAttachment('MetaData', step.Id, attBody);
            insert att;

            PageReference pReference = Page.DW_Overview;
            pReference.getParameters().put('id', deployment.Id);
            pReference.getParameters().put('MetadataPreselectionId', att.Id);
            Test.setCurrentPage(pReference);

            ApexPages.StandardController sc = new ApexPages.StandardController(deployment);
            DW_OverviewExtension controller = new DW_OverviewExtension(sc);
            System.assertEquals(deployment.Id, controller.deployment.Id);
            System.assertEquals(att.Id, controller.attId);
            System.assertEquals(metadataDeploymentRecordTypeId, controller.deployment.RecordTypeId);
            System.assertEquals(6, controller.pagesList.size());
            System.assertEquals(6, controller.stepsList.size());
            System.assertEquals(0, controller.pageMessagesMap.size());
            System.assertNotEquals(null, controller.deploymentInterface);
            System.assertEquals(3, controller.currentStepValue);

            String generalHeader = controller.deploymentInterface.getStepGeneralHeader();
            System.assertEquals(generalHeader, Label.New_Deployment);

            List<SelectOption> optionList = controller.getTestLevels();
            System.assertEquals(4, optionList.size());

            Boolean enableButtons = controller.getEnableButtons();
            System.assertEquals(true, enableButtons);
            System.assertEquals(0, controller.pageMessagesMap.size());

            Destination_Org__c dOrg = controller.getDestinationOrg();
            System.assertEquals(destinationOrg.Id, dOrg.Id);

            Test.startTest();
            pReference.getParameters().put('actionName', 'validation');
            String res = '{"customerOrg":{"Name":"Copado Ltd","orgId":"00Db0000000KFgoEAG","autoRecharge":"false","credits":1,"id":995}}';
            MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200, 'Complete', res, null);
            Test.setMock(HttpCalloutMock.class, fakeResponse);
            controller.confirmDeployment();
            System.assertEquals(1, controller.pageMessagesMap.size());
            for (String severity : controller.pageMessagesMap.keySet()) {
                System.assertEquals('warning', severity);
                for (Object obj : controller.pageMessagesMap.get(severity)) {
                    System.assertEquals(Label.NOT_ENOUGH_CREDITS, obj);
                }
            }
            Test.stopTest();
        }
    }

    /**
     * Open the DW_Overview page and click on "Validate Deployment" button
     */
    @IsTest
    private static void overviewValidateDeploymentWorkPending() {
        User sysUser = getAdminUserWithLicense();

        System.runAs(sysUser) {
            //Environment creation
            List<Environment__c> envList = TestDataFactory.createEnvironments(3);

            // Org Credential creation
            List<Org__c> orgList = TestDataFactory.createOrgCredentials(3, sysUser.Username, envList);

            // Deployment creation
            String metadataDeploymentRecordTypeId = Schema.Sobjecttype.Deployment__c.getRecordTypeInfosByName()
                .get('Metadata Deployment')
                .getRecordTypeId();
            Deployment__c deployment = TestDataFactory.createDeployment('Test Dev 1', metadataDeploymentRecordTypeId, orgList[2].Id);
            deployment.Deployment_Last_Step__c = 'DW_Overview';
            insert deployment;

            // Destination Org creation
            Destination_Org__c destinationOrg = TestDataFactory.createDestinationOrg(deployment.Id, orgList[1].Id);
            insert destinationOrg;

            // Step creation
            Step__c step = TestDataFactory.createStep(deployment.Id, 'Step 1', 'MetaData', 'Not Started', 1, null, '');
            insert step;

            // Attachment creation
            String attBody = '[{"n":"Test_AccountTrigger","s":true,"d":"2018-05-07","b":"Ferhat Ozsavran","cd":"2017-11-13","cb":"Ferhat Ozsavran","r":false,"t":"ApexClass"},{"n":"AccountTriggerHandler","s":true,"d":"2018-03-06","b":"Ferhat Ozsavran","cd":"2017-11-13","cb":"Ferhat Ozsavran","r":false,"t":"ApexClass"},{"n":"AccountTrigger","s":true,"d":"2018-02-19","b":"Ferhat Ozsavran","cd":"2017-11-13","cb":"Ferhat Ozsavran","r":false,"t":"ApexTrigger"}]';
            Attachment att = TestDataFactory.createAttachment('MetaData', step.Id, attBody);
            insert att;

            PageReference pReference = Page.DW_Overview;
            pReference.getParameters().put('id', deployment.Id);
            pReference.getParameters().put('MetadataPreselectionId', att.Id);
            Test.setCurrentPage(pReference);

            ApexPages.StandardController sc = new ApexPages.StandardController(deployment);
            DW_OverviewExtension controller = new DW_OverviewExtension(sc);
            System.assertEquals(deployment.Id, controller.deployment.Id);
            System.assertEquals(att.Id, controller.attId);
            System.assertEquals(metadataDeploymentRecordTypeId, controller.deployment.RecordTypeId);
            System.assertEquals(6, controller.pagesList.size());
            System.assertEquals(6, controller.stepsList.size());
            System.assertEquals(0, controller.pageMessagesMap.size());
            System.assertNotEquals(null, controller.deploymentInterface);
            System.assertEquals(3, controller.currentStepValue);

            String generalHeader = controller.deploymentInterface.getStepGeneralHeader();
            System.assertEquals(generalHeader, Label.New_Deployment);

            List<SelectOption> optionList = controller.getTestLevels();
            System.assertEquals(4, optionList.size());

            Boolean enableButtons = controller.getEnableButtons();
            System.assertEquals(true, enableButtons);
            System.assertEquals(0, controller.pageMessagesMap.size());

            Destination_Org__c dOrg = controller.getDestinationOrg();
            System.assertEquals(destinationOrg.Id, dOrg.Id);

            Test.startTest();
            pReference.getParameters().put('actionName', 'validation');
            String res = '{"customerOrg":{"Name":"Copado Ltd","orgId":"00Db0000000KFgoEAG","autoRecharge":"true","credits":10,"id":995}}';
            MockHttpResponseGenerator fakeResponse = new MockHttpResponseGenerator(200, 'Complete', res, null);
            Test.setMock(HttpCalloutMock.class, fakeResponse);
            controller.confirmDeployment();
            System.assertEquals(0, controller.pageMessagesMap.size());
            Test.stopTest();

            Deployment_Job__c deploymentJob = new Deployment_Job__c();
            deploymentJob.Status__c = '';
            deploymentJob.Step__c = step.Id;
            deploymentJob.Destination_Org__c = dOrg.Id;
            deploymentJob.Deployed__c = 0;
            insert deploymentJob;

            controller.deploymentDMLs();
            Step__c stepAssert = [SELECT Id, Status__c, CheckOnly__c FROM Step__c WHERE Deployment__c = :controller.deployment.Id];
            System.assertEquals('Not started', stepAssert.Status__c);
            System.assertEquals(true, stepAssert.CheckOnly__c);

            Deployment_Job__c djAssert = [
                SELECT Id, Status__c, Deployed__c
                FROM Deployment_Job__c
                WHERE Step__r.Deployment__c = :controller.deployment.Id
                LIMIT 1
            ];
            System.assertEquals('Pending', djAssert.Status__c);

            Destination_Org__c dOrgAssert = [SELECT Id, Status__c FROM Destination_Org__c WHERE Deployment__c = :controller.deployment.Id];
            System.assertEquals('Not started', dOrgAssert.Status__c);

            MockHttpResponseGenerator fakeResponse1 = new MockHttpResponseGenerator(200, 'Complete', 'success', null);
            Test.setMock(HttpCalloutMock.class, fakeResponse1);
            controller.deploymentCallout();
            System.assertEquals(1, controller.pageMessagesMap.size());
            for (String severity : controller.pageMessagesMap.keySet()) {
                System.assertEquals('error', severity);
                for (Object obj : controller.pageMessagesMap.get(severity)) {
                    System.assertEquals('You have uncommitted work pending. Please commit or rollback before calling out', obj);
                }
            }
        }
    }

    /**
     * Open the DW_Overview page and click on "Validate Deployment" button
     */
    @IsTest
    private static void overviewValidateDeployment() {
        User sysUser = getAdminUserWithLicense();

        System.runAs(sysUser) {
            Test.startTest();
            //Environment creation
            List<Environment__c> envList = TestDataFactory.createEnvironments(3);

            // Org Credential creation
            List<Org__c> orgList = TestDataFactory.createOrgCredentials(3, sysUser.Username, envList);

            // Deployment creation
            String metadataDeploymentRecordTypeId = Schema.Sobjecttype.Deployment__c.getRecordTypeInfosByName()
                .get('Metadata Deployment')
                .getRecordTypeId();
            Deployment__c deployment = TestDataFactory.createDeployment('Test Dev 1', metadataDeploymentRecordTypeId, orgList[2].Id);
            deployment.Deployment_Last_Step__c = 'DW_Overview';
            insert deployment;

            // Destination Org creation
            Destination_Org__c destinationOrg = TestDataFactory.createDestinationOrg(deployment.Id, orgList[1].Id);
            insert destinationOrg;

            // Step creation
            Step__c step = TestDataFactory.createStep(deployment.Id, 'Step 1', 'MetaData', 'Not Started', 1, null, '');
            insert step;

            // Attachment creation
            String attBody = '[{"n":"Test_AccountTrigger","s":true,"d":"2018-05-07","b":"Ferhat Ozsavran","cd":"2017-11-13","cb":"Ferhat Ozsavran","r":false,"t":"ApexClass"},{"n":"AccountTriggerHandler","s":true,"d":"2018-03-06","b":"Ferhat Ozsavran","cd":"2017-11-13","cb":"Ferhat Ozsavran","r":false,"t":"ApexClass"},{"n":"AccountTrigger","s":true,"d":"2018-02-19","b":"Ferhat Ozsavran","cd":"2017-11-13","cb":"Ferhat Ozsavran","r":false,"t":"ApexTrigger"}]';
            Attachment att = TestDataFactory.createAttachment('MetaData', step.Id, attBody);
            insert att;

            PageReference pReference = Page.DW_Overview;
            pReference.getParameters().put('id', deployment.Id);
            pReference.getParameters().put('MetadataPreselectionId', att.Id);
            Test.setCurrentPage(pReference);

            ApexPages.StandardController sc = new ApexPages.StandardController(deployment);
            DW_OverviewExtension controller = new DW_OverviewExtension(sc);
            System.assertEquals(deployment.Id, controller.deployment.Id);
            System.assertEquals(att.Id, controller.attId);
            System.assertEquals(metadataDeploymentRecordTypeId, controller.deployment.RecordTypeId);
            System.assertEquals(6, controller.pagesList.size());
            System.assertEquals(6, controller.stepsList.size());
            System.assertEquals(0, controller.pageMessagesMap.size());
            System.assertNotEquals(null, controller.deploymentInterface);
            System.assertEquals(3, controller.currentStepValue);

            String generalHeader = controller.deploymentInterface.getStepGeneralHeader();
            System.assertEquals(generalHeader, Label.New_Deployment);

            List<SelectOption> optionList = controller.getTestLevels();
            System.assertEquals(4, optionList.size());

            Boolean enableButtons = controller.getEnableButtons();
            System.assertEquals(true, enableButtons);
            System.assertEquals(0, controller.pageMessagesMap.size());

            Destination_Org__c dOrg = controller.getDestinationOrg();
            System.assertEquals(destinationOrg.Id, dOrg.Id);

            PageReference returnedPage = controller.confirmAndGoNextStep();
            PageReference expectedPage = Page.DW_Deployment;
            expectedPage.getParameters().put('id', controller.deployment.Id);
            expectedPage.getParameters().put('MetadataPreselectionId', att.Id);
            Boolean urlContains = returnedPage.getUrl().toLowerCase().contains(expectedPage.getUrl().toLowerCase());
            System.assertEquals(true, urlContains);

            Test.stopTest();
        }
    }

    @IsTest
    private static void exceptionOnValidateDataTemplate() {
        User sysUser = getAdminUserWithLicense();

        System.runAs(sysUser) {
            //Environment creation
            List<Environment__c> envList = TestDataFactory.createEnvironments(3);

            // Org Credential creation
            List<Org__c> orgList = TestDataFactory.createOrgCredentials(3, sysUser.Username, envList);

            // Deployment creation
            String dataDeploymentRecordTypeId = Schema.SObjectType.Deployment__c.getRecordTypeInfosByDeveloperName()
                .get('Data_Deployment')
                .getRecordTypeId();
            Deployment__c deployment = TestDataFactory.createDeployment('Test Dev 1', dataDeploymentRecordTypeId, orgList[2].Id);
            deployment.Deployment_Last_Step__c = 'DW_Overview';
            insert deployment;

            // Destination Org creation
            Destination_Org__c destinationOrg = TestDataFactory.createDestinationOrg(deployment.Id, orgList[1].Id);
            insert destinationOrg;

            // Step creation
            Step__c step = TestDataFactory.createStep(deployment.Id, 'Step 1', 'Data Template', 'Not Started', 1, null, '');
            insert step;

            PageReference pReference = Page.DW_Overview;
            pReference.getParameters().put('id', deployment.Id);
            Test.setCurrentPage(pReference);

            Test.startTest();
            ApexPages.StandardController sc = new ApexPages.StandardController(deployment);
            DW_OverviewExtension controller = new DW_OverviewExtension(sc);
            try {
                controller.validateDataTemplateDeployment();
            } catch (Exception e) {
                System.assertEquals(true, controller.pageMessagesMap.isEmpty(), 'Page error messages should not be empty.');
            }
            Test.stopTest();
        }
    }

    /**
     * Open the DW_Overview page and deployment source type is "git"
     */
    @IsTest
    private static void overviewGitCommitDeployment() {
        User sysUser = getAdminUserWithLicense();

        System.runAs(sysUser) {
            Test.startTest();
            //Environment creation
            List<Environment__c> envList = TestDataFactory.createEnvironments(3);

            // Org Credential creation
            List<Org__c> orgList = TestDataFactory.createOrgCredentials(3, sysUser.Username, envList);

            // Deployment creation
            String metadataDeploymentRecordTypeId = Schema.Sobjecttype.Deployment__c.getRecordTypeInfosByName()
                .get('Metadata Deployment')
                .getRecordTypeId();
            Deployment__c deployment = TestDataFactory.createDeployment('Test Dev 1', metadataDeploymentRecordTypeId, orgList[2].Id);
            deployment.Deployment_Last_Step__c = 'DW_Overview';
            insert deployment;

            // Destination Org creation
            Destination_Org__c destinationOrg = TestDataFactory.createDestinationOrg(deployment.Id, orgList[1].Id);
            insert destinationOrg;

            // Step creation
            Step__c step = TestDataFactory.createStep(deployment.Id, 'Step 1', 'MetaData', 'Not Started', 1, 'MyCommitName', '');
            insert step;

            // Attachment creation
            String attBody = '[{"n":"Test_AccountTrigger","s":true,"d":"2018-05-07","b":"Ferhat Ozsavran","cd":"2017-11-13","cb":"Ferhat Ozsavran","r":false,"t":"ApexClass"},{"n":"AccountTriggerHandler","s":true,"d":"2018-03-06","b":"Ferhat Ozsavran","cd":"2017-11-13","cb":"Ferhat Ozsavran","r":false,"t":"ApexClass"},{"n":"AccountTrigger","s":true,"d":"2018-02-19","b":"Ferhat Ozsavran","cd":"2017-11-13","cb":"Ferhat Ozsavran","r":false,"t":"ApexTrigger"}]';
            Attachment att = TestDataFactory.createAttachment('MetaData', step.Id, attBody);
            insert att;

            PageReference pReference = Page.DW_Overview;
            pReference.getParameters().put('id', deployment.Id);
            pReference.getParameters().put('MetadataPreselectionId', att.Id);
            Test.setCurrentPage(pReference);

            ApexPages.StandardController sc = new ApexPages.StandardController(deployment);
            DW_OverviewExtension controller = new DW_OverviewExtension(sc);
            System.assertEquals(deployment.Id, controller.deployment.Id);
            System.assertEquals(att.Id, controller.attId);
            System.assertEquals(metadataDeploymentRecordTypeId, controller.deployment.RecordTypeId);
            System.assertEquals(6, controller.pagesList.size());
            System.assertEquals(6, controller.stepsList.size());
            System.assertEquals(0, controller.pageMessagesMap.size());
            System.assertNotEquals(null, controller.deploymentInterface);
            System.assertEquals(3, controller.currentStepValue);

            String generalHeader = controller.deploymentInterface.getStepGeneralHeader();
            System.assertEquals(generalHeader, Label.New_Deployment);

            controller.getCommit();
            controller.getPageMessageSize();

            Test.stopTest();
        }
    }

    /**
     * Page message for not validated test
     */
    @IsTest
    private static void pageMessageTestForNotValidatedOrgs() {
        User sysUser = getAdminUserWithLicense();

        System.runAs(sysUser) {
            Test.startTest();
            //Environment creation
            List<Environment__c> envList = TestDataFactory.createEnvironments(3);

            // Org Credential creation
            List<Org__c> orgList = TestDataFactory.createOrgCredentials(3, sysUser.Username, envList);
            for (Org__c org : orgList) {
                org.Validated_Date__c = null;
            }
            update orgList;

            // Deployment creation
            String metadataDeploymentRecordTypeId = Schema.Sobjecttype.Deployment__c.getRecordTypeInfosByName()
                .get('Metadata Deployment')
                .getRecordTypeId();
            Deployment__c deployment = TestDataFactory.createDeployment('Test Dev 1', metadataDeploymentRecordTypeId, orgList[2].Id);
            deployment.Deployment_Last_Step__c = 'DW_Overview';
            insert deployment;

            // Destination Org creation
            Destination_Org__c destinationOrg = TestDataFactory.createDestinationOrg(deployment.Id, orgList[1].Id);
            insert destinationOrg;

            // Step creation
            Step__c step = TestDataFactory.createStep(deployment.Id, 'Step 1', 'MetaData', 'Not Started', 1, null, '');
            insert step;

            // Attachment creation
            String attBody = '[{"n":"Test_AccountTrigger","s":true,"d":"2018-05-07","b":"Ferhat Ozsavran","cd":"2017-11-13","cb":"Ferhat Ozsavran","r":false,"t":"ApexClass"},{"n":"AccountTriggerHandler","s":true,"d":"2018-03-06","b":"Ferhat Ozsavran","cd":"2017-11-13","cb":"Ferhat Ozsavran","r":false,"t":"ApexClass"},{"n":"AccountTrigger","s":true,"d":"2018-02-19","b":"Ferhat Ozsavran","cd":"2017-11-13","cb":"Ferhat Ozsavran","r":false,"t":"ApexTrigger"}]';
            Attachment att = TestDataFactory.createAttachment('MetaData', step.Id, attBody);
            insert att;

            PageReference pReference = Page.DW_Overview;
            pReference.getParameters().put('id', deployment.Id);
            pReference.getParameters().put('MetadataPreselectionId', att.Id);
            Test.setCurrentPage(pReference);

            ApexPages.StandardController sc = new ApexPages.StandardController(deployment);
            DW_OverviewExtension controller = new DW_OverviewExtension(sc);
            System.assertEquals(deployment.Id, controller.deployment.Id);
            System.assertEquals(att.Id, controller.attId);
            System.assertEquals(metadataDeploymentRecordTypeId, controller.deployment.RecordTypeId);
            System.assertEquals(1, controller.pageMessagesMap.size());

            String generalHeader = controller.deploymentInterface.getStepGeneralHeader();
            System.assertEquals(generalHeader, Label.New_Deployment);

            Test.stopTest();
        }
    }

    /**
     * Open the DW_Overview page and click on "Go to Advanced Deployment" button
     */
    @IsTest
    private static void overviewConnectionBehavior() {
        User sysUser = getAdminUserWithLicense();

        System.runAs(sysUser) {
            Test.startTest();
            // Connection Behavior creation
            Connection_Behavior__c cb = TestDataFactory.createConnectionBehavior('Manual', 'Manual', 'Completed');
            insert cb;

            // Quality Gate creation
            Quality_Gate__c qg = TestDataFactory.createQualityGate(null, null, cb.Id, null, null, 'Pull Request', '', 1);
            insert qg;

            // Environment creation
            List<Environment__c> envList = TestDataFactory.createEnvironments(3);
            envList[1].Connection_Behavior__c = cb.Id;
            update envList[1];

            // Org Credential creation
            List<Org__c> orgList = TestDataFactory.createOrgCredentials(3, sysUser.Username, envList);

            // Deployment creation
            String metadataDeploymentRecordTypeId = Schema.Sobjecttype.Deployment__c.getRecordTypeInfosByName()
                .get('Metadata Deployment')
                .getRecordTypeId();
            Deployment__c deployment = TestDataFactory.createDeployment('Test Dev 1', metadataDeploymentRecordTypeId, orgList[2].Id);
            deployment.Deployment_Last_Step__c = 'DW_Overview';
            insert deployment;

            // Destination Org creation
            Destination_Org__c destinationOrg = TestDataFactory.createDestinationOrg(deployment.Id, orgList[1].Id);
            insert destinationOrg;

            // Step creation
            Step__c step = TestDataFactory.createStep(deployment.Id, 'Step 1', 'MetaData', 'Not Started', 1, null, '');
            insert step;

            // Attachment creation
            String attBody = '[{"n":"Test_AccountTrigger","s":true,"d":"2018-05-07","b":"Ferhat Ozsavran","cd":"2017-11-13","cb":"Ferhat Ozsavran","r":false,"t":"ApexClass"},{"n":"AccountTriggerHandler","s":true,"d":"2018-03-06","b":"Ferhat Ozsavran","cd":"2017-11-13","cb":"Ferhat Ozsavran","r":false,"t":"ApexClass"},{"n":"AccountTrigger","s":true,"d":"2018-02-19","b":"Ferhat Ozsavran","cd":"2017-11-13","cb":"Ferhat Ozsavran","r":false,"t":"ApexTrigger"}]';
            Attachment att = TestDataFactory.createAttachment('MetaData', step.Id, attBody);
            insert att;

            PageReference pReference = Page.DW_Overview;
            pReference.getParameters().put('id', deployment.Id);
            pReference.getParameters().put('MetadataPreselectionId', att.Id);
            Test.setCurrentPage(pReference);

            ApexPages.StandardController sc = new ApexPages.StandardController(deployment);
            DW_OverviewExtension controller = new DW_OverviewExtension(sc);
            System.assertEquals(deployment.Id, controller.deployment.Id);
            System.assertEquals(att.Id, controller.attId);
            System.assertEquals(metadataDeploymentRecordTypeId, controller.deployment.RecordTypeId);
            System.assertEquals(6, controller.pagesList.size());
            System.assertEquals(6, controller.stepsList.size());
            System.assertEquals(1, controller.pageMessagesMap.size());
            System.assertNotEquals(null, controller.deploymentInterface);
            System.assertEquals(3, controller.currentStepValue);

            String generalHeader = controller.deploymentInterface.getStepGeneralHeader();
            System.assertEquals(generalHeader, Label.New_Deployment);

            List<SelectOption> optionList = controller.getTestLevels();
            System.assertEquals(4, optionList.size());

            Boolean enableButtons = controller.getEnableButtons();
            System.assertEquals(true, enableButtons);
            System.assertEquals(1, controller.pageMessagesMap.size());

            Destination_Org__c dOrg = controller.getDestinationOrg();
            System.assertEquals(destinationOrg.Id, dOrg.Id);

            PageReference returnedPage = controller.goToAdvanceDeployment();
            PageReference expectedPage = Page.Deployment;
            expectedPage.getParameters().put('id', controller.deployment.Id);
            Boolean urlContains = returnedPage.getUrl().toLowerCase().contains(expectedPage.getUrl().toLowerCase());
            System.assertEquals(true, urlContains);

            Test.stopTest();
        }
    }

    @IsTest
    private static void rollbackDeploymentSaveAndClose() {
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

            Step__c rbStep = TestDataFactory.createStep(rollbackDeployment.Id, 'Rollback step', 'Rollback', 'Draft', 1, null, null);
            insert rbStep;

            ContentVersion rbCv = new ContentVersion();
            rbCv.Title = 'Selected items to rollback_Git Promotion';
            rbCv.PathOnClient = 'Selected items to rollback_Git Promotion';
            rbCv.VersionData = Blob.valueOf(
                '[{"t":"ApexClass","n":"DemoClass","b":"Gabriel Serrano","d":"2020-09-15","cb":"Gabriel Serrano","cd":"2020-08-04","r":false,"cmm":"updated","snapshotCommitId":"a0M1n00001QD11mEAD"}]'
            );
            rbCv.FirstPublishLocationId = rbStep.Id;
            insert rbCv;

            // Exercise

            Test.startTest();

            PageReference pReference = Page.DW_Overview;
            pReference.getParameters().put('id', rollbackDeployment.Id);
            Test.setCurrentPage(pReference);

            ApexPages.StandardController sc = new ApexPages.StandardController(rollbackDeployment);
            DW_OverviewExtension controller = new DW_OverviewExtension(sc);
            PageReference deploymentPage = controller.saveAndCloseStep();

            Test.stopTest();

            // Verify

            System.assertNotEquals([SELECT Id, dataJson__c FROM Step__c WHERE Id = :rbStep.Id].dataJson__c, null);
        }
    }

    private static User getAdminUserWithLicense() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true, true);
        return sysUser;
    }
}