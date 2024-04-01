@IsTest
private class PromotionDeploymentServiceImplTest {
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
    private static void insertJobStepsInRightOrder() {
        System.runAs(getRunAsUser()) {
            //Setup
            FunctionEngine.mockResponse = functionCompletionEvent(true, '', '');
            Flow.mockResponse = flowCompletionEvent(true, '', '');

            User_Story__c userStory = getUserStory();
            new JobStep().executionSequence(PromotionConstants.BEFORE_VALUE).userStory(userStory.Id);
            new JobStep().executionSequence(PromotionConstants.AFTER_VALUE).userStory(userStory.Id).persist();

            Test.startTest();

            Promotion__c promotion = createPromotion();

            Actions.PromotionDeploymentRequest request = new Actions.PromotionDeploymentRequest();
            request.promotionId = promotion.Id;
            request.deploymentDryRun = false;

            //Exercise
            Actions.PromotionDeploymentResult response = Actions.PromotionDeploymentService.execute(request);
            Test.stopTest();

            // Verify
            List<JobStep__c> steps = [SELECT Type__c FROM JobStep__c WHERE JobExecution__c = :response.jobExecution.Id];
            System.assertEquals(4, steps.size(), 'Execution step should have 4 steps.');
            System.assertEquals('Test', steps[0].Type__c, 'Quality Gate step must come first.');
            System.assertEquals('Flow', steps[1].Type__c, 'Before Deployment step from user story must come second.');
            System.assertEquals('Function', steps[2].Type__c, 'Job execution step must come third.');
            System.assertEquals('Flow', steps[3].Type__c, 'After Deployment step from user story must come next.');
        }
    }

    @IsTest
    private static void insertJobStepsForManualTasks() {
        System.runAs(getRunAsUser()) {
            //Setup
            User_Story__c userStory = getUserStory();
            new JobStep()
                .executionSequence(PromotionConstants.BEFORE_VALUE)
                .type('Manual')
                .configJson(
                    '{"parameters":[{"name":"assigneeId","value":"' +
                        getRunAsUser().Id +
                        '"},{"name":"assigneeName","value":"Test User"}, {"name":"performAtSource","value":"false"}, {"name":"performAtDestination","value":"true"}, {"name":"disableForBackPromotions","value":"false"}, {"name":"disabledStages","value":"[]"}, {"name":"disabledEnvironments","value":"[]"}]}'
                )
                .userStory(userStory.Id);
            new JobStep()
                .executionSequence(PromotionConstants.AFTER_VALUE)
                .type('Manual')
                .configJson(
                    '{"parameters":[{"name":"assigneeId","value":"' +
                        getRunAsUser().Id +
                        '"},{"name":"assigneeName","value":"Test User"}, {"name":"performAtSource","value":"false"}, {"name":"performAtDestination","value":"true"}, {"name":"disableForBackPromotions","value":"false"}, {"name":"disabledStages","value":"[]"}, {"name":"disabledEnvironments","value":"[]"}]}'
                )
                .userStory(userStory.Id)
                .persist();

            Test.startTest();

            Promotion__c promotion = createPromotion();

            Actions.PromotionDeploymentRequest request = new Actions.PromotionDeploymentRequest();
            request.promotionId = promotion.Id;
            request.deploymentDryRun = false;

            //Exercise
            Actions.PromotionDeploymentResult response = Actions.PromotionDeploymentService.execute(request);
            Test.stopTest();

            // Verify
            List<JobStep__c> steps = [SELECT Type__c FROM JobStep__c WHERE JobExecution__c = :response.jobExecution.Id];
            System.assertEquals(4, steps.size(), 'Execution step should have 4 steps.');
            System.assertEquals('Test', steps[0].Type__c, 'Quality Gate step must come first.');
            System.assertEquals('Manual', steps[1].Type__c, 'Before Deployment step from user story must come second.');
            System.assertEquals('Function', steps[2].Type__c, 'Job execution step must come third.');
            System.assertEquals('Manual', steps[3].Type__c, 'After Deployment step from user story must come next.');
        }
    }

