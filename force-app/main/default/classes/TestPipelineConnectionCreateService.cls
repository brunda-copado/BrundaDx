@IsTest
public with sharing class TestPipelineConnectionCreateService {
    @TestSetup
    static void makeData() {
        TestUtilities.enableLicenses(2, 2, 2, 2, 2, 30);
        ITestDefaults userCreation = new CopadoSetupTestDefaults.UserDefaults().createRunAsUsers().executeDML();
        User standardUser = userCreation.getRunAsUsers().get('Standard')[0];
        System.runAs(standardUser) {
            TestUtilities.assignLicense(String.valueOf(standardUser.Username), true, true, true, true, true);
            ITestDefaults orgCredentialDefaults = new CopadoSetupTestDefaults.OrgCredentialDefaults()
                .setFieldDefaults()
                .setFieldValue(Org__c.SObjectType, Org__c.Name, 'staging')
                .setFieldValue(Org__c.SObjectType, Org__c.Default_Credential__c, true)
                .setFieldValue(Org__c.SObjectType, Org__c.Validated_Date__c, Datetime.now())
                .setFieldValue(Org__c.SObjectType, Org__c.SFDC_Org_ID__c, '00D1i00000095cEEAQ_0050X000007h8hTQAQ_6')
                .setDataSize(Org__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CopadoSetupTestDefaults.OrgCredentialDefaults.class)
                .setFieldValue(Org__c.SObjectType, Org__c.Name, 'dev1')
                .setFieldValue(Org__c.SObjectType, Org__c.Default_Credential__c, true)
                .setFieldValue(Org__c.SObjectType, Org__c.Validated_Date__c, Datetime.now())
                .setFieldValue(Org__c.SObjectType, Org__c.SFDC_Org_ID__c, '00D1i00000095CBEAY_0050X000007h8hTQAQ_3')
                .setDataSize(Org__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CopadoSetupTestDefaults.OrgCredentialDefaults.class)
                .setFieldValue(Org__c.SObjectType, Org__c.Name, 'scratchOrg1')
                .setFieldValue(Org__c.SObjectType, Org__c.Username__c, 'test-acqffozptfsc@example.com')
                .setFieldValue(Org__c.SObjectType, Org__c.Validated_Date__c, Datetime.now())
                .setFieldValue(Org__c.SObjectType, Org__c.Org_Type__c, 'Scratch Org')
                .setFieldValue(Org__c.SObjectType, Org__c.Scratch_Org_Status__c, 'Active')
                .setFieldValue(Org__c.SObjectType, Org__c.SFDC_Org_ID__c, '00D1i00000199CBEAY_0050X000007h8hTQAQ_3')
                .setDataSize(Org__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CopadoSetupTestDefaults.OrgCredentialDefaults.class)
                .setFieldValue(Org__c.SObjectType, Org__c.Name, 'prod')
                .setFieldValue(Org__c.SObjectType, Org__c.Default_Credential__c, true)
                .setFieldValue(Org__c.SObjectType, Org__c.Validated_Date__c, Datetime.now())
                .setFieldValue(Org__c.SObjectType, Org__c.SFDC_Org_ID__c, '00D1i00000097CBEAY_0050X000007h8hTQAQ_3')
                .setDataSize(Org__c.SObjectType, 1)
                .includeDefaults(CopadoUserStoryTestDefaults.GitRepositoryDefaults.class)
                .setDataSize(Git_Repository__c.SObjectType, 1)
                .generateDefaults()
                .executeDML();

            Git_Repository__c gitRepo = (Git_Repository__c) orgCredentialDefaults.getTestData(Git_Repository__c.SObjectType)[0];
            Map<Id, Org__c> createdOrgs = new Map<Id, Org__c>((List<Org__c>) orgCredentialDefaults.getTestData(Org__c.SObjectType));
            update createdOrgs.values();
            String dev1Environment;
            String stagingEnvironment;
            String productionEnvironment;

            for (Org__c orgItem : [SELECT Id, Environment__c, Environment__r.Name FROM Org__c WHERE Id = :createdOrgs.keySet()]) {
                switch on orgItem.Environment__r.Name {
                    when 'staging 0' {
                        stagingEnvironment = orgItem.Environment__c;
                    }
                    when 'dev1 0' {
                        dev1Environment = orgItem.Environment__c;
                    }
                    when 'prod 0' {
                        productionEnvironment = orgItem.Environment__c;
                    }
                }
            }

            new CopadoUserStoryTestDefaults.PipelineDefaults()
                .setFieldDefaults()
                .setFieldValue(Deployment_Flow__c.SObjectType, Deployment_Flow__c.Calculate_Based_on__c, 'User Story')
                .setFieldValue(Deployment_Flow__c.SObjectType, Deployment_Flow__c.Enable_Copado_DX__c, true)
                .setFieldValue(Deployment_Flow__c.SObjectType, Deployment_Flow__c.Git_Repository__c, gitRepo.Id)
                .setDataSize(Deployment_Flow__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CopadoUserStoryTestDefaults.PipelineConnectionDefaults.class)
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Branch__c, 'dev1')
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Source_Environment__c, dev1Environment)
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Destination_Branch__c, 'staging')
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Destination_Environment__c, stagingEnvironment)
                .setDataSize(Deployment_Flow_Step__c.SObjectType, 1)
                .generateDefaults()
                .includeDefaults(CopadoUserStoryTestDefaults.PipelineConnectionDefaults.class)
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Branch__c, 'staging')
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Enable_as_Scratch_Org_Destination__c, 'DX Target')
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Source_Environment__c, stagingEnvironment)
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Destination_Branch__c, 'production')
                .setFieldValue(Deployment_Flow_Step__c.SObjectType, Deployment_Flow_Step__c.Destination_Environment__c, productionEnvironment)
                .setDataSize(Deployment_Flow_Step__c.SObjectType, 1)
                .generateDefaults()
                .setSObjectRelation(
                    Deployment_Flow_Step__c.SObjectType,
                    Deployment_Flow__c.SObjectType,
                    new Map<Schema.SObjectField, Integer>{ Deployment_Flow_Step__c.Deployment_Flow__c => 2 }
                )
                .executeDML();
        }
    }
    /**
     * Having an External Scratch Org, we include the org in our pipeline
     */
    @IsTest
    static void testCreatePipelineConnection() {
        User runAsUser = getRunasUserAndAssignLicense();
        System.runAs(runAsUser) {
            PipelineConnectionCreateService pipelineCoonectionInstance = new PipelineConnectionCreateService();
            pipelineCoonectionInstance.getInstance();

            PipelineConnectionCreateService.Config pipelineConnData = pipelineConnCreateData();

            Test.startTest();
            String response = executeApiCall(pipelineConnData);
            PipelineConnectionCreateService.Response responseInfo = (PipelineConnectionCreateService.Response) JSON.deserialize(
                response,
                PipelineConnectionCreateService.Response.class
            );
            System.assertEquals(CliSfDataWrapper.StatusResult.OK.name(), responseInfo.status, 'Status must be OK');

            Test.stopTest();

            Deployment_Flow_Step__c assertDeploymentFlowStepinserted = getDeploymentFlowStepinserted(responseInfo.pipelineConnection);
            String assertOrgCredential = [SELECT Id FROM Org__c WHERE Environment__c = :pipelineConnData.sourceEnvironmentId LIMIT 1].Id;
            List<Git_Backup__c> assertGitSnapShot = getAssertGitSnapShot(assertOrgCredential);

            System.assertEquals(
                pipelineConnData.sourceEnvironmentId,
                assertDeploymentFlowStepinserted.Source_Environment__c,
                'Source Environment does not match'
            );
            System.assertEquals(
                pipelineConnData.destinationEnvironmentId,
                assertDeploymentFlowStepinserted.Destination_Environment__c,
                'Destination Environment does not match'
            );
            System.assertEquals('staging', assertDeploymentFlowStepinserted.Destination_Branch__c, 'Destination Branch does not match');
            System.assertEquals(
                'project/DX-' + assertOrgCredential.substring(3, 15),
                assertDeploymentFlowStepinserted.Branch__c,
                'Branch does not match'
            );

            System.assertEquals(true, assertGitSnapShot.isEmpty(), 'No Git Snapshot should be created');
        }
    }

    /**
     * Having an External Scratch Org, we include the org in our pipeline giving a branch name
     */
    @IsTest
    static void testCreatePipelineConnectionWithBranchName() {
        User runAsUser = getRunasUserAndAssignLicense();
        System.runAs(runAsUser) {
            PipelineConnectionCreateService pipelineCoonectionInstance = new PipelineConnectionCreateService();
            pipelineCoonectionInstance.getInstance();

            PipelineConnectionCreateService.Config pipelineConnData = pipelineConnCreateData();
            pipelineConnData.sourceBranch = 'scratchorgbranch';

            Test.startTest();
            String response = executeApiCall(pipelineConnData);
            PipelineConnectionCreateService.Response responseInfo = (PipelineConnectionCreateService.Response) JSON.deserialize(
                response,
                PipelineConnectionCreateService.Response.class
            );
            System.assertEquals(CliSfDataWrapper.StatusResult.OK.name(), responseInfo.status, 'Status must be OK');

            Test.stopTest();

            Deployment_Flow_Step__c assertDeploymentFlowStepinserted = getDeploymentFlowStepinserted(responseInfo.pipelineConnection);
            String assertOrgCredential = [SELECT Id FROM Org__c WHERE Environment__c = :pipelineConnData.sourceEnvironmentId LIMIT 1].Id;
            List<Git_Backup__c> assertGitSnapShot = getAssertGitSnapShot(assertOrgCredential);

            System.assertEquals(
                pipelineConnData.sourceEnvironmentId,
                assertDeploymentFlowStepinserted.Source_Environment__c,
                'Source Environment does not match'
            );
            System.assertEquals(
                pipelineConnData.destinationEnvironmentId,
                assertDeploymentFlowStepinserted.Destination_Environment__c,
                'Destination Environment does not match'
            );
            System.assertEquals('staging', assertDeploymentFlowStepinserted.Destination_Branch__c, 'Destination Branch does not match');
            System.assertEquals('scratchorgbranch', assertDeploymentFlowStepinserted.Branch__c, 'Branch does not match');

            System.assertEquals(1, assertGitSnapShot.size(), 'There must be only one record');
            System.assertEquals('scratchorgbranch', assertGitSnapShot[0].Branch__c, 'Branch does not match');
        }
    }

    /**
     * Having an External Scratch Org, we include the org in our pipeline, but we use the default scratch org id coming from local CLI
     */
    @IsTest
    static void testCreatePipelineConnectionWithDefaultScratchOrg() {
        User runAsUser = getRunasUserAndAssignLicense();
        Org__c defaultSourceEnv = [SELECT Id, Environment__c, Environment__r.Org_ID__c FROM Org__c WHERE Name = 'scratchOrg1 0'];

        System.runAs(runAsUser) {
            PipelineConnectionCreateService pipelineCoonectionInstance = new PipelineConnectionCreateService();
            pipelineCoonectionInstance.getInstance();

            PipelineConnectionCreateService.Config pipelineConnData = pipelineConnCreateData();
            pipelineConnData.sourceEnvironmentId = defaultSourceEnv.Environment__r.Org_ID__c;

            Test.startTest();
            String response = executeApiCall(pipelineConnData);
            PipelineConnectionCreateService.Response responseInfo = (PipelineConnectionCreateService.Response) JSON.deserialize(
                response,
                PipelineConnectionCreateService.Response.class
            );
            System.assertEquals(CliSfDataWrapper.StatusResult.OK.name(), responseInfo.status, 'Status must be OK');
            Test.stopTest();

            Deployment_Flow_Step__c assertDeploymentFlowStepinserted = getDeploymentFlowStepinserted(responseInfo.pipelineConnection);
            List<Git_Backup__c> assertGitSnapShot = getAssertGitSnapShot(defaultSourceEnv.Id);

            System.assertEquals(
                defaultSourceEnv.Environment__c,
                assertDeploymentFlowStepinserted.Source_Environment__c,
                'Source Environment does not match'
            );
            System.assertEquals(
                pipelineConnData.destinationEnvironmentId,
                assertDeploymentFlowStepinserted.Destination_Environment__c,
                'Destination Environment does not match'
            );
            System.assertEquals('staging', assertDeploymentFlowStepinserted.Destination_Branch__c, 'Destination Branch does not match');
            System.assertEquals(
                'project/DX-' + String.valueOf(defaultSourceEnv.Id).substring(3, 15),
                assertDeploymentFlowStepinserted.Branch__c,
                'Branch does not match'
            );
            System.assertEquals(true, assertGitSnapShot.isEmpty(), 'No Git Snapshot should be created');
        }
    }

    @IsTest
    static void testCreatePipelineConnectionScratchOrgNotRegistered() {
        User runAsUser = getRunasUserAndAssignLicense();

        System.runAs(runAsUser) {
            PipelineConnectionCreateService pipelineCoonectionInstance = new PipelineConnectionCreateService();
            pipelineCoonectionInstance.getInstance();

            PipelineConnectionCreateService.Config pipelineConnCreateData = pipelineConnCreateData();
            pipelineConnCreateData.sourceEnvironmentId = UserInfo.getOrganizationId();

            Test.startTest();
            String response = executeApiCall(pipelineConnCreateData);
            CliSfDataWrapper responseInfo = (CliSfDataWrapper) JSON.deserialize(response, CliSfDataWrapper.class);
            System.assertEquals(CliSfDataWrapper.StatusResult.ERROR.name(), responseInfo.status, 'Status must be ERROR');
            System.assertEquals(Label.DefaultOrgNotRegistered, responseInfo.message, 'Message does not match');

            Test.stopTest();
        }
    }

    /**
     * Negative test. Connection already Exists
     */
    @IsTest
    static void testCreateExistingPipelineConnection() {
        User runAsUser = getRunasUserAndAssignLicense();
        String sourceEnv = [SELECT Id FROM Environment__c WHERE Name = 'dev1 0'].Id;

        System.runAs(runAsUser) {
            PipelineConnectionCreateService pipelineCoonectionInstance = new PipelineConnectionCreateService();
            pipelineCoonectionInstance.getInstance();

            PipelineConnectionCreateService.Config pipelineConnCreateData = pipelineConnCreateData();
            pipelineConnCreateData.sourceEnvironmentId = sourceEnv;

            Test.startTest();
            String response = executeApiCall(pipelineConnCreateData);
            CliSfDataWrapper responseInfo = (CliSfDataWrapper) JSON.deserialize(response, CliSfDataWrapper.class);
            System.assertEquals(CliSfDataWrapper.StatusResult.ERROR.name(), responseInfo.status, 'Status must be ERROR');
            System.assertEquals('Source Environment exists in Pipeline', responseInfo.message, 'Message does not match');

            Test.stopTest();
        }
    }

    /**
     * Negative test. Destination Environment is not enabled as DX Target
     */
    @IsTest
    static void testCreatePipelineConnectionTargetNotEnabledforDX() {
        User runAsUser = getRunasUserAndAssignLicense();
        String destinationEnv = [SELECT Id FROM Environment__c WHERE Name = 'dev1 0'].Id;

        System.runAs(runAsUser) {
            PipelineConnectionCreateService pipelineCoonectionInstance = new PipelineConnectionCreateService();
            pipelineCoonectionInstance.getInstance();

            PipelineConnectionCreateService.Config pipelineConnCreateData = pipelineConnCreateData();
            pipelineConnCreateData.destinationEnvironmentId = destinationEnv;
            pipelineConnCreateData.isScratchOrg = true;

            Test.startTest();
            String response = executeApiCall(pipelineConnCreateData);
            CliSfDataWrapper responseInfo = (CliSfDataWrapper) JSON.deserialize(response, CliSfDataWrapper.class);
            System.assertEquals(CliSfDataWrapper.StatusResult.ERROR.name(), responseInfo.status, 'Status must be ERROR');
            System.assertEquals(Label.targetBranchRequired, responseInfo.message, 'Message does not match');

            Test.stopTest();
        }
    }

    /**
     * Method to create a template of data coming from CLI
     */
    private static PipelineConnectionCreateService.Config pipelineConnCreateData() {
        String scratchOrgEnvironment;
        String stagingEnvironment;

        String pipeline = [SELECT Id FROM Deployment_Flow__c WHERE Name = 'MyPipeline 0' LIMIT 1].Id;

        for (Org__c orgItem : [
            SELECT Id, Environment__c, Environment__r.Name, Environment__r.Org_ID__c
            FROM Org__c
            WHERE Name IN ('scratchOrg1 0', 'staging 0')
        ]) {
            switch on orgItem.Environment__r.Name {
                when 'staging 0' {
                    stagingEnvironment = orgItem.Environment__c;
                }
                when 'scratchOrg1 0' {
                    scratchOrgEnvironment = orgItem.Environment__c;
                }
            }
        }
        PipelineConnectionCreateService.Config pipelineConnCreateData = new PipelineConnectionCreateService.Config();
        pipelineConnCreateData.pipelineId = pipeline;
        pipelineConnCreateData.destinationEnvironmentId = stagingEnvironment;
        pipelineConnCreateData.sourceEnvironmentId = scratchOrgEnvironment;
        pipelineConnCreateData.createSnapShotRecord = true;

        return pipelineConnCreateData;
    }

    /**
     * Execute mock api call.
     */
    private static String executeApiCall(PipelineConnectionCreateService.Config pipelineConnCreateData) {
        CliProxy.CLIWrapper reqBody = new CliProxy.CLIWrapper();
        reqBody.mainService = 'pipeline';
        reqBody.subService = 'connection';
        reqBody.operation = 'create';
        reqBody.body = JSON.serialize(pipelineConnCreateData);
        RestResponse res = new RestResponse();
        RestContext.request = Test_CliProxy.commonRequest(JSON.serialize(reqBody));
        RestContext.response = res;
        return CliProxy.doPost();
    }

    /**
     * Gets pipeline connection inserted to assert the results
     */
    private static Deployment_Flow_Step__c getDeploymentFlowStepinserted(String pipelineConnId) {
        return [
            SELECT Id, Deployment_Flow__c, Branch__c, Source_Environment__c, Destination_Environment__c, Destination_Branch__c
            FROM Deployment_Flow_Step__c
            WHERE Id = :pipelineConnId
            LIMIT 1
        ];
    }

    /**
     * Get the inserted git snapshot record
     */
    private static List<Git_Backup__c> getAssertGitSnapShot(String orgId) {
        return [
            SELECT Id, Name, Org__c, Git_Snapshot_Permissions__c, Git_Repository__c, Branch__c
            FROM Git_Backup__c
            WHERE Name = :orgId + ' Git Snapshot' AND Org__c = :orgId AND Git_Snapshot_Permissions__c = 'Allow Commits Only'
        ];
    }

    private static User getRunasUserAndAssignLicense() {
        User standardUser = [SELECT Id, Username FROM User WHERE Username = 'test_user@myorg.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(standardUser.Username), true, true, false, false, false);
        return standardUser;
    }
}