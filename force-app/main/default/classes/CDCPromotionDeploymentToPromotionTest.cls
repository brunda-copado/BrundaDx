@IsTest
private class CDCPromotionDeploymentToPromotionTest {
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
            Promotion__c firstPromotion = createPromotion();

            PromotionDeployAction.Response response = new PromotionDeployAction.Response();
            response.jobExecution = (JobExecution__c) new JobExecution().dataJson('{ "promotionId" : "' + firstPromotion.Id + '"}').persist();

            Deployment_Flow__c pipeline = getPipeline();
            Automation_Event__c event = (Automation_Event__c) new AutomationEvent()
                .pipelineId(pipeline.Id)
                .actionName(ActionConstants.PROMOTION_DEPLOYMENT)
                .actionStatus(AutomationRuleConstants.SOURCE_ACTION_STATUS_SUCCESSFUL)
                .actionResult(JSON.serialize(response))
                .persist();

            // Exercise
            CDCPromotionDeploymentToPromotion promotionConnector = new CDCPromotionDeploymentToPromotion();
            AutomationConnectorContext context = new AutomationConnectorContext();
            context.automationEvents = new List<Automation_Event__c>{ event };
            promotionConnector.context = context;
            List<AutomationConnector> connectors = (List<AutomationConnector>) promotionConnector.getConnectors(context);
            Test.startTest();
            for (AutomationConnector connector : connectors) {
                connector.executeAutomation();
            }
            Test.stopTest();

            // Verify
            Id nextPromotionSource = [SELECT Destination_Environment__c FROM Promotion__c WHERE Id = :firstPromotion.Id].Destination_Environment__c;
            System.assertEquals(
                1,
                [SELECT COUNT() FROM Promotion__c WHERE Source_Environment__c = :nextPromotionSource],
                'A new Promotion for the next environment should be created'
            );
        }
    }

    @IsTest
    private static void validationDeployment() {
        System.runAs(getRunAsUser()) {
            // Setup
            Promotion__c firstPromotion = createPromotion();

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
            CDCPromotionDeploymentToPromotion promotionConnector = new CDCPromotionDeploymentToPromotion();
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
            .add(new Project().add(new UserStory().credential(dev1Credential).add(new UserStoryMetadata().name('TestClass').type('ApexClass'))))
            .persist();
    }

    private static Promotion__c createPromotion() {
        Promotion__c firstPromotion = (Promotion__c) new Promotion()
            .projectId([SELECT Id FROM Project__c LIMIT 1].Id)
            .sourceEnvId([SELECT Id FROM Environment__c WHERE Name = 'dev1' LIMIT 1].Id)
            .persist();

        Promoted_User_Story__c promotedUserStory = new Promoted_User_Story__c(
            User_Story__c = [SELECT Id FROM User_Story__c LIMIT 1]
            .Id,
            Promotion__c = firstPromotion.Id
        );
        insert promotedUserStory;
        return firstPromotion;
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

    private static Deployment_Flow__c getPipeline() {
        return [SELECT Id FROM Deployment_Flow__c LIMIT 1];
    }
}