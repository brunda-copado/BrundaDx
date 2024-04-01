@isTest
public with sharing class SprintWallUserStoriesCtrlTest {
    
    @TestSetup
    private static void setup() {
        User standardUser = setupUser();
        System.runAs(standardUser) {
            setupLicense();
            createDefaultTestData();
        }
    }

    @IsTest
    private static void sprintWithSameTeam() {

        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            // Setup
            Sprint__c sprint = [SELECT Id, Name FROM Sprint__c WHERE Name = 'Sprint1' LIMIT 1];

            // Exercise
            Test.startTest();
            Boolean isTeamSame = SprintWallUserStoriesCtrl.isUserStoriesTeamSame(sprint.Id);
            Test.stopTest();

            // Verify
            System.assertEquals(true, isTeamSame, 'Team should be same in Sprint & related User Stories');
        }
    }

    @IsTest
    private static void sprintWithDifferentTeam() {

        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            // Setup
            Sprint__c sprint = [SELECT Id, Name FROM Sprint__c WHERE Name = 'Sprint2' LIMIT 1];

            // Exercise
            Test.startTest();
            Boolean isTeamSame = SprintWallUserStoriesCtrl.isUserStoriesTeamSame(sprint.Id);
            Test.stopTest();

            // Verify
            System.assertEquals(false, isTeamSame, 'Team should not be same in Sprint & related User Stories');
        }
    }

  	@IsTest
    private static void sprintWallKanbanBoard() {

        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            // Setup
            Map<String, String> sprintNameToId = new Map<String, String>(); 
            for (Sprint__c sprint : [SELECT Id, Name FROM Sprint__c]) {
                sprintNameToId.put(sprint.Name, sprint.Id);
            }

            // Exercise
            Test.startTest();
            SprintWallUserStoriesCtrl.KanbanWrapper wrapper = SprintWallUserStoriesCtrl.getKanbanBoardUrl(sprintNameToId.get('Sprint2'));
            SprintWallUserStoriesCtrl.KanbanWrapper oldBoardWithoutSprintWrapper = SprintWallUserStoriesCtrl.getKanbanBoardUrl(sprintNameToId.get('Sprint 3'));
            SprintWallUserStoriesCtrl.KanbanWrapper existingBoardWrapper = SprintWallUserStoriesCtrl.getKanbanBoardUrl(sprintNameToId.get('Sprint 4'));
            Test.stopTest();

            // Verify
            System.assertNotEquals(null, wrapper.url, 'There should be Page Url available');
            System.assertNotEquals(null, oldBoardWithoutSprintWrapper.url, 'There should be Page Url available');
            System.assertNotEquals(null, existingBoardWrapper.url, 'There should be Page Url available');
        }
    }

    @IsTest
    private static void sprintWallKanbanBoardError() {

        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            // Setup
            Sprint__c sprint = [SELECT Id, Name FROM Sprint__c WHERE Name = 'Sprint2' LIMIT 1];

            // Exercise
            Test.startTest();
            delete sprint;
            SprintWallUserStoriesCtrl.KanbanWrapper wrapper = SprintWallUserStoriesCtrl.getKanbanBoardUrl(sprint.Id);
            Test.stopTest();

            // Verify
            System.assertNotEquals(null, wrapper.alerts, 'There should be an Alert');
            System.assertEquals(null, wrapper.url, 'There should no URL');
            System.assertEquals('error', wrapper.alerts[0].variant, 'It should be an Error Alert');
        }
    }

    private static TestUtilities createDefaultTestData() {
        TestUtilities tu = new TestUtilities();

        // Create Team records
        tu.insertSObject(
            'Team__c',
            new Map<String, Object>{ 'Name' => 'Team1', 'Active__c' => true }
        );
        
        tu.insertSObject(
            'Team__c',
            new Map<String, Object>{ 'Name' => 'Team2', 'Active__c' => true }
        );

        // Create current sprint record
        tu.insertSObject(
            'Sprint__c',
            new Map<String, Object>{ 'Name' => 'Sprint1',
                                    'Start_Date__c' => Date.today().addDays(-8),
                                    'End_Date__c' => Date.today().addDays(8),
                                    'Team__c' => tu.item('Team__c', 0).Id
                                }
        );

        tu.insertSObject(
            'Sprint__c',
            new Map<String, Object>{ 'Name' => 'Sprint2',
                                    'Start_Date__c' => Date.today().addDays(-8),
                                    'End_Date__c' => Date.today().addDays(8),
                                    'Team__c' => tu.item('Team__c', 1).Id
                                }
        );

        // Create user story to fill sobjectlist
        tu.insertSObjects(
            'User_Story__c',
            4,
            new Map<String, Object>{
                'User_Story_Title__c' => 'us-0000000',
                'Status__c' => 'Approved',
                'Sprint__c' => tu.item('Sprint__c', 0).Id,
                'Team__c' => tu.item('Team__c', 0).Id,
                'Story_Points_SFDC__c' => 2
            }
        );

        tu.insertSObjects(
            'User_Story__c',
            3,
            new Map<String, Object>{
                'User_Story_Title__c' => 'us-0000000',
                'Status__c' => 'Approved',
                'Sprint__c' => tu.item('Sprint__c', 1).Id,
                'Team__c' => tu.item('Team__c', 1).Id,
                'Story_Points_SFDC__c' => 2
            }
        );

        tu.insertSObjects(
            'User_Story__c',
            1,
            new Map<String, Object>{
                'User_Story_Title__c' => 'us-0000000',
                'Status__c' => 'Approved',
                'Sprint__c' => tu.item('Sprint__c', 1).Id,
                'Team__c' => tu.item('Team__c', 0).Id,
                'Story_Points_SFDC__c' => 2
            }
        );

         tu.insertSObject(
            'Sprint__c',
            new Map<String, Object>{ 'Name' => 'Sprint 3', 'Start_Date__c' => Date.today().addDays(-8), 'End_Date__c' => Date.today().addDays(8) }
        );

        tu.insertSObject(
            'Sprint__c',
            new Map<String, Object>{ 'Name' => 'Sprint 4', 'Start_Date__c' => Date.today().addDays(-8), 'End_Date__c' => Date.today().addDays(8) }
        );

        tu.insertSObject(
            'Kanban_Board__c',
            new Map<String, Object>{ 'Name' => 'Kanban Board For Sprint 3' }
        );

        tu.insertSObject(
            'Kanban_Board__c',
            new Map<String, Object>{ 'Name' => 'Kanban Board For Sprint 4', 'Sprint__c' => tu.item('Sprint__c', 3).Id }
        );

        return tu;
    }

    private static User setupUser() {
        ITestDefaults userCreation = new CopadoSetupTestDefaults.UserDefaults().createRunAsUsers().executeDML();
        User standardUser = userCreation.getRunAsUsers().get('Standard')[0];
        return standardUser;
    }

    private static void setupLicense() {
        TestUtilities.enableLicenses(2, 2, 2, 2, 2, 2, 2);
        TestUtilities.assignLicense(String.valueOf(UserInfo.getUserName()), true, true, true, true, true, true);
    }

    private static User getStandardUser() {
        User standardUser = [
            SELECT Id
            FROM User
            WHERE ProfileId IN (SELECT Id FROM Profile WHERE Name = 'Standard User')
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        return standardUser;
    }

    
}