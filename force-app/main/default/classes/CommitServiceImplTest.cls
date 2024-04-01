@IsTest
private with sharing class CommitServiceImplTest {
    @TestSetup
    private static void setup() {
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
            createData(true);
        }
    }

    @IsTest
    private static void successOnProperRequest() {
        System.runAs(getRunAsUser()) {
            // Setup
            Id userStoryId = getUserStory();
            Actions.CommitRequest request = new Actions.CommitRequest();
            request.userStoryId = userStoryId;
            request.changes = changes();
            request.recreateFeatureBranch = true;
            request.baseBranch = 'main';
            request.otherInformation = '{"key":"value"}';

            Flow.mockResponse = flowCompletionEvent(true, '', '{"commitId": "test_commit_id"}');

            // Exercise
            Test.startTest();
            Actions.CommitService.execute(request);
            Test.stopTest();

            // Verify
            JobExecution__c jobExecution = [SELECT Status__c, ErrorMessage__c, DataJson__c FROM JobExecution__c LIMIT 1];
            System.assertEquals(
                JobExecutionConstants.STATUS_SUCCESSFUL,
                jobExecution.Status__c,
                'Job execution status after stop test should be Successful'
            );
            Map<String, Object> dataJson = (Map<String, Object>) JSON.deserializeUntyped(jobExecution.DataJson__c);
            System.assertEquals('{"key":"value"}', dataJson.get('jsonInformation'), 'Job execution Data Json field should be updated');
            List<User_Story_Metadata__c> metadata = [SELECT Id FROM User_Story_Metadata__c];
            System.assertEquals(10, metadata.size(), 'Changes should have been created as User_Story_Metadata__c records');
            List<ContentVersion> files = [SELECT Id FROM ContentVersion WHERE PathOnClient = 'Copado Commit changes.json'];
            System.assertEquals(1, files.size(), 'Copado Commit changes.json file should have been upserted');
            List<Git_Org_Commit__c> gitCommits = [SELECT Status__c, Commit_Id__c FROM Git_Org_Commit__c];
            System.assertEquals(1, gitCommits.size(), 'One Git Org Commit record should have been created');
            List<User_Story_Commit__c> userStoryCommits = [SELECT LastJobExecutionId__c, External_Id__c FROM User_Story_Commit__c];
            System.assertEquals(1, userStoryCommits.size(), 'One User Story Commit record should have been created');

            // Verify callback
            User_Story__c userStory = [SELECT Latest_Commit_Date__c, Base_Branch__c FROM User_Story__c LIMIT 1];
            System.assertNotEquals(
                null,
                userStory.Latest_Commit_Date__c,
                'User_Story__c should have been updated with Latest_Commit_Date__c in callback execution'
            );
            System.assertNotEquals(
                null,
                userStory.Base_Branch__c,
                'User_Story__c should have been updated with Base_Branch__c in callback execution'
            );
            System.assertNotEquals(
                null,
                userStoryCommits[0].LastJobExecutionId__c,
                'User_Story_Commit__c should have been updated with LastJobExecutionId__c'
            );
            System.assertEquals(
                userStoryId + '_' + 'test_commit_id',
                userStoryCommits[0].External_Id__c,
                'User_Story_Commit__c should have been updated with External_Id__c in callback execution'
            );
            System.assertEquals(CommitConstants.STATUS_COMPLETE, gitCommits[0].Status__c, 'User Story Commit status should have been updated');
            System.assertEquals('test_commit_id', gitCommits[0].Commit_Id__c, 'User Story Commit status should have been updated');

            List<Automation_Event__c> events = [SELECT Id, Action_Name__c, Environment_Id__c FROM Automation_Event__c];
            System.assertEquals(1, events.size(), 'An Automation Event should be created');
            System.assertEquals(ActionConstants.COMMIT_ACTION, events[0].Action_Name__c, 'Action Name should match');
            Environment__c environment = [SELECT Id FROM Environment__c WHERE Name = 'dev1'];
            System.assertEquals(environment.Id, events[0].Environment_Id__c, 'Environment should match');
        }
    }

    @IsTest
    private static void overrideJobTemplateInOtherInformation() {
        System.runAs(getRunAsUser()) {
            // Setup
            Id userStoryId = getUserStory();
            Actions.CommitRequest request = new Actions.CommitRequest();
            request.userStoryId = userStoryId;
            request.changes = changes();
            request.recreateFeatureBranch = true;
            request.otherInformation = '{"overrideJobTemplate":"Commit_Template_1"}';

            Flow.mockResponse = flowCompletionEvent(true, '', '{"commitId": "test_commit_id"}');

            // Exercise
            Test.startTest();
            Actions.CommitService.execute(request);
            Test.stopTest();

            // Verify
            JobExecution__c jobExecution = [SELECT Status__c, ErrorMessage__c, DataJson__c FROM JobExecution__c LIMIT 1];
            System.assertEquals(
                JobExecutionConstants.STATUS_SUCCESSFUL,
                jobExecution.Status__c,
                'Job execution status after stop test should be Successful'
            );
            Map<String, Object> dataJson = (Map<String, Object>) JSON.deserializeUntyped(jobExecution.DataJson__c);
            System.assertEquals(
                '{"overrideJobTemplate":"Commit_Template_1"}',
                dataJson.get('jsonInformation'),
                'Job execution Data Json field should be updated'
            );
            List<User_Story_Metadata__c> metadata = [SELECT Id FROM User_Story_Metadata__c];
            System.assertEquals(10, metadata.size(), 'Changes should have been created as User_Story_Metadata__c records');
            List<ContentVersion> files = [SELECT Id FROM ContentVersion WHERE PathOnClient = 'Copado Commit changes.json'];
            System.assertEquals(1, files.size(), 'Copado Commit changes.json file should have been upserted');
            List<Git_Org_Commit__c> gitCommits = [SELECT Status__c, Commit_Id__c FROM Git_Org_Commit__c];
            System.assertEquals(1, gitCommits.size(), 'One Git Org Commit record should have been created');
            List<User_Story_Commit__c> userStoryCommits = [SELECT LastJobExecutionId__c, External_Id__c FROM User_Story_Commit__c];
            System.assertEquals(1, userStoryCommits.size(), 'One User Story Commit record should have been created');

            // Verify callback
            User_Story__c userStory = [SELECT Latest_Commit_Date__c FROM User_Story__c LIMIT 1];
            System.assertNotEquals(
                null,
                userStory.Latest_Commit_Date__c,
                'User_Story__c should have been updated with Latest_Commit_Date__c in callback execution'
            );
            System.assertNotEquals(
                null,
                userStoryCommits[0].LastJobExecutionId__c,
                'User_Story_Commit__c should have been updated with LastJobExecutionId__c'
            );
            System.assertEquals(
                userStoryId + '_' + 'test_commit_id',
                userStoryCommits[0].External_Id__c,
                'User_Story_Commit__c should have been updated with External_Id__c in callback execution'
            );
            System.assertEquals(CommitConstants.STATUS_COMPLETE, gitCommits[0].Status__c, 'User Story Commit status should have been updated');
            System.assertEquals('test_commit_id', gitCommits[0].Commit_Id__c, 'User Story Commit status should have been updated');

            List<Automation_Event__c> events = [SELECT Id, Action_Name__c, Environment_Id__c FROM Automation_Event__c];
            System.assertEquals(1, events.size(), 'An Automation Event should be created');
            System.assertEquals(ActionConstants.COMMIT_ACTION, events[0].Action_Name__c, 'Action Name should match');
            Environment__c environment = [SELECT Id FROM Environment__c WHERE Name = 'dev1'];
            System.assertEquals(environment.Id, events[0].Environment_Id__c, 'Environment should match');
        }
    }

    @IsTest
    private static void cliRequest() {
        System.runAs(getRunAsUser()) {
            // Setup
            Id userStoryId = getUserStory();
            Actions.CommitRequest request = new Actions.CommitRequest();
            request.userStoryId = userStoryId;
            request.changes = changes();
            request.recreateFeatureBranch = true;
            request.executeCommit = false;
            request.commitId = 'decb6302';

            // Exercise
            Test.startTest();
            Actions.CommitService.execute(request);
            Test.stopTest();

            // Verify
            List<JobExecution__c> jobExecution = [SELECT Id FROM JobExecution__c];
            System.assertEquals(0, jobExecution.size(), 'No Job Execution should be created');
            List<User_Story_Metadata__c> metadata = [SELECT Id FROM User_Story_Metadata__c];
            System.assertEquals(10, metadata.size(), 'Changes should have been created as User_Story_Metadata__c records');
            List<ContentVersion> files = [SELECT Id FROM ContentVersion WHERE PathOnClient = 'Copado Commit changes.json'];
            System.assertEquals(1, files.size(), 'Copado Commit changes.json file should have been upserted');
            List<Git_Org_Commit__c> gitCommits = [SELECT Status__c, Commit_Id__c FROM Git_Org_Commit__c];
            System.assertEquals(1, gitCommits.size(), 'One Git Org Commit record should have been created');
            System.assertEquals('decb6302', gitCommits[0].Commit_Id__c, 'Git Org Commit record should have been updated with commit id');
            List<User_Story_Commit__c> userStoryCommits = [SELECT LastJobExecutionId__c, External_Id__c FROM User_Story_Commit__c];
            System.assertEquals(1, userStoryCommits.size(), 'One User Story Commit record should have been created');
            List<Automation_Event__c> events = [SELECT Id, Action_Name__c FROM Automation_Event__c];
            System.assertEquals(1, events.size(), 'An Automation Event should be created');
            System.assertEquals(ActionConstants.COMMIT_ACTION, events[0].Action_Name__c, 'Action Name should match');
        }
    }

    @IsTest
    private static void cliRequestWithoutPipelineAction() {
        System.runAs(getRunAsUser()) {
            // Setup
            Deployment_Flow__c pipeline = createData(false);

            Id userStoryId = getUserStory(pipeline);
            Actions.CommitRequest request = new Actions.CommitRequest();
            request.userStoryId = userStoryId;
            request.changes = changes();
            request.recreateFeatureBranch = true;
            request.executeCommit = false;
            request.commitId = 'decb6302';

            // Exercise
            Test.startTest();
            Actions.CommitService.execute(request);
            Test.stopTest();

            // Verify
            List<JobExecution__c> jobExecution = [SELECT Id FROM JobExecution__c];
            System.assertEquals(0, jobExecution.size(), 'No Job Execution should be created');
            List<User_Story_Metadata__c> metadata = [SELECT Id FROM User_Story_Metadata__c];
            System.assertEquals(10, metadata.size(), 'Changes should have been created as User_Story_Metadata__c records');
            List<ContentVersion> files = [SELECT Id FROM ContentVersion WHERE PathOnClient = 'Copado Commit changes.json'];
            System.assertEquals(1, files.size(), 'Copado Commit changes.json file should have been upserted');
            List<Git_Org_Commit__c> gitCommits = [SELECT Status__c, Commit_Id__c FROM Git_Org_Commit__c];
            System.assertEquals(1, gitCommits.size(), 'One Git Org Commit record should have been created');
            System.assertEquals('decb6302', gitCommits[0].Commit_Id__c, 'Git Org Commit record should have been updated with commit id');
            List<User_Story_Commit__c> userStoryCommits = [SELECT LastJobExecutionId__c, External_Id__c FROM User_Story_Commit__c];
            System.assertEquals(1, userStoryCommits.size(), 'One User Story Commit record should have been created');
            List<Automation_Event__c> events = [SELECT Id, Action_Name__c FROM Automation_Event__c];
            System.assertEquals(1, events.size(), 'An Automation Event should be created');
            System.assertEquals(ActionConstants.COMMIT_ACTION, events[0].Action_Name__c, 'Action Name should match');
        }
    }

    @IsTest
    private static void cliRequestWithQualityGatePostStep() {
        System.runAs(getRunAsUser()) {
            // Setup
            Deployment_Flow__c pipeline = [SELECT Id FROM Deployment_Flow__c LIMIT 1];
            ExtensionConfiguration extensionConfig = new ExtensionConfiguration().active(true).tool('Manual Tests').application('Test');
            TestToolsSelector.mock(new List<TestTool__mdt>{ new TestTool__mdt(MasterLabel = 'None', TestType__c = 'Mock Type') });

            Quality_Gate_Rule__c rule = (Quality_Gate_Rule__c) new QualityGateRule()
                .action('Commit')
                .sequence('After')
                .tool('None')
                .active(false)
                .name('RuleCommit')
                .add(new QualityGateRuleCondition().pipelineId(pipeline.Id).extensionConfiguration(extensionConfig))
                .persist();

            rule.Status__c = QualityGateConstants.ACTIVE;
            update rule;

            Id userStoryId = getUserStory();
            Actions.CommitRequest request = new Actions.CommitRequest();
            request.userStoryId = userStoryId;
            request.changes = changes();
            request.recreateFeatureBranch = true;
            request.executeCommit = false;
            request.commitId = 'decb6302';

            // Exercise
            Test.startTest();
            Actions.CommitService.execute(request);
            Test.stopTest();

            // Verify
            List<JobExecution__c> jobExecution = [SELECT Id FROM JobExecution__c];
            // we need to fix the assertion once we fix the CLI related code from commit
            System.assertEquals(0, jobExecution.size(), 'There should not be a Job Execution created');
        }
    }

    @IsTest
    private static void cliRequestWithForceExecution() {
        System.runAs(getRunAsUser()) {
            // Setup
            Id userStoryId = getUserStory();
            Actions.CommitRequest request = new Actions.CommitRequest();
            request.userStoryId = userStoryId;
            request.changes = changes();
            request.recreateFeatureBranch = true;
            request.executeCommit = false;
            request.commitId = 'decb6302';
            ExtensionKeyValueSettingsSelector.mock = new List<ExtensionKeyValueSetting__mdt>{
                new ExtensionKeyValueSetting__mdt(
                    Extension__r = new ExtensionPackageConfiguration__mdt(Platform__c = 'Other'),
                    Key__c = 'forceCommitTemplateExecution',
                    Value__c = 'True'
                )
            };
            Flow.mockResponse = flowCompletionEvent(true, '', '');

            // Exercise
            Test.startTest();
            Actions.CommitService.execute(request);
            Test.stopTest();

            // Verify
            List<JobExecution__c> jobExecution = [SELECT Id FROM JobExecution__c];
            System.assertEquals(1, jobExecution.size(), 'There should be a Job Execution created');
            List<User_Story_Metadata__c> metadata = [SELECT Id FROM User_Story_Metadata__c];
            System.assertEquals(10, metadata.size(), 'Changes should have been created as User_Story_Metadata__c records');
            List<ContentVersion> files = [SELECT Id FROM ContentVersion WHERE PathOnClient = 'Copado Commit changes.json'];
            System.assertEquals(1, files.size(), 'Copado Commit changes.json file should have been upserted');
            List<Git_Org_Commit__c> gitCommits = [SELECT Status__c, Commit_Id__c FROM Git_Org_Commit__c];
            System.assertEquals(1, gitCommits.size(), 'One Git Org Commit record should have been created');
            System.assertEquals('decb6302', gitCommits[0].Commit_Id__c, 'Git Org Commit record should have been updated with commit id');
            List<User_Story_Commit__c> userStoryCommits = [SELECT LastJobExecutionId__c, External_Id__c FROM User_Story_Commit__c];
            System.assertEquals(1, userStoryCommits.size(), 'One User Story Commit record should have been created');
            List<Automation_Event__c> events = [SELECT Id, Action_Name__c FROM Automation_Event__c];
            System.assertEquals(1, events.size(), 'An Automation Event should be created');
            System.assertEquals(ActionConstants.COMMIT_ACTION, events[0].Action_Name__c, 'Action Name should match');
        }
    }

    @IsTest
    private static void errorJob() {
        System.runAs(getRunAsUser()) {
            // Setup
            Id userStoryId = getUserStory();
            Actions.CommitRequest request = new Actions.CommitRequest();
            request.userStoryId = userStoryId;
            request.changes = changes();
            request.recreateFeatureBranch = true;

            Flow.mockResponse = flowCompletionEvent(false, '', '');

            // Exercise
            Test.startTest();
            Actions.CommitService.execute(request);
            Test.stopTest();

            // Verify
            JobExecution__c jobExecution = [SELECT Status__c, ErrorMessage__c FROM JobExecution__c LIMIT 1];
            System.assertEquals(JobExecutionConstants.STATUS_ERROR, jobExecution.Status__c, 'Job execution status after stop test should be Error');
            List<User_Story_Metadata__c> metadata = [SELECT Id FROM User_Story_Metadata__c];
            System.assertEquals(0, metadata.size(), 'Changes should have not been created as User_Story_Metadata__c records');
            List<ContentVersion> files = [SELECT Id FROM ContentVersion WHERE PathOnClient = 'Copado Commit changes.json'];
            System.assertEquals(1, files.size(), 'Copado Commit changes.json file should have been upserted');
            List<Git_Org_Commit__c> gitCommits = [SELECT Status__c, Commit_Id__c FROM Git_Org_Commit__c];
            System.assertEquals(1, gitCommits.size(), 'One Git Org Commit record should have been created');
            List<User_Story_Commit__c> userStoryCommits = [SELECT LastJobExecutionId__c, External_Id__c FROM User_Story_Commit__c];
            System.assertEquals(1, userStoryCommits.size(), 'One User Story Commit record should have been created');

            // Verify callback
            User_Story__c userStory = [SELECT Latest_Commit_Date__c FROM User_Story__c LIMIT 1];
            System.assertNotEquals(
                null,
                userStory.Latest_Commit_Date__c,
                'User_Story__c should have been updated with Latest_Commit_Date__c in callback execution'
            );
            System.assertNotEquals(
                null,
                userStoryCommits[0].LastJobExecutionId__c,
                'User_Story_Commit__c should have been updated with LastJobExecutionId__c'
            );
            System.assertEquals(CommitConstants.STATUS_FAILED, gitCommits[0].Status__c, 'User Story Commit status should have been updated');

            List<Automation_Event__c> events = [SELECT Id, Action_Name__c FROM Automation_Event__c];
            System.assertEquals(1, events.size(), 'An Automation Event should be created');
            System.assertEquals(ActionConstants.COMMIT_ACTION, events[0].Action_Name__c, 'Action Name should match');
        }
    }

    @IsTest
    private static void exceptionOnLackOfPermissions() {
        // Setup
        Id userStoryId = getUserStory();
        Actions.CommitRequest request = new Actions.CommitRequest();
        request.userStoryId = userStoryId;
        request.changes = changes();
        request.recreateFeatureBranch = true;

        // Exercise
        String exceptionMessage;
        Test.startTest();
        try {
            Actions.CommitService.execute(request);
        } catch (Exception e) {
            exceptionMessage = e.getMessage();
        }
        Test.stopTest();

        // Verify
        System.assert(
            exceptionMessage.contains(Label.CanNotPerformThisAction.substringBefore(':')),
            'Can not perform this action exception should have been thrown'
        );
    }

    @IsTest
    private static void exceptionOnManyChanges() {
        System.runAs(getRunAsUser()) {
            // Setup
            Id userStoryId = getUserStory();
            Actions.CommitRequest request = new Actions.CommitRequest();
            request.userStoryId = userStoryId;
            request.changes = changes(9000);
            request.recreateFeatureBranch = true;

            // Exercise
            String exceptionMessage;
            Test.startTest();
            try {
                Actions.CommitService.execute(request);
            } catch (Exception e) {
                exceptionMessage = e.getMessage();
            }
            Test.stopTest();

            // Verify
            System.assert(
                exceptionMessage.contains(Label.Can_Not_Commit_More_Than_8000_Metadata),
                'No more than 8000 metadata exception should have been thrown'
            );
        }
    }

    @IsTest
    private static void exceptionOnDuplicatedChanges() {
        System.runAs(getRunAsUser()) {
            // Setup
            Id userStoryId = getUserStory();
            Actions.CommitRequest request = new Actions.CommitRequest();
            request.userStoryId = userStoryId;
            request.changes = duplicatedChanges();
            request.recreateFeatureBranch = true;

            // Exercise
            String exceptionMessage;
            Test.startTest();
            try {
                Actions.CommitService.execute(request);
            } catch (Exception e) {
                exceptionMessage = e.getMessage();
            }
            Test.stopTest();

            // Verify
            System.assert(
                exceptionMessage.contains(Label.Can_Not_Commit_Same_Metadata_With_Different_Operation),
                'Duplicated metadata exception should have been thrown'
            );
        }
    }

    private static Deployment_Flow__c createData(Boolean createPipelineAction) {
        if (createPipelineAction) {
            new JobTemplate().name('Commit Template').version(1).mockAutomation('Commit').add(new JobStep()).persist();
        }

        Credential source = new Credential();

        return (Deployment_Flow__c) new Pipeline()
            .mainBranch('main')
            .setPlatform('Other')
            .add(
                new Connection(
                        new Environment().name('dev1').platform('Other').add(source),
                        new Environment().platform('Other').add(new Credential())
                    )
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

    private static Id getUserStory() {
        return [SELECT Id FROM User_Story__c LIMIT 1].Id;
    }

    private static Id getUserStory(Deployment_Flow__c pipeline) {
        return [SELECT Id FROM User_Story__c WHERE Project__c IN (SELECT Id FROM Project__c WHERE Deployment_Flow__c = :pipeline.Id) LIMIT 1].Id;
    }

    private static List<Actions.CommitChange> changes() {
        return changes(10);
    }

    private static List<Actions.CommitChange> changes(Integer count) {
        List<Actions.CommitChange> result = new List<Actions.CommitChange>();

        for (Integer i = 0; i < count; i++) {
            Actions.CommitChange change = new Actions.CommitChange();
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

    private static List<Actions.CommitChange> duplicatedChanges() {
        List<Actions.CommitChange> result = new List<Actions.CommitChange>();

        Actions.CommitChange change = new Actions.CommitChange();
        change.a = 'add';
        change.n = 'TestClass';
        change.t = 'ApexClass';
        change.m = 'force-app/main/default';
        change.c = 'category';
        change.j = '{"vk": "6368cb8e-776c-4ad6-9906-444d460715d7"}';
        result.add(change);
        change = new Actions.CommitChange();
        change.a = 'add';
        change.n = 'TestClass';
        change.t = 'ApexClass';
        change.m = 'force-app/main/default';
        change.c = 'category';
        change.j = '{"vk": "6368cb8e-776c-4ad6-9906-444d460715d7"}';
        result.add(change);
        change = new Actions.CommitChange();
        change.a = 'retrieveOnly';
        change.n = 'TestClass';
        change.t = 'ApexClass';
        change.m = 'force-app/main/default';
        change.c = 'category';
        change.j = '{"vk": "6368cb8e-776c-4ad6-9906-444d460715d7"}';
        result.add(change);

        return result;
    }

    private static Event__e flowCompletionEvent(Boolean isSuccess, String errorMessage, String data) {
        Event__e result = new Event__e();
        result.Topic_Uri__c = OnJobStepComplete.STEP_ENDPOINT;
        result.Payload__c = Json.serialize(new OnJobStepComplete.EventPayload(isSuccess, errorMessage, data));

        return result;
    }
}