@IsTest
private class TestDeployJobHelper {
    @TestSetup
    static void setupTestData() {
        TestUtilities.setTestSettingsEE();
    }
    @isTest
    public static void doTest() {
        String b = '{"customerOrg":{"Name":"Copado Ltd","orgId":"00Db0000000KFgoEAG","autoRecharge":true,"credits":425,"Id":995},"userInfo":{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"currencySymbol":"€","orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDefaultCurrencyIsoCode":"EUR","orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"00Db0000000KFgoEAG","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":false,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mWB2AAM","roleId__is_set":true,"sessionSecondsValId__is_set":true,"sessionSecondsValId":7200,"userDefaultCurrencyIsoCode__is_set":true,"userEmail__is_set":true,"userEmail":"pr@copado.com","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000hMqqAAE","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copado.com.basepackage","userTimeZone__is_set":true,"userTimeZone":"Europe/Paris","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));

        Org__c orgCredential = testMethodUtilities.createOrg('Copado Org', 'Production/Developer', '', null, null, DateTime.now());
        insert orgCredential;
        orgCredential.SFDC_Org_ID__c = '00D24000000aZrZEAU_005240000012JyBAAU';
        update orgCredential;

        Deployment__c deployment = testMethodUtilities.create(
            'DEPLOYMENT_NAME',
            System.now(),
            System.now(),
            orgCredential.Id,
            'Deploy now',
            'Pending'
        );
        insert deployment;
        Step__c step = testMethodUtilities.create('Step 1', 'attId', 'JSONString', deployment.Id, 0, 'Pending', 'MetaData');
        insert step;
        Destination_Org__c destinationOrg = testMethodUtilities.create(deployment.Id, 'Pending', orgCredential.Id);
        insert destinationOrg;
        System.assertEquals(1, [SELECT COUNT() FROM Deployment_Job__c WHERE step__c = :step.Id AND Destination_Org__c = :destinationOrg.Id]);
        Destination_Org__c secondDestinationOrg = testMethodUtilities.create(deployment.Id, 'Pending', orgCredential.Id);
        insert secondDestinationOrg;
        System.assertEquals(1, [SELECT COUNT() FROM Deployment_Job__c WHERE step__c = :step.Id AND Destination_Org__c = :secondDestinationOrg.Id]);
        System.assertEquals(2, [SELECT COUNT() FROM Deployment_Job__c WHERE step__c = :step.Id]);

        delete destinationOrg;
        System.assertEquals(1, [SELECT COUNT() FROM Deployment_Job__c WHERE step__c = :step.Id AND Destination_Org__c = :secondDestinationOrg.Id]);
        System.assertEquals(1, [SELECT COUNT() FROM Deployment_Job__c WHERE step__c = :step.Id]);
    }

