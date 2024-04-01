@isTest
private class TestUserStoryAssignmentSetController {

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
    static void testMassAssignmentWithoutLicense() {
        List<User_Story__c> userStories = new List<User_Story__c>();
        for(Integer i=1; i<=2; i++){
            User_Story__c u = CMTestMethodUtilities.createUserStory('Test: '+i);
            userStories.add(u);
        }
        insert userStories;
        
        Release__c testRelease = CMTestMethodUtilities.createRelease('Test Release');
        insert testRelease;
        
        PageReference pageRef = Page.UserStoryAssignment;
        Test.setCurrentPage(pageRef);
        
        ApexPages.StandardSetController con = new ApexPages.StandardSetController(userStories);
        UserStoryAssignmentSetController ext = new UserStoryAssignmentSetController(con);
        
        Test.startTest();
        system.assertEquals(ext.records, null, 'Feature enabled without License');
        Test.stopTest();
    }

    static testMethod void testMassAssignment() {
        System.runAs(getRunningUser()) {
            List<User_Story__c> userStories = new List<User_Story__c>();
            for(Integer i=1; i<=2; i++){
                User_Story__c u = CMTestMethodUtilities.createUserStory('Test: '+i);
                userStories.add(u);
            }
            insert userStories;
            
            Release__c testRelease = CMTestMethodUtilities.createRelease('Test Release');
            insert testRelease;
            
            PageReference pageRef = Page.UserStoryAssignment;
            Test.setCurrentPage(pageRef);
            
            ApexPages.StandardSetController con = new ApexPages.StandardSetController(userStories);
            UserStoryAssignmentSetController ext = new UserStoryAssignmentSetController(con);
            ext.records = userStories;
            
            Test.startTest();
            ext.dummy.Release__c = testRelease.Id;
            PageReference result = ext.assign();
            system.assertEquals(new PageReference('/'+testRelease.Id).getUrl(), result.getUrl());
            system.assertEquals(2,[select Id, Release__c from User_Story__c where Release__c=:testRelease.Id].size());
            Test.stopTest();
        }
    }

    static testMethod void test_Cancel(){
        System.runAs(getRunningUser()) {
            List<User_Story__c> userStories = new List<User_Story__c>();
            for(Integer i=1; i<=2; i++){
                User_Story__c u = CMTestMethodUtilities.createUserStory('Test: '+i);
                userStories.add(u);
            }
            insert userStories;
            
            Release__c testRelease = CMTestMethodUtilities.createRelease('Test Release');
            insert testRelease;
            
            PageReference pageRef = Page.UserStoryAssignment;
            Test.setCurrentPage(pageRef);
            
            ApexPages.StandardSetController con = new ApexPages.StandardSetController(userStories);
            UserStoryAssignmentSetController ext = new UserStoryAssignmentSetController(con);
            ext.records = userStories;
            
            Test.startTest();
            PageReference result = ext.cancel();
            Test.stopTest();
            system.assert(result != null);
        }
    }

    static testMethod void test_Add_Error(){
        System.runAs(getRunningUser()) {
            List<User_Story__c> userStories = new List<User_Story__c>();
            for(Integer i=1; i<=2; i++){
                User_Story__c u = CMTestMethodUtilities.createUserStory('Test: '+i);
                userStories.add(u);
            }
            insert userStories;
            
            Release__c testRelease = CMTestMethodUtilities.createRelease('Test Release');
            insert testRelease;
            
            PageReference pageRef = Page.UserStoryAssignment;
            Test.setCurrentPage(pageRef);
            
            ApexPages.StandardSetController con = new ApexPages.StandardSetController(userStories);
            UserStoryAssignmentSetController ext = new UserStoryAssignmentSetController(con);
            Test.startTest();
            ext.dummy.Release__c = testRelease.Id;
            PageReference result = ext.assign();
            system.assertEquals(null, result);
            //system.assert(testMethodUtilities.hasMessage(Label.SELECT_AT_LEAST_ONE_RECORD));
            Test.stopTest();
        }
    }
}