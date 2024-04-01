@IsTest
private with sharing class UserStorySubmitCtrlTest {
    @TestSetup
    private static void makeData() {
        TestUtilities.getAllMultilicense();
        User user = (User) new User_t()
            .alias('TestUsr1')
            .assign(new PermissionSetAssignment_t().copadoUser())
            .assign(new PermissionSetAssignment_t().jobEngine())
            .assign(new PermissionSetAssignment_t().executeAutomations())
            .persist();
        new User_t()
            .alias('TestUsr2')
            .assign(new PermissionSetAssignment_t().copadoUser())
            .assign(new PermissionSetAssignment_t().executeAutomations())
            .persist();
        System.runAs(user) {
            new CopadoLicense().user(user).enableAll().persist();
            createData();
        }
    }

    @IsTest
    private static void getData() {
        // Setup
        System.runAs(getUser()) {
            User_Story__c userStory = getUserStory();
            Deployment_Flow__c pipeline = getPipeline();
            Org__c credential = getCredential('dev1');
            new UserStoryCommit(new SnapshotCommit().credentialId(credential.Id)).userStoryId(userStory.Id).persist();

            // Exercise
            Test.startTest();
            UserStorySubmitCtrl.SubmitData data = UserStorySubmitCtrl.getData(userStory.Id);
            Test.stopTest();

            // Verify
            System.assertEquals(pipeline.Id, data.pipelineId, 'Pipeline should be returned');
            System.assertEquals(true, data.userStoryReadyToPromote, 'User Story should be Ready To Promote');
            System.assertEquals('prod', data.destinationEnvironmentName, 'Destination Environment should match');
            System.assertEquals(0, data.errorList.size(), 'No errors should be returned');
        }
    }

    @IsTest
    private static void getDataWithPermissionErrors() {
        System.runAs(getUserWithoutPermissions()) {
            // Setup
            User_Story__c userStory = getUserStory();

            // Exercise
            Test.startTest();
            UserStorySubmitCtrl.SubmitData data = UserStorySubmitCtrl.getData(userStory.Id);
            Test.stopTest();

            // Verify
            String expectedMessage = Label.Submit_User_Story_Validate_Object_Permissions.replace('{0}', '');
            System.assertEquals(1, data.errorList.size(), 'An error should be returned');
            System.assert(data.errorList[0].contains(expectedMessage), 'Unexpected error message: ' + data.errorList[0]);
        }
    }

    @IsTest
    private static void getDataWithoutMetadata() {
        System.runAs(getUser()) {
            // Setup
            User_Story__c userStory = getUserStory();

            delete [SELECT Id FROM User_Story_Metadata__c WHERE User_Story__c = :userStory.Id];

            // Exercise
            Test.startTest();
            UserStorySubmitCtrl.SubmitData data = UserStorySubmitCtrl.getData(userStory.Id);
            Test.stopTest();

            // Verify
            System.assertEquals(1, data.errorList.size(), 'There should be an error.');
        }
    }

    @IsTest
    private static void getDataWithoutEnvironment() {
        System.runAs(getUser()) {
            // Setup
            User_Story__c userStory = getUserStory();
            Org__c credential = getCredential('dev1');
            new UserStoryCommit(new SnapshotCommit().credentialId(credential.Id)).userStoryId(userStory.Id).persist();
            userStory.Org_Credential__c = null;
            userStory.Environment__c = null;
            update userStory;

            // Exercise
            Test.startTest();
            UserStorySubmitCtrl.SubmitData data = UserStorySubmitCtrl.getData(userStory.Id);
            Test.stopTest();

            // Verify
            System.assertEquals(1, data.errorList.size(), 'An error should be returned');
            System.assertEquals(Label.Mandatory_Fields_To_Submit, data.errorList[0], 'Error message does not match');
        }
    }

    @IsTest
    private static void getDataWithLastEnvironment() {
        System.runAs(getUser()) {
            // Setup
            User_Story__c userStory = getUserStory();
            Org__c credential = getCredential('prod');
            new UserStoryCommit(new SnapshotCommit().credentialId(credential.Id)).userStoryId(userStory.Id).persist();
            userStory.Org_Credential__c = credential.Id;
            userStory.Environment__c = null;
            update userStory;

            // Exercise
            Test.startTest();
            UserStorySubmitCtrl.SubmitData data = UserStorySubmitCtrl.getData(userStory.Id);
            Test.stopTest();

            // Verify
            System.assertEquals(1, data.errorList.size(), 'An error should be returned');
            System.assertEquals(Label.Submit_User_Story_Validate_Last_Environment, data.errorList[0], 'Error message does not match');
        }
    }

    @IsTest
    private static void getDataWithExcludedFromPipeline() {
        System.runAs(getUser()) {
            // Setup
            User_Story__c userStory = getUserStory();
            Org__c credential = getCredential('dev1');
            new UserStoryCommit(new SnapshotCommit().credentialId(credential.Id)).userStoryId(userStory.Id).persist();
            userStory.Promote_Change__c = false;
            userStory.Exclude_From_CBM__c = true;
            update userStory;

            // Exercise
            Test.startTest();
            UserStorySubmitCtrl.SubmitData data = UserStorySubmitCtrl.getData(userStory.Id);
            Test.stopTest();

            // Verify
            System.assertEquals(1, data.errorList.size(), 'An error should be returned');
            System.assertEquals(Label.Submit_User_Story_Validate_Excluded_From_Pipeline, data.errorList[0], 'Error message does not match');
        }
    }

    @IsTest
    private static void testReSubmitBehaviour() {
        System.runAs(getUser()) {
            // Setup
            User_Story__c userStory = getUserStory();

            // Exercise
            Test.startTest();
            UserStorySubmitCtrl.resubmitUserStory(userStory.Id);
            Test.stopTest();

            // Verify
            userStory = getUserStory();
            System.assertEquals(true, userStory.Promote_Change__c, 'User story should be promoted.');

            List<Automation_Event__c> automationEvent = [SELECT Id FROM Automation_Event__c];
            System.assertEquals(1, automationEvent.size(), 'An automation event should be created.');
        }
    }

    private static void createData() {
        Credential dev1Credential = new Credential();
        Environment dev1 = new Environment().name('dev1').type('Sandbox').platform('Other').add(dev1Credential);
        Environment prod = new Environment().name('prod').type('Sandbox').platform('Other').add(new Credential());

        new Pipeline()
            .active(true)
            .mainBranch('main')
            .setPlatform('Other')
            .add(new Connection(dev1, prod).branch('dev1'))
            .add(new Project().add(new UserStory().credential(dev1Credential).add(new UserStoryMetadata().name('TestClass').type('ApexClass'))))
            .persist();

        List<User_Story__c> usToUpdate = new List<User_Story__c>();
        for (User_Story__c userStory : [SELECT Id FROM User_Story__c]) {
            usToUpdate.add(new User_Story__c(Id = userStory.Id, Promote_Change__c = true));
        }
        update usToUpdate;

        createAutomationRule();
    }

    private static User getUser() {
        return [SELECT Id FROM User WHERE Profile.Name = 'Standard User' AND Alias = 'TestUsr1' ORDER BY CreatedDate DESC LIMIT 1];
    }

    private static User getUserWithoutPermissions() {
        return [SELECT Id FROM User WHERE Profile.Name = 'Standard User' AND Alias = 'TestUsr2' ORDER BY CreatedDate DESC LIMIT 1];
    }

    private static User_Story__c getUserStory() {
        return [SELECT Id, Promote_Change__c FROM User_Story__c LIMIT 1];
    }

    private static Deployment_Flow__c getPipeline() {
        return [SELECT Id FROM Deployment_Flow__c LIMIT 1];
    }

    private static Org__c getCredential(String name) {
        return [SELECT Id FROM Org__c WHERE Environment__r.Name = :name LIMIT 1];
    }

    private static Automation_Rule__c createAutomationRule() {
        Automation_Rule__c automationRule = (Automation_Rule__c) new AutomationRule()
            .pipeline(getPipeline().Id)
            .active()
            .sourceAction(ActionConstants.SUBMIT_USER_STORIES)
            .automatedAction(ActionConstants.PROMOTION)
            .sourceActionStatus(AutomationRuleConstants.SOURCE_ACTION_STATUS_SUCCESSFUL)
            .connector(AutomationRuleConstants.AUTOMATION_CONNECTOR_CUSTOM)
            .execution(AutomationRuleConstants.EXECUTION_SCHEDULED)
            .cronExpression('0 0 0 ? * * *')
            .persist();
        return automationRule;
    }
}