    @isTest
    private static void testNextStep() {
        testMethodUtilities.upsertOrgwIdeSettings();

        String b = '{"customerOrg":{"Name":"Copado Ltd","orgId":"00Db0000000KFgoEAG","autoRecharge":true,"credits":425,"Id":995},"userInfo":{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"currencySymbol":"€","orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDefaultCurrencyIsoCode":"EUR","orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"00Db0000000KFgoEAG","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":false,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mWB2AAM","roleId__is_set":true,"sessionSecondsValId__is_set":true,"sessionSecondsValId":7200,"userDefaultCurrencyIsoCode__is_set":true,"userEmail__is_set":true,"userEmail":"pr@copado.com","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000hMqqAAE","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copado.com.basepackage","userTimeZone__is_set":true,"userTimeZone":"Europe/Paris","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));

        Org__c orgCredential = testMethodUtilities.createOrg('Copado Org', 'Production/Developer', '', null, null, DateTime.now());
        insert orgCredential;
        orgCredential.SFDC_Org_ID__c = '00D24000000aZrZEAU_005240000012JyBAAU';
        update orgCredential;

        Deployment__c deployment = testMethodUtilities.create(
            'DEPLOYMENT_NAME',
            System.now(),
            System.now(),
            orgCredential.Id,
            'Deploy now',
            'Pending'
        );
        insert deployment;

        Destination_Org__c destinationOrg = testMethodUtilities.create(deployment.Id, 'Pending', orgCredential.Id);
        Destination_Org__c secondDestinationOrg = testMethodUtilities.create(deployment.Id, 'Pending', orgCredential.Id);
        insert new List<Destination_Org__c>{ destinationOrg, secondDestinationOrg };

        String dataJson = '{"Perform_in_Destination_Orgs":true,"Perform_in_Source_Org":false,"Task_Description":"","Task_Owner":"';
        dataJson += UserInfo.getUserId();
        dataJson += '","Notify_Task_Owner":"Chatter and Email"}';
        Step__c step = testMethodUtilities.create('Step 1', 'attId', dataJson, deployment.Id, 1, 'Pending', 'Manual Task');
        Step__c step2 = testMethodUtilities.create('Step 2', 'attId', 'JSONString', deployment.Id, 2, 'Pending', 'MetaData');
        insert new List<Step__c>{ step, step2 };

        Deployment_Job__c deploymentJob = [
            SELECT Id, Status__c
            FROM Deployment_Job__c
            WHERE step__c = :step.Id AND Destination_Org__c = :destinationOrg.Id
        ];
        System.assertEquals('Pending', deploymentJob.Status__c);

        deploymentJob.Status__c = 'Success';
        deploymentJob.Deployed__c = 100;
        update deploymentJob;
        System.assertEquals('In progress', [SELECT Status__c FROM step__c WHERE Id = :step.Id].Status__c);
        
        String body = '{"sourceDomain":"https://copado-dev04-dev-ed.my.salesforce.com/","targetDomain":"https://copado-dev-10-dev-ed.my.salesforce.com/","results":[{"l":"Test_Case","m":{"templateId":"a0U0900000DA8BbEAL","templateName":"Test_Case","objectName":"Case","deployedRecords":0,"failedRecords":2,"generatedIds":0},"t":""},{"l":"Test_Contact","m":{"templateId":"a0U0900000DA8BaEAL","templateName":"Test_Contact","objectName":"Contact","deployedRecords":2,"failedRecords":0,"generatedIds":0},"t":""}]}';
        System.assertEquals(false, String.isBlank(DeployJobHelper.hasFailedRecords(body)), 'Result should not have failed records');
        body = null;
        System.assertEquals(true, String.isBlank(DeployJobHelper.hasFailedRecords(body)), 'Result should not have failed records');
        
        DeployJobHelper.ManualTaskStepAttachmentDetails attachmentDetail = new DeployJobHelper.ManualTaskStepAttachmentDetails();
        attachmentDetail.m =
            'NEW STATUS: ' +
            'SUCCESS' +
            ' on ' +
            JSON.serialize(System.now()) +
            ' : Comment: Copado auto-completed this task.';
        attachmentDetail.l = 'INFO';
        attachmentDetail.t = '';
        system.assertEquals(true, !String.isBlank(attachmentDetail.m), 'Manual Task exists with Content.');

        deployment.Status__c = 'Cancelled';
        update deployment;
        step2.Status__c = 'Cancelled';
        update step2;
        deploymentJob.Status__c = 'Cancelled';
        deploymentJob.Deployed__c = 100;
        update deploymentJob;
        
    }