    @IsTest
    private static void insertJobStepsForManualTasksWithConditions() {
        System.runAs(getRunAsUser()) {
            //Setup
            String intEnvironmentId = JSON.serialize(new List<String>{ [SELECT Id FROM Environment__c WHERE Name = 'int' LIMIT 1].Id })
                .replace('"', '\\"');

            String intEnvironmentConfigJSON =
                '{"parameters":[{"name":"assigneeId","value":"' +
                getRunAsUser().Id +
                '"},{"name":"assigneeName","value":"Test User"}, {"name":"performAtSource","value":"false"}, {"name":"performAtDestination","value":"true"}, {"name":"disableForBackPromotions","value":"false"}, {"name":"disabledStages","value":"[]"}, {"name":"disabledEnvironments","value":"' +
                intEnvironmentId +
                '"}]}';

            User_Story__c userStory = getUserStory();
            new JobStep()
                .executionSequence(PromotionConstants.BEFORE_VALUE)
                .type('Manual')
                .configJson(
                    '{"parameters":[{"name":"assigneeId","value":"' +
                        getRunAsUser().Id +
                        '"},{"name":"assigneeName","value":"Test User"}, {"name":"performAtSource","value":"false"}, {"name":"performAtDestination","value":"true"}, {"name":"disableForBackPromotions","value":"false"}, {"name":"disabledStages","value":"[]"}, {"name":"disabledEnvironments","value":"[]"}]}'
                )
                .userStory(userStory.Id);
            new JobStep()
                .executionSequence(PromotionConstants.AFTER_VALUE)
                .type('Manual')
                .configJson(intEnvironmentConfigJSON)
                .userStory(userStory.Id)
                .persist();

            Test.startTest();

            Promotion__c promotion = createPromotion();

            Actions.PromotionDeploymentRequest request = new Actions.PromotionDeploymentRequest();
            request.promotionId = promotion.Id;
            request.deploymentDryRun = false;

            //Exercise
            Actions.PromotionDeploymentResult response = Actions.PromotionDeploymentService.execute(request);
            Test.stopTest();

            // Verify
            List<JobStep__c> steps = [SELECT Type__c FROM JobStep__c WHERE JobExecution__c = :response.jobExecution.Id];
            System.assertEquals(3, steps.size(), 'Execution step should have 3 steps.');
            System.assertEquals('Test', steps[0].Type__c, 'Quality Gate step must come first.');
            System.assertEquals('Manual', steps[1].Type__c, 'Before Deployment step from user story must come second.');
            System.assertEquals('Function', steps[2].Type__c, 'Job execution step must come third.');
        }
    }

    @IsTest
    private static void executeWithDeploymentStepsInBackPromotion() {
        System.runAs(getRunAsUser()) {
            //Setup
            FunctionEngine.mockResponse = functionCompletionEvent(true, '', '');
            Flow.mockResponse = flowCompletionEvent(true, '', '');

            User_Story__c userStory = getUserStory();
            new JobStep().executionSequence(PromotionConstants.BEFORE_VALUE).userStory(userStory.Id);
            new JobStep().executionSequence(PromotionConstants.AFTER_VALUE).userStory(userStory.Id).persist();

            Promotion__c promotion = createPromotionWithBackPromotion();

            Actions.PromotionDeploymentRequest request = new Actions.PromotionDeploymentRequest();
            request.promotionId = promotion.Id;
            request.deploymentDryRun = false;

            //Exercise
            Test.startTest();
            Actions.PromotionDeploymentResult response = Actions.PromotionDeploymentService.execute(request);
            Test.stopTest();

            // Verify
            List<JobStep__c> steps = [SELECT Type__c FROM JobStep__c WHERE JobExecution__c = :response.jobExecution.Id];
            System.assertEquals(3, steps.size(), 'Execution step should have 3 steps.');
            System.assertEquals('Flow', steps[0].Type__c, 'Before Deployment step from user story must come second.');
            System.assertEquals('Function', steps[1].Type__c, 'Job execution step must come third.');
            System.assertEquals('Flow', steps[2].Type__c, 'After Deployment step from user story must come next.');
        }
    }

