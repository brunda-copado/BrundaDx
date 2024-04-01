@IsTest
private class ACPromotionDeploymentToPromotionTest {
    @TestSetup
    private static void setupData() {
        TestUtilities.getAllMultilicense();
        User user = (User) new User_t()
            .assign(new PermissionSetAssignment_t().copadoUser())
            .assign(new PermissionSetAssignment_t().functions())
            .assign(new PermissionSetAssignment_t().jobEngine())
            .assign(new PermissionSetAssignment_t().qualityGatesAdmin())
            .persist();
        System.runAs(user) {
            new CopadoLicense().user(user).enableAll().persist();
            createData();
        }
    }

    @IsTest
    private static void connectAndExecute() {
        System.runAs(getRunAsUser()) {
            // Setup
            Deployment_Flow__c pipeline = getPipeline();
            List<Automation_Event__c> events = new List<Automation_Event__c>();
            for (Promotion__c promotion : createPromotionsForRelease()) {
                PromotionDeployAction.Response response = new PromotionDeployAction.Response();
                response.jobExecution = (JobExecution__c) new JobExecution().dataJson('{ "promotionId" : "' + promotion.Id + '"}').persist();
                Automation_Event__c event = (Automation_Event__c) new AutomationEvent()
                    .pipelineId(pipeline.Id)
                    .actionName(ActionConstants.PROMOTION_DEPLOYMENT)
                    .actionStatus(AutomationRuleConstants.SOURCE_ACTION_STATUS_SUCCESSFUL)
                    .actionResult(JSON.serialize(response))
                    .persist();
                events.add(event);
            }

            // Exercise
            ACPromotionDeploymentToPromotion promotionConnector = new ACPromotionDeploymentToPromotion();
            AutomationConnectorContext context = new AutomationConnectorContext();
            context.automationEvents = events;
            context.automationRule = getAutomationRule(pipeline.Id, getFilterCriteria(), AutomationRuleConstants.EXECUTION_IMMEDIATE);
            promotionConnector.context = context;
            List<AutomationConnector> connectors = (List<AutomationConnector>) promotionConnector.getConnectors(context);
            Test.startTest();
            for (AutomationConnector connector : connectors) {
                connector.executeAutomation();
            }
            Test.stopTest();

            // Verify
            Integer promotionCount = [
                SELECT COUNT()
                FROM Promotion__c
                WHERE Source_Environment__c IN (SELECT Id FROM Environment__c WHERE Name = 'int')
            ];
            System.assertEquals(
                2,
                promotionCount,
                '2 forward promotions should be created, as one of the promotions has release and the other does not have'
            );
        }
    }

    @IsTest
    private static void cloneEventsForSchedule() {
        System.runAs(getRunAsUser()) {
            // Setup
            Deployment_Flow__c pipeline = getPipeline();
            List<User_Story__c> userStories = getUserStories();
            List<Automation_Event__c> events = new List<Automation_Event__c>();
            Promotion__c promotion = createPromotionForProject();
            PromotionDeployAction.Response response = new PromotionDeployAction.Response();
            response.jobExecution = (JobExecution__c) new JobExecution()
                .dataJson('{ "promotionId" : "' + promotion.Id + '","userStoryIds" : [ "' + userStories[0].Id + '", "' + userStories[1].Id + '" ]}')
                .persist();
            Automation_Event__c event = (Automation_Event__c) new AutomationEvent()
                .pipelineId(pipeline.Id)
                .actionName(ActionConstants.PROMOTION_DEPLOYMENT)
                .actionStatus(AutomationRuleConstants.SOURCE_ACTION_STATUS_SUCCESSFUL)
                .actionResult(JSON.serialize(response))
                .persist();
            events.add(event);

            // Exercise
            ACPromotionDeploymentToPromotion promotionConnector = new ACPromotionDeploymentToPromotion();
            AutomationConnectorContext context = new AutomationConnectorContext();
            context.automationEvents = events;
            context.automationRule = getAutomationRule(pipeline.Id, getFilterCriteriaForSchedule(), AutomationRuleConstants.EXECUTION_SCHEDULED);
            promotionConnector.context = context;
            List<AutomationConnector> connectors = (List<AutomationConnector>) promotionConnector.getConnectors(context);
            Test.startTest();
            for (AutomationConnector connector : connectors) {
                connector.executeAutomation();
            }
            Test.stopTest();

            // Verify
            Integer promotionCount = [
                SELECT COUNT()
                FROM Promotion__c
                WHERE Source_Environment__c IN (SELECT Id FROM Environment__c WHERE Name = 'int')
            ];
            System.assertEquals(0, promotionCount, 'There is no promotion created since the user stories did not match with filter criteria');
        }
    }