    @isTest
    private static void testNextStep2() {
        String b = '{"customerOrg":{"Name":"Copado Ltd","orgId":"00Db0000000KFgoEAG","autoRecharge":true,"credits":425,"Id":995},"userInfo":{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"currencySymbol":"€","orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDefaultCurrencyIsoCode":"EUR","orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"00Db0000000KFgoEAG","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":false,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mWB2AAM","roleId__is_set":true,"sessionSecondsValId__is_set":true,"sessionSecondsValId":7200,"userDefaultCurrencyIsoCode__is_set":true,"userEmail__is_set":true,"userEmail":"pr@copado.com","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000hMqqAAE","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copado.com.basepackage","userTimeZone__is_set":true,"userTimeZone":"Europe/Paris","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));

        Org__c orgCredential = testMethodUtilities.createOrg('Copado Org', 'Production/Developer', '', null, null, DateTime.now());
        insert orgCredential;
        orgCredential.SFDC_Org_ID__c = '00D24000000aZrZEAU_005240000012JyBAAU';
        update orgCredential;

        Deployment__c deployment = testMethodUtilities.create(
            'DEPLOYMENT_NAME',
            System.now(),
            System.now(),
            orgCredential.Id,
            'Deploy now',
            'In progress'
        );
        //US-0026886:Commenting Deployment Automation template as record type is deactivated
        //deployment.RecordTypeId = Schema.SObjectType.Deployment__c.getRecordTypeInfosByDeveloperName().get('Automation_Template').getRecordTypeId();
        insert deployment;

        Step__c step = testMethodUtilities.create('Step 1', 'attId', 'JSONString', deployment.Id, 1, 'Pending', 'MetaData');
        Step__c step2 = testMethodUtilities.create('Step 2', 'attId', 'JSONString', deployment.Id, 2, 'Pending', 'MetaData');
        insert new List<Step__c>{ step, step2 };

        Destination_Org__c destinationOrg = testMethodUtilities.create(deployment.Id, 'Pending', orgCredential.Id);
        Destination_Org__c secondDestinationOrg = testMethodUtilities.create(deployment.Id, 'Pending', orgCredential.Id);
        insert new List<Destination_Org__c>{ destinationOrg, secondDestinationOrg };

        Test.startTest();
        deployment.Status__c = 'In progress';
        update deployment;

        Deployment_Job__c deploymentJob = [
            SELECT Id, Status__c
            FROM Deployment_Job__c
            WHERE step__c = :step.Id AND Destination_Org__c = :destinationOrg.Id
        ];
        System.assertEquals('Pending', deploymentJob.Status__c);

        deploymentJob.Status__c = 'Failed';
        deploymentJob.Deployed__c = 0;
        update deploymentJob;

        System.assertEquals('In progress', [SELECT Status__c FROM step__c WHERE Id = :step.Id].Status__c);
        System.assertEquals('In progress', [SELECT Status__c FROM Deployment__c WHERE Id = :deployment.Id].Status__c);

        Deployment_Job__c stepDeploymentJobToUpdate = [
            SELECT Id, Status__c
            FROM Deployment_Job__c
            WHERE step__c = :step.Id AND Destination_Org__c = :secondDestinationOrg.Id
        ];
        System.assertEquals('Pending', stepDeploymentJobToUpdate.Status__c);

        stepDeploymentJobToUpdate.Status__c = 'Failed';
        stepDeploymentJobToUpdate.Deployed__c = 0;
        update stepDeploymentJobToUpdate;
        System.assertEquals('Completed with Errors', [SELECT Status__c FROM step__c WHERE Id = :step.Id].Status__c);
        System.assertEquals('Completed with Errors', [SELECT Status__c FROM Deployment__c WHERE Id = :deployment.Id].Status__c);

        Deployment_Job__c step2DeploymentJobToUpdate = [
            SELECT Id, Status__c
            FROM Deployment_Job__c
            WHERE step__c = :step2.Id AND Destination_Org__c = :destinationOrg.Id
        ];
        System.assertEquals('Pending', step2DeploymentJobToUpdate.Status__c);
        System.assertEquals('Completed with Errors', [SELECT Status__c FROM step__c WHERE Id = :step.Id].Status__c);

        Deployment_Job__c step2DeploymentJobToUpdateForSecondDestinationOrg = [
            SELECT Id, Status__c
            FROM Deployment_Job__c
            WHERE step__c = :step2.Id AND Destination_Org__c = :secondDestinationOrg.Id
        ];
        System.assertEquals('Pending', step2DeploymentJobToUpdateForSecondDestinationOrg.Status__c);
        System.assertEquals('Pending', [SELECT Status__c FROM step__c WHERE Id = :step2.Id].Status__c);
        Test.stopTest();
    }
    @isTest
    private static void testNextStep3() {
        String b = '{"customerOrg":{"Name":"Copado Ltd","orgId":"00Db0000000KFgoEAG","autoRecharge":true,"credits":425,"Id":995},"userInfo":{"accessibilityMode__is_set":true,"accessibilityMode":false,"currencySymbol__is_set":true,"currencySymbol":"€","orgAttachmentFileSizeLimit__is_set":true,"orgAttachmentFileSizeLimit":5242880,"orgDefaultCurrencyIsoCode__is_set":true,"orgDefaultCurrencyIsoCode":"EUR","orgDisallowHtmlAttachments__is_set":true,"orgDisallowHtmlAttachments":false,"orgHasPersonAccounts__is_set":true,"orgHasPersonAccounts":false,"organizationId__is_set":true,"organizationId":"00Db0000000KFgoEAG","organizationMultiCurrency__is_set":true,"organizationMultiCurrency":false,"organizationName__is_set":true,"organizationName":"Copado Ltd","profileId__is_set":true,"profileId":"00eb0000000mWB2AAM","roleId__is_set":true,"sessionSecondsValId__is_set":true,"sessionSecondsValId":7200,"userDefaultCurrencyIsoCode__is_set":true,"userEmail__is_set":true,"userEmail":"pr@copado.com","userFullName__is_set":true,"userFullName":"Philipp Rackwitz","userId__is_set":true,"userId":"005b0000000hMqqAAE","userLanguage__is_set":true,"userLanguage":"en_US","userLocale__is_set":true,"userLocale":"en_GB","userName__is_set":true,"userName":"pr@copado.com.basepackage","userTimeZone__is_set":true,"userTimeZone":"Europe/Paris","userType__is_set":true,"userType":"Standard","userUiSkin__is_set":true,"userUiSkin":"Theme3"}}';
        Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock(b, null));

        Org__c orgCredential = testMethodUtilities.createOrg('Copado Org', 'Production/Developer', '', null, null, DateTime.now());
        insert orgCredential;
        orgCredential.SFDC_Org_ID__c = '00D24000000aZrZEAU_005240000012JyBAAU';
        update orgCredential;

