@IsTest
private with sharing class ACSubmitUserStoriesToPromotionTest {
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
            List<Automation_Event__c> events = new List<Automation_Event__c>();
            for (User_Story__c userStory : getUserStories()) {
                Automation_Event__c event = (Automation_Event__c) new AutomationEvent()
                    .pipelineId(getPipeline().Id)
                    .actionName(ActionConstants.SUBMIT_USER_STORIES)
                    .actionStatus(AutomationRuleConstants.SOURCE_ACTION_STATUS_SUCCESSFUL)
                    .payload(SubmitUserStoryServiceImpl.getPayload(userStory))
                    .persist();
                events.add(event);
            }

            // Exercise
            ACSubmitUserStoriesToPromotionDeployment submitUserStoryConnector = new ACSubmitUserStoriesToPromotionDeployment();
            AutomationConnectorContext context = new AutomationConnectorContext();
            context.automationEvents = events;
            submitUserStoryConnector.context = context;
            List<AutomationConnector> connectors = (List<AutomationConnector>) submitUserStoryConnector.getConnectors(context);
            Test.startTest();
            for (AutomationConnector connector : connectors) {
                connector.executeAutomation();
                // Note: considering only one connector or we will hit SOQL limit
                break;
            }
            Test.stopTest();

            // Verify
            Integer promotionCount = [SELECT COUNT() FROM Promotion__c];
            // Note: 2 promotions should be created, as one of the user stories has release and the other does not have, but we are discarding one of the connectors to avoid limits
            System.assertEquals(1, promotionCount, '1 promotions should be created');
        }
    }

    // HELPERS

    private static void createData() {
        new JobTemplate().name('Promotion_Template').mockAutomation('Promotion').add(new JobStep());
        new JobTemplate().name('Commit Template').version(1).mockAutomation('Commit').add(new JobStep()).persist();
        Credential source = new Credential();

        new Pipeline()
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
            .add(
                new Project()
                    .name('P1')
                    .add(
                        new Release()
                            .name('R1')
                            .add(new UserStory().title('US2').credential(source).add(new UserStoryMetadata().name('TestClass').type('ApexClass')))
                    )
                    .add(new UserStory().title('US1').credential(source).add(new UserStoryMetadata().name('TestClass').type('ApexClass')))
            )
            .persist();

        createAutomationRule();

        UserStories.bypassTrigger = true;
        List<User_Story__c> userStoriesToUpdate = new List<User_Story__c>();
        for (User_Story__c userStory : getUserStories()) {
            userStoriesToUpdate.add(new User_Story__c(Id = userStory.Id, Promote_Change__c = true));
        }
        update userStoriesToUpdate;
        UserStories.bypassTrigger = false;
    }

    private static List<User_Story__c> getUserStories() {
        return [SELECT Id, User_Story_Title__c, Project__c, Release__c, Release__r.Project__c, Environment__c, Promote_Change__c FROM User_Story__c];
    }

    private static User getRunAsUser() {
        return [SELECT Id FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1];
    }

    private static Deployment_Flow__c getPipeline() {
        return [SELECT Id FROM Deployment_Flow__c LIMIT 1];
    }

    private static Automation_Rule__c createAutomationRule() {
        Automation_Rule__c automationRule = (Automation_Rule__c) new AutomationRule()
            .pipeline(getPipeline().Id)
            .active()
            .sourceAction(ActionConstants.SUBMIT_USER_STORIES)
            .automatedAction(ActionConstants.PROMOTION)
            .sourceActionStatus(AutomationRuleConstants.SOURCE_ACTION_STATUS_SUCCESSFUL)
            .connector(AutomationRuleConstants.AUTOMATION_CONNECTOR_CUSTOM)
            .execution(AutomationRuleConstants.EXECUTION_IMMEDIATE)
            .filterCriteria(getFilterCriteria())
            .persist();
        return automationRule;
    }

    private static String getFilterCriteria() {
        String objectName = Schema.SObjectType.User_Story__c.getName();
        return '{"mainObject":"' +
            objectName +
            '","isCustom":true,"whereCondition":"User_Story_Title__c != null AND Team__c = null AND Close_Date__c = null"}';
    }
}