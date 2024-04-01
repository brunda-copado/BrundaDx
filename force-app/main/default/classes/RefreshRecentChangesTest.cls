@IsTest
private with sharing class RefreshRecentChangesTest {
    @TestSetup
    private static void setup() {
        TestUtilities.getAllMultilicense();
        User runAsUser = createTestUserWithPermissionSets();

        System.runAs(runAsUser) {
            TestUtilities.assignLicense(String.valueOf(runAsUser.Username), true, true, true, true, true, true);

            new Credential().persist();
        }
    }

    @IsTest
    private static void refreshRecentChanges() {
        // Setup
        Org__c org = [SELECT Id FROM Org__c];

        insert new Attachment(Name = 'MetaData', Body = Blob.valueOf('[{"n": "ExampleTest", "t": "ApexClass"}]'), ParentId = org.Id);

        GlobalAPI.ProxyOrgResponse queryResponse = getQueryResponse('testprofile', 'Profile', false);

        MockHttpResponseGenerator mockResponse = new MockHttpResponseGenerator(200, 'Complete', JSON.serialize(queryResponse), null);
        Test.setMock(HttpCalloutMock.class, mockResponse);

        // Exercise
        Test.startTest();
        List<SourceMemberResult> recentChanges = new RefreshRecentChanges(org.Id).execute();
        Test.stopTest();

        // Verify
        
        Assert.areEqual(1, recentChanges.size(), 'The size of the source member response is incorrect');
        Assert.areEqual('testprofile', recentChanges.get(0).MemberName, 'The MemberName of the source member is incorrect');
        Assert.areEqual('Profile', recentChanges.get(0).MemberType, 'The MemberType of the source member is incorrect');
    }

    @IsTest
    private static void refreshRecentChangesWithSpecialCharacters() {
        // Setup
        Org__c org = [SELECT Id FROM Org__c];

        insert new Attachment(Name = 'MetaData', Body = Blob.valueOf('[{"n": "ExampleTest", "t": "ApexClass"}]'), ParentId = org.Id);

        GlobalAPI.ProxyOrgResponse queryResponse = getQueryResponse('Test__c-Testテスáćト日本語áć!@#$%^&*()_+-={}[]|:;<>,.?/', 'Layout', false);

        MockHttpResponseGenerator mockResponse = new MockHttpResponseGenerator(200, 'Complete', JSON.serialize(queryResponse), null);
        Test.setMock(HttpCalloutMock.class, mockResponse);

        // Exercise
        Test.startTest();
        List<SourceMemberResult> recentChanges = new RefreshRecentChanges(org.Id).execute();
        Test.stopTest();

       // Verify
        
        Assert.areEqual(1, recentChanges.size(), 'The size of the source member response is incorrect');
        Assert.areEqual('Test__c-Testテスáćト日本語áć%21%40%23%24%25%5E%26*%28%29_%2B-%3D%7B%7D%5B%5D%7C%3A%3B%3C%3E%2C.%3F%2F', recentChanges.get(0).MemberName, 'The MemberName of the source member is incorrect');
        Assert.areEqual('Layout', recentChanges.get(0).MemberType, 'The MemberType of the source member is incorrect');
    }

    @IsTest
    private static void refreshRecentChangesSinceSpecifiedDateTime() {
        // Setup
        Org__c org = [SELECT Id FROM Org__c LIMIT 1];

        GlobalAPI.ProxyOrgResponse queryResponse = getQueryResponse('testprofile', 'Profile', false);

        MockHttpResponseGenerator mockResponse = new MockHttpResponseGenerator(200, 'Complete', JSON.serialize(queryResponse), null);
        Test.setMock(HttpCalloutMock.class, mockResponse);

        // Exercise
        Test.startTest();
        List<SourceMemberResult> recentChanges = new RefreshRecentChanges(org.Id, DateTime.newInstance(2021, 2, 6)).execute();
        Test.stopTest();

        // Verify
        
        Assert.areEqual(1, recentChanges.size(), 'The size of the source member response is incorrect');
        Assert.areEqual('testprofile', recentChanges.get(0).MemberName, 'The MemberName of the source member is incorrect');
        Assert.areEqual('Profile', recentChanges.get(0).MemberType, 'The MemberName of the source member is incorrect');
    }

    @IsTest
    private static void refreshRecentChangesException() {
        // Setup
        Org__c org = [SELECT Id FROM Org__c];

        insert new Attachment(Name = 'MetaData', Body = Blob.valueOf('[{"n": "ExampleTest", "t": "ApexClass"}]'), ParentId = org.Id);

        String fixedResponse = '{' +
            '"error" : "TestError"' +
        '}';

        MockHttpResponseGenerator mockResponse = new MockHttpResponseGenerator(200, 'Complete', fixedResponse, null);
        Test.setMock(HttpCalloutMock.class, mockResponse);

        String exceptionMessage;
        // Exercise
        Test.startTest();
        try {
            new RefreshRecentChanges(org.Id).execute();
        } catch(Exception e) {
            exceptionMessage = e.getMessage();
        }
        Test.stopTest();

        // Verify
        Assert.areEqual(exceptionMessage, 'TestError', 'Refresh Recent Changes should have thrown an exception');
    }

    private static User createTestUserWithPermissionSets() {
        User result = TestDataFactory.createUsers()[0];

        List<PermissionSet> permissionSets = [SELECT Id FROM PermissionSet WHERE Name IN ('Copado_User', 'Copado_Functions', 'Copado_Job_Engine')];
        List<PermissionSetAssignment> assignments = new List<PermissionSetAssignment>();
        for (PermissionSet permissionSet : permissionSets) {
            assignments.add(new PermissionSetAssignment(AssigneeId = result.Id, PermissionSetId = permissionSet.Id));
        }
        insert assignments;

        return result;
    }

    private static GlobalAPI.ProxyOrgResponse getQueryResponse(String memberName, String memberType, Boolean isNameObsolete) {
        GlobalAPI.ProxyOrgResponse result = new GlobalAPI.ProxyOrgResponse();
        result.statusCode = 200;
        result.content = getSourceMemberContent(memberName, memberType, isNameObsolete);
        result.errorCode = '';
        result.errorMessage = '';
        return result;
    }

    private static String getSourceMemberContent(String memberName, String memberType, Boolean isNameObsolete) {
        RefreshRecentChanges.SourceMemberQueryResult result = new RefreshRecentChanges.SourceMemberQueryResult();
        result.records = new List<SourceMemberResult>();
        result.records.add(getSourceMemberResult(memberName, memberType, isNameObsolete));
        return JSON.serialize(result);
    }

    private static SourceMemberResult getSourceMemberResult(String memberName, String memberType, Boolean isNameObsolete) {
        SourceMemberResult result = new SourceMemberResult();
        result.MemberName = memberName;
        result.MemberType = memberType;
        result.IsNameObsolete = isNameObsolete;
        result.CreatedDate = String.valueOf(Datetime.now());
        result.LastModifiedDate = String.valueOf(Datetime.now());
        result.CreatedBy = getLookupUserField('User User');
        result.LastModifiedBy = getLookupUserField('User User');
        return result;
    }

    private static SourceMemberResult.LookupUserField getLookupUserField(String name) {
        SourceMemberResult.LookupUserField result = new SourceMemberResult.LookupUserField();   
        result.Name = name;
        return result;
    }
}