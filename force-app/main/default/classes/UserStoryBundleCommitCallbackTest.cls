@IsTest
private class UserStoryBundleCommitCallbackTest {
    @TestSetup
    private static void setupData() {
        TestUtilities.getAllMultilicense();
        User user = getUserStoryBundleUser();
        System.runAs(user) {
            new CopadoLicense().user(user).enableAll().persist();
            createData();
        }
    }

    @IsTest
    private static void execute() {
        System.runAs(getRunAsUser()) {
            // Setup
            Flow.mockResponse = flowCompletionEvent(false, '', '');

            // Exercise
            Test.startTest();
            Actions.UserStoryBundleService.execute(getRequest());
            Test.stopTest();

            // Verify
            Id recordTypeId = Schema.SObjectType.User_Story__c.getRecordTypeInfosByDeveloperName().get('Utility').getRecordTypeId();
            List<User_Story__c> createdBundledUserStories = [SELECT Id FROM User_Story__c WHERE RecordTypeId = :recordTypeId];
            System.assertEquals(1, createdBundledUserStories.size(), '1 bundle user stories created');

            JobExecution__c jobExecution = [SELECT Status__c, ErrorMessage__c FROM JobExecution__c LIMIT 1];
            System.assertEquals(JobExecutionConstants.STATUS_ERROR, jobExecution.Status__c, 'Job execution status after stop test should be Error');
            List<User_Story_Commit__c> userStoryCommits = [SELECT Status__c FROM User_Story_Commit__c];
            System.assertEquals(1, userStoryCommits.size(), 'One User Story Commit record should have been created');
            System.assertEquals(CommitConstants.STATUS_FAILED, userStoryCommits[0].Status__c, 'User Story Commit status should have been updated');

            // Verify callback
            List<Artifact_Version__c> packageVersions = [
                SELECT Id, Status__c
                FROM Artifact_Version__c
                WHERE User_Story__c = :createdBundledUserStories[0].Id
                LIMIT 1
            ];
            System.assertEquals('Open', packageVersions[0].Status__c, 'Package Status is updated');
            List<Bundled_Story__c> bundledStories = [
                SELECT Id, User_Story__r.Exclude_From_CBM__c, User_Story__r.Stop_Indexing_Metadata__c
                FROM Bundled_Story__c
                WHERE Package_Version__c = :packageVersions[0].Id
            ];
            System.assertEquals(
                false,
                bundledStories[0].User_Story__r.Exclude_From_CBM__c,
                'Child User Story.Exclude_From_CBM__c should have been updated'
            );
            System.assertEquals(
                false,
                bundledStories[0].User_Story__r.Stop_Indexing_Metadata__c,
                'Child User Story.Stop_Indexing_Metadata__c should have been updated'
            );
        }
    }

    // HELPERS

    private static void createData() {
        new JobTemplate().name('Commit_Template').version(1).mockAutomation('Commit').add(new JobStep()).persist();

        Credential dev1Credential = new Credential();
        Environment dev1 = new Environment().name('dev1').type('Sandbox').platform('Other').add(dev1Credential);
        Environment dev2 = new Environment().name('dev2').type('Sandbox').platform('Other').add(new Credential());
        Credential intCredential = new Credential();
        Environment integration = new Environment().name('int').type('Sandbox').platform('Other').add(intCredential);
        new Environment().name('uat').type('Sandbox').platform('Other').add(new Credential());
        new Environment().name('prod').type('Sandbox').platform('Other').add(new Credential());

        new Pipeline()
            .mainBranch('main')
            .setPlatform('Other')
            .add(new Connection(dev1, integration).branch('dev1'))
            .add(new Connection(dev2, integration).branch('dev2'))
            .add(
                new Project()
                    .add(new UserStory().credential(dev1Credential).add(new UserStoryMetadata().name('TestClass').type('ApexClass')))
                    .add(new UserStory().credential(dev1Credential).add(new UserStoryMetadata().name('TestClass 1').type('ApexClass')))
                    .add(new UserStory().credential(dev1Credential).add(new UserStoryMetadata().name('TestClass 2').type('ApexClass')))
            )
            .persist();

        Id recordTypeId = Schema.SObjectType.Artifact__c.getRecordTypeInfosByDeveloperName().get('User_Story_Bundle').getRecordTypeId();
        new Package_t().name('Test').recordTypeId(recordTypeId).add(new PackageVersion()).persist();
    }

    private static Id getPackageVersionId() {
        return [SELECT Id FROM Artifact_Version__c LIMIT 1].Id;
    }

    private static Org__c getCredential() {
        return [SELECT Id, Environment__c FROM Org__c WHERE Environment__r.Name = 'dev1' LIMIT 1];
    }

    private static List<User_Story__c> getUserStories() {
        return [SELECT Id FROM User_Story__c LIMIT 2];
    }

    private static Id getProjectId() {
        return [SELECT Id FROM Project__c LIMIT 1].Id;
    }

    private static User getRunAsUser() {
        return [SELECT Id FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1];
    }

    private static Actions.ExecuteUserStoryBundleRequest getRequest() {
        User_Story__c bundledUserStory = new User_Story__c();
        bundledUserStory.Org_Credential__c = getCredential().Id;
        bundledUserStory.Project__c = getProjectId();
        bundledUserStory.Environment__c = getCredential().Environment__c;

        Actions.ExecuteUserStoryBundleRequest request = new Actions.ExecuteUserStoryBundleRequest();
        request.packageVersionId = getPackageVersionId();
        request.bundleUserStory = bundledUserStory;

        List<Id> userStoryIds = new List<Id>();
        for (User_Story__c userStory : getUserStories()) {
            userStoryIds.add(userStory.Id);
        }

        Actions.AddUserStoryBundleRequest addRequest = new Actions.AddUserStoryBundleRequest();
        addRequest.packageVersionId = getPackageVersionId();
        addRequest.userStoryIds = userStoryIds;
        Actions.UserStoryBundleService.add(addRequest);

        return request;
    }

    private static Event__e flowCompletionEvent(Boolean isSuccess, String errorMessage, String data) {
        Event__e result = new Event__e();
        result.Topic_Uri__c = OnJobStepComplete.STEP_ENDPOINT;
        result.Payload__c = Json.serialize(new OnJobStepComplete.EventPayload(isSuccess, errorMessage, data));
        return result;
    }

    private static User getUserStoryBundleUser() {
        return (User) new User_t()
            .assign(getCopadoUserPermissionSetAssignment())
            .assign(new PermissionSetAssignment_t().functions())
            .assign(new PermissionSetAssignment_t().jobEngine())
            .assign(new PermissionSetAssignment_t().qualityGatesAdmin())
            .persist();
    }

    private static PermissionSetAssignment_t getCopadoUserPermissionSetAssignment() {
        PermissionSetAssignment_t copadoUserPermissionSetAssignment = new PermissionSetAssignment_t().copadoUser();
        if (!customPermissionAlreadyAssigned()) {
            copadoUserPermissionSetAssignment.add(new CustomPermission_t().userStoryBundles());
        }
        return copadoUserPermissionSetAssignment;
    }

    private static Boolean customPermissionAlreadyAssigned() {
        return [
                SELECT COUNT()
                FROM SetupEntityAccess
                WHERE
                    SetupEntityId IN (
                        SELECT Id
                        FROM CustomPermission
                        WHERE DeveloperName = :CustomPermissionConstants.USER_STORY_BUNDLE_CUSTOM_PERMISSION
                    )
                    AND ParentId IN (SELECT PermissionSetId FROM PermissionSetAssignment WHERE PermissionSet.Name = 'Copado_User')
            ] > 0;
    }
}