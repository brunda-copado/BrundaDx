@IsTest
public with sharing class AddWarningOnUserStoryControllerTest {

    @TestSetup
    private static void setup() {
        User standardUser = setupUser();
        System.runAs(standardUser) {
            setupLicense();
            createDefaultTestData();
        }
    }

    private static void setupLicense() {
        TestUtilities.enableLicenses(2, 2, 2, 2, 2, 2, 2);
        TestUtilities.assignLicense(String.valueOf(UserInfo.getUserName()), true, true, true, true, true, true);
    }

    private static User setupUser() {
        ITestDefaults userCreation = new CopadoSetupTestDefaults.UserDefaults().createRunAsUsers().executeDML();
        User standardUser = userCreation.getRunAsUsers().get('Standard')[0];
        return standardUser;
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

    private static TestUtilities createDefaultTestData() {
        TestUtilities tu = new TestUtilities();

        // Create Team records
        tu.insertSObject(
            'Team__c',
            new Map<String, Object>{ 'Name' => 'Team1', 'Active__c' => true }
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

        // Create user story to fill sobjectlist
        tu.insertSObject(
            'User_Story__c',
            new Map<String, Object>{
                'User_Story_Title__c' => 'us-0000000',
                'Status__c' => 'Approved',
                'Sprint__c' => tu.item('Sprint__c', 0).Id,
                'Team__c' => tu.item('Team__c', 0).Id,
                'Story_Points_SFDC__c' => 2
            }
        );

        // Create user story to fill sobjectlist
        tu.insertSObject(
            'User_Story__c',
            new Map<String, Object>{
                'User_Story_Title__c' => 'us-0000001',
                'Status__c' => 'Approved',
                'Sprint__c' => tu.item('Sprint__c', 0).Id,
                'Team__c' => tu.item('Team__c', 0).Id,
                'Story_Points_SFDC__c' => 2
            }
        );

        // Create user story dependency to fill sobjectlist
        tu.insertSObject(
            'Team_Dependency__c',
            new Map<String, Object>{
                'Relationship_Type__c' => 'blocking',
                'Dependency_Status__c' => 'New',
                'Dependent_User_Story__c' => tu.item('User_Story__c', 0).Id,
                'Provider_User_Story__c' => tu.item('User_Story__c', 1).Id,
                'Notes__c' => 'test notes'
            }
        );
        return tu;
    }

    @IsTest
    private static void userStoryWithBlockingDependency() {

        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            // Setup
            User_Story__c userStoryObj = [SELECT Id, User_Story_Title__c FROM User_Story__c WHERE User_Story_Title__c = 'us-0000000' LIMIT 1];

            // Exercise
            Test.startTest();
            List<UIDesignHelper.AlertWrapper> alerts = new List<UIDesignHelper.AlertWrapper>();
            alerts = CopadoAlertCommunicatorCtrl.getAlerts(userStoryObj.Id,System.Label.UserStoryAlertCommunicationId);
            Test.stopTest();

            // Verify
            System.assertEquals(System.Label.DependencyWarning, alerts[0].message, 'Team should not be same in Sprint & related User Stories');
        }
    }


}