    @IsTest
    private static void deploymentSuccessful() {
        System.runAs(getRunAsUser()) {
            //Setup
            FunctionEngine.mockResponse = functionCompletionEvent(true, '', '');
            Flow.mockResponse = flowCompletionEvent(true, '', '');

            Test.startTest();
            User_Story__c userStory = getUserStory();
            User_Story_Metadata__c userStoryMetadata = getUserStoryMetadata(userStory.Id);
            Promotion__c promotion = createPromotion();

            List<PromotionDeploymentServiceImpl.Change> ignoredChanges = new List<PromotionDeploymentServiceImpl.Change>();
            PromotionDeploymentServiceImpl.Change change = new PromotionDeploymentServiceImpl.Change();
            change.n = userStoryMetadata.Metadata_API_Name__c;
            change.t = userStoryMetadata.Type__c;
            change.u = userStoryMetadata.User_Story__r.Name;
            change.a = userStoryMetadata.Action__c;
            ignoredChanges.add(change);

            new Files().upsertFile(promotion.Id, PromotionConstants.IGNORED_CHANGES_FILE_NAME, JSON.serialize(ignoredChanges));

            Actions.PromotionDeploymentRequest request = new Actions.PromotionDeploymentRequest();
            request.promotionId = promotion.Id;
            request.deploymentDryRun = false;

            //Exercise
            Actions.PromotionDeploymentService.execute(request);
            Test.stopTest();

            // Verify
            List<Deployment__c> deployments = [SELECT Id FROM Deployment__c WHERE Promotion__c = :promotion.Id];
            System.assertEquals(1, deployments.size(), 'There is only one deployment');
            List<JobStep__c> executionSteps = [SELECT Id FROM JobStep__c WHERE JobExecution__r.Deployment__c = :deployments[0].Id];
            System.assertEquals(2, executionSteps.size(), 'Execution step has 2 steps');
            List<Automation_Event__c> events = [SELECT Id, Action_Name__c FROM Automation_Event__c ORDER BY CreatedDate ASC];
            System.assertEquals(1, events.size(), 'An Automation Event should be created');
            System.assertEquals(ActionConstants.PROMOTION_DEPLOYMENT, events[0].Action_Name__c, 'Action Name should match');

            List<ContentDocumentLink> documentLink = [
                SELECT ContentDocument.LatestPublishedVersion.VersionData
                FROM ContentDocumentLink
                WHERE LinkedEntityId = :promotion.Id AND ContentDocument.Title = :PromotionConstants.IGNORED_CHANGES_FILE_NAME.substringBefore('.')
                LIMIT 1
            ];
            List<PromotionDeploymentServiceImpl.Change> promotionChanges = (List<PromotionDeploymentServiceImpl.Change>) JSON.deserialize(
                documentLink[0].ContentDocument.LatestPublishedVersion.VersionData.toString(),
                List<PromotionDeploymentServiceImpl.Change>.class
            );
            System.assertEquals(true, promotionChanges.contains(change), 'Ignored change should be in the changes file');
        }
    }

    @IsTest
    private static void qualityGateStepsOnValidation() {
        System.runAs(getRunAsUser()) {
            //Setup
            FunctionEngine.mockResponse = functionCompletionEvent(true, '', '');
            Flow.mockResponse = flowCompletionEvent(true, '', '');

            Promotion__c promotion = createPromotion();

            Actions.PromotionDeploymentRequest request = new Actions.PromotionDeploymentRequest();
            request.promotionId = promotion.Id;
            request.deploymentDryRun = true;

            //Exercise
            Test.startTest();
            Actions.PromotionDeploymentService.execute(request);
            Test.stopTest();

            // Verify
            List<JobExecution__c> executions = [SELECT Id FROM JobExecution__c];
            System.assertEquals(1, executions.size(), 'There should be one execution');
            List<Deployment__c> deployments = [SELECT Id FROM Deployment__c WHERE Promotion__c = :promotion.Id];
            System.assertEquals(1, deployments.size(), 'There is only one deployment');
            List<JobStep__c> executionSteps = [SELECT Id FROM JobStep__c WHERE JobExecution__r.Deployment__c = :deployments[0].Id];
            System.assertEquals(1, executionSteps.size(), 'Execution step has 1 steps');
            List<Automation_Event__c> events = [SELECT Id, Action_Name__c FROM Automation_Event__c ORDER BY CreatedDate ASC];
            System.assertEquals(1, events.size(), 'An Automation Event should be created');
            System.assertEquals(ActionConstants.PROMOTION_DEPLOYMENT, events[0].Action_Name__c, 'Action Name should match');
        }
    }

