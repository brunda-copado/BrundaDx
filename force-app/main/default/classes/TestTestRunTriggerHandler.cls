@isTest
private class TestTestRunTriggerHandler {
    private static final Integer STEPSCOUNT = 25;
    private static final Integer RUNSCOUNT = 10;

    @isTest
    private static void insertTestRunsTest() {
        //Setup
        Test_Script__c testScript = [SELECT id FROM Test_Script__c LIMIT 1];
        Test__c test = [SELECT id FROM Test__c LIMIT 1];

        //Exercise
        createTestRuns(testScript.id, test.id);

        //Verify
        Id userStoryId = [SELECT id FROM User_Story__c LIMIT 1].id;
        Id projectId = [SELECT id FROM Project__c LIMIT 1].id;
        Id sprintId = [SELECT id FROM Sprint__c LIMIT 1].id;
        for (Test_Run__c testRun : [SELECT Id, Project__c, Sprint__c, User_Story__c, Total_Steps__c FROM Test_Run__c]) {
            system.assertEquals(STEPSCOUNT, testRun.Total_Steps__c, 'The step count is 25.');
            system.assertEquals(userStoryId, testRun.User_Story__c, 'User story Id is the same.');
            system.assertEquals(projectId, testRun.Project__c, 'The project is the same.');
            system.assertEquals(sprintId, testRun.Sprint__c, 'The sprint id is the same');
        }
    }

    @isTest
    private static void updateTestRunsTest() {
        //Setup
        Test_Script__c testScript = [SELECT id FROM Test_Script__c LIMIT 1];
        Test__c test = [SELECT id FROM Test__c LIMIT 1];
        createTestRuns(testScript.id, test.id);

        //Exercise
        List<Test_Run__c> testRuns = [SELECT Id, Status__c FROM Test_Run__c];
        for (Test_Run__c testRun : testRuns) {
            testRun.Status__c = 'Passed';
        }
        update testRuns;

        //Verify
        for (Test_Run__c testRun : testRuns) {
            system.assertEquals('Passed', testRun.Status__c, 'The status should update to Passed.');
        }
    }

    @TestSetup
    private static void setup() {
        Project__c testProject = CMtestMethodUtilities.createProject('My Project');
        insert testProject;

        Sprint__c testSprint = CMtestMethodUtilities.createSprint('My Sprint');
        testSprint.Project__c = testProject.Id;
        insert testSprint;

        User_Story__c userStory = CMtestMethodUtilities.createUserStory('testUserStoryName');
        userStory.Project__c = testProject.Id;
        userStory.Sprint__c = testSprint.Id;
        insert userStory;

        Test_Script__c testScript = CMTestMethodUtilities.createTestScript('test');
        testScript.User_Story__c = userStory.Id;
        testScript.Expected_Result__c = 'Some expected result';
        testScript.Introduction__c = 'Some introduction';
        insert testScript;

        List<Test_Script_Step__c> steps = new List<Test_Script_Step__c>();
        for (Integer counter = 1; counter <= STEPSCOUNT; counter++) {
            Test_Script_Step__c scriptStep = CMTestMethodUtilities.createTestScriptStep(testScript.Id, counter + ' step title');
            scriptStep.Action_Description__c = '' + counter + ' some text';
            scriptStep.Expected_Result__c = '' + counter + ' some text';
            scriptStep.Guidance_notes__c = '' + counter + ' some text';
            scriptStep.Order__c = counter;
            steps.add(scriptStep);
        }
        insert steps;

        ExtensionConfiguration__c extensionConfiguration = new ExtensionConfiguration__c(
            Active__c = true,
            ExtensionTool__c = 'Manual Tests',
            ExtensionApplication__c = 'Test'
        );
        insert extensionConfiguration;

        Test__c testItem = new Test__c(ExtensionConfiguration__c = extensionConfiguration.Id);
        insert testItem;
    }

    private static void createTestRuns(Id scriptId, Id testId) {
        List<Test_Run__c> runs = new List<Test_Run__c>();
        for (Integer index = 1; index <= RUNSCOUNT; index++) {
            Test_Run__c run = new Test_Run__c();
            run.Test_Script__c = scriptId;
            run.Status__c = 'Ready for testing';
            run.Test__c = testId;
            runs.add(run);
        }
        insert runs;
    }
}