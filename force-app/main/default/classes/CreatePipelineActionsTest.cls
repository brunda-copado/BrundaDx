@isTest
private with sharing class CreatePipelineActionsTest {
    @TestSetup
    private static void setup() {
        insertData();
    }

    @isTest
    private static void createAsAdminWithEmptyPlatform() {
        // Setup
        User user = (User) new User_t()
            .admin()
            .assign(new PermissionSetAssignment_t().copadoUser())
            .assign(new PermissionSetAssignment_t().jobEngine())
            .persist();

        System.runAs(user) {
            new CopadoLicense().user(user).enableAll().persist();
        }

        mockAutomations();

        // Exercise
        Deployment_Flow__c pipeline;
        System.runAs(user) {
            Test.startTest();
            pipeline = (Deployment_Flow__c) new Pipeline().persist();
            Test.stopTest();
        }

        // Verify
        System.assertEquals('Salesforce', pipeline.Platform__c, 'Empty Platform was not autopopulated.');

        List<Pipeline_Action__c> actions = pipelineActions(pipeline.Id);
        System.assert(actions.isEmpty(), 'No pipeline actions should be created for Salesforce pipelines.');
    }

    @isTest
    private static void createAsAdminWithSalesforcePlatform() {
        // Setup
        User user = (User) new User_t()
            .admin()
            .assign(new PermissionSetAssignment_t().copadoUser())
            .assign(new PermissionSetAssignment_t().jobEngine())
            .persist();

        System.runAs(user) {
            new CopadoLicense().user(user).enableAll().persist();
        }

        mockAutomations();

        // Exercise
        Deployment_Flow__c pipeline;
        System.runAs(user) {
            Test.startTest();
            pipeline = (Deployment_Flow__c) new Pipeline().setPlatform('Salesforce').persist();
            Test.stopTest();
        }

        // Verify
        List<Pipeline_Action__c> actions = pipelineActions(pipeline.Id);
        System.assert(actions.isEmpty(), 'No pipeline actions should be created for Salesforce pipelines.');
    }

    @isTest
    private static void createAsAdminWithOtherPlatform() {
        // Setup
        User user = (User) new User_t()
            .admin()
            .assign(new PermissionSetAssignment_t().copadoUser())
            .assign(new PermissionSetAssignment_t().jobEngine())
            .persist();

        System.runAs(user) {
            new CopadoLicense().user(user).enableAll().persist();
        }

        mockAutomations();

        // Exercise
        Deployment_Flow__c pipeline;
        System.runAs(user) {
            Test.startTest();
            pipeline = (Deployment_Flow__c) new Pipeline().setPlatform('Other').persist();
            Test.stopTest();
        }

        // Verify
        List<Pipeline_Action__c> actions = pipelineActions(pipeline.Id);
        System.assertEquals(1, actions.size(), 'Failed to create pipeline action for MultiCloud pipeline.');
        System.assertEquals(true, actions[0].Default__c, 'Pipeline action should be set as default on new pipeline action records.');
        System.assertEquals('Other', actions[0].Platform__c, 'Incorrect platform set on new pipeline action record.');
        System.assertEquals('Commit', actions[0].Action__c, 'Incorrect action set on new pipeline action record.');
        System.assertEquals('Commit_Template_1', actions[0].Job_Template__r.ApiName__c, 'Incorrect job template set on pipeline action record.');
        System.assertNotEquals('SubmitUserStories', actions[0].Action__c, 'Incorrect action set on new pipeline action record.');
    }

    @isTest
    private static void createAsStandardUserWithExistingConfigurationWithoutJobEnginePermission() {
        // Setup
        User user = (User) new User_t().assign(new PermissionSetAssignment_t().copadoUser()).persist();

        System.runAs(user) {
            new CopadoLicense().user(user).enableAll().persist();
        }

        mockAutomations();

        // Exercise
        Deployment_Flow__c pipeline;
        String errorMessage;
        System.runAs(user) {
            Test.startTest();
            try {
                pipeline = (Deployment_Flow__c) new Pipeline().setPlatform('Other').persist();
            } catch (Exception error) {
                errorMessage = error.getMessage();
            }
            Test.stopTest();
        }

        // Verify
        List<Pipeline_Action__c> actions = pipelineActions(pipeline?.Id);
        System.assert(actions.isEmpty(), 'There should be no actions created for a user without Job Engine permission.');
        System.assert(
            errorMessage.contains(String.format('Permission to access an {0}JobTemplate__c denied.', new List<String>{ Settings.ns })),
            'Incorrect error message returned by trigger validation.'
        );
    }

    @isTest
    private static void createAsStandardUserWithEmptyPlatform() {
        // Setup
        User user = (User) new User_t()
            .assign(new PermissionSetAssignment_t().copadoUser())
            .assign(new PermissionSetAssignment_t().jobEngine())
            .persist();

        System.runAs(user) {
            new CopadoLicense().user(user).enableAll().persist();
        }

        mockAutomations();

        // Exercise
        Deployment_Flow__c pipeline;
        System.runAs(user) {
            Test.startTest();
            pipeline = (Deployment_Flow__c) new Pipeline().persist();
            Test.stopTest();
        }

        // Verify
        System.assertEquals('Salesforce', pipeline.Platform__c, 'Empty Platform was not autopopulated.');

        List<Pipeline_Action__c> actions = pipelineActions(pipeline.Id);
        System.assert(actions.isEmpty(), 'No pipeline actions should be created for Salesforce pipelines.');
    }

    @isTest
    private static void createAsStandardUserWithSalesforcePlatform() {
        // Setup
        User user = (User) new User_t()
            .assign(new PermissionSetAssignment_t().copadoUser())
            .assign(new PermissionSetAssignment_t().jobEngine())
            .persist();

        System.runAs(user) {
            new CopadoLicense().user(user).enableAll().persist();
        }

        mockAutomations();

        // Exercise
        Deployment_Flow__c pipeline;
        System.runAs(user) {
            Test.startTest();
            pipeline = (Deployment_Flow__c) new Pipeline().setPlatform('Salesforce').persist();
            Test.stopTest();
        }

        // Verify
        List<Pipeline_Action__c> actions = pipelineActions(pipeline.Id);
        System.assert(actions.isEmpty(), 'No pipeline actions should be created for Salesforce pipelines.');
    }

    @isTest
    private static void createAsStandardUserWithOtherPlatform() {
        // Setup
        User user = (User) new User_t()
            .assign(new PermissionSetAssignment_t().copadoUser())
            .assign(new PermissionSetAssignment_t().jobEngine())
            .persist();

        System.runAs(user) {
            new CopadoLicense().user(user).enableAll().persist();
        }

        mockAutomations();

        // Exercise
        Deployment_Flow__c pipeline;
        System.runAs(user) {
            Test.startTest();
            pipeline = (Deployment_Flow__c) new Pipeline().setPlatform('Other').persist();
            Test.stopTest();
        }

        // Verify
        List<Pipeline_Action__c> actions = pipelineActions(pipeline.Id);
        System.assertEquals(1, actions.size(), 'Failed to create pipeline action for MultiCloud pipeline.');
        System.assertEquals(true, actions[0].Default__c, 'Pipeline action should be set as default on new pipeline action records.');
        System.assertEquals('Other', actions[0].Platform__c, 'Incorrect platform set on new pipeline action record.');
        System.assertEquals('Commit', actions[0].Action__c, 'Incorrect action set on new pipeline action record.');
        System.assertEquals('Commit_Template_1', actions[0].Job_Template__r.ApiName__c, 'Incorrect job template set on pipeline action record.');
        System.assertNotEquals('SubmitUserStories', actions[0].Action__c, 'Incorrect action set on new pipeline action record.');
    }

    // HELPER

    private static List<Pipeline_Action__c> pipelineActions(Id pipelineId) {
        return [SELECT Action__c, Job_Template__r.ApiName__c, Platform__c, Default__c FROM Pipeline_Action__c WHERE Pipeline__c = :pipelineId];
    }

    private static void insertData() {
        new JobTemplate().name('Commit Template').add(new JobStep().name('Function Step').type('Function')).persist();
    }

    private static void mockAutomations() {
        List<MultiCloudAutomation__mdt> automations = new List<MultiCloudAutomation__mdt>{
            new MultiCloudAutomation__mdt(
                MasterLabel = 'CommitAction',
                DeveloperName = 'CommitAction',
                Action__c = 'Commit',
                Job_Template__c = 'Commit_Template_1'
            ),
            new MultiCloudAutomation__mdt(
                MasterLabel = 'SubmitUserStoriesAction',
                DeveloperName = 'SubmitUserStoriesAction',
                Action__c = ActionConstants.SUBMIT_USER_STORIES,
                Job_Template__c = 'Submit_User_Stories_Template_1'
            )
        };

        MultiCloudAutomationsSelector.mockAutomations = new Map<String, List<MultiCloudAutomation__mdt>>{ 'Other' => automations };
    }
}