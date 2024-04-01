@IsTest
private class AutomationEngineTest {
    @TestSetup
    private static void makeData() {
        TestUtilities.getAllMultilicense();
        User user = (User) new User_t()
            .assign(new PermissionSetAssignment_t().copadoUser())
            .assign(new PermissionSetAssignment_t().configureAutomations())
            .assign(new PermissionSetAssignment_t().executeAutomations())
            .standard()
            .persist();
        System.runAs(user) {
            new CopadoLicense().user(user).enableAll().persist();

            new AutomationRule()
                .pipeline(new Pipeline())
                .active()
                .sourceAction(ActionConstants.PROMOTION_DEPLOYMENT)
                .automatedAction(ActionConstants.PROMOTION)
                .sourceActionStatus(AutomationRuleConstants.SOURCE_ACTION_STATUS_SUCCESSFUL)
                .connector(AutomationRuleConstants.AUTOMATION_CONNECTOR_CUSTOM)
                .execution(AutomationRuleConstants.EXECUTION_IMMEDIATE)
                .customConnector(AutomationConnectorMock.class.getName())
                .persist();
        }
    }

    @IsTest
    private static void automationEngineWithValidPipelineAndActionStatus() {
        // Setup
        System.runAs(getUser()) {
            Deployment_Flow__c pipeline = [SELECT Id FROM Deployment_Flow__c LIMIT 1];
            new AutomationEvent()
                .pipelineId(pipeline.Id)
                .actionName(ActionConstants.PROMOTION_DEPLOYMENT)
                .actionStatus(AutomationRuleConstants.SOURCE_ACTION_STATUS_SUCCESSFUL)
                .actionResult('Test Result')
                .persist();

            Automation_Event__c automationEvent = [SELECT Id FROM Automation_Event__c LIMIT 1];

            // Exercise
            Test.startTest();
            AutomationEngine.AutomationEngineRequest request = new AutomationEngine.AutomationEngineRequest();
            request.automationEventId = automationEvent.Id;
            AutomationEngine.execute(new List<AutomationEngine.AutomationEngineRequest>{ request });
            Test.stopTest();
        }

        // Verify
        List<JobExecution__c> resultJobExecutions = [SELECT Id, ErrorMessage__c FROM JobExecution__c];
        System.assertEquals(1, resultJobExecutions.size(), 'Only one Job Execution should be created');
        System.assertEquals('Test Result', resultJobExecutions[0].ErrorMessage__c, 'Job Execution should contain the information from the event');
        List<Automation_Event__c> automationEvents = [
            SELECT Id, Target_Action_Job_Execution_Ids__c, Log__c, Target_Action_Number__c
            FROM Automation_Event__c
        ];
        System.assertEquals(1, automationEvents.size(), 'Only one Automation Event should be created');
        System.assertEquals(resultJobExecutions[0].Id, automationEvents[0].Target_Action_Job_Execution_Ids__c, 'Job Execution Id should match');
        List<AsyncApexJob> apexJobs = [SELECT Id FROM AsyncApexJob ORDER BY CreatedDate ASC];
        System.assertEquals(2, apexJobs.size(), 'Two Apex Job should be created');
        String expectedLog = apexJobs[0].Id + ' - CONNECT: SUCCESS / ' + apexJobs[1].Id + ' - EXECUTE: SUCCESS (' + resultJobExecutions[0].Id + ')';
        System.assertEquals(expectedLog, automationEvents[0].Log__c, 'Log should match');
        System.assertEquals(1, automationEvents[0].Target_Action_Number__c, 'Number of Executions should match');
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @IsTest
    private static void automationEngineWithoutMatchingPipeline() {
        // Setup
        System.runAs(getUser()) {
            Deployment_Flow__c pipeline = (Deployment_Flow__c) new Pipeline().persist();
            new AutomationEvent()
                .pipelineId(pipeline.Id)
                .actionName(ActionConstants.PROMOTION_DEPLOYMENT)
                .actionStatus(AutomationRuleConstants.SOURCE_ACTION_STATUS_SUCCESSFUL)
                .actionResult('Test Result')
                .persist();

            Automation_Event__c automationEvent = [SELECT Id FROM Automation_Event__c LIMIT 1];

            // Exercise
            Test.startTest();
            AutomationEngine.AutomationEngineRequest request = new AutomationEngine.AutomationEngineRequest();
            request.automationEventId = automationEvent.Id;
            AutomationEngine.execute(new List<AutomationEngine.AutomationEngineRequest>{ request });
            Test.stopTest();
        }

        // Verify
        assertJobExecutionNotCreated();
        assertAutomationEventNotModified();
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @IsTest
    private static void automationEngineWithoutMatchingActionName() {
        // Setup
        System.runAs(getUser()) {
            Deployment_Flow__c pipeline = [SELECT Id FROM Deployment_Flow__c LIMIT 1];
            new AutomationEvent()
                .pipelineId(pipeline.Id)
                .actionName(ActionConstants.PUBLISH_PACKAGE_VERSION)
                .actionStatus(AutomationRuleConstants.SOURCE_ACTION_STATUS_SUCCESSFUL)
                .actionResult('Test Result')
                .persist();

            Automation_Event__c automationEvent = [SELECT Id FROM Automation_Event__c LIMIT 1];

            // Exercise
            Test.startTest();
            AutomationEngine.AutomationEngineRequest request = new AutomationEngine.AutomationEngineRequest();
            request.automationEventId = automationEvent.Id;
            AutomationEngine.execute(new List<AutomationEngine.AutomationEngineRequest>{ request });
            Test.stopTest();
        }

        // Verify
        assertJobExecutionNotCreated();
        assertAutomationEventNotModified();
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @IsTest
    private static void automationEngineWithoutMatchingActionStatus() {
        // Setup
        System.runAs(getUser()) {
            Deployment_Flow__c pipeline = [SELECT Id FROM Deployment_Flow__c LIMIT 1];
            new AutomationEvent()
                .pipelineId(pipeline.Id)
                .actionName(ActionConstants.PROMOTION_DEPLOYMENT)
                .actionStatus(AutomationRuleConstants.SOURCE_ACTION_STATUS_ERROR)
                .actionResult('Test Result')
                .persist();

            Automation_Event__c automationEvent = [SELECT Id FROM Automation_Event__c LIMIT 1];

            // Exercise
            Test.startTest();
            AutomationEngine.AutomationEngineRequest request = new AutomationEngine.AutomationEngineRequest();
            request.automationEventId = automationEvent.Id;
            AutomationEngine.execute(new List<AutomationEngine.AutomationEngineRequest>{ request });
            Test.stopTest();
        }

        // Verify
        assertJobExecutionNotCreated();
        assertAutomationEventNotModified();
    }

    @IsTest
    private static void automationEngineWithExceptionOnConnect() {
        // Setup
        Exception expectedException;
        final String errorMessage = 'Throw Connect Exception';
        System.runAs(getUser()) {
            Deployment_Flow__c pipeline = [SELECT Id FROM Deployment_Flow__c LIMIT 1];
            new AutomationEvent()
                .pipelineId(pipeline.Id)
                .actionName(ActionConstants.PROMOTION_DEPLOYMENT)
                .actionStatus(AutomationRuleConstants.SOURCE_ACTION_STATUS_SUCCESSFUL)
                .actionResult(errorMessage)
                .persist();

            Automation_Event__c automationEvent = [SELECT Id FROM Automation_Event__c LIMIT 1];

            // Exercise
            try {
                Test.startTest();
                AutomationEngine.AutomationEngineRequest request = new AutomationEngine.AutomationEngineRequest();
                request.automationEventId = automationEvent.Id;
                AutomationEngine.execute(new List<AutomationEngine.AutomationEngineRequest>{ request });
                Test.stopTest();
            } catch (Exception ex) {
                expectedException = ex;
            }
        }

        // Verify
        assertJobExecutionNotCreated();
        List<Automation_Event__c> automationEvents = [
            SELECT Id, Target_Action_Job_Execution_Ids__c, Log__c, Target_Action_Number__c
            FROM Automation_Event__c
        ];
        System.assertEquals(1, automationEvents.size(), 'Only one Automation Event should be created');
        System.assert(String.isBlank(automationEvents[0].Target_Action_Job_Execution_Ids__c), 'Job Execution Id should be empty');
        List<AsyncApexJob> apexJobs = [SELECT Id FROM AsyncApexJob ORDER BY CreatedDate ASC];
        System.assertEquals(1, apexJobs.size(), 'One Apex Job should be created');
        String expectedLog = apexJobs[0].Id + ' - CONNECT: ' + errorMessage;
        System.assertEquals(expectedLog, automationEvents[0].Log__c, 'Log should match');
        System.assertNotEquals(null, expectedException, 'An exception should be thrown');
        System.assertEquals(errorMessage, expectedException.getMessage(), 'Exception message does not match');
        System.assertEquals(0, automationEvents[0].Target_Action_Number__c, 'Number of Executions should match');
    }

    @IsTest
    private static void automationEngineWithExceptionOnExecution() {
        // Setup
        Exception expectedException;
        final String errorMessage = 'Throw Exception';
        System.runAs(getUser()) {
            Deployment_Flow__c pipeline = [SELECT Id FROM Deployment_Flow__c LIMIT 1];
            new AutomationEvent()
                .pipelineId(pipeline.Id)
                .actionName(ActionConstants.PROMOTION_DEPLOYMENT)
                .actionStatus(AutomationRuleConstants.SOURCE_ACTION_STATUS_SUCCESSFUL)
                .actionResult(errorMessage)
                .persist();

            Automation_Event__c automationEvent = [SELECT Id FROM Automation_Event__c LIMIT 1];

            // Exercise
            try {
                Test.startTest();
                AutomationEngine.AutomationEngineRequest request = new AutomationEngine.AutomationEngineRequest();
                request.automationEventId = automationEvent.Id;
                AutomationEngine.execute(new List<AutomationEngine.AutomationEngineRequest>{ request });
                Test.stopTest();
            } catch (Exception ex) {
                expectedException = ex;
            }
        }

        // Verify
        assertJobExecutionNotCreated();
        List<Automation_Event__c> automationEvents = [
            SELECT Id, Target_Action_Job_Execution_Ids__c, Log__c, Target_Action_Number__c
            FROM Automation_Event__c
        ];
        System.assertEquals(1, automationEvents.size(), 'Only one Automation Event should be created');
        System.assert(String.isBlank(automationEvents[0].Target_Action_Job_Execution_Ids__c), 'Job Execution Id should be empty');
        List<AsyncApexJob> apexJobs = [SELECT Id FROM AsyncApexJob ORDER BY CreatedDate ASC];
        System.assertEquals(2, apexJobs.size(), 'Two Apex Job should be created');
        String expectedLog = apexJobs[0].Id + ' - CONNECT: SUCCESS / ' + apexJobs[1].Id + ' - EXECUTE: ' + errorMessage;
        System.assertEquals(expectedLog, automationEvents[0].Log__c, 'Log should match');
        System.assertNotEquals(null, expectedException, 'An exception should be thrown');
        System.assertEquals(errorMessage, expectedException.getMessage(), 'Exception message does not match');
        System.assertEquals(1, automationEvents[0].Target_Action_Number__c, 'Number of Executions should match');
    }

    @IsTest
    private static void automationEngineWithMultipleExecutions() {
        // Setup
        Exception expectedException;
        final String errorMessage = 'Throw Exception';
        System.runAs(getUser()) {
            Deployment_Flow__c pipeline = [SELECT Id FROM Deployment_Flow__c LIMIT 1];
            new AutomationEvent()
                .pipelineId(pipeline.Id)
                .actionName(ActionConstants.PROMOTION_DEPLOYMENT)
                .actionStatus(AutomationRuleConstants.SOURCE_ACTION_STATUS_SUCCESSFUL)
                .actionResult('Multiple Executions')
                .persist();

            Automation_Event__c automationEvent = [SELECT Id FROM Automation_Event__c LIMIT 1];

            // Exercise
            try {
                Test.startTest();
                AutomationEngine.AutomationEngineRequest request = new AutomationEngine.AutomationEngineRequest();
                request.automationEventId = automationEvent.Id;
                AutomationEngine.execute(new List<AutomationEngine.AutomationEngineRequest>{ request });
                Test.stopTest();
            } catch (Exception ex) {
                expectedException = ex;
            }
        }

        // Verify
        List<JobExecution__c> resultJobExecutions = [SELECT Id, ErrorMessage__c FROM JobExecution__c];
        System.assertEquals(2, resultJobExecutions.size(), 'Two Job Executions should be created');
        System.assertEquals('Mock 1', resultJobExecutions[0].ErrorMessage__c, 'Job Execution should contain the information from the event');
        System.assertEquals('Mock 2', resultJobExecutions[1].ErrorMessage__c, 'Job Execution should contain the information from the event');
        List<Automation_Event__c> automationEvents = [
            SELECT Id, Target_Action_Job_Execution_Ids__c, Log__c, Target_Action_Number__c
            FROM Automation_Event__c
        ];
        System.assertEquals(1, automationEvents.size(), 'Only one Automation Event should be created');
        String expectedJobExecutionIds = resultJobExecutions[0].Id + ', ' + resultJobExecutions[1].Id;
        System.assertEquals(expectedJobExecutionIds, automationEvents[0].Target_Action_Job_Execution_Ids__c, 'Job Execution Id should match');
        List<AsyncApexJob> apexJobs = [SELECT Id FROM AsyncApexJob ORDER BY CreatedDate ASC];
        System.assertEquals(4, apexJobs.size(), 'Four Apex Jobs should be created');
        String expectedLog =
            apexJobs[0].Id +
            ' - CONNECT: SUCCESS / ' +
            apexJobs[1].Id +
            ' - EXECUTE: SUCCESS (' +
            resultJobExecutions[0].Id +
            ') / ';
        expectedLog += apexJobs[2].Id + ' - EXECUTE: SUCCESS (' + resultJobExecutions[1].Id + ') / ';
        expectedLog += apexJobs[3].Id + ' - EXECUTE: ' + errorMessage;
        System.assertEquals(expectedLog, automationEvents[0].Log__c, 'Log should match');
        System.assertEquals(errorMessage, expectedException.getMessage(), 'Exception message does not match');
        System.assertEquals(3, automationEvents[0].Target_Action_Number__c, 'Number of Executions should match');
    }

    @IsTest
    private static void automationEngineWithMultipleEventsForSingleRule() {
        // Setup
        System.runAs(getUser()) {
            Deployment_Flow__c pipeline = [SELECT Id FROM Deployment_Flow__c LIMIT 1];
            new AutomationEvent()
                .pipelineId(pipeline.Id)
                .actionName(ActionConstants.PROMOTION_DEPLOYMENT)
                .actionStatus(AutomationRuleConstants.SOURCE_ACTION_STATUS_SUCCESSFUL)
                .actionResult('Test 1');
            new AutomationEvent()
                .pipelineId(pipeline.Id)
                .actionName(ActionConstants.PROMOTION_DEPLOYMENT)
                .actionStatus(AutomationRuleConstants.SOURCE_ACTION_STATUS_SUCCESSFUL)
                .actionResult('Test 2');
            new AutomationEvent()
                .pipelineId(pipeline.Id)
                .actionName(ActionConstants.PROMOTION_DEPLOYMENT)
                .actionStatus(AutomationRuleConstants.SOURCE_ACTION_STATUS_SUCCESSFUL)
                .actionResult('Test 3')
                .persist();

            List<Automation_Event__c> automationEvents = [SELECT Id FROM Automation_Event__c];

            // Exercise
            Test.startTest();
            List<AutomationEngine.AutomationEngineRequest> requests = new List<AutomationEngine.AutomationEngineRequest>();
            for (Automation_Event__c automationEvent : automationEvents) {
                AutomationEngine.AutomationEngineRequest request = new AutomationEngine.AutomationEngineRequest();
                request.automationEventId = automationEvent.Id;
                requests.add(request);
            }
            AutomationEngine.execute(requests);
            Test.stopTest();
        }

        // Verify
        List<JobExecution__c> resultJobExecutions = [SELECT Id, ErrorMessage__c FROM JobExecution__c ORDER BY CreatedDate ASC];
        System.assertEquals(1, resultJobExecutions.size(), 'One Job Execution should be created');
        System.assertEquals('Test 1Test 2Test 3', resultJobExecutions[0].ErrorMessage__c, 'Job Execution should contain the information from all the events');
        List<Automation_Event__c> automationEvents = [
            SELECT Id, Target_Action_Job_Execution_Ids__c, Log__c, Target_Action_Number__c
            FROM Automation_Event__c
            ORDER BY CreatedDate ASC
        ];

        List<AsyncApexJob> apexJobs = [SELECT Id FROM AsyncApexJob ORDER BY CreatedDate ASC];
        System.assertEquals(2, apexJobs.size(), 'Two Apex Jobs should be created');

        System.assertEquals(3, automationEvents.size(), 'Three Automation Events should be created');
        for(Automation_Event__c event : automationEvents) {
            System.assertEquals(resultJobExecutions[0].Id, event.Target_Action_Job_Execution_Ids__c, 'Job Execution Id should match');
            String expectedLog = apexJobs[0].Id + ' - CONNECT: SUCCESS / ' + apexJobs[1].Id + ' - EXECUTE: SUCCESS (' + resultJobExecutions[0].Id + ')';
            System.assertEquals(expectedLog, automationEvents[0].Log__c, 'Log should match');
            System.assertEquals(1, automationEvents[0].Target_Action_Number__c, 'Number of Executions should match');
        }
    }

    @IsTest
    private static void automationEngineWithMultipleEventsForDifferentRules() {
        // Setup
        System.runAs(getUser()) {
            Deployment_Flow__c pipeline = [SELECT Id FROM Deployment_Flow__c LIMIT 1];

            new AutomationRule()
                .pipeline(pipeline.Id)
                .active()
                .sourceAction(ActionConstants.COMMIT_ACTION)
                .automatedAction(ActionConstants.PROMOTION)
                .sourceActionStatus(AutomationRuleConstants.SOURCE_ACTION_STATUS_SUCCESSFUL)
                .connector(AutomationRuleConstants.AUTOMATION_CONNECTOR_CUSTOM)
                .execution(AutomationRuleConstants.EXECUTION_IMMEDIATE)
                .customConnector(AutomationConnectorMock.class.getName())
                .persist();

            new AutomationEvent()
                .pipelineId(pipeline.Id)
                .actionName(ActionConstants.COMMIT_ACTION)
                .actionStatus(AutomationRuleConstants.SOURCE_ACTION_STATUS_SUCCESSFUL)
                .actionResult('Test 1');
            new AutomationEvent()
                .pipelineId(pipeline.Id)
                .actionName(ActionConstants.COMMIT_ACTION)
                .actionStatus(AutomationRuleConstants.SOURCE_ACTION_STATUS_SUCCESSFUL)
                .actionResult('Test 2');
            new AutomationEvent()
                .pipelineId(pipeline.Id)
                .actionName(ActionConstants.PROMOTION_DEPLOYMENT)
                .actionStatus(AutomationRuleConstants.SOURCE_ACTION_STATUS_SUCCESSFUL)
                .actionResult('Test 3')
                .persist();

            List<Automation_Event__c> automationEvents = [SELECT Id FROM Automation_Event__c];

            // Exercise
            Test.startTest();
            List<AutomationEngine.AutomationEngineRequest> requests = new List<AutomationEngine.AutomationEngineRequest>();
            for (Automation_Event__c automationEvent : automationEvents) {
                AutomationEngine.AutomationEngineRequest request = new AutomationEngine.AutomationEngineRequest();
                request.automationEventId = automationEvent.Id;
                requests.add(request);
            }
            AutomationEngine.execute(requests);
            Test.stopTest();
        }

        // Verify
        List<JobExecution__c> resultJobExecutions = [SELECT Id, ErrorMessage__c FROM JobExecution__c ORDER BY CreatedDate ASC];
        System.assertEquals(2, resultJobExecutions.size(), 'Two Job Executions should be created');
        System.assertEquals('Test 1Test 2', resultJobExecutions[0].ErrorMessage__c, 'Job Execution should contain the information from all the events');
        System.assertEquals('Test 3', resultJobExecutions[1].ErrorMessage__c, 'Job Execution should contain the information from all the events');
        List<Automation_Event__c> automationEvents = [
            SELECT Id, Target_Action_Job_Execution_Ids__c, Log__c, Target_Action_Number__c
            FROM Automation_Event__c
            ORDER BY CreatedDate ASC
        ];

        List<AsyncApexJob> apexJobs = [SELECT Id FROM AsyncApexJob ORDER BY CreatedDate ASC];
        System.assertEquals(4, apexJobs.size(), 'Four Apex Jobs should be created');

        System.assertEquals(3, automationEvents.size(), 'Three Automation Events should be created');
        System.assertEquals(resultJobExecutions[0].Id, automationEvents[0].Target_Action_Job_Execution_Ids__c, 'Job Execution Id should match');
        String expectedLog = apexJobs[0].Id + ' - CONNECT: SUCCESS / ' + apexJobs[1].Id + ' - EXECUTE: SUCCESS (' + resultJobExecutions[0].Id + ')';
        System.assertEquals(expectedLog, automationEvents[0].Log__c, 'Log should match');
        System.assertEquals(1, automationEvents[0].Target_Action_Number__c, 'Number of Executions should match');

        System.assertEquals(resultJobExecutions[0].Id, automationEvents[1].Target_Action_Job_Execution_Ids__c, 'Job Execution Id should match');
        expectedLog = apexJobs[0].Id + ' - CONNECT: SUCCESS / ' + apexJobs[1].Id + ' - EXECUTE: SUCCESS (' + resultJobExecutions[0].Id + ')';
        System.assertEquals(expectedLog, automationEvents[1].Log__c, 'Log should match');
        System.assertEquals(1, automationEvents[1].Target_Action_Number__c, 'Number of Executions should match');

        System.assertEquals(resultJobExecutions[1].Id, automationEvents[2].Target_Action_Job_Execution_Ids__c, 'Job Execution Id should match');
        expectedLog = apexJobs[2].Id + ' - CONNECT: SUCCESS / ' + apexJobs[3].Id + ' - EXECUTE: SUCCESS (' + resultJobExecutions[1].Id + ')';
        System.assertEquals(expectedLog, automationEvents[2].Log__c, 'Log should match');
        System.assertEquals(1, automationEvents[2].Target_Action_Number__c, 'Number of Executions should match');
    }

    private static void assertJobExecutionNotCreated() {
        List<JobExecution__c> resultJobExecutions = [SELECT Id, ErrorMessage__c FROM JobExecution__c];
        System.assertEquals(0, resultJobExecutions.size(), 'Job Execution should not be created');
    }

    private static void assertAutomationEventNotModified() {
        List<Automation_Event__c> automationEvents = [
            SELECT Id, Target_Action_Job_Execution_Ids__c, Log__c, Target_Action_Number__c
            FROM Automation_Event__c
        ];
        System.assertEquals(1, automationEvents.size(), 'Only one Automation Event should be created');
        System.assert(String.isBlank(automationEvents[0].Target_Action_Job_Execution_Ids__c), 'Job Execution Id should be empty');
        System.assert(String.isBlank(automationEvents[0].Log__c), 'Log should be empty');
        System.assertEquals(0, automationEvents[0].Target_Action_Number__c, 'Number of Executions should match');
    }

    private static User getUser() {
        return [SELECT Id FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1];
    }
}