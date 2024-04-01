@isTest
private class ManualTestsScriptSelectorCtrlTest {
    @isTest
    private static void getRecentlyViewedTestScripts() {
        System.runAs(getRunAsUser()) {
            // Setup
            Test_Script__c script = [SELECT Id, Name, Test_Title__c FROM Test_Script__c WHERE Test_Title__c = 'Login to the Org' LIMIT 1];
            ManualTestsScriptSelectorCtrl.mockTestScripts = new List<Test_Script__c>{ script };

            // Exercise
            List<LookupSearchResult> recentlyViewedScripts = ManualTestsScriptSelectorCtrl.getRecentlyViewedTestScripts();

            // Verify
            System.assertEquals(1, recentlyViewedScripts.size(), 'List should have 1 script');
            System.assertEquals(script.Name, recentlyViewedScripts[0].getTitle(), 'Title should match');
            System.assertEquals('Login to the Org', recentlyViewedScripts[0].getSubtitle(), 'Subtitle should be Login to the Org');
            System.assertEquals(script.Id, recentlyViewedScripts[0].getId(), 'Script Id should match');
            System.assertEquals('standard:article', recentlyViewedScripts[0].getIcon(), 'Icon should be standard:article');
            System.assertEquals('Test Script', recentlyViewedScripts[0].getSObjectType(), 'sObjectType should be Test Script');
        }
    }

    @isTest
    private static void getSelectedScriptDetailsFor() {
        System.runAs(getRunAsUser()) {
            // Setup
            Test_Script__c script = [SELECT Id, Name, Test_Title__c FROM Test_Script__c WHERE Test_Title__c = 'Login to the Org' LIMIT 1];
            Test__c test = [SELECT Id FROM Test__c WHERE Name = 'Test1 for MT' LIMIT 1];

            // Exercise
            List<Test_Script__c> scripts = ManualTestsScriptSelectorCtrl.getSelectedScriptDetailsFor(script.Id, test.Id);

            // Verify
            System.assertEquals(1, scripts.size(), 'List should have 1 script');
            System.assertEquals(2, scripts[0].Script_Steps__r.size(), 'List should have 2 script steps');
            System.assertEquals(1, scripts[0].Test_Suite_Scripts__r.size(), 'List should have 1 test suite script');
        }
    }

    @isTest
    private static void getTestScriptWithoutStepsDetailsFor() {
        System.runAs(getRunAsUser()) {
            // Setup
            String errorMessage;
            Test_Script__c script = [SELECT Id, Name, Test_Title__c FROM Test_Script__c WHERE Test_Title__c = 'No Steps Script' LIMIT 1];
            Test__c test = [SELECT Id FROM Test__c WHERE Name = 'Test1 for MT' LIMIT 1];

            // Exercise
            try {
                ManualTestsScriptSelectorCtrl.getSelectedScriptDetailsFor(script.Id, test.Id);
            } catch (AuraHandledException error) {
                errorMessage = error.getMessage();
            }

            // Verify
            System.assertEquals(Label.SuiteMustContainSteps, errorMessage, 'There is an exception.');
        }
    }

    @isTest
    private static void getTestScriptWithoutIdDetailsFor() {
        System.runAs(getRunAsUser()) {
            // Setup
            String errorMessage;

            // Exercise
            try {
                ManualTestsScriptSelectorCtrl.getSelectedScriptDetailsFor(null, null);
            } catch (AuraHandledException error) {
                errorMessage = error.getMessage();
            }

            // Verify
            System.assertEquals(Label.NODATATODISPLAY, errorMessage, 'There is an exception.');
        }
    }

