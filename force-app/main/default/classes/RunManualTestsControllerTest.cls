@IsTest
private class RunManualTestsControllerTest {
    private static final String EXTENSION_CONFIGURATION_NAME = 'Mock Extension Configuration';
    private static final String TEST_TOOL_NAME = 'Manual Tests';
    private static String failedOutput;
    private static String inProgressOutput;
    private static String passedOutput;

    @IsTest
    private static void retrieveTestRunsHappyPath() {
        System.runAs(getRunAsUser()) {
            // Setup
            List<Id> testIds = createTestRecords();

            // Exercise
            List<RunManualTestsController.TestRunRow> rows = RunManualTestsController.retrieveTestRuns(testIds[0]);

            // Verify
            System.assertEquals(2, rows.size(), '2 Test Run rows should be available.');
            System.assertEquals(2, rows[0].testScript.Script_Steps__r.size(), 'Test Script1 has 2 Test Script Steps');
            System.assertEquals(true, rows[0].testRunId != null, 'Test Script1 has a related test run which is in progress');
            System.assertEquals(2, rows[0].testRunSteps.size(), 'Test Script1 has two test run steps');
        }
    }

    @IsTest
    private static void saveTestRunsForFailedResult() {
        System.runAs(getRunAsUser()) {
            // Setup
            List<Id> testIds = createTestRecords();

            // Exercise

            RunManualTestsController.saveTestRuns(failedOutput, testIds[0]);

            // Verify
            List<Test_Run__c> testRuns = getTestRuns(testIds[0]);
            System.assertEquals(2, testRuns.size(), 'There should be 2 test runs associated with given Test & Tester Combination.');
            System.assertEquals(2, testRuns[0].Test_Run_Steps__r.size(), 'The test run should have 2 test run steps');
            System.assertEquals('Failed', testRuns[0].Test_Run_Steps__r[1].Status__c, 'The test run step status should be failed');
            System.assertEquals('Comments', testRuns[0].Test_Run_Steps__r[1].Actual_Result__c, 'The test run step should have comments');
            System.assertEquals('Failed', testRuns[0].Status__c, 'The test run status should be failed');
            System.assertEquals('Failed', getResultStatus(testIds[0]), 'The result status should be failed.');
        }
    }

    @IsTest
    private static void saveTestRunsForInProgressResult() {
        System.runAs(getRunAsUser()) {
            // Setup
            List<Id> testIds = createTestRecords();

            // Exercise
            RunManualTestsController.saveTestRuns(inProgressOutput, testIds[1]);

            // Verify
            List<Test_Run__c> testRuns = getTestRuns(testIds[1]);
            System.assertEquals(2, testRuns.size(), 'There should be 2 test runs associated with given Test & Tester Combination.');
            System.assertEquals(2, testRuns[0].Test_Run_Steps__r.size(), 'The test run should have 2 test run steps');
            System.assertEquals(null, testRuns[0].Test_Run_Steps__r[1].Status__c, 'The test run step status should be null');
            System.assertEquals('Comments from Tester', testRuns[1].Test_Run_Steps__r[1].Actual_Result__c, 'The test run step should have comments');
            System.assertEquals('In progress', testRuns[0].Status__c, 'The test run status should be in progress');
            System.assertEquals('In Progress', getResultStatus(testIds[1]), 'The result status should be in progress as AC is not met');
        }
    }

    @IsTest
    private static void saveTestRunsForPassedResult() {
        System.runAs(getRunAsUser()) {
            // Setup
            List<Id> testIds = createTestRecords();

            // Exercise
            RunManualTestsController.saveTestRuns(passedOutput, testIds[2]);

            // Verify
            List<Test_Run__c> testRuns = getTestRuns(testIds[2]);
            System.assertEquals(2, testRuns.size(), 'There should be 2 test runs associated with given Test & Tester Combination.');
            System.assertEquals(2, testRuns[0].Test_Run_Steps__r.size(), 'The test run should have 2 test run steps');
            System.assertEquals('Passed', testRuns[0].Test_Run_Steps__r[1].Status__c, 'The test run step status should be passed');
            System.assertEquals(null, testRuns[1].Test_Run_Steps__r[1].Actual_Result__c, 'The test run step comments should be blank');
            System.assertEquals('Passed', testRuns[1].Status__c, 'The test run status should be passes');
            System.assertEquals('Success', getResultStatus(testIds[2]), 'The result status should be success.');
        }
    }

    @IsTest
    private static void saveTestRunsEmptyBody() {
        System.runAs(getRunAsUser()) {
            // Setup
            List<Id> testIds = createTestRecords();

            String errorMessage;

            // Exercise
            try {
                RunManualTestsController.saveTestRuns('', testIds[0]);
            } catch (AuraHandledException error) {
                errorMessage = error.getMessage();
            }

            // Verify
            System.assertEquals(true, String.isNotBlank(errorMessage), 'There is an exception.');
        }
    }

