@IsTest
private class GlobalFindAndReplaceTest {
    private static User_Story__c userStory;
    private static Deployment_Flow__c deploymentFlow;
    private static List<Environment__c> environments;
    private static List<Org__c> credentials;
    private static JobTemplate__c deploymentJobTemplate;
    private static JobTemplate__c promotionJobTemplate;
    private static Project__c project;
    private static Function__c functionPromotion;
    private static Function__c functionDeployment;
    private static String namespace;

    @TestSetup
    private static void setupData() {
        List<User> userList = TestDataFactory.createUsers();
        TestUtilities.enableLicenses(2, 2, 2, 2, 2);
        FeatureManagement.setPackageIntegerValue('CBM_Branches', 2);
        List<PermissionSet> permissionSets = [
            SELECT Id
            FROM PermissionSet
            WHERE Name IN ('Copado_User', 'Copado_Functions', 'Copado_Job_Engine')
        ];
        List<PermissionSetAssignment> assignments = new List<PermissionSetAssignment>();
        for (PermissionSet permissionSet : permissionSets) {
            assignments.add(new PermissionSetAssignment(AssigneeId = userList[0].Id, PermissionSetId = permissionSet.Id));
        }
        insert assignments;
    }

    @IsTest
    static void executeFromSourceEnvironment() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true);

        System.runAs(sysUser) {
            data();

            Promotion__c promotion = TestDataFactory.createPromotion(project.Id, null, environments[0].Id, null, null, 'Draft');
            insert promotion;

            JobExecution__c jobExecution = new JobExecutionsSelector().byPromotionId(promotion.Id);
            System.assertEquals(null, jobExecution, 'Job Execution is not created');

            promotion = [
                SELECT Id, Name, Source_Environment__c, Source_Org_Credential__c, Destination_Environment__c, Destination_Org_Credential__c
                FROM Promotion__c
                WHERE Id = :promotion.Id
            ];
            System.assertNotEquals(null, promotion.Source_Org_Credential__c, 'Promotion Source Credential is null');
            System.assertNotEquals(null, promotion.Destination_Environment__c, 'Promotion Destination Environment is null');
            System.assertNotEquals(null, promotion.Destination_Org_Credential__c, 'Promotion Destination Credential is null');

            JobExecution__c promotionExecution = TestDataFactory.createJobExecution(promotionJobTemplate.Id, 'Successful');
            promotionExecution.Promotion__c = promotion.Id;
            promotionExecution.Source__c = promotion.Source_Environment__c;
            promotionExecution.Destination__c = promotion.Destination_Environment__c;
            promotionExecution.Callback__c = namespace + 'PromoteAction';
            insert promotionExecution;

            JobStep__c functionPromotionExecutionStep = TestDataFactory.createJobStep(
                'Function',
                null,
                'Function',
                1,
                '{"functionName":"mulePromotion","parameters":[]}'
            );
            functionPromotionExecutionStep.JobExecution__c = promotionExecution.Id;
            insert functionPromotionExecutionStep;

            functionPromotionExecutionStep = [
                SELECT Id, Pipeline_Id__c, Source_Id__c, Destination_Id__c
                FROM JobStep__c
                WHERE Id = :functionPromotionExecutionStep.Id
            ];

            Result__c functionPromotionExecutionStepResult = TestDataFactory.createResult(
                functionPromotionExecutionStep.Id,
                functionPromotion.API_Name__c,
                'Success',
                functionPromotion.Id
            );
            insert functionPromotionExecutionStepResult;

            functionPromotionExecutionStep.Result__c = functionPromotionExecutionStepResult.Id;
            update functionPromotionExecutionStep;

            PromotedUserStoriesDatatableController.addSelectedUserStoriesToPromotion(promotion.Id, new List<Id>{ userStory.Id });

            // create new file
            ContentVersion contentVersionRecord = new ContentVersion();
            contentVersionRecord.ContentLocation = 'S'; // 'S' = a Salesforce File
            contentVersionRecord.VersionData = Blob.valueOf('sample content');
            contentVersionRecord.Title = 'Copado';
            contentVersionRecord.PathOnClient = 'Copado.yml';
            insert contentVersionRecord;

            Id contentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersionRecord.Id].ContentDocumentId;
            ContentDocumentLink contentDocumentLinkRecord = new ContentDocumentLink();
            contentDocumentLinkRecord.LinkedEntityId = environments[0].Id;
            contentDocumentLinkRecord.ContentDocumentId = contentDocumentId;
            contentDocumentLinkRecord.shareType = 'V';
            insert contentDocumentLinkRecord;

            Test.startTest();
            GlobalFindAndReplaceSourceId controller = new GlobalFindAndReplaceSourceId();
            String fileId = controller.execute(functionPromotionExecutionStep.Id);
            Test.stopTest();

            System.assertNotEquals(contentDocumentId, fileId, 'file id is different');
        }
    }

    @IsTest
    static void executeFromDestinationEnvironment() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true);

        System.runAs(sysUser) {
            data();

            Promotion__c promotion = TestDataFactory.createPromotion(project.Id, null, environments[0].Id, null, null, 'Draft');
            insert promotion;

            JobExecution__c jobExecution = new JobExecutionsSelector().byPromotionId(promotion.Id);
            System.assertEquals(null, jobExecution, 'Job Execution is not created');

            promotion = [
                SELECT Id, Name, Source_Environment__c, Source_Org_Credential__c, Destination_Environment__c, Destination_Org_Credential__c
                FROM Promotion__c
                WHERE Id = :promotion.Id
            ];
            System.assertNotEquals(null, promotion.Source_Org_Credential__c, 'Promotion Source Credential is null');
            System.assertNotEquals(null, promotion.Destination_Environment__c, 'Promotion Destination Environment is null');
            System.assertNotEquals(null, promotion.Destination_Org_Credential__c, 'Promotion Destination Credential is null');

            JobExecution__c promotionExecution = TestDataFactory.createJobExecution(promotionJobTemplate.Id, 'Successful');
            promotionExecution.Promotion__c = promotion.Id;
            promotionExecution.Source__c = promotion.Source_Environment__c;
            promotionExecution.Destination__c = promotion.Destination_Environment__c;
            promotionExecution.Callback__c = namespace + 'PromoteAction';
            insert promotionExecution;

            JobStep__c functionPromotionExecutionStep = TestDataFactory.createJobStep(
                'Function',
                null,
                'Function',
                1,
                '{"functionName":"mulePromotion","parameters":[]}'
            );
            functionPromotionExecutionStep.JobExecution__c = promotionExecution.Id;
            insert functionPromotionExecutionStep;

            functionPromotionExecutionStep = [
                SELECT Id, Pipeline_Id__c, Source_Id__c, Destination_Id__c
                FROM JobStep__c
                WHERE Id = :functionPromotionExecutionStep.Id
            ];

            Result__c functionPromotionExecutionStepResult = TestDataFactory.createResult(
                functionPromotionExecutionStep.Id,
                functionPromotion.API_Name__c,
                'Success',
                functionPromotion.Id
            );
            insert functionPromotionExecutionStepResult;

            functionPromotionExecutionStep.Result__c = functionPromotionExecutionStepResult.Id;
            update functionPromotionExecutionStep;

            PromotedUserStoriesDatatableController.addSelectedUserStoriesToPromotion(promotion.Id, new List<Id>{ userStory.Id });

            // create new file
            ContentVersion contentVersionRecord = new ContentVersion();
            contentVersionRecord.ContentLocation = 'S'; // 'S' = a Salesforce File
            contentVersionRecord.VersionData = Blob.valueOf('sample content');
            contentVersionRecord.Title = 'Copado';
            contentVersionRecord.PathOnClient = 'Copado.yml';
            insert contentVersionRecord;

            Id contentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersionRecord.Id].ContentDocumentId;
            ContentDocumentLink contentDocumentLinkRecord = new ContentDocumentLink();
            contentDocumentLinkRecord.LinkedEntityId = promotion.Destination_Environment__c;
            contentDocumentLinkRecord.ContentDocumentId = contentDocumentId;
            contentDocumentLinkRecord.shareType = 'V';
            insert contentDocumentLinkRecord;

            Test.startTest();
            GlobalFindAndReplaceDestinationId controller = new GlobalFindAndReplaceDestinationId();
            String fileId = controller.execute(functionPromotionExecutionStep.Id);
            Test.stopTest();

            System.assertNotEquals(contentDocumentId, fileId, 'file id is different');
        }
    }

    @IsTest
    static void executeFromPipeline() {
        User sysUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test1@test1.com' LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(sysUser.Username), true, true, true, true, true);

        System.runAs(sysUser) {
            data();

            Promotion__c promotion = TestDataFactory.createPromotion(project.Id, null, environments[0].Id, null, null, 'Draft');
            insert promotion;

            JobExecution__c jobExecution = new JobExecutionsSelector().byPromotionId(promotion.Id);
            System.assertEquals(null, jobExecution, 'Job Execution is not created');

            promotion = [
                SELECT Id, Name, Source_Environment__c, Source_Org_Credential__c, Destination_Environment__c, Destination_Org_Credential__c
                FROM Promotion__c
                WHERE Id = :promotion.Id
            ];
            System.assertNotEquals(null, promotion.Source_Org_Credential__c, 'Promotion Source Credential is null');
            System.assertNotEquals(null, promotion.Destination_Environment__c, 'Promotion Destination Environment is null');
            System.assertNotEquals(null, promotion.Destination_Org_Credential__c, 'Promotion Destination Credential is null');

            JobExecution__c promotionExecution = TestDataFactory.createJobExecution(promotionJobTemplate.Id, 'Successful');
            promotionExecution.Promotion__c = promotion.Id;
            promotionExecution.Source__c = promotion.Source_Environment__c;
            promotionExecution.Destination__c = promotion.Destination_Environment__c;
            promotionExecution.Callback__c = namespace + 'PromoteAction';
            insert promotionExecution;

            JobStep__c functionPromotionExecutionStep = TestDataFactory.createJobStep(
                'Function',
                null,
                'Function',
                1,
                '{"functionName":"mulePromotion","parameters":[]}'
            );
            functionPromotionExecutionStep.JobExecution__c = promotionExecution.Id;
            insert functionPromotionExecutionStep;

            functionPromotionExecutionStep = [
                SELECT Id, Pipeline_Id__c, Source_Id__c, Destination_Id__c
                FROM JobStep__c
                WHERE Id = :functionPromotionExecutionStep.Id
            ];

            Result__c functionPromotionExecutionStepResult = TestDataFactory.createResult(
                functionPromotionExecutionStep.Id,
                functionPromotion.API_Name__c,
                'Success',
                functionPromotion.Id
            );
            insert functionPromotionExecutionStepResult;

            functionPromotionExecutionStep.Result__c = functionPromotionExecutionStepResult.Id;
            update functionPromotionExecutionStep;

            PromotedUserStoriesDatatableController.addSelectedUserStoriesToPromotion(promotion.Id, new List<Id>{ userStory.Id });

            // create new file
            ContentVersion contentVersionRecord = new ContentVersion();
            contentVersionRecord.ContentLocation = 'S'; // 'S' = a Salesforce File
            contentVersionRecord.VersionData = Blob.valueOf('sample content');
            contentVersionRecord.Title = 'Copado';
            contentVersionRecord.PathOnClient = 'Copado.yml';
            insert contentVersionRecord;

            Id contentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersionRecord.Id].ContentDocumentId;
            ContentDocumentLink contentDocumentLinkRecord = new ContentDocumentLink();
            contentDocumentLinkRecord.LinkedEntityId = deploymentFlow.Id;
            contentDocumentLinkRecord.ContentDocumentId = contentDocumentId;
            contentDocumentLinkRecord.shareType = 'V';
            insert contentDocumentLinkRecord;

            Test.startTest();
            GlobalFindAndReplaceDestinationId controller = new GlobalFindAndReplaceDestinationId();
            String fileId = controller.execute(functionPromotionExecutionStep.Id);
            Test.stopTest();

            System.assertNotEquals(contentDocumentId, fileId, 'file id is different');
        }
    }

    private static void data() {
        Personal_Settings__c ps = Personal_Settings__c.getInstance();
        if (String.isBlank(ps.API_Key__c)) {
            ps.API_Key__c = DeployAPI.encryptAPIKey('99999999999999999999');
            upsert ps;
        }

        //Environment creation
        environments = new List<Environment__c>();
        for (Integer i = 0; i < 3; i++) {
            Environment__c environment = TestDataFactory.createEnvironments('Environment ' + i, 'Production/Developer');
            environment.Platform__c = 'Other';
            environments.add(environment);
        }
        insert environments;

        // Function creation
        String namespace = namespacePrefix();
        functionPromotion = new Function__c(
            Name = 'mulePromotion',
            API_Name__c = 'mulePromotion',
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
            ApexClass__c = namespace + 'FunctionStepExecutionCallback'
        );
        functionDeployment = new Function__c(
            Name = 'muleDeployment',
            API_Name__c = 'muleDeployment',
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
            ApexClass__c = namespace + 'FunctionStepExecutionCallback'
        );
        insert new List<Function__c>{ functionPromotion, functionDeployment };

        // Job template creation
        deploymentJobTemplate = TestDataFactory.createJobTemplate(
            'JOB_TEMPLATE_DEPLOYMENT',
            'JOB_TEMPLATE_DEPLOYMENT',
            1,
            '[{ "name": "volumeEnabled", "value": "false" }]'
        );
        promotionJobTemplate = TestDataFactory.createJobTemplate(
            'JOB_TEMPLATE_PROMOTION',
            'JOB_TEMPLATE_PROMOTION',
            1,
            '[{ "name": "volumeEnabled", "value": "false" }]'
        );
        insert new List<JobTemplate__c>{ deploymentJobTemplate, promotionJobTemplate };

        // Job step creation
        JobStep__c functionDeploymentStep = TestDataFactory.createJobStep(
            'Function',
            deploymentJobTemplate.Id,
            'Function',
            1,
            '{"functionName":"muleDeployment","parameters":[]}'
        );
        JobStep__c functionPromotionStep = TestDataFactory.createJobStep(
            'Function',
            promotionJobTemplate.Id,
            'Function',
            1,
            '{"functionName":"mulePromotion","parameters":[]}'
        );
        insert new List<JobStep__c>{ functionDeploymentStep, functionPromotionStep };

        // Git repository creation
        Git_Repository__c gitRepository = TestDataFactory.createGitRepository();
        insert gitRepository;

        // Deployment flow creation
        deploymentFlow = TestDataFactory.createDeploymentFlow('Deployment Flow', true, gitRepository.Id, false);
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
        credentials = [
            SELECT Id, Name, Environment__c, Platform__c, Oauth_Signature__c, Validated_Date__c, Disable_Validation__c, SFDC_Org_ID__c
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
        project = TestDataFactory.createProject('My project', deploymentFlow.Id, false);
        insert project;

        // User Story creation
        userStory = TestDataFactory.createUserStory('us-0000000', 'Approved', null, project.Id, null, credentials[0].Id);
        insert userStory;
    }

    private static String namespacePrefix() {
        return Settings.ns.replace('__', '.');
    }
}