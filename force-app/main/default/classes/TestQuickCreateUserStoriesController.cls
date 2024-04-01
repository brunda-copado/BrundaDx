@isTest
private class TestQuickCreateUserStoriesController {

    @TestSetup
    private static void setup(){
        User runningUser = createRunningUser();
        assignUserPermissions(runningUser.Id);
        TestUtilities.enableLicenses(2, 2, 2, 2, 2, 2, 2);
    }

    private static User createRunningUser() {
        List<User> users = TestDataFactory.createUsers();
        return users[1];
    }

    private static void assignUserPermissions(Id userId) {
        PermissionSet permissionSet = [SELECT Id FROM PermissionSet WHERE Name = 'Copado_User'];
        List<PermissionSetAssignment> assignments = [
            SELECT Id
            FROM PermissionSetAssignment
            WHERE PermissionSetId = :permissionSet.Id AND AssigneeId = :userId
        ];
        if (assignments.isEmpty()) {
            insert new PermissionSetAssignment(AssigneeId = userId, PermissionSetId = permissionSet.Id);
        }
    }

    private static User getRunningUser() {
        User runningUser = [SELECT Id, Name, LastName, Email, Username FROM User WHERE ProfileId IN (SELECT Id FROM Profile WHERE Name = 'Standard User') AND IsActive = TRUE AND CompanyName = 'TEST' ORDER BY CreatedDate LIMIT 1];
        TestUtilities.assignLicense(String.valueOf(runningUser.Username), true, true, true, true, true, true);
        return runningUser;
    }

	@isTest
	static void tesWithoutLicense() {
		Project__c testProject = CMTestMethodUtilities.createProject('My Project');
		insert testProject;
		Sprint__c testSprint = CMTestMethodUtilities.createSprint('Sprint1');
		testSprint.Project__c = testProject.Id;
		insert testSprint;
		Sprint__c testSprint2 = CMTestMethodUtilities.createSprint('Sprint1');
		testSprint2.Project__c = testProject.Id;
		insert testSprint2;
		
		PageReference pref = Page.QuickCreateUserStories;
		pref.getParameters().put('sid',testSprint.id);
		Test.setCurrentPage(pref);
		QuickCreateUserStoriesController con = new QuickCreateUserStoriesController();
		system.assertEquals(null, con.dummyStory,'Feature enabled without License');
		system.assertNotEquals(null, con.getRecordType(),'Permission missing');
	}

	static testMethod void test_bad_params_given() {
		System.runAs(getRunningUser()) {
			PageReference pref = Page.QuickCreateUserStories;
			pref.getParameters().put('pid','test123');
			Test.setCurrentPage(pref);
			QuickCreateUserStoriesController con = new QuickCreateUserStoriesController();
			system.assert(CMTestMethodUtilities.hasMessage('Invalid id'));
			system.assertEquals(false, con.isValid);
		}
    }

    static testMethod void test_only_Sprint_given() {
		System.runAs(getRunningUser()) {
			Project__c testProject = CMTestMethodUtilities.createProject('My Project');
			insert testProject;
			Sprint__c testSprint = CMTestMethodUtilities.createSprint('Sprint1');
			testSprint.Project__c = testProject.Id;
			insert testSprint;
			Sprint__c testSprint2 = CMTestMethodUtilities.createSprint('Sprint1');
			testSprint2.Project__c = testProject.Id;
			insert testSprint2;
			
			PageReference pref = Page.QuickCreateUserStories;
			pref.getParameters().put('sid',testSprint.id);
			Test.setCurrentPage(pref);
			QuickCreateUserStoriesController con = new QuickCreateUserStoriesController();
			system.assertEquals(testProject.Id, con.dummyStory.Project__c);
			con.updatePreset();
			system.assertEquals(0, con.userStories.size());
			con.dummyStory.User_Story_Title__c = 'my title';
			con.preLoadExisting = true;
			con.addRow();
			system.assertEquals(1, [select Id, Project__c, Sprint__c from User_Story__c where Project__c=:testProject.Id].size());
			system.assertEquals(1, con.userStories.size());
			
			// now we update the story
			con.userStories[0].story.User_Story_Title__c = 'updated title123';
			con.userStories[0].saveStory();
			system.assertEquals(1, [select Id, User_Story_Title__c from User_Story__c where User_Story_Title__c='updated title123'].size());
			system.assertEquals(1, con.userStories.size());
			
			con = new QuickCreateUserStoriesController();
			con.preLoadExisting = false;
			con.setUserStoryPresets();
			system.assertEquals(0, con.userStories.size());
			
			con.preLoadExisting = true;
			con.setUserStoryPresets();
			system.assertEquals(1, con.userStories.size());
			// now we delete that story
			con.userStories[0].deleteStory();
			system.assertEquals(0, [select Id, Project__c, Sprint__c from User_Story__c where Project__c=:testProject.Id].size());
			
			//Add another user story
			con.preLoadExisting = true;
			con.updatePreset();
			con.dummyStory.User_Story_Title__c = 'my title';
			con.addRow();
			system.assertEquals(1, [select Id, Project__c, Sprint__c from User_Story__c where Project__c=:testProject.Id].size());
			system.assertEquals(1, con.userStories.size());
			
			con.dummyStory.Sprint__c = testSprint2.Id;
			//con.updateFromLookups();
			//system.assertEquals(testSprint2.Id, con.sprintId);
			
			con.dummyStory.Sprint__c = null;
			//con.updateFromLookups();
			
			con.dummyStory.Project__c = null;
			con.dummyStory.Sprint__c = null;
			//con.updateFromLookups();
			
			con.dummyStory.Project__c = testProject.Id;
			con.dummyStory.Sprint__c = null;
			//con.updateFromLookups();
			
			// abort the page and go to project
			pref = con.cancel();
			system.assertEquals('/'+testProject.Id, pref.getUrl());
			
			con = new QuickCreateUserStoriesController();
			
			con.dummyStory.Project__c = null;
			con.dummyStory.Sprint__c = null;
			
			pref = con.cancel();
			system.assertEquals('/home/home.jsp', pref.getUrl());
		}
    }
}