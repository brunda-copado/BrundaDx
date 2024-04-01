@IsTest
private class PromotionServiceImplTest {
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
            createData();
        }
    }

    @IsTest
    static void execute() {
        System.runAs(getRunAsUser()) {
            // Setup
            User_Story__c userStory = getUserStoryWithRelease();

            Actions.PromotionRequest request = new Actions.PromotionRequest();
            request.promotionId = null;
            request.userStoryIds = new List<Id>{ userStory.Id };
            request.executePromotion = true;
            request.sourceEnvironmentId = userStory.Environment__c;

            FunctionEngine.mockResponse = functionCompletionEvent(true, '', '');
            Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock('{}', null));

            // Exercise
            Test.startTest();
            Actions.PromotionResult result = Actions.PromotionService.execute(request);
            Test.stopTest();

            JobExecution__c jobExecution = [SELECT Id, Status__c FROM JobExecution__c WHERE Id = :result.jobExecution.Id];

            // Assertions
            System.assertNotEquals(null, result.jobExecution, 'There should be a Job Execution');
            System.assertEquals(JobExecutionConstants.STATUS_SUCCESSFUL, jobExecution.Status__c, 'Job Execution should be successful');
            System.assertNotEquals(null, result.promotion.Id, 'A new promotion should be created');
            System.assertNotEquals(null, result.promotion.Project__c, 'There should be Project on promotion');
            System.assertNotEquals(null, result.promotion.Release__c, 'There should be Release on promotion');
        }
    }

    @IsTest
    static void executeWithoutMetadataAndDeploymentStep() {
        System.runAs(getRunAsUser()) {
            // Setup
            User_Story__c userStory = [SELECT Id, Environment__c, Project__c FROM User_Story__c LIMIT 1];

            Actions.PromotionRequest request = new Actions.PromotionRequest();
            request.promotionId = null;
            request.userStoryIds = new List<Id>{ userStory.Id };
            request.executePromotion = true;
            request.sourceEnvironmentId = userStory.Environment__c;
            request.projectId = userStory.Project__c;

            FunctionEngine.mockResponse = functionCompletionEvent(true, '', '');
            Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock('{}', null));

            // Exercise
            String exceptionMessage;
            Test.startTest();
            try {
                Actions.PromotionService.execute(request);
            } catch (Exception e) {
                exceptionMessage = e.getMessage();
            }

            Test.stopTest();

            // Verify
            System.assert(
                exceptionMessage.contains(Label.Can_Not_Promote_If_Either_No_Deployment_Steps_or_Metadata_Commits),
                'No metadata change or deployment steps to promote'
            );
        }
    }

    @IsTest
    static void executeWithDeploymentSteps() {
        System.runAs(getRunAsUser()) {
            // Setup
            User_Story__c userStory = [SELECT Id, Environment__c, Project__c FROM User_Story__c LIMIT 1];
            Flow.mockResponse = flowCompletionEvent(true, '', '');
            new JobStep().executionSequence(PromotionConstants.BEFORE_VALUE).userStory(userStory.Id);
            new JobStep().executionSequence(PromotionConstants.AFTER_VALUE).userStory(userStory.Id).persist();

            Actions.PromotionRequest request = new Actions.PromotionRequest();
            request.promotionId = null;
            request.userStoryIds = new List<Id>{ userStory.Id };
            request.executePromotion = true;
            request.executeDeployment = true;
            request.sourceEnvironmentId = userStory.Environment__c;
            request.projectId = userStory.Project__c;

            // Exercise
            Test.startTest();
            Actions.PromotionService.execute(request);
            Test.stopTest();

            JobExecution__c jobExecution = [SELECT Id, Status__c FROM JobExecution__c LIMIT 1];
            List<JobStep__c> steps = [SELECT Type__c FROM JobStep__c WHERE JobExecution__c = :jobExecution.Id];

            // Assertions
            System.assertEquals(JobExecutionConstants.STATUS_SUCCESSFUL, jobExecution.Status__c, 'Job Execution should be successful');
            System.assertEquals(2, steps.size(), 'Execution step should have 2 steps.');
        }
    }

    @IsTest
    static void executeWithFilteredDeploymentSteps() {
        System.runAs(getRunAsUser()) {
            // Setup
            User_Story__c userStory = [SELECT Id, Environment__c, Project__c FROM User_Story__c LIMIT 1];
            Environment__c environment = [SELECT Id FROM Environment__c WHERE Name = :'int' LIMIT 1];
            Flow.mockResponse = flowCompletionEvent(true, '', '');
            Map<String, Object> dataToSerialize = new Map<String, Object>();
            dataToSerialize.put(
                'parameters',
                new List<CopadoFunctions.FunctionParameter>{
                    new CopadoFunctions.FunctionParameter('disabledEnvironments', JSON.serialize(new List<String>{ environment.Id }))
                }
            );

            new JobStep()
                .executionSequence(PromotionConstants.BEFORE_VALUE)
                .userStory(userStory.Id)
                .configJson(JSON.serialize(dataToSerialize))
                .persist();

            Actions.PromotionRequest request = new Actions.PromotionRequest();
            request.promotionId = null;
            request.userStoryIds = new List<Id>{ userStory.Id };
            request.executePromotion = true;
            request.executeDeployment = true;
            request.sourceEnvironmentId = userStory.Environment__c;
            request.projectId = userStory.Project__c;

            // Exercise
            Test.startTest();
            Actions.PromotionService.execute(request);
            Test.stopTest();

            List<JobExecution__c> jobExecution = [SELECT Id, Status__c FROM JobExecution__c LIMIT 1];
            Promotion__c promotion = [SELECT Id, Status__c FROM Promotion__c LIMIT 1];

            // Assertions
            System.assertEquals(0, jobExecution.size(), 'Job Execution should not be created');
            System.assertEquals(PromotionConstants.STATUS_COMPLETED, promotion.Status__c, 'Promotion completed successfuly');
        }
    }

    @IsTest
    static void executeWithDeploymentStepsAndQualitySteps() {
        System.runAs(getRunAsUser()) {
            // Setup
            Deployment_Flow__c pipeline = getPipeline();
            TestToolsSelector.mock(new List<TestTool__mdt>{ new TestTool__mdt(MasterLabel = 'None', TestType__c = 'Mock Type') });
            Quality_Gate_Rule__c rule = (Quality_Gate_Rule__c) new QualityGateRule()
                .action(ActionConstants.PROMOTION_DEPLOYMENT)
                .sequence(PromotionConstants.AFTER_VALUE)
                .tool('None') // @Note: Has to be one of the packaged values for the Copado Test Tool picklist
                .active(false)
                .name('RulePromotion')
                .add(new QualityGateRuleCondition().pipelineId(pipeline.Id).extensionConfiguration(getExtensionConfigurationId()))
                .persist();

            rule.Status__c = QualityGateConstants.ACTIVE;
            update rule;

            User_Story__c userStory = [SELECT Id, Environment__c, Project__c FROM User_Story__c LIMIT 1];
            Flow.mockResponse = flowCompletionEvent(true, '', '');
            new JobStep().executionSequence(PromotionConstants.BEFORE_VALUE).userStory(userStory.Id);
            new JobStep().executionSequence(PromotionConstants.AFTER_VALUE).userStory(userStory.Id).persist();

            Promotion__c promotion = (Promotion__c) new Promotion()
                .projectId(userStory.Project__c)
                .sourceEnvId(userStory.Environment__c)
                .add(new PromotedUserStory().userStory(UserStory.Id))
                .persist();

            Actions.PromotionRequest request = new Actions.PromotionRequest();
            request.promotionId = promotion.Id;
            request.userStoryIds = new List<Id>{ userStory.Id };
            request.executePromotion = true;
            request.executeDeployment = true;
            request.sourceEnvironmentId = userStory.Environment__c;
            request.projectId = userStory.Project__c;

            // Exercise
            Test.startTest();
            Actions.PromotionService.execute(request);
            Test.stopTest();

            List<JobStep__c> steps = [SELECT Type__c FROM JobStep__c WHERE JobExecution__c != NULL];

            // Assertions
            System.assertEquals(2, steps.size(), 'Execution step should have 2 steps.');
            System.assertEquals('Flow', steps[0].Type__c, 'Before Deployment step from user story must come first');
            System.assertEquals('Flow', steps[1].Type__c, 'After Deployment step from user story must come next.');
        }
    }

    @IsTest
    static void executeWithExistingPromotion() {
        System.runAs(getRunAsUser()) {
            // Setup
            User_Story__c userStory = [SELECT Id, Environment__c, Project__c FROM User_Story__c LIMIT 1];
            metadata(userStory);

            Promotion__c promotion = (Promotion__c) new Promotion()
                .projectId(userStory.Project__c)
                .sourceEnvId(userStory.Environment__c)
                .status(PromotionConstants.STATUS_DRAFT)
                .persist();

            new PromotedUSerStory().promotion(promotion.Id).userStory(userStory.Id).persist();

            Actions.PromotionRequest request = new Actions.PromotionRequest();
            request.promotionId = promotion.Id;
            request.userStoryIds = new List<Id>{ userStory.Id };
            request.executePromotion = true;
            request.sourceEnvironmentId = userStory.Environment__c;
            request.projectId = userStory.Project__c;

            FunctionEngine.mockResponse = functionCompletionEvent(true, '', '');
            Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock('{}', null));

            // Exercise
            Test.startTest();
            Actions.PromotionResult result = Actions.PromotionService.execute(request);
            Test.stopTest();

            JobExecution__c jobExecution = [SELECT Id, Status__c FROM JobExecution__c WHERE Id = :result.jobExecution.Id];

            // Assertions
            System.assertNotEquals(null, result.jobExecution, 'There should be a Job Execution');
            System.assertEquals(JobExecutionConstants.STATUS_SUCCESSFUL, jobExecution.Status__c, 'Job Execution should be successful');
            System.assertEquals(promotion.Id, result.promotion.Id, 'Promotion Id should be the same');
        }
    }

    @IsTest
    static void executeWithoutQualityGatesInBackPromotion() {
        System.runAs(getRunAsUser()) {
            // Setup
            Deployment_Flow__c pipeline = getPipeline();
            TestToolsSelector.mock(new List<TestTool__mdt>{ new TestTool__mdt(MasterLabel = 'None', TestType__c = 'Mock Type') });
            Quality_Gate_Rule__c rule = (Quality_Gate_Rule__c) new QualityGateRule()
                .action(ActionConstants.PROMOTION)
                .sequence(PromotionConstants.BEFORE_VALUE)
                .tool('None') // @Note: Has to be one of the packaged values for the Copado Test Tool picklist
                .active(false)
                .name('RulePromotion')
                .add(new QualityGateRuleCondition().pipelineId(pipeline.Id).extensionConfiguration(getExtensionConfigurationId()))
                .persist();

            rule.Status__c = QualityGateConstants.ACTIVE;
            update rule;
            User_Story__c userStory = [SELECT Id, Environment__c, Project__c FROM User_Story__c LIMIT 1];
            metadata(userStory);
            Actions.PromotionRequest request = new Actions.PromotionRequest();
            request.userStoryIds = new List<Id>{ userStory.Id };
            request.sourceEnvironmentId = userStory.Environment__c;
            request.projectId = userStory.Project__c;
            request.executePromotion = true;
            request.isBackPromotion = true;

            FunctionEngine.mockResponse = functionCompletionEvent(true, '', '');
            Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock('{}', null));

            // Exercise
            Test.startTest();
            JobExecution__c jobExecution = Actions.PromotionService.execute(request).jobExecution;
            Test.stopTest();

            // Verify
            List<JobStep__c> steps = [SELECT Id FROM JobStep__c WHERE JobExecution__c = :jobExecution.Id AND Type__c = 'Test'];
            System.assertEquals(0, steps.size(), 'Quality Gates should not be enforced in back-promotions.');
        }
    }

    @IsTest
    static void userStoriesOrderedByDefault() {
        System.runAs(getRunAsUser()) {
            // Setup
            User_Story__c us1 = [SELECT Id, Environment__c, Project__c FROM User_Story__c LIMIT 1];
            insert us1.clone(false, true, false, false);
            List<User_Story__c> userStories = [SELECT Id, Environment__c, Project__c FROM User_Story__c ORDER BY Name ASC];
            metadata(userStories[0]);
            metadata(userStories[1]);

            Actions.PromotionRequest request = new Actions.PromotionRequest();
            request.userStoryIds = new List<Id>(new Map<Id, User_Story__c>(userStories).keySet());
            request.sourceEnvironmentId = userStories[0].Environment__c;
            request.projectId = userStories[0].Project__c;
            request.executePromotion = true;
            request.isBackPromotion = false;

            FunctionEngine.mockResponse = functionCompletionEvent(true, '', '');
            Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock('{}', null));

            // Exercise
            Test.startTest();
            Actions.PromotionService.execute(request);
            Test.stopTest();

            // Verify
            JobExecution__c jobExecution = [SELECT Status__c, ErrorMessage__c, DataJson__c FROM JobExecution__c LIMIT 1];
            System.assertEquals('Successful', jobExecution.Status__c, 'Job execution status after stop test should be Successful');
            Map<String, Object> dataJson = (Map<String, Object>) JSON.deserializeUntyped(jobExecution.DataJson__c);
            List<Object> userStoryIds = (List<Object>) dataJson.get('userStoryIds');
            List<Id> orderedUserStoryIds = new List<Id>(new Map<Id, User_Story__c>(userStories).keySet());
            System.assertEquals(orderedUserStoryIds, userStoryIds, 'User Stories should be ordered by default');
        }
    }

    @IsTest
    static void userStoriesOrderedByPromotionOrder() {
        System.runAs(getRunAsUser()) {
            // Setup
            Promotion__c promotion = (Promotion__c) new Promotion()
                .projectId([SELECT Id FROM Project__c LIMIT 1].Id)
                .sourceEnvId([SELECT Id FROM Environment__c LIMIT 1].Id)
                .persist();
            promotion.Order_by__c = 'Name DESC';
            update promotion;
            User_Story__c us1 = [SELECT Id, Name, Environment__c, Project__c FROM User_Story__c LIMIT 1];
            insert us1.clone(false, true, false, false);
            List<User_Story__c> userStories = [SELECT Id, Environment__c, Project__c FROM User_Story__c ORDER BY Name DESC];
            metadata(userStories[0]);
            metadata(userStories[1]);
            List<Promoted_User_Story__c> promotedUserStories = new List<Promoted_User_Story__c>();
            for (User_Story__c userStory : userStories) {
                promotedUserStories.add(new Promoted_User_Story__c(User_Story__c = userStory.Id, Promotion__c = promotion.Id));
            }
            insert promotedUserStories;

            Actions.PromotionRequest request = new Actions.PromotionRequest();
            request.promotionId = promotion.Id;
            request.sourceEnvironmentId = promotion.Source_Environment__c;
            request.projectId = promotion.Project__c;
            request.executePromotion = true;
            request.isBackPromotion = false;

            FunctionEngine.mockResponse = functionCompletionEvent(true, '', '');
            Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock('{}', null));

            List<PromotionServiceImpl.Change> ignoredChanges = new List<PromotionServiceImpl.Change>();
            PromotionServiceImpl.Change change = new PromotionServiceImpl.Change();
            change.n = 'TestClass2';
            change.t = 'ApexClass2';
            change.u = us1.Name;
            ignoredChanges.add(change);
            new Files().upsertFile(promotion.Id, PromotionConstants.IGNORED_CHANGES_FILE_NAME, JSON.serialize(ignoredChanges));

            // Exercise
            Test.startTest();
            Actions.PromotionService.execute(request);
            Test.stopTest();

            // Verify
            JobExecution__c jobExecution = [SELECT Status__c, ErrorMessage__c, DataJson__c FROM JobExecution__c LIMIT 1];
            System.assertEquals('Successful', jobExecution.Status__c, 'Job execution status after stop test should be Successful');
            Map<String, Object> dataJson = (Map<String, Object>) JSON.deserializeUntyped(jobExecution.DataJson__c);
            List<Object> userStoryIds = (List<Object>) dataJson.get('userStoryIds');
            List<Id> orderedUserStoryIds = new List<Id>(new Map<Id, User_Story__c>(userStories).keySet());
            System.assertEquals(orderedUserStoryIds, userStoryIds, 'User Stories should be ordered by promotion order');
            List<ContentDocumentLink> documentLink = [
                SELECT ContentDocument.LatestPublishedVersion.VersionData
                FROM ContentDocumentLink
                WHERE LinkedEntityId = :promotion.Id AND ContentDocument.Title = :PromotionConstants.PROMOTE_FILE_NAME.substringBefore('.')
                LIMIT 1
            ];
            List<PromotionServiceImpl.Change> promotionChanges = (List<PromotionServiceImpl.Change>) JSON.deserialize(
                documentLink[0].ContentDocument.LatestPublishedVersion.VersionData.toString(),
                List<PromotionServiceImpl.Change>.class
            );
            System.assertEquals(false, promotionChanges.contains(change), 'Ignored change should not be in the changes file');
        }
    }

    @IsTest
    static void userStoriesOrderedByPipelineOrder() {
        System.runAs(getRunAsUser()) {
            // Setup
            Deployment_Flow__c pipeline = getPipeline();
            pipeline.Order_by__c = 'CreatedDate DESC';
            update pipeline;
            User_Story__c us1 = [SELECT Id, Environment__c, Project__c FROM User_Story__c LIMIT 1];

            insert us1.clone(false, true, false, false);
            List<User_Story__c> userStories = [SELECT Id, Environment__c, Project__c FROM User_Story__c ORDER BY CreatedDate DESC];
            metadata(userStories[0]);
            metadata(userStories[1]);

            Actions.PromotionRequest request = new Actions.PromotionRequest();
            request.userStoryIds = new List<Id>(new Map<Id, User_Story__c>(userStories).keySet());
            request.sourceEnvironmentId = userStories[0].Environment__c;
            request.projectId = userStories[0].Project__c;
            request.executePromotion = true;
            request.isBackPromotion = false;

            FunctionEngine.mockResponse = functionCompletionEvent(true, '', '');
            Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock('{}', null));

            // Exercise
            Test.startTest();
            Actions.PromotionService.execute(request);
            Test.stopTest();

            // Verify
            JobExecution__c jobExecution = [SELECT Status__c, ErrorMessage__c, DataJson__c FROM JobExecution__c LIMIT 1];
            System.assertEquals('Successful', jobExecution.Status__c, 'Job execution status after stop test should be Successful');
            Map<String, Object> dataJson = (Map<String, Object>) JSON.deserializeUntyped(jobExecution.DataJson__c);
            List<Object> userStoryIds = (List<Object>) dataJson.get('userStoryIds');
            List<Id> orderedUserStoryIds = new List<Id>(new Map<Id, User_Story__c>(userStories).keySet());
            System.assertEquals(orderedUserStoryIds, userStoryIds, 'User Stories should be ordered by pipeline order');
        }
    }

    @IsTest
    static void executeWithPromotionWithRelease() {
        System.runAs(getRunAsUser()) {
            // Setup
            User_Story__c userStory = [SELECT Id, Environment__c, Project__c FROM User_Story__c LIMIT 1];
            metadata(userStory);

            Promotion__c promotion = (Promotion__c) new Promotion()
                .projectId(userStory.Project__c)
                .sourceEnvId(userStory.Environment__c)
                .status(PromotionConstants.STATUS_DRAFT)
                .persist();

            Release__c release = new Release__c(Project__c = userStory.Project__c, Version__c = '1.1');
            insert release;
            promotion.Release__c = release.Id;
            update promotion;

            new PromotedUSerStory().promotion(promotion.Id).userStory(userStory.Id).persist();

            Actions.PromotionRequest request = new Actions.PromotionRequest();
            request.promotionId = promotion.Id;
            request.userStoryIds = new List<Id>{ userStory.Id };
            request.executePromotion = true;
            request.sourceEnvironmentId = userStory.Environment__c;
            request.projectId = userStory.Project__c;

            FunctionEngine.mockResponse = functionCompletionEvent(true, '', '');
            Test.setMock(HttpCalloutMock.class, new testHttpCalloutMock('{}', null));

            // Exercise
            Test.startTest();
            Actions.PromotionResult result = Actions.PromotionService.execute(request);
            Test.stopTest();

            JobExecution__c jobExecution = [SELECT Id, Status__c, DataJson__c FROM JobExecution__c WHERE Id = :result.jobExecution.Id];

            // Assertions
            System.assertNotEquals(null, result.jobExecution, 'There should be a Job Execution');
            System.assertEquals(JobExecutionConstants.STATUS_SUCCESSFUL, jobExecution.Status__c, 'Job Execution should be successful');
            System.assertEquals(promotion.Id, result.promotion.Id, 'Promotion Id should be the same');
            Map<String, Object> dataJson = (Map<String, Object>) JSON.deserializeUntyped(jobExecution.DataJson__c);
            String version = (String) dataJson.get('gitTag');
            System.assertEquals(release.Version__c, version, 'Version from Release should match');
        }
    }

    @IsTest
    static void exceptionOnManyChanges() {
        System.runAs(getRunAsUser()) {
            // Setup
            User_Story__c userStory = [SELECT Id, Environment__c, Project__c FROM User_Story__c LIMIT 1];
            bulkMetadata(userStory, 9000);
            Actions.PromotionRequest request = new Actions.PromotionRequest();
            request.userStoryIds = new List<Id>{ userStory.Id };
            request.sourceEnvironmentId = userStory.Environment__c;
            request.projectId = userStory.Project__c;
            request.executePromotion = true;

            // Exercise
            String exceptionMessage;
            Test.startTest();
            try {
                Actions.PromotionService.execute(request);
            } catch (Exception e) {
                exceptionMessage = e.getMessage();
            }

            Test.stopTest();

            // Verify
            System.assert(
                exceptionMessage.contains(Label.Can_Not_Promote_More_Than_8000_Metadata),
                'No more than 8000 metadata exception should have been thrown'
            );
        }
    }

    @IsTest
    static void exceptionOnPromotedUserStoryCount() {
        System.runAs(getRunAsUser()) {
            // Setup
            User_Story__c userStory = [SELECT Id, Environment__c, Project__c FROM User_Story__c LIMIT 1];
            metadata(userStory);

            Promotion__c promotion = (Promotion__c) new Promotion()
                .projectId(userStory.Project__c)
                .sourceEnvId(userStory.Environment__c)
                .status(PromotionConstants.STATUS_DRAFT)
                .persist();

            Actions.PromotionRequest request = new Actions.PromotionRequest();
            request.promotionId = promotion.Id;
            request.userStoryIds = new List<Id>{ userStory.Id };
            request.executePromotion = true;
            request.sourceEnvironmentId = userStory.Environment__c;

            // Exercise
            Test.startTest();
            String exceptionMessage;
            try {
                Actions.PromotionService.execute(request);
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }
            Test.stopTest();

            // Assertions
            System.assert(
                exceptionMessage.contains(Label.Please_add_at_least_one_user_story_to_your_promotion),
                'There should be at least one user story to promote.'
            );
        }
    }

    @IsTest
    static void exceptionOnProjectValidation() {
        System.runAs(getRunAsUser()) {
            // Setup
            User_Story__c userStory = [SELECT Id, Environment__c FROM User_Story__c LIMIT 1];
            metadata(userStory);

            Actions.PromotionRequest request = new Actions.PromotionRequest();
            request.projectId = getProjectId('masterProject');
            request.userStoryIds = new List<Id>{ userStory.Id };
            request.executePromotion = true;
            request.sourceEnvironmentId = userStory.Environment__c;

            // Exercise
            Test.startTest();
            String exceptionMessage;
            try {
                Actions.PromotionService.execute(request);
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }
            Test.stopTest();

            // Assertions
            System.assert(
                exceptionMessage.contains(Label.Project_Id_Validation),
                'User stories in the request should have the same Project as in the request parameter.'
            );
        }
    }

    @IsTest
    static void exceptionOnReleaseProjectValidation() {
        System.runAs(getRunAsUser()) {
            // Setup
            User_Story__c userStory = getUserStoryWithRelease();

            Actions.PromotionRequest request = new Actions.PromotionRequest();
            request.projectId = getProjectId('project1');
            request.userStoryIds = new List<Id>{ userStory.Id };
            request.executePromotion = true;
            request.sourceEnvironmentId = userStory.Environment__c;

            // Exercise
            Test.startTest();
            String exceptionMessage;
            try {
                Actions.PromotionService.execute(request);
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }
            Test.stopTest();

            // Assertions
            System.assert(
                exceptionMessage.contains(Label.Project_Id_Validation),
                'The project in the request parameter should be same as the user story release project.'
            );
        }
    }

    @IsTest
    static void exceptionOnDifferentReleasesValidation() {
        System.runAs(getRunAsUser()) {
            // Setup
            List<User_Story__c> userStories = getUserStoriesWithDifferentReleases();

            Actions.PromotionRequest request = new Actions.PromotionRequest();
            request.userStoryIds = new List<Id>{ userStories[0].Id, userStories[1].Id };
            request.executePromotion = true;
            request.sourceEnvironmentId = userStories[0].Environment__c;

            // Exercise
            Test.startTest();
            String exceptionMessage;
            try {
                Actions.PromotionService.execute(request);
            } catch (Exception ex) {
                exceptionMessage = ex.getMessage();
            }
            Test.stopTest();

            // Assertions
            System.assert(exceptionMessage.contains(Label.Different_Releases_Promotion_Validation), 'User Stories belongs to different Releases.');
        }
    }

    @IsTest
    static void executeCallbackSuccessful() {
        System.runAs(getRunAsUser()) {
            // Setup
            User_Story__c userStory = [SELECT Id, Environment__c, Project__c FROM User_Story__c LIMIT 1];

            Promotion__c promotion = (Promotion__c) new Promotion()
                .projectId(userStory.Project__c)
                .sourceEnvId(userStory.Environment__c)
                .status(PromotionConstants.STATUS_COMPLETED)
                .persist();

            new PromotedUSerStory().promotion(promotion.Id).userStory(userStory.Id);

            JobExecution__c jobExecution = (JobExecution__c) new JobExecution()
                .dataJson('{"promotionId": "' + promotion.Id + '", "executeDeployment": false}')
                .promotion(promotion.Id)
                .add(new JobStep().add(new Result()))
                .persist();

            jobExecution = [
                SELECT Id, ParentId__c, DataJson__c, Status__c, Pipeline__c, Destination__c, VolumeOptions__c
                FROM JobExecution__c
                WHERE Id = :jobExecution.Id
            ];

            // Exercise
            Test.startTest();
            new PromotionServiceImpl().execute(jobExecution, JobExecutionConstants.STATUS_SUCCESSFUL);
            Test.stopTest();

            // Assertions
            Promotion__c promotionResult = [SELECT Id, Status__c, Merge_Conflict__c FROM Promotion__c WHERE Id = :promotion.Id];
            System.assertEquals(PromotionConstants.STATUS_COMPLETED, promotionResult.Status__c, 'Promotion status should be Completed');
            System.assertEquals(false, promotionResult.Merge_Conflict__c, 'Promotion Merge Conflict should be false');
        }
    }

    @IsTest
    static void executeCallbackWithConflict() {
        System.runAs(getRunAsUser()) {
            // Setup
            User_Story__c userStory = [SELECT Id, Environment__c, Project__c FROM User_Story__c LIMIT 1];

            Promotion__c promotion = (Promotion__c) new Promotion()
                .projectId(userStory.Project__c)
                .sourceEnvId(userStory.Environment__c)
                .status(PromotionConstants.STATUS_DRAFT)
                .persist();

            new PromotedUSerStory().promotion(promotion.Id).userStory(userStory.Id);

            JobExecution__c jobExecution = (JobExecution__c) new JobExecution()
                .dataJson('{"promotionId": "' + promotion.Id + '"}')
                .promotion(promotion.Id)
                .add(new JobStep().add(new Result().resultData('{"status": "conflicts"}')))
                .persist();

            jobExecution = [
                SELECT Id, ParentId__c, DataJson__c, Status__c, Pipeline__c, Destination__c, VolumeOptions__c
                FROM JobExecution__c
                WHERE Id = :jobExecution.Id
            ];

            // Exercise
            Test.startTest();
            new PromotionServiceImpl().execute(jobExecution, JobExecutionConstants.STATUS_ERROR);
            Test.stopTest();

            // Assertions
            Promotion__c promotionResult = [SELECT Id, Status__c, Merge_Conflict__c FROM Promotion__c WHERE Id = :promotion.Id];
            System.assertEquals(PromotionConstants.STATUS_MERGE_CONFLICT, promotionResult.Status__c, 'Promotion status should be Merge Conflict');
            System.assertEquals(true, promotionResult.Merge_Conflict__c, 'Promotion Merge Conflict should be true');
        }
    }

    // HELPERS

    private static void createData() {
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
            .apexClass(FunctionStepExecutionCallback.class.getName());

        new JobTemplate()
            .name('JOB_TEMPLATE_PROMOTION')
            .mockAutomation(ActionConstants.PROMOTION)
            .add(new JobStep().order(1).type('Function').configJson('{"functionName":"mulePromotion","parameters":[]}'))
            .volumeOptions('[{ "name": "volumeEnabled", "value": "false" }]')
            .add(new JobStep().order(1).type('Function').configJson('{"functionName":"mulePromotion","parameters":[]}'))
            .persist();

        Credential source = new Credential();

        new Pipeline()
            .mainBranch('main')
            .setPlatform('Other')
            .add(
                new Connection(
                        new Environment().name('dev1').platform('Other').add(source),
                        new Environment().name('int').platform('Other').add(new Credential())
                    )
                    .branch('dev1')
            )
            .add(
                new Connection(new Environment().platform('Other').add(new Credential()), new Environment().platform('Other').add(new Credential()))
                    .branch('dev2')
            )
            .add(new Project().name('masterProject').add(new UserStory().credential(source)))
            .add(new Project().name('project1').add(new Release()))
            .add(new Project().name('project2').add(new Release()))
            .persist();

        ExtensionConfiguration__c extensionConfig = new ExtensionConfiguration__c(
            ExtensionTool__c = 'Manual Tests', // @Note: Has to be one of the packaged values for this picklist field
            ExtensionApplication__c = 'Test',
            Active__c = true
        );

        insert extensionConfig;
        TestToolsSelector.mock(new List<TestTool__mdt>{ new TestTool__mdt(MasterLabel = 'None', TestType__c = 'Mock Type') });
    }

    private static User getRunAsUser() {
        return [SELECT Id FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1];
    }

    private static Deployment_Flow__c getPipeline() {
        return [SELECT Id FROM Deployment_Flow__c LIMIT 1];
    }

    private static Id getExtensionConfigurationId() {
        return [SELECT Id FROM ExtensionConfiguration__c LIMIT 1].id;
    }

    private static Id getProjectId(String name) {
        return [SELECT Id FROM Project__c WHERE Name != :name LIMIT 1].Id;
    }

    private static void metadata(User_Story__c userStory) {
        new UserStoryMetadata().name('TestClass1').type('ApexClass1').userStoryId(userStory.Id);
        new UserStoryMetadata().name('TestClass2').type('ApexClass2').userStoryId(userStory.Id).persist();
    }

    private static List<User_Story_Metadata__c> bulkMetadata(User_Story__c userStory, Integer count) {
        List<User_Story_Metadata__c> result = new List<User_Story_Metadata__c>();

        for (Integer i = 0; i < count; i++) {
            result.add(new User_Story_Metadata__c(User_Story__c = userStory.Id, Name = 'TestClass_' + i, Type__c = 'ApexClass'));
        }
        insert result;
        return result;
    }

    private static List<User_Story__c> getUserStoriesWithDifferentReleases() {
        Org__c credential = [SELECT Id FROM Org__c LIMIT 1];

        for (Release__c release : [SELECT Id, Project__c FROM Release__c]) {
            new UserStory().credentialId(credential.Id).releaseId(release.Id).persist();
        }

        return [SELECT Id, Environment__c, Project__c, Release__c FROM User_Story__c WHERE Release__c != NULL];
    }

    private static User_Story__c getUserStoryWithRelease() {
        User_Story__c userStory = [SELECT Id, Environment__c, Project__c, Release__c FROM User_Story__c LIMIT 1];
        metadata(userStory);

        userStory.Release__c = [SELECT Id, Project__c FROM Release__c WHERE Project__r.Name = 'project2' LIMIT 1].Id;
        userStory.Project__c = null;
        UserStories.bypassTrigger = true;
        update userStory;
        UserStories.bypassTrigger = false;

        return userStory;
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
}