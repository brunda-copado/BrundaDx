@isTest
private class SprintTriggerHandlerTest {
    private static final String STANDARD_USER_QUERY = 'SELECT Username FROM User WHERE Username = \'test_user@myorg.com\' LIMIT 1';

    @testSetup
    static void setupData() {
        TestUtilities.enableLicenses(2, 2, 2, 2, 2, 30);
        ITestDefaults userCreation = new CopadoSetupTestDefaults.UserDefaults().createRunAsUsers();
        userCreation.executeDML();
    }

    @isTest
    private static void testSprintUpdate() {
        User currentUser = Database.query(STANDARD_USER_QUERY);
        TestUtilities.assignLicense(currentUser.Username, true, true, true, true, true);
        System.runAs(currentUser) {
            Project__c testProject = CMTestMethodUtilities.createProject('my project');
            insert testProject;

            Sprint__c testSprint = CMTestMethodUtilities.createSprint('my sprint');
            testSprint.Project__c = testProject.Id;
            testSprint.Status__c = 'Draft';
            insert testSprint;

            List<User_Story__c> userStories = new List<User_Story__c>();
            for (Integer i = 0; i < 20; i++) {
                User_Story__c testUserStory = CMTestMethodUtilities.createUserStory('test');
                testUserStory.Sprint__c = testSprint.Id;
                testUserStory.Project__c = null;
                testUserStory.Status__c = 'Draft';
                testUserStory.Story_Points_Other__c = 3;
                userStories.add(testUserStory);
            }
            insert userStories;

            Sprint__c sprintRecord = [
                SELECT Id, Status__c, Planned_Velocity__c, Actual_Velocity__c, InitialPlannedVelocity__c
                FROM Sprint__c
                WHERE Id = :testSprint.Id
                LIMIT 1
            ];

            system.assertEquals(sprintRecord.Planned_Velocity__c, 60, 'Sprint Planned Velocity should be 60.');
            system.assertEquals(sprintRecord.Actual_Velocity__c, null, 'Sprint Actual Velocity should be blank.');
            system.assertEquals(sprintRecord.InitialPlannedVelocity__c, null, 'Sprint Initial Planned Velocity should be blank.');

            Test.startTest();
            testSprint.Status__c = 'In progress';
            update testSprint;
            Test.stopTest();

            Sprint__c sprint = [
                SELECT Id, Status__c, Planned_Velocity__c, Actual_Velocity__c, InitialPlannedVelocity__c
                FROM Sprint__c
                WHERE Id = :testSprint.Id
                LIMIT 1
            ];

            system.assertEquals(sprint.Planned_Velocity__c, 60, 'Sprint Planned Velocity should be 60.');
            system.assertEquals(sprint.Actual_Velocity__c, null, 'Sprint Actual Velocity should be blank.');
            system.assertEquals(sprint.InitialPlannedVelocity__c, 60, 'Sprint Initial Planned Velocity should be 60.');
        }
    }

    @isTest
    private static void testSprintUpdateBulk() {
        User currentUser = Database.query(STANDARD_USER_QUERY);
        TestUtilities.assignLicense(currentUser.Username, true, true, true, true, true);
        System.runAs(currentUser) {
            Project__c testProject = CMTestMethodUtilities.createProject('my project');
            insert testProject;

            List<Sprint__c> sprints = new List<Sprint__c>();
            for (Integer i = 0; i < 155; i++) {
                Sprint__c testSprint = CMTestMethodUtilities.createSprint('my sprint');
                testSprint.Project__c = testProject.Id;
                testSprint.Status__c = 'Draft';
                sprints.add(testSprint);
            }
            insert sprints;

            List<User_Story__c> userStories = new List<User_Story__c>();
            for (Sprint__c eachSprint : sprints) {
                for (Integer i = 0; i < 20; i++) {
                    User_Story__c testUserStory = CMTestMethodUtilities.createUserStory('test');
                    testUserStory.Sprint__c = eachSprint.Id;
                    testUserStory.Project__c = null;
                    testUserStory.Status__c = 'Draft';
                    testUserStory.Story_Points_Other__c = 3;
                    testUserStory.Planned_Points_Other__c = 2;
                    userStories.add(testUserStory);
                }
            }
            insert userStories;

            Sprint__c sprintRecord = [
                SELECT Id, Status__c, Planned_Velocity__c, Actual_Velocity__c, InitialPlannedVelocity__c
                FROM Sprint__c
                LIMIT 1
            ];

            system.assertEquals(sprintRecord.Planned_Velocity__c, 100, 'Sprint Planned Velocity should be 100.');
            system.assertEquals(sprintRecord.Actual_Velocity__c, null, 'Sprint Actual Velocity should be blank.');
            system.assertEquals(sprintRecord.InitialPlannedVelocity__c, null, 'Sprint Inidial Planned Velocity should be blank.');

            Test.startTest();
            List<Sprint__c> sprintsToUpdate = new List<Sprint__c>();
            for (Sprint__c eachSprint : sprints) {
                eachSprint.Status__c = 'In progress';
                sprintsToUpdate.add(eachSprint);
            }
            update sprintsToUpdate;
            Test.stopTest();

            for (Sprint__c sprint : [SELECT Id, Planned_Velocity__c, Actual_Velocity__c, InitialPlannedVelocity__c FROM Sprint__c]) {
                system.assertEquals(sprint.Planned_Velocity__c, 100, 'Sprint Planned Velocity should be 100.');
                system.assertEquals(sprint.Actual_Velocity__c, null, 'Sprint Actual Velocity should be blank.');
                system.assertEquals(sprint.InitialPlannedVelocity__c, 100, 'Sprint Initial Planned Velocity should be 100.');
            }
        }
    }
}