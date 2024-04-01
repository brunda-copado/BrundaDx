@isTest
public class RestrictUserStoryDependencyDuplicateTest {

    // Test Setup

    @TestSetup
    private static void setup() {
        User standardUser = setupUser();
        System.runAs(standardUser) {
            setupLicense();
            createTestData();
        }
    }

    @isTest
    private static void validateDuplicateUserStoryDependencyInsert() {
        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            List<User_Story__c> userStories = getUserStories();

            //Execute
            TestUtilities testUtilities = new TestUtilities();
            try {
                testUtilities.insertSObjects(
                    'Team_Dependency__c',
                    1,
                    new Map<String, Object>{
                        'Relationship_Type__c' => 'relates to',
                        'Dependency_Status__c' => 'New',
                        'Dependent_User_Story__c' => userStories[0].Id,
                        'Provider_User_Story__c' => userStories[1].Id,
                        'Notes__c' => 'test notes'
                    }
                );
            }
            catch (Exception ex) {

                // Verify
                System.assertEquals(ex.getMessage().contains(Label.Duplicate_User_Story_Dependency_Error), true, 
                                    'There should be a duplicate User Story Dependency Error Message');
            }
        }     
    }

    @isTest
    private static void validateDuplicateUserStoryDependencyUpdate() {
        User standardUser = getStandardUser();
        System.runAs(standardUser) {
            List<User_Story__c> userStories = getUserStories();
            List<Team_Dependency__c> dependencies = getUserStoryDependencies();

            //Execute
            TestUtilities testUtilities = new TestUtilities();
            try {
                system.assert(userStories.size() == 3, 'User Story list size must be three.'); 
                system.assert(dependencies.size() > 0, 'Dependency list size should be greater than zero.');
                dependencies[0].Provider_User_Story__c = userStories[2].id;
                update dependencies;

                // Verify
                System.assert(true, 'Dependency should be updated successfully');
            }
            catch (Exception ex) {

                // Verify
                System.assert(false, 'There is an error in Dependency update.');
            }
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

    private static List<User_Story__c> getUserStories() {
        List<User_Story__c> userStories = [
            SELECT Id, Name
            FROM User_Story__c
            ORDER BY User_Story_Title__c
        ];
        return userStories;
    }

    private static List<Team_Dependency__c> getUserStoryDependencies() {
        List<Team_Dependency__c> dependencies = [
            SELECT Id, Provider_User_Story__c, Dependent_User_Story__c
            FROM Team_Dependency__c 
        ];
        return dependencies;
    }

    private static TestUtilities createTestData() {
        TestUtilities testUtilities = new TestUtilities();

        // Create Team record
        testUtilities.insertSObject(
            'Team__c',
            new Map<String, Object>{ 'Name' => 'Team1', 'Active__c' => true }
        );

        // Create current sprint record
        testUtilities.insertSObject(
            'Sprint__c',
            new Map<String, Object>{ 'Name' => 'Sprint1',
                                    'Start_Date__c' => Date.today().addDays(-8),
                                    'End_Date__c' => Date.today().addDays(8),
                                    'Team__c' => testUtilities.item('Team__c', 0).Id
                                }
        );

        // Create user story to fill sobjectlist
        testUtilities.insertSObject(
            'User_Story__c',
            new Map<String, Object>{
                'User_Story_Title__c' => 'us-0000000',
                'Status__c' => 'Approved',
                'Sprint__c' => testUtilities.item('Sprint__c', 0).Id,
                'Team__c' => testUtilities.item('Team__c', 0).Id,
                'Story_Points_SFDC__c' => 2
            }
        );

        // Create user story to fill sobjectlist
        testUtilities.insertSObject(
            'User_Story__c',
            new Map<String, Object>{
                'User_Story_Title__c' => 'us-0000001',
                'Status__c' => 'Approved',
                'Sprint__c' => testUtilities.item('Sprint__c', 0).Id,
                'Team__c' => testUtilities.item('Team__c', 0).Id,
                'Story_Points_SFDC__c' => 2
            }
        );

        // Create user story to fill sobjectlist
        testUtilities.insertSObject(
            'User_Story__c',
            new Map<String, Object>{
                'User_Story_Title__c' => 'us-0000002',
                'Status__c' => 'Approved',
                'Sprint__c' => testUtilities.item('Sprint__c', 0).Id,
                'Team__c' => testUtilities.item('Team__c', 0).Id,
                'Story_Points_SFDC__c' => 2
            }
        );

        // Create user story dependency to fill sobjectlist
        testUtilities.insertSObjects(
            'Team_Dependency__c',
            1,
            new Map<String, Object>{
                'Relationship_Type__c' => 'relates to',
                'Dependency_Status__c' => 'New',
                'Dependent_User_Story__c' => testUtilities.item('User_Story__c', 0).Id,
                'Provider_User_Story__c' => testUtilities.item('User_Story__c', 1).Id,
                'Notes__c' => 'test notes'
            }
        );
        return testUtilities;
    }

}