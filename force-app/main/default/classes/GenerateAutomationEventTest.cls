@IsTest
private class GenerateAutomationEventTest {

    @TestSetup
    private static void makeData() {
        TestUtilities.getAllMultilicense();
        new User_t()
            .assign(new PermissionSetAssignment_t().copadoUser())
            .assign(new PermissionSetAssignment_t().executeAutomations())
            .alias('TestUsr1')
            .standard()
            .persist();
        new User_t()
            .assign(new PermissionSetAssignment_t().copadoUser())
            .alias('TestUsr2')
            .standard()
            .persist();
        User adminUser = (User) new User_t()
            .assign(new PermissionSetAssignment_t().copadoUser())
            .admin()
            .persist();

        System.runAs(adminUser) {
            new CopadoLicense().user(adminUser).enableAll().persist();

            Environment devEnvironment = new Environment().name('Dev1').platform('Other').add(new Credential());
            Environment uatEnvironment = new Environment().name('UAT').platform('Other').add(new Credential());
            Environment prodEnvironment = new Environment().name('PROD').platform('Other').add(new Credential());
            StageConnection devStageConnection = new StageConnection().stage(new Stage().name('Dev').metaStage('Build'));
            StageConnection uatStageConnection = new StageConnection().stage(new Stage().name('UAT').metaStage('Build'));
            Pipeline aPipeline = new Pipeline()
                .setPlatform('Other')
                .add(
                    new Connection(
                        devEnvironment,
                        uatEnvironment
                    ).branch('dev')
                    .stageConnection(devStageConnection)
                )
                .add(
                    new Connection(
                        uatEnvironment,
                        prodEnvironment
                    ).branch('uat')
                    .stageConnection(uatStageConnection)
                )
                .add(devStageConnection)
                .add(uatStageConnection)
                .active(true);

            new JobExecution()
                .pipeline(aPipeline)
                .destination(devEnvironment)
                .status(AutomationRuleConstants.SOURCE_ACTION_STATUS_SUCCESSFUL)
                .persist();
        }
    }
    
    @IsTest
    private static void createEventWithPermissions() {
        // Setup
        JobExecution__c job = [SELECT Id, Status__c, Pipeline__c, Destination__c FROM JobExecution__c LIMIT 1];

        Stage__c stage = [SELECT Id FROM Stage__c WHERE Name = 'Dev'];

        System.runAs(getUserWithPermissions()) {
            // Exercise
            Test.startTest();
            new GenerateAutomationEvent(ActionConstants.PROMOTION_DEPLOYMENT, job, 'Test Result').execute();
            Test.stopTest();
        }

        // Verify
        List<Automation_Event__c> resultEvents = [
            SELECT Id, Action_Name__c,
                Action_Status__c,
                Action_Result__c,
                Pipeline_Id__c,
                Environment_Id__c,
                Stage_Id__c,
                Job_Execution_Id__c
            FROM Automation_Event__c
        ];
        System.assertEquals(1, resultEvents.size(), 'One event should be created');
        System.assertEquals(ActionConstants.PROMOTION_DEPLOYMENT, resultEvents[0].Action_Name__c, 'Action Name should match');
        System.assertEquals(AutomationRuleConstants.SOURCE_ACTION_STATUS_SUCCESSFUL, resultEvents[0].Action_Status__c, 'Action Status should match');
        System.assertEquals('Test Result', resultEvents[0].Action_Result__c, 'Action Result should match');
        System.assertEquals(job.Pipeline__c, resultEvents[0].Pipeline_Id__c, 'Pipeline should match with Job Pipeline');
        System.assertEquals(job.Destination__c, resultEvents[0].Environment_Id__c, 'Environment should match with Job Destination');
        System.assertEquals(stage.Id, resultEvents[0].Stage_Id__c, 'Stage should match');
        System.assertEquals(job.Id, resultEvents[0].Job_Execution_Id__c, 'Job Execution Id should match');
    }

    @IsTest
    private static void createEventWithoutPermissions() {
        // Setup
        JobExecution__c job = [SELECT Id, Status__c, Pipeline__c, Destination__c FROM JobExecution__c LIMIT 1];
        Exception expectedException;

        System.runAs(getUserWithoutPermissions()) {
            // Exercise
            Test.startTest();
            try {
                new GenerateAutomationEvent(ActionConstants.PROMOTION_DEPLOYMENT, job, 'Test Result').execute();
            } catch(Exception ex) {
                expectedException = ex;
            }
            Test.stopTest();
        }

        // Verify
        System.assertNotEquals(null, expectedException, 'An exception should be thrown');
        List<Automation_Event__c> resultEvents = [SELECT Id FROM Automation_Event__c];
        System.assertEquals(0, resultEvents.size(), 'No event should be created');
    }

    @IsTest
    private static void createEventOverridingEnvironment() {
        // Setup
        JobExecution__c job = [SELECT Id, Status__c, Pipeline__c, Destination__c FROM JobExecution__c LIMIT 1];

        Stage__c stage = [SELECT Id FROM Stage__c WHERE Name = 'UAT'];
        Environment__c environment = [SELECT Id FROM Environment__c WHERE Name = 'UAT'];

        System.runAs(getUserWithPermissions()) {
            // Exercise
            Test.startTest();
            new GenerateAutomationEvent(ActionConstants.PROMOTION_DEPLOYMENT, job, 'Test Result').setEnvironment(environment.Id).execute();
            Test.stopTest();
        }

        // Verify
        List<Automation_Event__c> resultEvents = [
            SELECT Id, Action_Name__c,
                Action_Status__c,
                Action_Result__c,
                Pipeline_Id__c,
                Environment_Id__c,
                Stage_Id__c,
                Job_Execution_Id__c
            FROM Automation_Event__c
        ];
        System.assertEquals(1, resultEvents.size(), 'One event should be created');
        System.assertEquals(ActionConstants.PROMOTION_DEPLOYMENT, resultEvents[0].Action_Name__c, 'Action Name should match');
        System.assertEquals(AutomationRuleConstants.SOURCE_ACTION_STATUS_SUCCESSFUL, resultEvents[0].Action_Status__c, 'Action Status should match');
        System.assertEquals('Test Result', resultEvents[0].Action_Result__c, 'Action Result should match');
        System.assertEquals(job.Pipeline__c, resultEvents[0].Pipeline_Id__c, 'Pipeline should match with Job Pipeline');
        System.assertEquals(environment.Id, resultEvents[0].Environment_Id__c, 'Environment should match with Job Destination');
        System.assertEquals(stage.Id, resultEvents[0].Stage_Id__c, 'Stage should match');
        System.assertEquals(job.Id, resultEvents[0].Job_Execution_Id__c, 'Job Execution Id should match');
    }

    private static User getUserWithPermissions() {
        return [SELECT Id FROM User WHERE Profile.Name = 'Standard User' AND Alias = 'TestUsr1' ORDER BY CreatedDate DESC LIMIT 1];
    }

    private static User getUserWithoutPermissions() {
        return [SELECT Id FROM User WHERE Profile.Name = 'Standard User' AND Alias = 'TestUsr2'  ORDER BY CreatedDate DESC LIMIT 1];
    }

}