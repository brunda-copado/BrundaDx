@IsTest
private with sharing class SubmitUserStoryServiceImplTest {
    @TestSetup
    private static void makeData() {
        TestUtilities.getAllMultilicense();
        User user = (User) new User_t()
            .assign(new PermissionSetAssignment_t().copadoUser())
            .assign(new PermissionSetAssignment_t().jobEngine())
            .assign(new PermissionSetAssignment_t().executeAutomations())
            .persist();
        System.runAs(user) {
            new CopadoLicense().user(user).enableAll().persist();
            createData();
        }
    }

    @IsTest
    private static void matchAutomationRule() {
        System.runAs(getUser()) {
            // Setup
            Actions.MatchAutomationRuleRequest request = new Actions.MatchAutomationRuleRequest();
            request.userStoryId = getUserStory().Id;

            // Exercise
            Test.startTest();
            Actions.MatchAutomationRuleResult result = Actions.SubmitUserStoryService.match(request);
            Test.stopTest();

            // Verify
            System.assertEquals(true, result.automationRule != null, 'Automation Rule should be returned');
            System.assertEquals(true, result.userStory != null, 'User Story should be returned');
        }
    }

    @IsTest
    private static void submitUserStory() {
        System.runAs(getUser()) {
            // Setup
            Actions.SubmitUserStoryRequest request = new Actions.SubmitUserStoryRequest();
            request.userStoryId = getUserStory().Id;

            // Exercise
            Test.startTest();
            Actions.SubmitUserStoryResult result = Actions.SubmitUserStoryService.submit(request);
            Test.stopTest();

            // Verify
            System.assertEquals(true, result.automationEvent != null, 'Event should be created with source Action');

            Automation_Event__c event = [
                SELECT Id, Action_Name__c, Payload__c
                FROM Automation_Event__c
                WHERE Id = :result.automationEvent.Id
                LIMIT 1
            ];
            System.assertEquals(ActionConstants.SUBMIT_USER_STORIES, event.Action_Name__c, 'Event should be created with source Action');
            System.assertEquals(true, event.Payload__c != null, 'Payload should exist');
        }
    }

    private static void createData() {
        Stage devStage = new Stage().name('Dev').metaStage('Build');
        Stage testStage = new Stage().name('Test').metaStage('Test');
        Stage productionStage = new Stage().name('Production').metaStage('Production');

        Credential dev1Credential = new Credential();
        Environment dev1 = new Environment().name('dev1').type('Sandbox').platform('Other').add(dev1Credential);
        Environment integration = new Environment().name('int').type('Sandbox').platform('Other').add(new Credential());
        Environment uat = new Environment().name('uat').type('Sandbox').platform('Other').add(new Credential());
        Environment prod = new Environment().name('prod').type('Sandbox').platform('Other').add(new Credential());

        StageConnection devStageConnection = new StageConnection().stage(devStage);
        StageConnection testStageConnection = new StageConnection().stage(testStage);
        StageConnection productionStageConnection = new StageConnection().stage(productionStage);

        new Pipeline()
            .active(true)
            .mainBranch('main')
            .setPlatform('Other')
            .add(new Connection(dev1, integration).branch('dev1').stageConnection(devStageConnection))
            .add(new Connection(integration, uat).branch('int').stageConnection(devStageConnection))
            .add(new Connection(uat, prod).branch('uat').stageConnection(testStageConnection))
            .add(devStageConnection)
            .add(testStageConnection)
            .add(productionStageConnection)
            .add(
                new Project()
                    .add(
                        new UserStory()
                            .title('Include')
                            .credential(dev1Credential)
                            .add(new UserStoryMetadata().name('TestClass').type('ApexClass'))
                            .add(new UserStoryMetadata().name('MyClass').type('ApexClass'))
                    )
            )
            .persist();

        Stage_Connection__c devStageConnectionRecord = getStageConnections('Dev');
        Stage_Connection__c testStageConnectionRecord = getStageConnections('Test');
        Stage_Connection__c prodStageConnectionRecord = getStageConnections('Production');
        devStageConnectionRecord.Next_Stage_Connection__c = testStageConnectionRecord.Id;
        testStageConnectionRecord.Next_Stage_Connection__c = prodStageConnectionRecord.Id;
        update new List<Stage_Connection__c>{ devStageConnectionRecord, testStageConnectionRecord };

        createAutomationRule();
    }

    private static Stage_Connection__c getStageConnections(String stageName) {
        return [SELECT Id FROM Stage_Connection__c WHERE Stage__r.Name = :stageName];
    }

    private static User getUser() {
        return [SELECT Id FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1];
    }

    private static User_Story__c getUserStory() {
        return [SELECT Id FROM User_Story__c LIMIT 1];
    }

    private static Deployment_Flow__c getPipeline() {
        return [SELECT Id FROM Deployment_Flow__c LIMIT 1];
    }

    private static Org__c getCredential(String name) {
        return [SELECT Id FROM Org__c WHERE Environment__r.Name = :name LIMIT 1];
    }

    private static Stage__c getStage(String name) {
        return [SELECT Id FROM Stage__c WHERE Name = :name LIMIT 1];
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
            .stage(getStage('Dev').Id)
            .filterCriteria(getFilterCriteria())
            .persist();
        return automationRule;
    }

    private static String getFilterCriteria() {
        String objectName = Schema.SObjectType.User_Story__c.getName();
        return '{"mainObject":"' + objectName + '","isCustom":true,"whereCondition":"User_Story_Title__c = \'Include\'"}';
    }
}