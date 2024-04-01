@isTest
private class TestExecuteTestRunExtension {

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
    static void myUnitTestWithoutLicense() {
		Test_Script__c script = CMTestMethodUtilities.createTestScript('Test');
		insert script;
		Test_Script_Step__c step = CMTestMethodUtilities.createTestScriptStep(script.Id, 'Test');
		insert step;
		Test_Run__c run = CMTestMethodUtilities.createTestRun(script.Id);
		insert run;
		Test_Run_Step__c trs = CMTestMethodUtilities.createTestRunStep(run.Id, step.Id);
		insert trs;
		
		Test.startTest();
		PageReference pref = Page.MassAddToRelease;
		pref.getParameters().put('id',run.id);
		Test.setCurrentPage(pref);
		
		ExecuteTestRunExtension ext = new ExecuteTestRunExtension(new ApexPages.StandardController(run));
		system.assertEquals(ext.mapSteps, null, 'Feature enabled without License');
	}

    static testMethod void myUnitTest() {
		System.runAs(getRunningUser()) {
			TestUtilities.setTestSettingsEE();
			Test_Script__c script = CMTestMethodUtilities.createTestScript('Test');
			insert script;
			Test_Script_Step__c step = CMTestMethodUtilities.createTestScriptStep(script.Id, 'Test');
			insert step;
			Test_Run__c run = CMTestMethodUtilities.createTestRun(script.Id);
			insert run;
			Test_Run_Step__c trs = CMTestMethodUtilities.createTestRunStep(run.Id, step.Id);
			insert trs;
			
			Test.startTest();
			PageReference pref = Page.MassAddToRelease;
			pref.getParameters().put('id',run.id);
			Test.setCurrentPage(pref);
			
			ExecuteTestRunExtension ext = new ExecuteTestRunExtension(new ApexPages.StandardController(run));
			ext.access_statusColumn = 'Dropdown box';
			ext.updateAccess_statusColumn();
			system.assertEquals('Dropdown box', ext.access_statusColumn);
			ext.access_statusColumn = 'Images';
			ext.updateAccess_statusColumn();
			system.assertEquals('Images', ext.access_statusColumn);
			
			ext.steps[0].Status__c = 'Changed';
			ext.saveProgress();
			ext = new ExecuteTestRunExtension(new ApexPages.StandardController(run));
			system.assertEquals('Changed', ext.steps[0].Status__c);
			
			ext.thisStepId = trs.Id;
			ext.thisStepStatus = 'Pass';
			ext.updateTestRunStatus();
			system.assertEquals('', ext.thisStepId);
			system.assertEquals('', ext.thisStepStatus);
			system.assertEquals('Pass', [select Id, Status__c from Test_Run_Step__c where Id=:trs.Id].Status__c);
			
			Test.stopTest();
		}
    }
}