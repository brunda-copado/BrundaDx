@IsTest
private with sharing class JobTemplateServiceTest {
    @TestSetup
    private static void setupData() {
        TestUtilities.getAllMultilicense();
        User user = (User) new User_t()
            .assign(new PermissionSetAssignment_t().copadoUser())
            .assign(new PermissionSetAssignment_t().functions())
            .assign(new PermissionSetAssignment_t().jobEngine())
            .assign(new PermissionSetAssignment_t().qualityGatesAdmin())
            .assign(new PermissionSetAssignment_t().configureAutomations())
            .assign(new PermissionSetAssignment_t().executeAutomations())
            .persist();
        System.runAs(user) {
            new CopadoLicense().user(user).enableAll().persist();
            data();
        }
    }

    @IsTest
    static void promotionValidation() {
        // Setup
        User user = getRunAsUser();
        List<Environment__c> environments = [SELECT Id, Name, Type__c, Platform__c FROM Environment__c];
        Deployment_Flow__c deploymentFlow = getPipeline();

        System.runAs(user) {
            // Exercise
            Test.startTest();

            PageReference pReference = Page.PipelineManager;
            Test.setCurrentPage(pReference);
            ApexPages.StandardController pipelineSc = new ApexPages.StandardController(deploymentFlow);
            PipelineManagerExtension currentPipelineController = new PipelineManagerExtension(pipelineSc);
            currentPipelineController.populateFlowGridMap();
            currentPipelineController.getPromotableUserStoriesCount();
            currentPipelineController.getBackPromotableUserStoriesCount();

            List<PipelineManagerExtension.EnvironmentWrapper> assertionStage = new List<PipelineManagerExtension.EnvironmentWrapper>(
                currentPipelineController.allEnvironmentsByStageGroupMap.get(1).get(environments[2].Id)
            );
            System.assertEquals(2, assertionStage.size(), 'The number of environments in stage 1 is not 2');
            System.assertEquals(false, assertionStage[0].isDestinationEnv, 'Environment 1 in stage 1 is not marked as Destination Environment');
            System.assertEquals(1, assertionStage[0].userStoriesAhead, 'In Environment 2 there are not only 1 User Stories Ahead in stage 1');
            System.assertEquals(0, assertionStage[0].userStoriesBehind, 'In Environment 2 there are more than 0 User Stories Behind in stage 1');

            System.assertEquals(false, assertionStage[1].isDestinationEnv, 'Environment 2 in stage 1 is not marked as Destination Environment');
            System.assertEquals(0, assertionStage[1].userStoriesAhead, 'In Environment 2 there are not only 0 User Stories Ahead in stage 1');
            System.assertEquals(0, assertionStage[1].userStoriesBehind, 'In Environment 2 there are more than 0 User Stories Behind in stage 1');

            // This code block simulates a click on a forward arrow in Pipeline Manager
            ApexPages.currentPage().getParameters().put('fromId', environments[0].Id);
            ApexPages.currentPage().getParameters().put('toId', environments[2].Id);
            ApexPages.currentPage().getParameters().put('pathType', 'merge');
            currentPipelineController.getPromotableBackPromotableUserStoriesList();
            // End of code block

            System.assertEquals('merge', currentPipelineController.newOverlay.pathType, 'Path type is not merge');
            System.assertEquals(1, currentPipelineController.newOverlay.userStories.size(), 'Number of user stories is not 1');

            currentPipelineController.createPromotionforValidation();

            Test.stopTest();
        }
    }

    @IsTest
    static void deployActionExecuteParameters() {
        // Setup
        User user = getRunAsUser();
        List<Environment__c> environments = [SELECT Id, Name, Type__c, Platform__c FROM Environment__c];
        Deployment_Flow__c deploymentFlow = getPipeline();

        System.runAs(user) {
            // Exercise
            PageReference pReference = Page.PipelineManager;
            Test.setCurrentPage(pReference);
            ApexPages.StandardController pipelineSc = new ApexPages.StandardController(deploymentFlow);
            PipelineManagerExtension currentPipelineController = new PipelineManagerExtension(pipelineSc);
            currentPipelineController.populateFlowGridMap();
            currentPipelineController.getPromotableUserStoriesCount();
            currentPipelineController.getBackPromotableUserStoriesCount();

            // This code block simulates a click on a forward arrow in Pipeline Manager
            ApexPages.currentPage().getParameters().put('fromId', environments[0].Id);
            ApexPages.currentPage().getParameters().put('toId', environments[2].Id);
            ApexPages.currentPage().getParameters().put('pathType', 'merge');
            currentPipelineController.getPromotableBackPromotableUserStoriesList();
            // End of code Block

            Test.startTest();
            currentPipelineController.createPromotion();
            Test.stopTest();

            // Verify
            Promotion__c currentPromotionWrapper = currentPipelineController.promotionWrappers[0].promotion; // Created for better readability

            Promotion__c assertCurrentPromotion = [
                SELECT Id, Name, Destination_Environment__c, Source_Environment__c, Project__c, Status__c
                FROM Promotion__c
                WHERE Source_Environment__r.Name = :environments[0].Name AND Destination_Environment__r.Name = :environments[2].Name
                LIMIT 1
            ];

            System.assertNotEquals(null, assertCurrentPromotion.Id, 'Promotion is not created');
            System.assertEquals(
                1,
                currentPipelineController.promotionWrappers.size(),
                'Promotion list wrapper is not populated correctly with 1 record'
            );
            System.assertEquals(
                assertCurrentPromotion.Name,
                currentPromotionWrapper.Name,
                'Name of Promotion created and Promotion shown in the list is not the same'
            );
            System.assertEquals(
                assertCurrentPromotion.Destination_Environment__c,
                currentPromotionWrapper.Destination_Environment__c,
                'Destination Environment of Promotion created and Promotion shown in the list is not the same'
            );
            System.assertEquals(
                assertCurrentPromotion.Source_Environment__c,
                currentPromotionWrapper.Source_Environment__c,
                'Source Environment of Promotion created and Promotion shown in the list is not the same'
            );
            System.assertEquals(
                assertCurrentPromotion.Project__c,
                currentPromotionWrapper.Project__c,
                'Project of Promotion created and Promotion shown in the list is not the same'
            );
            System.assertEquals('Draft', currentPromotionWrapper.Status__c, 'Draft of Promotion shown in the list is not Scheduled');
            System.assertEquals(
                assertCurrentPromotion.Status__c,
                currentPromotionWrapper.Status__c,
                'Name of Promotion created and Promotion shown in the list is not the same'
            );
        }
    }

    // PRIVATE

    private static void data() {
        Personal_Settings__c ps = Personal_Settings__c.getInstance();
        if (String.isBlank(ps.API_Key__c)) {
            ps.API_Key__c = DeployAPI.encryptAPIKey('99999999999999999999');
            upsert ps;
        }

        //Environment creation
        for (Integer i = 0; i < 3; i++) {
            new Environment().name('Environment ' + i).type('Production/Developer').platform('Other');
        }
        new Environment().name('Test Environment 3').type('Production/Developer').platform('Other').persist();
        List<Environment__c> environments = [SELECT Id, Name, Type__c, Platform__c FROM Environment__c ORDER BY CreatedDate];

        // Org Credential validation
        List<Org__c> credentials = [
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

        // Function creation
        String namespace = namespacePrefix();
        new Function()
            .name('mulePromotion')
            .apiName('mulePromotion')
            .script('echo hello world $par1')
            .type('Custom')
            .paramaters(
                '[{"name": "SourceDBName", "defaultValue": "{!$Source.Property.DBName}", "required": true},' +
                '{"name": "DestinationDBProvider", "defaultValue": "{!$Destination.Property.DB-Provider}", "required": true},' +
                '{"name": "PipelineUsername", "defaultValue": "{!$Pipeline.Property.Username}", "required": true},' +
                '{"name": "UserEmail", "defaultValue": "{!$User.Property.Email}", "required": true},' +
                '{"name": "LogLevel", "defaultValue": "ERROR", "required": false}]'
            )
            .options(
                '[{"name": "gitUrl", "value": "xxxxxx", "sensitive": true},' +
                '{"name": "gitUsername", "value": "", "sensitive": true},' +
                '{"name": "gitPassword", "value": "", "sensitive": true},' +
                '{"name": "branchName", "value": "", "sensitive": false}]'
            )
            .callbackType('ApexClass')
            .apexClass(namespace + 'FunctionStepExecutionCallback');

        new Function()
            .name('muleDeployment')
            .apiName('muleDeployment')
            .script('echo hello world $par1')
            .type('Custom')
            .paramaters(
                '[{"name": "SourceDBName", "defaultValue": "{!$Source.Property.DBName}", "required": true},' +
                '{"name": "DestinationDBProvider", "defaultValue": "{!$Destination.Property.DB-Provider}", "required": true},' +
                '{"name": "PipelineUsername", "defaultValue": "{!$Pipeline.Property.Username}", "required": true},' +
                '{"name": "UserEmail", "defaultValue": "{!$User.Property.Email}", "required": true},' +
                '{"name": "LogLevel", "defaultValue": "ERROR", "required": false}]'
            )
            .options(
                '[{"name": "gitUrl", "value": "xxxxxx", "sensitive": true},' +
                '{"name": "gitUsername", "value": "", "sensitive": true},' +
                '{"name": "gitPassword", "value": "", "sensitive": true},' +
                '{"name": "branchName", "value": "", "sensitive": false}]'
            )
            .callbackType('ApexClass')
            .apexClass(namespace + 'FunctionStepExecutionCallback')
            .persist();

        new JobTemplate()
            .name('JOB_TEMPLATE_PROMOTION')
            .mockAutomation('Promotion')
            .volumeOptions('[{ "name": "volumeEnabled", "value": "false" }]')
            .add(new JobStep().order(1).type('Flow').configJson('{"flowName" : "MockedFlow"}'));
        new JobTemplate()
            .name('JOB_TEMPLATE_DEPLOYMENT')
            .mockAutomation('PromotionDeployment')
            .volumeOptions('[{ "name": "volumeEnabled", "value": "false" }]')
            .add(new JobStep().order(1).type('Function').configJson('{"functionName":"mulePromotion","parameters":[]}'))
            .persist();

        // Pipeline creation
        Deployment_Flow__c pipeline = (Deployment_Flow__c) new Pipeline()
            .active(true)
            .mainBranch('master')
            .setPlatform('Other')
            .add(new Connection().sourceId(environments[0].Id).destinationId(environments[2].Id).branch('dev1'))
            .add(new Connection().sourceId(environments[1].Id).destinationId(environments[2].Id).branch('dev2'))
            .add(
                new Project()
                    .add(
                        new UserStory()
                            .status('Approved')
                            .credentialId(credentials[0].Id)
                            .add(new UserStoryMetadata().name('TestClass').type('ApexClass'))
                    )
            )
            .persist();

        List<User_Story__c> usToUpdate = new List<User_Story__c>();
        for (User_Story__c userStory : [SELECT Id FROM User_Story__c]) {
            usToUpdate.add(new User_Story__c(Id = userStory.Id, Promote_Change__c = true));
        }
        update usToUpdate;

        // Quality Gate Rule creation
        createExtensionConfiguration();
        TestToolsSelector.mock(new List<TestTool__mdt>{ new TestTool__mdt(MasterLabel = 'None', TestType__c = 'Mock Type') });
        Quality_Gate_Rule__c rule = (Quality_Gate_Rule__c) new QualityGateRule()
            .action('PromotionDeployment')
            .sequence('Before')
            .tool('None') // @Note: Has to be one of the packaged values for the Copado Test Tool picklist
            .active(false)
            .name('Rule1')
            .add(new QualityGateRuleCondition().pipelineId(pipeline.Id).extensionConfiguration(getExtensionConfigurationId()))
            .persist();

        rule.Status__c = QualityGateConstants.ACTIVE;
        update rule;
    }

    private static String namespacePrefix() {
        return Settings.ns.replace('__', '.');
    }

    private static MC_Result__e functionCompletionEvent(Boolean isSuccess, String errorMessage, String data) {
        MC_Result__e result = new MC_Result__e();
        result.IsFinished__c = true;
        result.Result_Data__c = data;
        result.IsSuccess__c = isSuccess;
        result.Error_Message__c = errorMessage;

        return result;
    }

    private static Event__e flowCompletionEvent(Boolean isSuccess, String errorMessage, String data) {
        Event__e result = new Event__e();
        result.Topic_Uri__c = OnJobStepComplete.STEP_ENDPOINT;
        result.Payload__c = Json.serialize(new OnJobStepComplete.EventPayload(isSuccess, errorMessage, data));

        return result;
    }

    private static User getRunAsUser() {
        return [SELECT Id, Email FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1];
    }

    private static Deployment_Flow__c getPipeline() {
        return [
            SELECT
                Id,
                OwnerId,
                IsDeleted,
                Name,
                CreatedDate,
                CreatedById,
                LastModifiedDate,
                LastModifiedById,
                SystemModstamp,
                LastViewedDate,
                LastReferencedDate,
                Active__c,
                Branch_Management_Coordinates__c,
                Disable_Validations__c,
                Equal_Branch_Environment_Name__c,
                Flow_Step_Coordinates__c,
                Git_Repository__c,
                Main_Branch__c,
                Manage_Branches__c,
                Static_Code_Analysis_Settings__c,
                Block_Commits__c,
                Calculate_Based_on__c,
                Copado_DX_Mode__c,
                Enable_Copado_DX__c,
                Exclude_From_Auto_Resolve__c,
                Hide_Tabs__c,
                Order_by__c,
                Merge_Strategy__c,
                Enable_Smart_Conflict_Resolution__c,
                Platform__c
            FROM Deployment_Flow__c
            LIMIT 1
        ];
    }

    private static Id getExtensionConfigurationId() {
        return [SELECT Id FROM ExtensionConfiguration__c LIMIT 1].id;
    }

    private static ExtensionConfiguration__c createExtensionConfiguration() {
        ExtensionConfiguration__c extensionConfig = new ExtensionConfiguration__c(
            ExtensionTool__c = 'Manual Tests', // @Note: Has to be one of the packaged values for this picklist field
            ExtensionApplication__c = 'Test',
            Active__c = true
        );

        insert extensionConfig;
        return extensionConfig;
    }

    private static List<User_Story_Metadata__c> metadata(User_Story__c userStory, Integer count) {
        List<User_Story_Metadata__c> result = new List<User_Story_Metadata__c>();

        for (Integer i = 0; i < count; i++) {
            result.add(new User_Story_Metadata__c(User_Story__c = userStory.Id, Name = 'TestClass_' + i, Type__c = 'ApexClass'));
        }
        insert result;
        return result;
    }
}