    @IsTest
    private static void excludedUserStories() {
        System.runAs(getRunAsUser()) {
            // Setup
            Promotion__c firstPromotion = createPromotionForProject();
            List<User_Story__c> userStories = new List<User_Story__c>();
            for (User_Story__c userStory : [SELECT Id, Name, Exclude_From_CBM__c FROM User_Story__c]) {
                userStory.Exclude_From_CBM__c = true;
                userStories.add(userStory);
            }
            update userStories;

            PromotionDeployAction.Response response = new PromotionDeployAction.Response();
            response.jobExecution = (JobExecution__c) new JobExecution().dataJson('{ "promotionId" : "' + firstPromotion.Id + '"}').persist();

            Flow.mockResponse = flowCompletionEvent(true, '', '');

            Deployment_Flow__c pipeline = getPipeline();

            Automation_Event__c event = (Automation_Event__c) new AutomationEvent()
                .pipelineId(pipeline.Id)
                .actionName(ActionConstants.PROMOTION_DEPLOYMENT)
                .actionStatus(AutomationRuleConstants.SOURCE_ACTION_STATUS_SUCCESSFUL)
                .actionResult(JSON.serialize(response))
                .persist();

            // Exercise
            Test.startTest();
            ACPromotionDeploymentToPromotion promotionConnector = new ACPromotionDeploymentToPromotion();
            AutomationConnectorContext context = new AutomationConnectorContext();
            context.automationEvents = new List<Automation_Event__c>{ event };
            context.automationRule = getAutomationRule(pipeline.Id, null, AutomationRuleConstants.EXECUTION_IMMEDIATE);
            promotionConnector.context = context;
            List<AutomationConnector> connectors = (List<AutomationConnector>) promotionConnector.getConnectors(context);
            for (AutomationConnector connector : connectors) {
                connector.executeAutomation();
            }
            Test.stopTest();

            // Verify
            Id nextPromotionSource = [SELECT Destination_Environment__c FROM Promotion__c WHERE Id = :firstPromotion.Id].Destination_Environment__c;
            System.assertEquals(
                0,
                [SELECT COUNT() FROM Promotion__c WHERE Source_Environment__c = :nextPromotionSource],
                'A new Promotion for the next environment should not be created as there are no valid user stories'
            );
        }
    }

    @IsTest
    private static void validationDeployment() {
        System.runAs(getRunAsUser()) {
            // Setup
            Promotion__c firstPromotion = createPromotionForProject();

            PromotionDeployAction.Response response = new PromotionDeployAction.Response();
            response.jobExecution = (JobExecution__c) new JobExecution()
                .dataJson('{ "promotionId" : "' + firstPromotion.Id + '", "deploymentDryRun" : true}')
                .persist();

            Flow.mockResponse = flowCompletionEvent(true, '', '');

            Deployment_Flow__c pipeline = getPipeline();
            Automation_Event__c event = (Automation_Event__c) new AutomationEvent()
                .pipelineId(pipeline.Id)
                .actionName(ActionConstants.PROMOTION_DEPLOYMENT)
                .actionStatus(AutomationRuleConstants.SOURCE_ACTION_STATUS_SUCCESSFUL)
                .actionResult(JSON.serialize(response))
                .persist();

            // Exercise
            Test.startTest();
            ACPromotionDeploymentToPromotion promotionConnector = new ACPromotionDeploymentToPromotion();
            AutomationConnectorContext context = new AutomationConnectorContext();
            context.automationEvents = new List<Automation_Event__c>{ event };
            promotionConnector.context = context;
            List<AutomationConnector> connectors = (List<AutomationConnector>) promotionConnector.getConnectors(context);
            Test.stopTest();

            // Verify
            System.assertEquals(0, connectors.size(), 'A new Promotion will not be created');
        }
    }