        Deployment__c deployment = testMethodUtilities.create(
            'DEPLOYMENT_NAME',
            System.now(),
            System.now(),
            orgCredential.Id,
            'Deploy now',
            'In progress'
        );
        insert deployment;

        Step__c step = testMethodUtilities.create('Step 1', 'attId', 'JSONString', deployment.Id, 1, 'Pending', 'MetaData');
        insert step;

        Destination_Org__c destinationOrg = testMethodUtilities.create(deployment.Id, 'Pending', orgCredential.Id);
        Destination_Org__c secondDestinationOrg = testMethodUtilities.create(deployment.Id, 'Pending', orgCredential.Id);
        insert new List<Destination_Org__c>{ destinationOrg, secondDestinationOrg };

        Deployment_Job__c deploymentJob = [
            SELECT Id, Status__c
            FROM Deployment_Job__c
            WHERE step__c = :step.Id AND Destination_Org__c = :destinationOrg.Id
        ];
        deployment.Status__c = 'In progress';
        update deployment;

        System.assertEquals('Pending', deploymentJob.Status__c);
        deploymentJob.Status__c = 'Failed';
        deploymentJob.Deployed__c = 0;
        update deploymentJob;
        System.assertEquals('In progress', [SELECT Status__c FROM step__c WHERE Id = :step.Id].Status__c);
        System.assertEquals('In progress', [SELECT Status__c FROM Deployment__c WHERE Id = :deployment.Id].Status__c);
        System.assertEquals('Completed with Errors', [SELECT Status__c FROM Destination_Org__c WHERE Id = :destinationOrg.Id].Status__c);

