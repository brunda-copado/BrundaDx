@IsTest
private class AutomationRuleScheduleTest {
    @TestSetup
    private static void makeData() {
        TestUtilities.getAllMultilicense();
        User user = (User) new User_t()
            .assign(new PermissionSetAssignment_t().copadoUser())
            .assign(new PermissionSetAssignment_t().configureAutomations())
            .assign(new PermissionSetAssignment_t().executeAutomations())
            .persist();
        System.runAs(user) {
            new CopadoLicense().user(user).enableAll().persist();
            createData();
        }
    }

    @IsTest
    private static void executeSchedule() {
        // Setup
        System.runAs(getUser()) {
            Deployment_Flow__c pipeline = getPipeline();

            Automation_Rule__c rule = (Automation_Rule__c) new AutomationRule()
                .pipeline(pipeline.Id)
                .active()
                .sourceAction(ActionConstants.PROMOTION_DEPLOYMENT)
                .automatedAction(ActionConstants.PROMOTION)
                .sourceActionStatus(AutomationRuleConstants.SOURCE_ACTION_STATUS_SUCCESSFUL)
                .connector(AutomationRuleConstants.AUTOMATION_CONNECTOR_CUSTOM)
                .execution(AutomationRuleConstants.EXECUTION_SCHEDULED)
                .cronExpression('0 0 0 ? * * *')
                .lastExecutionDatetime(System.now().addDays(-1))
                .customConnector(AutomationConnectorMock.class.getName())
                .persist();

            new AutomationEvent()
                .pipelineId(pipeline.Id)
                .actionName(ActionConstants.PROMOTION_DEPLOYMENT)
                .actionStatus(AutomationRuleConstants.SOURCE_ACTION_STATUS_SUCCESSFUL)
                .actionResult('Test1')
                .persist();

            // Exercise
            Test.startTest();
            System.schedule('Automation Rule Schedule', rule.Cron_Expression__c, new AutomationRuleSchedule(rule.Id));
            Test.stopTest();

            // Verify
            System.assertNotEquals(
                null,
                [SELECT Last_Execution_Date_Time__c FROM Automation_Rule__c WHERE Id = :rule.Id LIMIT 1]
                .Last_Execution_Date_Time__c,
                'Automation Rule should be updated with last execution'
            );
        }
    }

    @IsTest
    private static void executeBatch() {
        // Setup
        System.runAs(getUser()) {
            Deployment_Flow__c pipeline = getPipeline();

            Automation_Rule__c rule = (Automation_Rule__c) new AutomationRule()
                .pipeline(pipeline.Id)
                .active()
                .sourceAction(ActionConstants.PROMOTION_DEPLOYMENT)
                .automatedAction(ActionConstants.PROMOTION)
                .sourceActionStatus(AutomationRuleConstants.SOURCE_ACTION_STATUS_SUCCESSFUL)
                .connector(AutomationRuleConstants.AUTOMATION_CONNECTOR_CUSTOM)
                .execution(AutomationRuleConstants.EXECUTION_SCHEDULED)
                .cronExpression('0 0 0 ? * * *')
                .lastExecutionDatetime(System.now().addDays(-1))
                .customConnector(AutomationConnectorMock.class.getName())
                .persist();

            new AutomationEvent()
                .pipelineId(pipeline.Id)
                .actionName(ActionConstants.PROMOTION_DEPLOYMENT)
                .actionStatus(AutomationRuleConstants.SOURCE_ACTION_STATUS_SUCCESSFUL)
                .actionResult('Test1')
                .persist();

            // Exercise
            Test.startTest();
            Database.executeBatch(new AutomationRuleSchedule(rule.Id));
            Test.stopTest();

            // Verify
            List<JobExecution__c> jobExecutions = [SELECT Id, ErrorMessage__c FROM JobExecution__c ORDER BY CreatedDate ASC];
            System.assertEquals(1, jobExecutions.size(), 'One Job Executions should be created');
            System.assertEquals('Test1', jobExecutions[0].ErrorMessage__c, 'Job Execution should contain the information from all the events');
        }
    }

    private static void createData() {
        new Pipeline()
            .setPlatform('Other')
            .add(
                new Connection(
                    new Environment().name('Dev1').platform('Other').add(new Credential()),
                    new Environment().name('Int').platform('Other').add(new Credential())
                )
            )
            .add(new StageConnection().stage(new Stage().name('Dev').metaStage('Build')))
            .active(true)
            .persist();
    }

    private static User getUser() {
        return [SELECT Id FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1];
    }

    private static Deployment_Flow__c getPipeline() {
        return [SELECT Id FROM Deployment_Flow__c LIMIT 1];
    }

    private static Environment__c getEnvironment() {
        return [SELECT Id FROM Environment__c LIMIT 1];
    }

    private static Stage__c getStage() {
        return [SELECT Id FROM Stage__c LIMIT 1];
    }
}