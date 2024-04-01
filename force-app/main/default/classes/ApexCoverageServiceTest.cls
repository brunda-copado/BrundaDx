@isTest
private with sharing class ApexCoverageServiceTest {
    private static String mockCredentialId = '0987654321';
    private static String mockTestClassNames = 'MoebiusTest, FibonacciTriggerTest';

    @TestSetup
    private static void setupData() {
        insertData();
    }

    @isTest
    private static void queryResults() {
        System.runAs(getTestUser()) {
            // Setup
            new HttpMock()
                .post('/json/v1/proxyOrgRequest/#1', getMockCoverageResponseByTestMethod())
                .post('/json/v1/proxyOrgRequest/#2', getMockGlobalCoverageResponse())
                .mock();

            // Exercise
            Test.startTest();
            AggregateCoverageResult aggregateCoverageResult = new ApexCoverageService()
                .queryResults(mockCredentialId, getMockUserStory().Id, mockTestClassNames);
            Test.stopTest();

            // Verify
            System.assertEquals(aggregateCoverageResult.records.size(), 3, 'Coverage should display information for the three apex files commited');
            assertTriggerCoverage(aggregateCoverageResult.records[0], 5, 2, 'FibonacciTrigger');
            assertClassCoverage(aggregateCoverageResult.records[1], 2, 8, 'Moebius');
            assertClassCoverage(aggregateCoverageResult.records[2], 0, 1, 'BlitzClass');
        }
    }

    @isTest
    private static void queryResultsWithEmptyAttachment() {
        System.runAs(getTestUser()) {
            // Setup
            new HttpMock()
                .post('/json/v1/proxyOrgRequest/#1', getMockCoverageResponseByTestMethod())
                .post('/json/v1/proxyOrgRequest/#2', getMockGlobalCoverageResponse())
                .mock();

            // Exercise
            Test.startTest();
            AggregateCoverageResult aggregateCoverageResult = new ApexCoverageService()
                .queryResults(mockCredentialId, getMockEmptyUserStory().Id, mockTestClassNames);
            Test.stopTest();

            // Verify
            System.assertEquals(aggregateCoverageResult, null, 'No coverage should exist for an empty user story');
        }
    }

    private static void assertTriggerCoverage( // NOPMD
        AggregateCoverageResult.FileCoverageResult triggerCoverage,
        Integer numLinesCovered,
        Integer numLinesUncovered,
        String triggerName
    ) {
        System.assertEquals(numLinesCovered, triggerCoverage.NumLinesCovered, 'NumLinesCovered must be ' + numLinesCovered);
        System.assertEquals(numLinesUncovered, triggerCoverage.NumLinesUncovered, 'NumLinesUncovered must be ' + numLinesUncovered);
        System.assertEquals(triggerName, triggerCoverage.ApexClassOrTrigger.Name, 'Name should be ' + triggerName);
        System.assertEquals('ApexTrigger', triggerCoverage.ApexClassOrTrigger.attributes.type, 'Type should indicate that the file is a trigger');
        System.assert(triggerCoverage.ApexClassOrTrigger.attributes.url.contains('ApexTrigger'), 'Url should indicate that the file is a trigger');
    }

    private static void assertClassCoverage( // NOPMD
        AggregateCoverageResult.FileCoverageResult classCoverage,
        Integer numLinesCovered,
        Integer numLinesUncovered,
        String className
    ) {
        System.assertEquals(numLinesCovered, classCoverage.NumLinesCovered, 'NumLinesCovered must be ' + numLinesCovered);
        System.assertEquals(numLinesUncovered, classCoverage.NumLinesUncovered, 'NumLinesUncovered must be ' + numLinesUncovered);
        System.assertEquals(className, classCoverage.ApexClassOrTrigger.Name, 'Name should be ' + className);
        System.assert(classCoverage.ApexClassOrTrigger.attributes.url.contains('ApexClass'), 'Url should indicate that the file is an apex class');
    }

    private static SalesforceAPIProxyResponse getMockCoverageResponseByTestMethod() {
        SalesforceAPIProxyResponse result = new SalesforceAPIProxyResponse();

        String mockCoverageByTestMethod = '{ "size": 3, "totalSize": 3, "done": true, "queryLocator": null, "entityTypeName": "ApexCodeCoverage", "records": [ { "attributes": { "type": "ApexCodeCoverage", "url": "/services/data/v52.0/tooling/sobjects/ApexCodeCoverage/7140900000GvY4HAAV" }, "ApexClassOrTrigger": { "attributes": { "type": "Name", "url": "/services/data/v52.0/tooling/sobjects/ApexTrigger/01q09000000pDITAA2" }, "Name": "FibonacciTrigger" }, "ApexTestClass": { "attributes": { "type": "ApexClass", "url": "/services/data/v52.0/tooling/sobjects/ApexClass/01p0900000NQTLmAAP" }, "Name": "FibonacciTriggerTest" }, "TestMethodName": "happyMars", "NumLinesCovered": 5, "NumLinesUncovered": 2, "Coverage": { "coveredLines": [ 2, 4, 5, 8, 12 ], "uncoveredLines": [ 9, 13 ] } }, { "attributes": { "type": "ApexCodeCoverage", "url": "/services/data/v52.0/tooling/sobjects/ApexCodeCoverage/7140900000GvY4LAAV" }, "ApexClassOrTrigger": { "attributes": { "type": "Name", "url": "/services/data/v52.0/tooling/sobjects/ApexClass/01p0900000NTDg5AAH" }, "Name": "Moebius" }, "ApexTestClass": { "attributes": { "type": "ApexClass", "url": "/services/data/v52.0/tooling/sobjects/ApexClass/01p0900000NTDgAAAX" }, "Name": "MoebiusTest" }, "TestMethodName": "testHelloFromDev", "NumLinesCovered": 1, "NumLinesUncovered": 9, "Coverage": { "coveredLines": [ 6 ], "uncoveredLines": [ 2, 10, 14, 18, 22, 26, 30, 34, 38 ] } }, { "attributes": { "type": "ApexCodeCoverage", "url": "/services/data/v52.0/tooling/sobjects/ApexCodeCoverage/7140900000GvY4MAAV" }, "ApexClassOrTrigger": { "attributes": { "type": "Name", "url": "/services/data/v52.0/tooling/sobjects/ApexClass/01p0900000NTDg5AAH" }, "Name": "Moebius" }, "ApexTestClass": { "attributes": { "type": "ApexClass", "url": "/services/data/v52.0/tooling/sobjects/ApexClass/01p0900000NTDgAAAX" }, "Name": "MoebiusTest" }, "TestMethodName": "testHelloFromStaging", "NumLinesCovered": 2, "NumLinesUncovered": 8, "Coverage": { "coveredLines": [ 2, 6 ], "uncoveredLines": [ 10, 14, 18, 22, 26, 30, 34, 38 ] } } ] }';
        result.content = mockCoverageByTestMethod;

        return result;
    }

    private static SalesforceAPIProxyResponse getMockGlobalCoverageResponse() {
        SalesforceAPIProxyResponse result = new SalesforceAPIProxyResponse();

        String mockGlobalCoverage = '{ "size": 3, "totalSize": 3, "done": true, "queryLocator": null, "entityTypeName": "ApexCodeCoverageAggregate", "records": [ { "attributes": { "type": "ApexCodeCoverageAggregate", "url": "/services/data/v52.0/tooling/sobjects/ApexCodeCoverageAggregate/71509000000qcKQAAY" }, "ApexClassOrTrigger": { "attributes": { "type": "Name", "url": "/services/data/v52.0/tooling/sobjects/ApexTrigger/01q09000000pDITAA2" }, "Name": "FibonacciTrigger" }, "NumLinesCovered": 5, "NumLinesUncovered": 2, "Coverage": { "coveredLines": [ 2, 4, 5, 8, 12 ], "uncoveredLines": [ 9, 13 ] } }, { "attributes": { "type": "ApexCodeCoverageAggregate", "url": "/services/data/v52.0/tooling/sobjects/ApexCodeCoverageAggregate/71509000000q2SlAAI" }, "ApexClassOrTrigger": { "attributes": { "type": "Name", "url": "/services/data/v52.0/tooling/sobjects/ApexClass/01p0900000DUCrJAAX" }, "Name": "BlitzClass" }, "NumLinesCovered": 0, "NumLinesUncovered": 1, "Coverage": { "coveredLines": [], "uncoveredLines": [] } }, { "attributes": { "type": "ApexCodeCoverageAggregate", "url": "/services/data/v52.0/tooling/sobjects/ApexCodeCoverageAggregate/71509000000qjb4AAA" }, "ApexClassOrTrigger": { "attributes": { "type": "Name", "url": "/services/data/v52.0/tooling/sobjects/ApexClass/01p0900000NTDg5AAH" }, "Name": "Moebius" }, "NumLinesCovered": 2, "NumLinesUncovered": 8, "Coverage": { "coveredLines": [ 2, 6 ], "uncoveredLines": [ 10, 14, 18, 22, 26, 30, 34, 38 ] } } ] }';
        result.content = mockGlobalCoverage;

        return result;
    }

    private static User_Story__c getMockUserStory() {
        return [SELECT Id FROM User_Story__c WHERE User_Story_Title__c = 'Apex and Tests' LIMIT 1];
    }

    private static User_Story__c getMockEmptyUserStory() {
        return [SELECT Id FROM User_Story__c WHERE User_Story_Title__c = 'Empty User Story' LIMIT 1];
    }

    private static void insertData() {
        User adminUser = setupUser();
        System.runAs(adminUser) {
            User_Story__c mockUserStory = new User_Story__c(User_Story_Title__c = 'Apex and Tests');
            insert mockUserStory;

            Attachment attachment = new Attachment();
            String gitMetadata = '[{"t":"ApexClass","n":"Moebius","b":"Manuel Moya Ferrer","d":"2021-09-02","cb":"Manuel Moya Ferrer","cd":"2021-09-02","r":false,"cmm":"updated","snapshotCommitId":"a0g09000001EJLHAA4"},{"t":"ApexTrigger","n":"FibonacciTrigger","b":"Manuel Moya Ferrer","d":"2021-09-02","cb":"Manuel Moya Ferrer","cd":"2021-09-02","r":false,"cmm":"updated","snapshotCommitId":"a0g09000001EJLHAA4"},{"t":"ApexClass","n":"BlitzClass","b":"Manuel Moya Ferrer","d":"2021-08-18","cb":"Manuel Moya Ferrer","cd":"2021-07-05","r":false,"cmm":"updated","snapshotCommitId":"a0g09000001EJcqAAG"}]';
            attachment.Body = Blob.valueOf(gitMetadata);
            attachment.Name = 'Git Metadata';
            attachment.ParentId = mockUserStory.Id;
            insert attachment;

            User_Story__c emptyUserStory = new User_Story__c(User_Story_Title__c = 'Empty User Story');
            insert emptyUserStory;
        }
    }

    private static User setupUser() {
        ITestDefaults userCreation = new CopadoSetupTestDefaults.UserDefaults().createRunAsUsers().executeDML();
        User adminUser = userCreation.getRunAsUsers().get('Admin')[0];

        return adminUser;
    }

    private static User getTestUser() {
        return [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test@test.org' LIMIT 1].get(0);
    }
}