    @IsTest
    private static void exceptionOnManyChanges() {
        System.runAs(getRunAsUser()) {
            //Setup
            FunctionEngine.mockResponse = functionCompletionEvent(true, '', '');
            Flow.mockResponse = flowCompletionEvent(true, '', '');

            User_Story__c userStory = [SELECT Id, Environment__c, Project__c FROM User_Story__c LIMIT 1];
            metadata(userStory, 9000);
            Promotion__c promotion = createPromotion();

            Actions.PromotionDeploymentRequest request = new Actions.PromotionDeploymentRequest();
            request.promotionId = promotion.Id;
            request.deploymentDryRun = false;

            //Exercise
            Test.startTest();
            String exceptionMessage;
            try {
                Actions.PromotionDeploymentService.execute(request);
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

    private static void data() {
        new JobTemplate()
            .name('PromotionDeployment_Template')
            .mockAutomation(ActionConstants.PROMOTION_DEPLOYMENT)
            .add(new JobStep().type('Function'))
            .persist();

        Credential dev1Credential = new Credential();
        Environment dev1 = new Environment().name('dev1').type('Sandbox').platform('Other').add(dev1Credential);
        Credential intCredential = new Credential();
        Environment integration = new Environment().name('int').type('Sandbox').platform('Other').add(intCredential);

        Pipeline pipeline = new Pipeline()
            .active(true)
            .mainBranch('main')
            .setPlatform('Other')
            .add(new Connection(dev1, integration).branch('dev1'))
            .add(
                new Project()
                    .add(
                        new UserStory()
                            .credential(dev1Credential)
                            .add(new UserStoryMetadata().name('TestClass').type('ApexClass'))
                            .add(new UserStoryMetadata().name('MyClass').type('ApexClass'))
                    )
            );

        ExtensionConfiguration extensionConfiguration = new ExtensionConfiguration().active(true).tool('Manual Tests').application('Test');
        TestToolsSelector.mock(new List<TestTool__mdt>{ new TestTool__mdt(MasterLabel = 'None', TestType__c = 'Mock Type') });
        new QualityGateRule()
            .active(false)
            .name('Rule1')
            .action(ActionConstants.PROMOTION_DEPLOYMENT)
            .sequence(PromotionConstants.BEFORE_VALUE)
            .tool('None')
            .add(new QualityGateRuleCondition().pipeline(pipeline).extensionConfiguration(extensionConfiguration));

        new QualityGateRule()
            .active(false)
            .name('Rule2')
            .action(ActionConstants.PROMOTION_DEPLOYMENT)
            .sequence(PromotionConstants.AFTER_VALUE)
            .tool('None')
            .add(new QualityGateRuleCondition().pipeline(pipeline).extensionConfiguration(extensionConfiguration))
            .persist();

        activateRules();
    }

    private static void activateRules() {
        List<Quality_Gate_Rule__c> result = new List<Quality_Gate_Rule__c>();
        for (Quality_Gate_Rule__c rule : [SELECT Status__c FROM Quality_Gate_Rule__c LIMIT 10]) {
            rule.Status__c = QualityGateConstants.ACTIVE;

            result.add(rule);
        }
        update result;
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

    private static User_Story__c getUserStory() {
        return [SELECT Id, Environment__c, Project__c FROM User_Story__c LIMIT 1];
    }

    private static User_Story_Metadata__c getUserStoryMetadata(Id userStoryId) {
        return [
            SELECT Id, User_Story__c, User_Story__r.Name, Metadata_API_Name__c, Type__c, Action__c
            FROM User_Story_Metadata__c
            WHERE User_Story__c = :userStoryId
            WITH USER_MODE
            LIMIT 1
        ];
    }

    private static List<User_Story_Metadata__c> metadata(User_Story__c userStory, Integer count) {
        List<User_Story_Metadata__c> result = new List<User_Story_Metadata__c>();

        for (Integer i = 0; i < count; i++) {
            result.add(new User_Story_Metadata__c(User_Story__c = userStory.Id, Name = 'TestClass_' + i, Type__c = 'ApexClass'));
        }
        insert result;
        return result;
    }

    private static Promotion__c createPromotion() {
        Promotion__c firstPromotion = (Promotion__c) new Promotion()
            .projectId([SELECT Id FROM Project__c LIMIT 1].Id)
            .sourceEnvId([SELECT Id FROM Environment__c WHERE Name = 'dev1' LIMIT 1].Id)
            .add(new PromotedUserStory().userStory(getUserStory().Id))
            .persist();
        return firstPromotion;
    }

    private static Promotion__c createPromotionWithBackPromotion() {
        User_Story__c userStory = getUserStory();
        Promotion__c promotion = (Promotion__c) new Promotion()
            .projectId(userStory.Project__c)
            .sourceEnvId(userStory.Environment__c)
            .destinationEnvId(userStory.Environment__c)
            .backPromotion(true)
            .status(PromotionConstants.STATUS_COMPLETED)
            .add(new PromotedUserStory().userStory(userStory.Id))
            .persist();
        return promotion;
    }
}