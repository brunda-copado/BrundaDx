@IsTest
private class ExecuteUserStoryBundleServiceImplTest {
    private static final String MOCK_TEST = 'Mock Test';
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

            // Exercise
            Test.startTest();
            Actions.UserStoryBundleService.execute(request);
            Test.stopTest();

            // Verify
            Id recordTypeId = Schema.SObjectType.User_Story__c.getRecordTypeInfosByDeveloperName().get('Utility').getRecordTypeId();
            List<User_Story__c> createdBundledUserStories = [SELECT Id FROM User_Story__c WHERE RecordTypeId = :recordTypeId];
            System.assertEquals(1, createdBundledUserStories.size(), '1 bundle user stories created');
        }
    }

    @IsTest
    private static void executeWithExtensionLogic() {
        System.runAs(getRunAsUser()) {
            // Setup
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

            ExtensionKeyValueSettingsSelector.mock = new List<ExtensionKeyValueSetting__mdt>{
                new ExtensionKeyValueSetting__mdt(
                    Extension__r = new ExtensionPackageConfiguration__mdt(Platform__c = 'Other'),
                    Key__c = 'UserStoryBundleLogic',
                    Value__c = Settings.ns.replace('__', '.') + 'Job_Step_Flow'
                )
            };

            Actions.AddUserStoryBundleRequest addRequest = new Actions.AddUserStoryBundleRequest();
            addRequest.packageVersionId = getPackageVersionId();
            addRequest.userStoryIds = userStoryIds;
            Actions.UserStoryBundleService.add(addRequest);

            // Exercise
            Test.startTest();
            Actions.ExecuteUserStoryBundleResult result = Actions.UserStoryBundleService.execute(request);
            Test.stopTest();

            // Verify
            System.assertEquals(null, result.bundleUserStory, 'Extension overridden logic executed and Bundle user story is not created');
        }
    }

    @IsTest
    private static void executeWithExtensionCallback() {
        System.runAs(getRunAsUser()) {
            // Setup
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

            ExtensionKeyValueSettingsSelector.mock = new List<ExtensionKeyValueSetting__mdt>{
                new ExtensionKeyValueSetting__mdt(
                    Extension__r = new ExtensionPackageConfiguration__mdt(Platform__c = 'Other'),
                    Key__c = 'UserStoryBundleCommitCallback',
                    Value__c = Settings.ns.replace('__', '.') + 'ActionCallbackMock'
                )
            };

            Flow.mockResponse = flowCompletionEvent(true, '', '');

            Actions.AddUserStoryBundleRequest addRequest = new Actions.AddUserStoryBundleRequest();
            addRequest.packageVersionId = getPackageVersionId();
            addRequest.userStoryIds = userStoryIds;
            Actions.UserStoryBundleService.add(addRequest);

            // Exercise
            Test.startTest();
            Actions.ExecuteUserStoryBundleResult result = Actions.UserStoryBundleService.execute(request);
            Test.stopTest();

            // Verify
            System.assertEquals(true, result.commitResult != null, 'Commit Result is created');
            Result__c mockCallbackResult = [SELECT Result_Data__c FROM Result__c WHERE ParentId__c = :result.commitResult.JobExecution.Id LIMIT 1];
            System.assertEquals('Action Callback executed', mockCallbackResult.Result_Data__c, 'Action callback should have been executed');
        }
    }

    @IsTest
    private static void deploymentTaskAndTestConsolidation() {
        System.runAs(getRunAsUser()) {
            // Setup
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

            ExtensionConfiguration__c extensionConfiguration = getExtensionConfiguration();
            createDeploymentTasks(userStoryIds);
            createTest(extensionConfiguration.Id, userStoryIds);

            Actions.AddUserStoryBundleRequest addRequest = new Actions.AddUserStoryBundleRequest();
            addRequest.packageVersionId = getPackageVersionId();
            addRequest.userStoryIds = userStoryIds;
            Actions.UserStoryBundleService.add(addRequest);

            // Exercise
            Test.startTest();
            Actions.UserStoryBundleService.execute(request);
            Test.stopTest();

            // Verify
            Id recordTypeId = Schema.SObjectType.User_Story__c.getRecordTypeInfosByDeveloperName().get('Utility').getRecordTypeId();
            List<User_Story__c> createdDundledUserStories = [SELECT Id FROM User_Story__c WHERE RecordTypeId = :recordTypeId];
            System.assertEquals(1, createdDundledUserStories.size(), '1 bundle user stories created');

            List<JobStep__c> deploymentTasks = getDeploymentTasks(createdDundledUserStories[0].Id);
            Assert.isTrue(deploymentTasks.size() > 0, 'deployment Tasks created for user story bundle successfully');

            List<Test__c> tests = [SELECT Id FROM Test__c WHERE User_Story__c = :createdDundledUserStories[0].Id];
            Assert.isTrue(tests.size() > 0, ' Tests created for user story bundle successfully');
        }
    }

    // HELPERS

    private static void createData() {
        new JobTemplate().name('Commit Template').version(1).mockAutomation('Commit').add(new JobStep()).persist();

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
        createExtensionConfiguration();
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

    private static ExtensionConfiguration__c getExtensionConfiguration() {
        return [SELECT Id FROM ExtensionConfiguration__c LIMIT 1][0];
    }

    private static List<JobStep__c> getDeploymentTasks(Id userStoryId) {
        return [SELECT Id FROM JobStep__c WHERE UserStory__c = :userStoryId LIMIT 1];
    }

    private static void createDeploymentTasks(list<Id> userStoryIds) {
        List<JobStep__c> deploymentTasksToInsert = new List<JobStep__c>();

        for (Id userStoryId : userStoryIds) {
            JobStep__c task = new JobStep__c();
            task.Order__c = 1;
            task.ExecutionSequence__c = 'before';
            task.Name = 'Manual Task';
            task.Type__c = 'Manual';
            task.UserStory__c = userStoryId;
            deploymentTasksToInsert.add(task);
        }

        insert deploymentTasksToInsert;
    }

    private static void createExtensionConfiguration() {
        ExtensionConfiguration__c result = new ExtensionConfiguration__c(
            ExtensionTool__c = 'Manual Tests',
            ExtensionApplication__c = 'Test',
            Active__c = true
        );

        insert result;
    }

    private static void createTest(Id extensionConfigId, list<Id> userStoryIds) {
        List<Test__c> testsToInsert = new List<Test__c>();
        for (Id userStoryId : userStoryIds) {
            testsToInsert.add(new Test__c(Name = MOCK_TEST, User_Story__c = userStoryId, ExtensionConfiguration__c = extensionConfigId));
        }
        insert testsToInsert;
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