@IsTest
private with sharing class UserStoryCommitCtrlTest {
    @TestSetup
    private static void setup() {
        TestUtilities.getAllMultilicense();
        User user = (User) new User_t()
            .assign(new PermissionSetAssignment_t().copadoUser())
            .assign(new PermissionSetAssignment_t().functions())
            .assign(new PermissionSetAssignment_t().jobEngine())
            .assign(new PermissionSetAssignment_t().qualityGatesReadOnly())
            .assign(new PermissionSetAssignment_t().executeAutomations())
            .persist();
        System.runAs(user) {
            new CopadoLicense().user(user).enableAll().persist();
            createData();
        }
    }

    @IsTest
    private static void isReCreateFeatureBranchAvailable() {
        System.runAs(getRunAsUser()) {
            // Setup
            Personal_Settings__c personalSettings = Personal_Settings__c.getInstance();
            personalSettings.Disable_Re_Create_Feature_Branch_in_US__c = true;
            upsert personalSettings;

            // Exercise
            Boolean isReCreateFeatureBranchAvailable = UserStoryCommitCtrl.isReCreateFeatureBranchAvailable();

            // Verify
            System.assert(!isReCreateFeatureBranchAvailable, 'Re-create feature branch option should not be available');
        }
    }

    @IsTest
    private static void commitChanges() {
        System.runAs(getRunAsUser()) {
            // Setup
            Id userStoryId = [SELECT Id FROM User_Story__c].Id;

            UserStoryCommitRequest request = new UserStoryCommitRequest();
            request.userStoryId = userStoryId;
            request.changes = changes();
            request.recreateFeatureBranch = true;
            request.executeCommit = true;

            Flow.mockResponse = flowCompletionEvent(true, '', '');

            // Exercise
            Test.startTest();
            UserStoryCommitCtrl.commitChanges(request);
            List<User_Story_Metadata__c> userStoryMetadata = UserStoryCommitCtrl.getUserStoryMetadata(userStoryId);
            Test.stopTest();

            // Verify
            System.assertEquals(
                'Successful',
                [SELECT Status__c FROM JobExecution__c]
                .Status__c,
                'Job execution status after stop test should be Successful'
            );
            System.assertEquals(
                10,
                [SELECT COUNT() FROM User_Story_Metadata__c],
                'Changes should have been created as User_Story_Metadata__c records'
            );
            System.assertEquals(10, userStoryMetadata.size(), 'Changes should have been created as User_Story_Metadata__c records');
            System.assertEquals(
                1,
                [SELECT COUNT() FROM ContentVersion WHERE PathOnClient = 'Copado Commit changes.json'],
                'Copado Commit changes.json file should have been upserted'
            );

            // Verify callback
            System.assertNotEquals(
                null,
                [SELECT Latest_Commit_Date__c FROM User_Story__c]
                .Latest_Commit_Date__c,
                'User_Story__c should have been updated with Latest_Commit_Date__c in callback execution'
            );
        }
    }

    @IsTest
    private static void commitChangesException() {
        // Setup & Exercise
        String exceptionMessage;
        Test.startTest();
        try {
            UserStoryCommitRequest request = new UserStoryCommitRequest();
            UserStoryCommitCtrl.commitChanges(request);
        } catch (Exception e) {
            exceptionMessage = e.getMessage();
        }
        Test.stopTest();

        // Verify
        System.assert(String.isNotBlank(exceptionMessage), 'Exception should have been thrown');
    }

    @IsTest
    private static void validateCommitRequirements() {
        System.runAs(getRunAsUser()) {
            // Setup
            Id userStoryId = [SELECT Id FROM User_Story__c].Id;
            Deployment_Flow__c flow = [SELECT Id FROM Deployment_Flow__c LIMIT 1];
            flow.Block_Commits__c = true;
            update flow;

            // Exercise
            Test.startTest();
            List<CopadoAlert> errors = UserStoryCommitCtrl.validateCommitRequirements(userStoryId);
            Test.stopTest();

            // Verify
            System.assert(!errors.isEmpty(), 'There should be some validation errors');
        }
    }

    private static void createData() {
        new JobTemplate().name('Commit Template').mockAutomation('Commit').add(new JobStep()).persist();

        Credential source = new Credential();

        new Pipeline()
            .mainBranch('main')
            .setPlatform('Other')
            .add(
                new Connection(new Environment().platform('Other').add(source), new Environment().platform('Other').add(new Credential()))
                    .branch('dev1')
            )
            .add(
                new Connection(new Environment().platform('Other').add(new Credential()), new Environment().platform('Other').add(new Credential()))
                    .branch('dev2')
            )
            .add(new Project().add(new UserStory().credential(source)))
            .persist();
    }

    private static User getRunAsUser() {
        return [SELECT Id FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1];
    }

    private static List<UserStoryCommitChange> changes() {
        List<UserStoryCommitChange> result = new List<UserStoryCommitChange>();

        for (Integer i = 0; i < 10; i++) {
            UserStoryCommitChange change = new UserStoryCommitChange();
            change.a = 'add';
            change.n = 'TestClass_' + i;
            change.t = 'ApexClass';
            change.m = 'force-app/main/default';
            change.c = 'category';
            change.j = '{"vk": "6368cb8e-776c-4ad6-9906-444d460715d7"}';
            result.add(change);
        }

        return result;
    }

    private static Event__e flowCompletionEvent(Boolean isSuccess, String errorMessage, String data) {
        Event__e result = new Event__e();
        result.Topic_Uri__c = OnJobStepComplete.STEP_ENDPOINT;
        result.Payload__c = Json.serialize(new OnJobStepComplete.EventPayload(isSuccess, errorMessage, data));

        return result;
    }
}