    @IsTest
    private static void saveTestRunsException() {
        System.runAs(getRunAsUser()) {
            //Setup
            String errorMessage;

            // Exercise
            try {
                RunManualTestsController.saveTestRuns(failedOutput, null);
            } catch (AuraHandledException error) {
                errorMessage = error.getMessage();
            }

            // Verify
            System.assertEquals(true, String.isNotBlank(errorMessage), 'There is an exception.');
        }
    }

    @TestSetup
    private static void setup() {
        TestUtilities.getAllMultilicense();
        User user = (User) new User_t()
            // @ToDo: To be replaced by AQF Perm sets
            .assign(new PermissionSetAssignment_t().copadoUser())
            .assign(new PermissionSetAssignment_t().jobEngine())
            .persist();
        System.runAs(user) {
            new CopadoLicense().user(user).enableAll().persist();
            insertData();
        }
    }

    private static void insertData() {
        createExtensionConfiguration();
    }

    private static List<Id> createTestRecords() {
        Application_Feature__c feature = new Application_Feature__c();
        insert feature;

        User_Story__c userStory = new User_Story__c(US_Feature__c = feature.Id);
        insert userStory;

        Test_Script__c testScript1 = TestDataFactory.createTestScript('Login to the Org', userStory.Id);
        Test_Script__c testScript2 = TestDataFactory.createTestScript('Verify Test Table', userStory.Id);
        Test_Script__c testScript3 = TestDataFactory.createTestScript('No Steps Script', userStory.Id);
        List<Test_Script__c> testScripts = new List<Test_Script__c>{ testScript1, testScript2, testScript3 };
        insert testScripts;

        Test_Script_Step__c step1 = TestDataFactory.createTestScriptStep(
            1,
            'Enter username',
            'Enter the username',
            'Username should be visible',
            testScript1.Id
        );
        Test_Script_Step__c step2 = TestDataFactory.createTestScriptStep(
            2,
            'Enter password',
            'Enter the password',
            'Password should be hidden',
            testScript1.Id
        );
        Test_Script_Step__c step3 = TestDataFactory.createTestScriptStep(
            1,
            'Create a US',
            'Enter details to create a US',
            'US should be created',
            testScript2.Id
        );
        Test_Script_Step__c step4 = TestDataFactory.createTestScriptStep(
            2,
            'Verify Test Tab',
            'Navigate to Test tab',
            'Test table should be visible',
            testScript2.Id
        );
        List<Test_Script_Step__c> steps = new List<Test_Script_Step__c>{ step1, step2, step3, step4 };
        insert steps;

        ExtensionConfiguration__c extensionConfiguration = getExtensionConfiguration();

        String acceptanceCriteria =
            '[{"testerScope":"User","tester":{"icon":"standard:user","id":"' +
            UserInfo.getUserId() +
            '","sObjectType":"User","subtitle":"User • Test User","title":"Test User","titleFormatted":"<strong>Tes</strong>t User","subtitleFormatted":"User • <strong>Tes</strong>t User"},"type":"Required","minimumTesters":1,"editableTesters":false}]';

        String groupAc =
            '[{"testerScope":"Group","tester":{"icon":"standard:groups","id":"00G09000003gbdNEAQ","sObjectType":"Group","subtitle":"Group • Test","title":"Test","titleFormatted":"Test","subtitleFormatted":"Group • Test"},"type":"Required","minimumTesters":"2","editableTesters":true},{"testerScope":"User","tester":{"icon":"standard:user","id":"' +
            UserInfo.getUserId() +
            '","sObjectType":"User","subtitle":"User • Test User","title":"Test User","titleFormatted":"<strong>Tes</strong>t User","subtitleFormatted":"User • <strong>Tes</strong>t User"},"type":"Required","minimumTesters":1,"editableTesters":false}]';

        Test__c test = new Test__c(Configuration__c = 't3', ExtensionConfiguration__c = extensionConfiguration.Id, User_Story__c = userStory.Id);
        Test__c test2 = new Test__c(Configuration__c = 't3', ExtensionConfiguration__c = extensionConfiguration.Id, User_Story__c = userStory.Id);
        Test__c test3 = new Test__c(Configuration__c = 't3', ExtensionConfiguration__c = extensionConfiguration.Id, User_Story__c = userStory.Id);
        List<Test__c> tests = new List<Test__c>{ test, test2, test3 };
        insert tests;
        test.AcceptanceCriteria__c = acceptanceCriteria;
        test2.AcceptanceCriteria__c = groupAc;
        test3.AcceptanceCriteria__c = acceptanceCriteria;
        update tests;

        Test_Suite_Script__c testSuiteScript1 = new Test_Suite_Script__c(Order__c = 1, Test__c = tests[0].id, Test_Script__c = testScript1.id);
        Test_Suite_Script__c testSuiteScript2 = new Test_Suite_Script__c(Order__c = 2, Test__c = tests[0].id, Test_Script__c = testScript2.id);
        Test_Suite_Script__c testSuiteScript3 = new Test_Suite_Script__c(Order__c = 1, Test__c = tests[1].id, Test_Script__c = testScript1.id);
        Test_Suite_Script__c testSuiteScript4 = new Test_Suite_Script__c(Order__c = 2, Test__c = tests[1].id, Test_Script__c = testScript2.id);
        Test_Suite_Script__c testSuiteScript5 = new Test_Suite_Script__c(Order__c = 1, Test__c = tests[2].id, Test_Script__c = testScript1.id);
        Test_Suite_Script__c testSuiteScript6 = new Test_Suite_Script__c(Order__c = 2, Test__c = tests[2].id, Test_Script__c = testScript2.id);
        List<Test_Suite_Script__c> suiteScripts = new List<Test_Suite_Script__c>{
            testSuiteScript1,
            testSuiteScript2,
            testSuiteScript3,
            testSuiteScript4,
            testSuiteScript5,
            testSuiteScript6
        };
        insert suiteScripts;

        Test_Run__c run1 = new Test_Run__c(
            Test_Script__c = testScript1.id,
            Tester__c = UserInfo.getUserId(),
            Test__c = tests[0].id,
            Status__c = 'In Progress'
        );
        Test_Run__c run2 = new Test_Run__c(
            Test_Script__c = testScript2.id,
            Tester__c = UserInfo.getUserId(),
            Test__c = tests[0].id,
            Status__c = 'In Progress'
        );
        List<Test_Run__c> testRuns = new List<Test_Run__c>{ run1, run2 };
        insert testRuns;

        failedOutput =
            '[{"scriptId":"' +
            testScript1.id +
            '","scriptStepId":"' +
            step1.id +
            '","status":"Passed","actualResult":"Comments","testRunId":"' +
            run1.id +
            '"},{"scriptId":"' +
            testScript1.id +
            '","scriptStepId":"' +
            step2.id +
            '","status":"Failed","actualResult":"Comments","testRunId":"' +
            run1.id +
            '"},{"scriptId":"' +
            testScript2.id +
            '","scriptStepId":"' +
            step3.id +
            '","status":"Passed","actualResult":"","testRunId":"' +
            run2.id +
            '"},{"scriptId":"' +
            testScript2.id +
            '","scriptStepId":"' +
            step4.id +
            '","status":"","actualResult":"","testRunId":"' +
            run2.id +
            '"}]';

        inProgressOutput =
            '[{"scriptId":"' +
            testScript1.id +
            '","scriptStepId":"' +
            step1.id +
            '","status":"Passed","actualResult":"","testRunId":null},{"scriptId":"' +
            testScript1.id +
            '","scriptStepId":"' +
            step2.id +
            '","status":"","actualResult":"","testRunId":null},{"scriptId":"' +
            testScript2.id +
            '","scriptStepId":"' +
            step3.id +
            '","status":"Passed","actualResult":"Dummy Comments","testRunId":null},{"scriptId":"' +
            testScript2.id +
            '","scriptStepId":"' +
            step4.id +
            '","status":"Passed","actualResult":"Comments from Tester","testRunId":null}]';

        passedOutput =
            '[{"scriptId":"' +
            testScript1.id +
            '","scriptStepId":"' +
            step1.id +
            '","status":"Passed","actualResult":"","testRunId":null},{"scriptId":"' +
            testScript1.id +
            '","scriptStepId":"' +
            step2.id +
            '","status":"Passed","actualResult":"","testRunId":null},{"scriptId":"' +
            testScript2.id +
            '","scriptStepId":"' +
            step3.id +
            '","status":"Passed","actualResult":"","testRunId":null},{"scriptId":"' +
            testScript2.id +
            '","scriptStepId":"' +
            step4.id +
            '","status":"Passed","actualResult":"","testRunId":null}]';

        Result__c result = new Result__c(Job_Type__c = 'Manual Tests', Test__c = tests[0].id, Status__c = 'In Progress');
        Result__c result2 = new Result__c(Job_Type__c = 'Manual Tests', Test__c = tests[1].id, Status__c = 'Success');
        List<Result__c> results = new List<Result__c>{ result, result2 };
        insert results;

        return new List<Id>{ test.Id, test2.Id, test3.Id };
    }

    private static void createExtensionConfiguration() {
        insert new ExtensionConfiguration__c(
            Name = EXTENSION_CONFIGURATION_NAME,
            ExtensionApplication__c = 'Test',
            ExtensionTool__c = TEST_TOOL_NAME,
            Active__c = true
        );
    }

    private static ExtensionConfiguration__c getExtensionConfiguration() {
        return [SELECT Id FROM ExtensionConfiguration__c LIMIT 1];
    }

    private static User getRunAsUser() {
        return [SELECT Id, FirstName, LastName, Name FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1];
    }

    private static List<Test_Run__c> getTestRuns(Id testId) {
        return [
            SELECT id, Status__c, (SELECT id, Status__c, Actual_Result__c FROM Test_Run_Steps__r)
            FROM Test_Run__c
            WHERE Test__c = :testId AND Tester__c = :UserInfo.getUserId()
        ];
    }

    private static String getResultStatus(Id testId) {
        return [SELECT Status__c FROM Result__c WHERE Test__c = :testId ORDER BY CreatedDate DESC LIMIT 1].Status__c;
    }
}