    private static void createData() {
        new JobTemplate().name('Promotion_Template').mockAutomation('Promotion').add(new JobStep());

        new JobTemplate().name('PromotionDeployment_Template').mockAutomation('PromotionDeployment').add(new JobStep()).persist();

        Credential dev1Credential = new Credential();
        Environment dev1 = new Environment().name('dev1').type('Sandbox').platform('Other').add(dev1Credential);
        Environment dev2 = new Environment().name('dev2').type('Sandbox').platform('Other').add(new Credential());
        Credential intCredential = new Credential();
        Environment integration = new Environment().name('int').type('Sandbox').platform('Other').add(intCredential);
        Environment uat = new Environment().name('uat').type('Sandbox').platform('Other').add(new Credential());
        Environment prod = new Environment().name('prod').type('Sandbox').platform('Other').add(new Credential());

        new Pipeline()
            .active(true)
            .mainBranch('main')
            .setPlatform('Other')
            .add(new Connection(dev1, integration).branch('dev1'))
            .add(new Connection(dev2, integration).branch('dev2'))
            .add(new Connection(integration, uat).branch('int'))
            .add(new Connection(uat, prod).branch('uat'))
            .add(
                new Project()
                    .add(new UserStory().title('US1').credential(dev1Credential).add(new UserStoryMetadata().name('TestClass').type('ApexClass')))
                    .add(new UserStory().title('US2').credential(dev1Credential).add(new UserStoryMetadata().name('TestClass').type('ApexClass')))
                    .add(new UserStory().title('US3').credential(dev1Credential).add(new UserStoryMetadata().name('TestClass').type('ApexClass')))
            )
            .persist();
    }

    private static Promotion__c createPromotionForProject() {
        Promotion__c firstPromotion = createPromotion();
        createPromotedUserStories(firstPromotion.Id, [SELECT Id FROM User_Story__c]);
        return firstPromotion;
    }

    private static List<Promotion__c> createPromotionsForRelease() {
        Promotion__c firstPromotion = createPromotion();

        Promotion__c secondPromotion = createPromotion();

        Release__c release = new Release__c(Project__c = secondPromotion.Project__c, Name = 'R1');
        insert release;
        secondPromotion.Release__c = release.Id;
        update secondPromotion;

        createPromotedUserStories(firstPromotion.Id, [SELECT Id FROM User_Story__c WHERE User_Story_Title__c = 'US1']);
        createPromotedUserStories(secondPromotion.Id, [SELECT Id FROM User_Story__c WHERE User_Story_Title__c = 'US2']);

        return new List<Promotion__c>{ firstPromotion, secondPromotion };
    }

    private static Promotion__c createPromotion() {
        return (Promotion__c) new Promotion()
            .projectId([SELECT Id FROM Project__c LIMIT 1].Id)
            .sourceEnvId([SELECT Id FROM Environment__c WHERE Name = 'dev1' LIMIT 1].Id)
            .persist();
    }

    private static List<Promoted_User_Story__c> createPromotedUserStories(Id promotionId, List<User_Story__c> userStories) {
        List<Promoted_User_Story__c> result = new List<Promoted_User_Story__c>();

        for (User_Story__c userStory : userStories) {
            result.add(new Promoted_User_Story__c(User_Story__c = userStory.Id, Promotion__c = promotionId));
        }

        insert result;
        return result;
    }

    private static Event__e flowCompletionEvent(Boolean isSuccess, String errorMessage, String data) {
        Event__e result = new Event__e();
        result.Topic_Uri__c = OnJobStepComplete.STEP_ENDPOINT;
        result.Payload__c = Json.serialize(new OnJobStepComplete.EventPayload(isSuccess, errorMessage, data));

        return result;
    }

    private static User getRunAsUser() {
        return [SELECT Id FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1];
    }

    private static List<User_Story__c> getUserStories() {
        return [SELECT Id FROM User_Story__c LIMIT 2];
    }

    private static Deployment_Flow__c getPipeline() {
        return [SELECT Id FROM Deployment_Flow__c LIMIT 1];
    }

    private static Automation_Rule__c getAutomationRule(Id pipelineId, String filterCriteria, String execution) {
        Automation_Rule__c automationRule = (Automation_Rule__c) new AutomationRule()
            .pipeline(pipelineId)
            .active()
            .sourceAction(ActionConstants.PROMOTION_DEPLOYMENT)
            .automatedAction(ActionConstants.PROMOTION)
            .sourceActionStatus(AutomationRuleConstants.SOURCE_ACTION_STATUS_SUCCESSFUL)
            .connector(AutomationRuleConstants.AUTOMATION_CONNECTOR_CUSTOM)
            .execution(execution)
            .customConnector(AutomationConnectorMock.class.getName())
            .filterCriteria(filterCriteria)
            .persist();
        return automationRule;
    }

    private static String getFilterCriteria() {
        String objectName = Schema.SObjectType.User_Story__c.getName();
        return '{"mainObject":"' + objectName + '","isCustom":true,"whereCondition":"User_Story_Title__c IN (\'US1\', \'US2\')"}';
    }

    private static String getFilterCriteriaForSchedule() {
        String objectName = Schema.SObjectType.User_Story__c.getName();
        return '{"mainObject":"' + objectName + '","isCustom":false,"whereCondition":"Promote_Change__c = true"}';
    }
}