    @isTest
    private static void getSavedTestScriptsFor() {
        System.runAs(getRunAsUser()) {
            // Setup
            Test__c test = [SELECT Id FROM Test__c WHERE Name = 'Test1 for MT' LIMIT 1];

            // Exercise
            List<Test_Script__c> scripts = ManualTestsScriptSelectorCtrl.getSavedTestScriptsFor(test.Id);

            // Verify
            System.assertEquals(1, scripts.size(), 'List should have 1 script');
            System.assertEquals(2, scripts[0].Script_Steps__r.size(), 'List should have 2 script steps');
            System.assertEquals(1, scripts[0].Test_Suite_Scripts__r.size(), 'List should have 1 test suite script');
        }
    }

    @isTest
    private static void getSavedTestScriptsForException() {
        System.runAs(getRunAsUser()) {
            // Setup
            String errorMessage;

            // Exercise
            try {
                ManualTestsScriptSelectorCtrl.getSavedTestScriptsFor(null);
            } catch (AuraHandledException error) {
                errorMessage = error.getMessage();
            }

            // Verify
            System.assertEquals(Label.NODATATODISPLAY, errorMessage, 'There is an exception.');
        }
    }

    @isTest
    private static void saveWithException() {
        System.runAs(getRunAsUser()) {
            // Setup
            String errorMessage;

            // Exercise
            try {
                ManualTestsScriptSelectorCtrl.saveTestScriptSuitesFor(null, '');
            } catch (AuraHandledException error) {
                errorMessage = error.getMessage();
            }

            // Verify
            System.assertEquals(Label.NODATATODISPLAY, errorMessage, 'There is an exception.');
        }
    }

    @isTest
    private static void saveTestScriptSuitesFor() {
        System.runAs(getRunAsUser()) {
            // Setup
            Test__c test = [SELECT Id FROM Test__c WHERE Name = 'Test1 for MT' LIMIT 1];
            Test_Script__c script = [SELECT Id, Name, Test_Title__c FROM Test_Script__c WHERE Test_Title__c = 'Verify Test Table' LIMIT 1];
            String body = '[{"testScriptId":"' + script.Id + '","order":1,"suiteScriptId":null}]';

            // Exercise
            ManualTestsScriptSelectorCtrl.saveTestScriptSuitesFor(test.Id, body);

            // Verify
            List<Test_Suite_Script__c> testSuiteScripts = [
                SELECT Id, Order__c, Test__c, Test_Script__c
                FROM Test_Suite_Script__c
                WHERE Test__c = :test.Id AND Test_Script__c = :script.Id
                LIMIT 1
            ];
            System.assertEquals(1, testSuiteScripts.size(), 'List should have 1 suite script');
            System.assertEquals(1, testSuiteScripts[0].Order__c, 'The order should be 1');
        }
    }

    @TestSetup
    private static void setup() {
        TestUtilities.getAllMultilicense();
        User user = (User) new User_t().assign(new PermissionSetAssignment_t().copadoUser()).persist();
        System.runAs(user) {
            new CopadoLicense().user(user).enableAll().persist();
            createData();
        }
    }

    private static User getRunAsUser() {
        return [SELECT Name FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1];
    }

    private static void createData() {
        ExtensionConfiguration__c extensionConfiguration = new ExtensionConfiguration__c(
            Name = 'Test EC',
            Active__c = true,
            ExtensionTool__c = 'Manual Tests',
            ExtensionApplication__c = 'Test'
        );
        insert extensionConfiguration;

        Test__c testItem1 = new Test__c(Name = 'Test1 for MT', ExtensionConfiguration__c = extensionConfiguration.Id);
        Test__c testItem2 = new Test__c(Name = 'Test2 for MT', ExtensionConfiguration__c = extensionConfiguration.Id);
        List<Test__c> tests = new List<Test__c>{ testItem1, testItem2 };
        insert tests;

        Project__c project = TestDataFactory.createProject('Test Project', null, true);
        insert project;

        User_Story__c userStory = TestDataFactory.createUserStory('us-0000000', 'Ready for Testing', null, null, null, null);
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

        Test_Suite_Script__c testSuiteScript = new Test_Suite_Script__c(Order__c = 1, Test__c = testItem1.id, Test_Script__c = testScript1.id);
        insert testSuiteScript;
    }
}