        Deployment_Job__c stepDeploymentJobToUpdate = [
            SELECT Id, Status__c
            FROM Deployment_Job__c
            WHERE step__c = :step.Id AND Destination_Org__c = :secondDestinationOrg.Id
        ];
        System.assertEquals('Pending', stepDeploymentJobToUpdate.Status__c);
        stepDeploymentJobToUpdate.Status__c = 'Success';
        stepDeploymentJobToUpdate.Deployed__c = 100;
        update stepDeploymentJobToUpdate;
        System.assertEquals('Completed with Errors', [SELECT Status__c FROM step__c WHERE Id = :step.Id].Status__c);
        System.assertEquals('Completed Successfully', [SELECT Status__c FROM Destination_Org__c WHERE Id = :secondDestinationOrg.Id].Status__c);
        System.assertEquals('Completed with Errors', [SELECT Status__c FROM Deployment__c WHERE Id = :deployment.Id].Status__c);
    }

    @IsTest
    private static void testSalesforceFlowStepExecution() {
        Settings__c setting = Settings__c.getOrgDefaults();
        setting.CryptoKey__c = EncodingUtil.base64Encode(Crypto.generateAesKey(256));
        upsert setting;

        Personal_Settings__c personalSetting = Personal_Settings__c.getInstance();
        personalSetting.API_Key__c = DeployAPI.encryptAPIKey('testApiKey');
        upsert personalSetting;

        ITestDefaults environmentDefaults = new CopadoSetupTestDefaults.EnvironmentDefaults()
            .setFieldDefaults()
            .setFieldValue(Environment__c.SObjectType, Environment__c.Name, 'Copado')
            .setDataSize(Environment__c.SObjectType, 1)
            .generateDefaults()
            .includeDefaults(CopadoSetupTestDefaults.EnvironmentDefaults.class)
            .setFieldValue(Environment__c.SObjectType, Environment__c.Name, 'Production')
            .setDataSize(Environment__c.SObjectType, 1)
            .generateDefaults()
            .executeDML();

        Environment__c copadoEnvironment;
        Environment__c productionEnvironment;

        for (Environment__c env : (List<Environment__c>) environmentDefaults.getTestData(Environment__c.SObjectType)) {
            switch on env.Name {
                when 'Copado 0' {
                    copadoEnvironment = env;
                }
                when 'Production 0' {
                    productionEnvironment = env;
                }
            }
        }

        String sfdcOrgId = UserInfo.getOrganizationId() + '_' + UserInfo.getUserId();
        ITestDefaults orgCredentialDefaults = new CopadoSetupTestDefaults.OrgCredentialDefaults()
            .setFieldDefaults()
            .setFieldValue(Org__c.SObjectType, Org__c.Name, 'Copado')
            .setFieldValue(Org__c.SObjectType, Org__c.Environment__c, copadoEnvironment.Id)
            .setFieldValue(Org__c.SObjectType, Org__c.Default_Credential__c, true)
            .setFieldValue(Org__c.SObjectType, Org__c.Validated_Date__c, System.now())
            .setFieldValue(Org__c.SObjectType, Org__c.SFDC_Org_ID__c, sfdcOrgId)
            .setDataSize(Org__c.SObjectType, 1)
            .generateDefaults()
            .includeDefaults(CopadoSetupTestDefaults.OrgCredentialDefaults.class)
            .setFieldValue(Org__c.SObjectType, Org__c.Name, 'Production')
            .setFieldValue(Org__c.SObjectType, Org__c.Environment__c, productionEnvironment.Id)
            .setFieldValue(Org__c.SObjectType, Org__c.Default_Credential__c, true)
            .setDataSize(Org__c.SObjectType, 1)
            .generateDefaults()
            .executeDML();

        Org__c copadoOrg = new Org__c();
        Org__c productionOrg = new Org__c();

        for (Org__c org : (List<Org__c>) orgCredentialDefaults.getTestData(Org__c.SObjectType)) {
            switch on org.Name {
                when 'Copado 0' {
                    copadoOrg = org;
                }
                when 'Production 0' {
                    productionOrg = org;
                }
            }
        }

        String dataJson =
            '{"flowApiName": "TestFlow","type":"wait","flowParameters":[' +
            '["Copado Org Id","{!CopadoOrg.OrgId}"],' +
            '["Copado Org Credential Id","{!CopadoOrg.CredentialId}"],' +
            '["Copado Org Api Key","{!CopadoOrg.ApiKey}"],' +
            '["Source Org Id","{!Source.OrgId}"],' +
            '["Source Credential Id","{!Source.CredentialId}"],' +
            '["Destination Org Id","{!Destination.OrgId}"],' +
            '["Destination Credential Id","{!Destination.CredentialId}"],' +
            '["Deployment Id","{!Deployment.Id}"],' +
            '["Deployment Job Id","{!Deployment.JobId}"],' +
            '["Promotion Id","{!Promotion.Id}"],' +
            '["Resume URL","{!ResumeURL}"]' +
            ']}';

        ITestDefaults deploymentDefaults = new CopadoUserStoryTestDefaults.DeploymentDefaults()
            .setFieldDefaults()
            .setFieldValue(Deployment__c.SObjectType, Deployment__c.From_Org__c, productionOrg.Id)
            .setDataSize(Deployment__c.SObjectType, 1)
            .generateDefaults()
            .includeDefaults(CopadoUserStoryTestDefaults.DeploymentStepDefaults.class)
            .setFieldValue(Step__c.SObjectType, Step__c.Status__c, 'Pending')
            .setFieldValue(Step__c.SObjectType, Step__c.Type__c, 'Salesforce Flow')
            .setFieldValue(Step__c.SObjectType, Step__c.dataJson__c, dataJson)
            .setDataSize(Step__c.SObjectType, 1)
            .setSObjectRelation(Step__c.SObjectType, Deployment__c.SObjectType, new Map<Schema.SObjectField, Integer>{ Step__c.Deployment__c => 1 })
            .generateDefaults()
            .executeDML();

        Deployment__c deployment = (Deployment__c) deploymentDefaults.getTestData(Deployment__c.SObjectType)[0];

        Destination_Org__c destinationOrg = testMethodUtilities.create(deployment.Id, 'Pending', productionOrg.Id);
        insert destinationOrg;

        Step__c salesforceFlowStep = (Step__c) deploymentDefaults.getTestData(Step__c.SObjectType)[0];

        Test.startTest();
        Deployment_Job__c deploymentJob = [
            SELECT Status__c, Last_Result__c
            FROM Deployment_Job__c
            WHERE Step__c = :salesforceFlowStep.Id AND Destination_org__c = :destinationOrg.Id
        ];
        System.assertEquals('Pending', deploymentJob.Status__c, 'Job Status should be pending');
        deploymentJob.Status__c = 'In progress';
        update deploymentJob;
        List<AsyncApexJob> ayncFlowExecutors = [SELECT Id FROM AsyncApexJob];
        deploymentJob = [
            SELECT Last_Result__c
            FROM Deployment_Job__c
            WHERE Step__c = :salesforceFlowStep.Id AND Destination_org__c = :destinationOrg.Id
        ];
        Result__c result = [SELECT Job_Type__c, Status__c FROM Result__c];
        System.assertEquals(result.Id, deploymentJob.Last_Result__c, 'Last_Result__c should correspond to Result Id');
        System.assertEquals('Deployment Step 0', result.Job_Type__c, 'Job Type should correspond to Step Name');
        System.assertEquals('In Progress', result.Status__c, 'Result Status should be In progress');
        System.assert(!ayncFlowExecutors.isEmpty(), 'There should be a job enqueued');
        Test.stopTest();

        deploymentJob = [
            SELECT Status__c, Step__r.Deployment__c
            FROM Deployment_Job__c
            WHERE Step__c = :salesforceFlowStep.Id AND Destination_org__c = :destinationOrg.Id
        ];
        /*System.assertEquals('Failed', deploymentJob.Status__c, 'Deployment job status should be Failed.');
        Attachment resultAttachment = [SELECT Body FROM Attachment WHERE ParentId = :deploymentJob.Step__r.Deployment__c];

        String resultBody = resultAttachment.Body.toString();
        String expectedMessage = String.format(Label.ERROR_FLOW_EXECUTION, new List<Object>{ 'Invalid type: TestFlow' });
        System.assert(resultBody.contains(expectedMessage), 'Flow execution should fail');

        result = [SELECT Status__c, Error_Message__c FROM Result__c];
        System.assertEquals('Failed', result.Status__c, 'Result Status should be Failed');
        System.assertEquals(expectedMessage, result.Error_Message__c, 'Result error message should match');*/
    }

    @IsTest
    private static void testSalesforceFlowStepExecutionJsonParsingError() {
        ITestDefaults environmentDefaults = new CopadoSetupTestDefaults.EnvironmentDefaults()
            .setFieldDefaults()
            .setFieldValue(Environment__c.SObjectType, Environment__c.Name, 'Copado')
            .setDataSize(Environment__c.SObjectType, 1)
            .generateDefaults()
            .includeDefaults(CopadoSetupTestDefaults.EnvironmentDefaults.class)
            .setFieldValue(Environment__c.SObjectType, Environment__c.Name, 'Production')
            .setDataSize(Environment__c.SObjectType, 1)
            .generateDefaults()
            .executeDML();

        Environment__c copadoEnvironment;
        Environment__c productionEnvironment;

        for (Environment__c env : (List<Environment__c>) environmentDefaults.getTestData(Environment__c.SObjectType)) {
            switch on env.Name {
                when 'Copado 0' {
                    copadoEnvironment = env;
                }
                when 'Production 0' {
                    productionEnvironment = env;
                }
            }
        }

        String sfdcOrgId = UserInfo.getOrganizationId() + '_' + UserInfo.getUserId();
        ITestDefaults orgCredentialDefaults = new CopadoSetupTestDefaults.OrgCredentialDefaults()
            .setFieldDefaults()
            .setFieldValue(Org__c.SObjectType, Org__c.Name, 'Copado')
            .setFieldValue(Org__c.SObjectType, Org__c.Environment__c, copadoEnvironment.Id)
            .setFieldValue(Org__c.SObjectType, Org__c.Default_Credential__c, true)
            .setFieldValue(Org__c.SObjectType, Org__c.Validated_Date__c, System.now())
            .setFieldValue(Org__c.SObjectType, Org__c.SFDC_Org_ID__c, sfdcOrgId)
            .setDataSize(Org__c.SObjectType, 1)
            .generateDefaults()
            .includeDefaults(CopadoSetupTestDefaults.OrgCredentialDefaults.class)
            .setFieldValue(Org__c.SObjectType, Org__c.Name, 'Production')
            .setFieldValue(Org__c.SObjectType, Org__c.Environment__c, productionEnvironment.Id)
            .setFieldValue(Org__c.SObjectType, Org__c.Default_Credential__c, true)
            .setDataSize(Org__c.SObjectType, 1)
            .generateDefaults()
            .executeDML();

        Org__c copadoOrg = new Org__c();
        Org__c productionOrg = new Org__c();

        for (Org__c org : (List<Org__c>) orgCredentialDefaults.getTestData(Org__c.SObjectType)) {
            switch on org.Name {
                when 'Copado 0' {
                    copadoOrg = org;
                }
                when 'Production 0' {
                    productionOrg = org;
                }
            }
        }

        ITestDefaults deploymentDefaults = new CopadoUserStoryTestDefaults.DeploymentDefaults()
            .setFieldDefaults()
            .setFieldValue(Deployment__c.SObjectType, Deployment__c.From_Org__c, productionOrg.Id)
            .setDataSize(Deployment__c.SObjectType, 1)
            .generateDefaults()
            .includeDefaults(CopadoUserStoryTestDefaults.DeploymentStepDefaults.class)
            .setFieldValue(Step__c.SObjectType, Step__c.Status__c, 'Pending')
            .setFieldValue(Step__c.SObjectType, Step__c.Type__c, 'Salesforce Flow')
            .setFieldValue(Step__c.SObjectType, Step__c.dataJson__c, 'testDataJson')
            .setDataSize(Step__c.SObjectType, 1)
            .setSObjectRelation(Step__c.SObjectType, Deployment__c.SObjectType, new Map<Schema.SObjectField, Integer>{ Step__c.Deployment__c => 1 })
            .generateDefaults()
            .executeDML();

        Deployment__c deployment = (Deployment__c) deploymentDefaults.getTestData(Deployment__c.SObjectType)[0];

        Destination_Org__c destinationOrg = testMethodUtilities.create(deployment.Id, 'Pending', productionOrg.Id);
        insert destinationOrg;

        Step__c salesforceFlowStep = (Step__c) deploymentDefaults.getTestData(Step__c.SObjectType)[0];

        Test.startTest();
        Deployment_Job__c deploymentJob = [
            SELECT Status__c, Last_Result__c
            FROM Deployment_Job__c
            WHERE Step__c = :salesforceFlowStep.Id AND Destination_org__c = :destinationOrg.Id
        ];
        System.assertEquals('Pending', deploymentJob.Status__c, 'Job Status should be pending');
        deploymentJob.Status__c = 'In progress';
        update deploymentJob;
        List<AsyncApexJob> ayncFlowExecutors = [SELECT Id FROM AsyncApexJob];
        deploymentJob = [
            SELECT Last_Result__c
            FROM Deployment_Job__c
            WHERE Step__c = :salesforceFlowStep.Id AND Destination_org__c = :destinationOrg.Id
        ];
        Result__c result = [SELECT Job_Type__c, Status__c FROM Result__c];
        System.assertEquals(result.Id, deploymentJob.Last_Result__c, 'Last_Result__c should correspond to Result Id');
        System.assertEquals('Deployment Step 0', result.Job_Type__c, 'Job Type should correspond to Step Name');
        System.assertEquals('In Progress', result.Status__c, 'Result Status should be In progress');
        System.assert(!ayncFlowExecutors.isEmpty(), 'There should be a job enqueued');
        Test.stopTest();

        deploymentJob = [
            SELECT Status__c, Step__r.Deployment__c
            FROM Deployment_Job__c
            WHERE Step__c = :salesforceFlowStep.Id AND Destination_org__c = :destinationOrg.Id
        ];

        System.assertEquals('Failed', deploymentJob.Status__c, 'Deployment job status should be Failed.');
        Attachment resultAttachment = [SELECT Body FROM Attachment WHERE ParentId = :deploymentJob.Step__r.Deployment__c];

        String resultBody = resultAttachment.Body.toString();
        String expectedMessage = String.format(Label.ERROR_PARSING_FLOW_INFORMATION, new List<Object>{ '' });
        System.assert(resultBody.contains(expectedMessage), 'Flow information parsing should fail');

        result = [SELECT Status__c, Error_Message__c FROM Result__c];
        System.assertEquals('Failed', result.Status__c, 'Result Status should be Failed');
        System.assert(result.Error_Message__c.contains(expectedMessage), 'Result error message should match');
    }

    /**
     * Test method to check the Order field in the inserted steps is autopopulated according the existing steps for that deployment.
     * TODO: Refactor StepTriggerHelper and create TestStepTriggerHelper.cls, move this method there.
     */
    @IsTest
    private static void testSetStepOrderOnInsert() {
        Org__c testOrg = testMethodUtilities.createOrg('OrgName', 'Production', 'SFDC_OrgId', 'SFDC_TOKEN', 'USERNAME', System.now());
        insert testOrg;

        Deployment__c deployment = testMethodUtilities.create('DEPLOYMENT_NAME', System.now(), System.now(), testOrg.Id, 'Deploy now', 'In progress');
        //US-0026886:Commenting Deployment Automation template as record type is deactivated
        //deployment.RecordTypeId = Schema.SObjectType.Deployment__c.getRecordTypeInfosByDeveloperName().get('Automation_Template').getRecordTypeId();
        insert deployment;

        Test.startTest();
        Step__c step = testMethodUtilities.create('Step 1', 'attId', 'JSONString', deployment.Id, 7, 'Pending', 'Manual Task');
        Step__c step2 = testMethodUtilities.create('Step 2', 'attId', 'JSONString', deployment.Id, 6, 'Pending', 'Manual Task');
        Step__c step3 = testMethodUtilities.create('Step 3', 'attId', 'JSONString', deployment.Id, 0, 'Pending', 'Manual Task');
        insert new List<Step__c>{ step, step2, step3 };
        Test.stopTest();

        //Orders will be reordered based on order asc on after insert hence, it will be 3,2,1
        System.assertEquals(3, [SELECT Order__c FROM step__c WHERE Id = :step.Id].Order__c, 'Order is not sequential.');
        System.assertEquals(2, [SELECT Order__c FROM step__c WHERE Id = :step2.Id].Order__c, 'Order is not sequential.');
        System.assertEquals(1, [SELECT Order__c FROM step__c WHERE Id = :step3.Id].Order__c, 'Order is not sequential.');
    }

    @IsTest
    private static void testManualStepNotification() {
        createPipeline('Salesforce');
        Deployment_Flow__c pipeline = pipeline('Salesforce');

        Org__c testOrg1 = [SELECT Id, Environment__c FROM Org__c WHERE Name = 'USER-ORG'];
        Org__c testOrg2 = [SELECT Id, Environment__c FROM Org__c WHERE Name = 'DEV-1'];

        Project__c testProject = CMTestMethodUtilities.createProject('Test project');
        TestProject.Deployment_Flow__c = pipeline.Id;
        insert TestProject;
        Promotion__c testPromotion = CMTestMethodUtilities.createPromotion(TestProject.Id, testOrg2.Environment__c);
        insert TestPromotion;

        Deployment__c deployment = testMethodUtilities.create('DEPLOYMENT_NAME', System.now(), System.now(), testOrg1.Id, 'Deploy now', 'In progress');
        deployment.Promotion__c = TestPromotion.Id;
        //US-0026886:Commenting Deployment Automation template as record type is deactivated
        //deployment.RecordTypeId = Schema.SObjectType.Deployment__c.getRecordTypeInfosByDeveloperName().get('Automation_Template').getRecordTypeId();
        insert deployment;
        String jsonString = '{"Task_Owner":"' + UserInfo.getUserId() + '","Notify_Task_Owner":"Email","Apply_to":"All Environments in Pipeline","Disable_Task_for_Back_Promotions":false,"Selected_Environments":[]}';

        Test.startTest();
        Step__c step = testMethodUtilities.create('Step 1', 'attId', jsonString, deployment.Id, 1, 'Pending', 'Manual Task');
        insert step;
        Destination_Org__c dOrg = new Destination_Org__c(Deployment__c = deployment.Id, To_Org__c = testOrg2.Id);
        insert dOrg;
        Deployment_Job__c depJob = new Deployment_Job__c(Step__c = step.Id, Destination_Org__c = dOrg.Id);
        insert depJob;

        step.Status__c = 'In Progress';
        update step;
        Integer invocations = Limits.getEmailInvocations();
        Test.stopTest();

        system.assertEquals(1, invocations, 'An email should be sent');
    }

    private static Deployment_Flow__c pipeline(String platform) {
        return [SELECT Id, Platform__c FROM Deployment_Flow__c WHERE Platform__c = :platform LIMIT 1];
    }

    private static void createPipeline(String platform) {
        List<Environment__c> environments = new List<Environment__c>();
        Environment__c dev1Environment = CMTestMethodUtilities.createEnvironment('DEV-1', '000000000000000001');
        dev1Environment.Platform__c = platform;
        environments.add(dev1Environment);
        Environment__c intEnvironment = CMTestMethodUtilities.createEnvironment('INT', '000000000000000002');
        intEnvironment.Platform__c = platform;
        environments.add(intEnvironment);
        insert environments;

        List<Org__c> orgs = new List<Org__c>();
        Org__c userCredential = CMTestMethodUtilities.createOrg(
            'USER-ORG',
            'Production',
            UserInfo.getOrganizationId() +
            '_' +
            UserInfo.getUserId(),
            null,
            UserInfo.getUserName(),
            System.now(),
            null
        );
        userCredential.Oauth_Signature__c = '111222333444';
        orgs.add(userCredential);
        Org__c dev1Credential = CMTestMethodUtilities.createOrg(
            'DEV-1',
            'Production',
            '000000000000000001',
            null,
            null,
            System.now(),
            dev1Environment.Id
        );
        orgs.add(dev1Credential);
        Org__c intCredential = CMTestMethodUtilities.createOrg(
            'INT',
            'Production',
            '000000000000000002',
            null,
            null,
            System.now(),
            intEnvironment.Id
        );
        orgs.add(intCredential);
        insert orgs;

        Deployment_Flow__c pipeline = CMTestMethodUtilities.createFlow('PIPELINE');
        pipeline.Active__c = true;
        pipeline.Platform__c = platform;
        insert pipeline;

        Deployment_Flow_Step__c connection = CMTestMethodUtilities.createFlowStep(dev1Environment.Id, intEnvironment.Id, pipeline.Id);
        insert connection;

        List<System_Property__c> properties = new List<System_Property__c>();
        System_Property__c sourceProperty = new System_Property__c(
            API_Name__c = 'DBName',
            Value__c = 'OracleDB',
            Environment__c = dev1Environment.Id
        );
        properties.add(sourceProperty);
        System_Property__c destinationProperty = new System_Property__c(
            API_Name__c = 'DB-Provider',
            Value__c = 'Oracle',
            Environment__c = intEnvironment.Id
        );
        properties.add(destinationProperty);
        System_Property__c pipelineProperty = new System_Property__c(
            API_Name__c = 'Username',
            Value__c = 'user@oracledb.com',
            Pipeline__c = pipeline.Id
        );
        properties.add(pipelineProperty);
        insert properties;
    }
    
}