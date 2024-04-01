@isTest
private with sharing class QueryApexTestsResultActionTest {
    @isTest
    private static void execute() {
        System.runAs(getTestUser()) {
            // Setup
            setCalloutMocks();
            List<QueryApexTestResultsAction.Request> requests = new List<QueryApexTestResultsAction.Request>{getRequests()[0]};

            // Exercise
            Test.startTest();
            List<QueryApexTestResultsAction.Result> results = QueryApexTestResultsAction.execute(requests);
            Test.stopTest();

            // Verify
            System.assertEquals(
                getExpectedResult(),
                results[0].resultJson.replaceAll(' ', '').replaceAll('\n', ''),
                'Json in result should equal the expected Apex Test Json result'
            );
            System.assertEquals(
                true,
                results[0].isSuccess,
                '\'Is Success\' should return True, when there is no exception in the Apex Test Json Result'
            );
        }
    }

    @isTest
    private static void executeWithOnlyTests() {
        System.runAs(getTestUser()) {
            // Setup
            setCalloutMocks();
            List<QueryApexTestResultsAction.Request> requests = new List<QueryApexTestResultsAction.Request>{getRequests()[0]};

            User_Story__c emptyUserStory = new User_Story__c();
            insert emptyUserStory;

            requests[0].userStoryId = emptyUserStory.Id;

            // Exercise
            Test.startTest();
            List<QueryApexTestResultsAction.Result> results = QueryApexTestResultsAction.execute(requests);
            Test.stopTest();

            // Verify
            System.assertEquals(
                getExpectedResultWithOnlyTestsResults(),
                results[0].resultJson.replaceAll(' ', '').replaceAll('\n', ''),
                'Json in result should equal the expected Apex Test Json result'
            );
            System.assertEquals(
                true,
                results[0].isSuccess,
                '\'Is Success\' should return True, when there is no exception in the Apex Test Json Result'
            );
        }
    }

    @isTest
    private static void executeWithException() {
        System.runAs(getTestUser()) {
            // Setup
            setNegativeCalloutMocks();
            List<QueryApexTestResultsAction.Request> requests = new List<QueryApexTestResultsAction.Request>{getRequests()[0]};

            User_Story__c emptyUserStory = new User_Story__c();
            insert emptyUserStory;

            requests[0].userStoryId = emptyUserStory.Id;

            // Exercise
            Test.startTest();
            List<QueryApexTestResultsAction.Result> results = QueryApexTestResultsAction.execute(requests);
            Test.stopTest();

            // Verify
            System.assertEquals(
                false,
                results[0].isSuccess,
                '\'Is Success\' should return False, when there is an exception in the Apex Test Json Result'
            );
        }
    }
    
    @isTest
    private static void executeWithNoCoverableLines() {
        System.runAs(getTestUser()) {
            // Setup
            setCalloutMocksForNoCoverableLines();
            List<QueryApexTestResultsAction.Request> requests = new List<QueryApexTestResultsAction.Request>{getRequests()[1]};

            // Exercise
            Test.startTest();
            List<QueryApexTestResultsAction.Result> results = QueryApexTestResultsAction.execute(requests);
            Test.stopTest();

            // Verify
            System.assertEquals(
                getResultForFilesWithNoCoverableLines(),
                results[0].resultJson.replaceAll(' ', '').replaceAll('\n', ''),
                'Json in result should equal the expected Apex Test Json result'
            );
            System.assertEquals(
                true,
                results[0].isSuccess,
                '\'Is Success\' should return True, when there is no exception in the Apex Test Json Result'
            );
        }
    }

    private static List<QueryApexTestResultsAction.Request> getRequests() {
        QueryApexTestResultsAction.Request request = new QueryApexTestResultsAction.Request();
        request.asyncJobId = '1234567890';
        request.credentialId = 'a000E000000A0aa'; // NOPMD: Hardcoding Id rule does not apply on tests
        request.testClassNames = 'MoebiusTest, FibonacciTriggerTest';
        request.userStoryId = getMockUserStory()[0].Id;
        
        QueryApexTestResultsAction.Request request1 = new QueryApexTestResultsAction.Request();
        request1.asyncJobId = '1234567894';
        request1.credentialId = 'a000E000000A0aa'; // NOPMD: Hardcoding Id rule does not apply on tests
        request1.testClassNames = 'US001ClassTest';
        request1.userStoryId = getMockUserStory()[1].Id;
		
        return new List<QueryApexTestResultsAction.Request>{ request, request1 };
    }
    
    private static void setCalloutMocks() {
        new HttpMock()
            .post('/json/v1/proxyOrgRequest/#Get Test Run Status', getMockStatusResponse())
            .post('/json/v1/proxyOrgRequest/#Query Apex Tests Results', getMockRunResults())
            .post('/json/v1/proxyOrgRequest/#Get Class Coverage By Executed Tests', getMockCoverageResponseByTestMethod())
            .post('/json/v1/proxyOrgRequest/#Get Global Aggregated Coverage By Apex File', getMockGlobalCoverageResponse())
            .mock();
    }
    
    private static void setCalloutMocksForNoCoverableLines() {
        new HttpMock()
            .post('/json/v1/proxyOrgRequest/#Get Test Run Status', getMockStatusResponse())
            .post('/json/v1/proxyOrgRequest/#Query Apex Tests Results', getMockRunResultsNoCoverage())
            .post('/json/v1/proxyOrgRequest/#Get Class Coverage By Executed Tests', getMockNoCoverageResponse())
            .post('/json/v1/proxyOrgRequest/#Get Global Aggregated Coverage By Apex File', getMockGlobalNoCoverageResponse())
            .mock();
    }

    private static void setNegativeCalloutMocks() {
        new HttpMock().post('/json/v1/proxyOrgRequest/#Get Test Run Status', getNegativeMockStatusResponse()).mock();
    }

    private static String getExpectedResult() {
        return ('{' +
            '"userStoryCoverage" : 38.0,' +
            '"triggersWithoutCoverage" : 1,' +
            '"triggerCoverageResults" : {' +
            '  "FibonacciTrigger" : {' +
            '    "numLocationsNotCovered" : 2,' +
            '    "numLocations" : 7,' +
            '    "coverage" : 71.42857142857143' +
            '  }' +
            '},' +
            '"time" : 6,' +
            '"tests" : 3,' +
            '"testClassResults" : {' +
            '  "FibonacciTriggerTest" : {' +
            '    "methods" : [ {' +
            '      "success" : true,' +
            '      "name" : "happyMars",' +
            '      "message" : ""' +
            '    } ]' +
            '  },' +
            '  "MoebiusTest" : {' +
            '    "methods" : [ {' +
            '      "success" : false,' +
            '      "name" : "testHelloFromDev",' +
            '      "message" : "System.AssertException: Assertion Failed"' +
            '    }, {' +
            '      "success" : true,' +
            '      "name" : "testHelloFromStaging",' +
            '      "message" : ""' +
            '    } ]' +
            '  }' +
            '},' +
            '"failures" : 1,' +
            '"failingMethods" : 1,' +
            '"errors" : true,' +
            '"details" : "For details visit the Apex Test Results page from Salesforce setup.",' +
            '"coverageWarning" : "Average test coverage across all Apex Classes and Triggers is 38%, at least 75% test coverage is required.",' +
            '"classesWithoutCoverage" : 2,' +
            '"classCoverageResults" : {' +
            '  "BlitzClass" : {' +
            '    "numLocationsNotCovered" : 1,' +
            '    "numLocations" : 1,' +
            '    "coverage" : 0.0' +
            '  },' +
            '  "Moebius" : {' +
            '    "numLocationsNotCovered" : 8,' +
            '    "numLocations" : 10,' +
            '    "coverage" : 20.0' +
            '  }' +
            '}' +
            '}')
            .replaceAll(' ', '')
            .replaceAll('\n', '');
    }

    private static String getExpectedResultWithOnlyTestsResults() {
        return ('{' +
            '"userStoryCoverage" : null,' +
            '"triggersWithoutCoverage" : null,' +
            '"triggerCoverageResults" : {},' +
            '"time" : 6,' +
            '"tests" : 3,' +
            '"testClassResults" : {' +
            '  "FibonacciTriggerTest" : {' +
            '    "methods" : [ {' +
            '      "success" : true,' +
            '      "name" : "happyMars",' +
            '      "message" : ""' +
            '    } ]' +
            '  },' +
            '  "MoebiusTest" : {' +
            '    "methods" : [ {' +
            '      "success" : false,' +
            '      "name" : "testHelloFromDev",' +
            '      "message" : "System.AssertException: Assertion Failed"' +
            '    }, {' +
            '      "success" : true,' +
            '      "name" : "testHelloFromStaging",' +
            '      "message" : ""' +
            '    } ]' +
            '  }' +
            '},' +
            '"failures" : 1,' +
            '"failingMethods" : 1,' +
            '"errors" : true,' +
            '"details" : "For details visit the Apex Test Results page from Salesforce setup.",' +
            '"coverageWarning" : "",' +
            '"classesWithoutCoverage" : null,' +
            '"classCoverageResults" : {}' +
            '}')
            .replaceAll(' ', '')
            .replaceAll('\n', '');
    }
    
    private static String getResultForFilesWithNoCoverableLines() {
        return('{'+
               '"userStoryCoverage" : 0.0,'+
               '"triggersWithoutCoverage" : 0,'+
               '"triggerCoverageResults" : { },'+
               '"time" : 1,'+
               '"tests" : 1,'+
               '"testClassResults" : {'+
               '  "US001ClassTest" : {'+
               '    "methods" : [ {'+
               '    "success" : true,'+
               '    "name" : "pipelineDev1FuncTest",'+
               '    "message" : ""'+
               '    } ]'+
               '  }'+
               '},'+
               '"failures" : 0,'+
               '"failingMethods" : 0,'+
               '"errors" : false,'+
               '"details" : "For details visit the Apex Test Results page from Salesforce setup.",'+
               '"coverageWarning" : "Average test coverage across all Apex Classes and Triggers is 0%, at least 75% test coverage is required.",'+
               '"classesWithoutCoverage" : 0,'+
               '"classCoverageResults" : {}'+
               '}' )
            .replaceAll(' ', '')
            .replaceAll('\n', '');
    }

    private static SalesforceAPIProxyResponse getNegativeMockStatusResponse() {
        SalesforceAPIProxyResponse result = new SalesforceAPIProxyResponse();
        result.errorCode = '400';

        return result;
    }

    private static SalesforceAPIProxyResponse getMockStatusResponse() {
        SalesforceAPIProxyResponse result = new SalesforceAPIProxyResponse();

        String mockStatusResponse = '{ "size": 1, "totalSize": 1, "done": true, "queryLocator": null, "entityTypeName": "ApexTestRunResult", "records": [ { "attributes": { "type": "ApexTestRunResult", "url": "/services/data/v52.0/tooling/sobjects/ApexTestRunResult/05m09000000oVXZAA2" }, "ClassesCompleted": 1, "ClassesEnqueued": 1, "Status": "Completed" } ] }';
        result.content = mockStatusResponse;

        return result;
    }
    
    private static SalesforceAPIProxyResponse getMockRunResults() {
        SalesforceAPIProxyResponse result = new SalesforceAPIProxyResponse();

        String mockResults = '{"size":3,"totalSize":3,"done":true,"queryLocator":null,"entityTypeName":"ApexTestResult","records":[{"attributes":{"type":"ApexTestResult","url":"/services/data/v52.0/tooling/sobjects/ApexTestResult/07M09000000wVLLEA2"},"ApexClass":{"attributes":{"type":"ApexClass","url":"/services/data/v52.0/tooling/sobjects/ApexClass/01p0900000NTDgAAAX"},"Name":"MoebiusTest"},"MethodName":"testHelloFromDev","Outcome":"Fail","RunTime":1,"Message":"System.AssertException: Assertion Failed","StackTrace":"Class.MockTestClass1.testMethod1: line 22, column 1"},{"attributes":{"type":"ApexTestResult","url":"/services/data/v52.0/tooling/sobjects/ApexTestResult/07M09000000wVLMEA2"},"ApexClass":{"attributes":{"type":"ApexClass","url":"/services/data/v52.0/tooling/sobjects/ApexClass/01p0900000NTDgAAAX"},"Name":"MoebiusTest"},"MethodName":"testHelloFromStaging","Outcome":"Pass","RunTime":2,"Message":null,"StackTrace":null},{"attributes":{"type":"ApexTestResult","url":"/services/data/v52.0/tooling/sobjects/ApexTestResult/07M09000000wVLNEA2"},"ApexClass":{"attributes":{"type":"ApexClass","url":"/services/data/v52.0/tooling/sobjects/ApexClass/01p0900000NTDgAAAE"},"Name":"FibonacciTriggerTest"},"MethodName":"happyMars","Outcome":"Pass","RunTime":3,"Message":null,"StackTrace":null}]}';
        result.content = mockResults;

        return result;
    }
    
    private static SalesforceAPIProxyResponse getMockRunResultsNoCoverage() {
        SalesforceAPIProxyResponse result = new SalesforceAPIProxyResponse();

        String mockResults = '{"size":1,"totalSize":1,"done":true,"queryLocator":null,"entityTypeName":"ApexTestResult","records":[{"attributes":{"type":"ApexTestResult","url":"/services/data/v52.0/tooling/sobjects/ApexTestResult/07M09000000wVLLEA2"},"ApexClass":{"attributes":{"type":"ApexClass","url":"/services/data/v52.0/tooling/sobjects/ApexClass/01p0900000NTDgAAAX"},"Name":"US001ClassTest"},"MethodName":"pipelineDev1FuncTest","Outcome":"Pass","RunTime":1,"Message":null,"StackTrace":null}]}';
        result.content = mockResults;

        return result;
    }

    private static SalesforceAPIProxyResponse getMockCoverageResponseByTestMethod() {
        SalesforceAPIProxyResponse result = new SalesforceAPIProxyResponse();

        String mockCoverageByTestMethod = '{ "size": 3, "totalSize": 3, "done": true, "queryLocator": null, "entityTypeName": "ApexCodeCoverage", "records": [ { "attributes": { "type": "ApexCodeCoverage", "url": "/services/data/v52.0/tooling/sobjects/ApexCodeCoverage/7140900000GvY4HAAV" }, "ApexClassOrTrigger": { "attributes": { "type": "Name", "url": "/services/data/v52.0/tooling/sobjects/ApexTrigger/01q09000000pDITAA2" }, "Name": "FibonacciTrigger" }, "ApexTestClass": { "attributes": { "type": "ApexClass", "url": "/services/data/v52.0/tooling/sobjects/ApexClass/01p0900000NQTLmAAP" }, "Name": "FibonacciTriggerTest" }, "TestMethodName": "happyMars", "NumLinesCovered": 5, "NumLinesUncovered": 2, "Coverage": { "coveredLines": [ 2, 4, 5, 8, 12 ], "uncoveredLines": [ 9, 13 ] } }, { "attributes": { "type": "ApexCodeCoverage", "url": "/services/data/v52.0/tooling/sobjects/ApexCodeCoverage/7140900000GvY4LAAV" }, "ApexClassOrTrigger": { "attributes": { "type": "Name", "url": "/services/data/v52.0/tooling/sobjects/ApexClass/01p0900000NTDg5AAH" }, "Name": "Moebius" }, "ApexTestClass": { "attributes": { "type": "ApexClass", "url": "/services/data/v52.0/tooling/sobjects/ApexClass/01p0900000NTDgAAAX" }, "Name": "MoebiusTest" }, "TestMethodName": "testHelloFromDev", "NumLinesCovered": 1, "NumLinesUncovered": 9, "Coverage": { "coveredLines": [ 6 ], "uncoveredLines": [ 2, 10, 14, 18, 22, 26, 30, 34, 38 ] } }, { "attributes": { "type": "ApexCodeCoverage", "url": "/services/data/v52.0/tooling/sobjects/ApexCodeCoverage/7140900000GvY4MAAV" }, "ApexClassOrTrigger": { "attributes": { "type": "Name", "url": "/services/data/v52.0/tooling/sobjects/ApexClass/01p0900000NTDg5AAH" }, "Name": "Moebius" }, "ApexTestClass": { "attributes": { "type": "ApexClass", "url": "/services/data/v52.0/tooling/sobjects/ApexClass/01p0900000NTDgAAAX" }, "Name": "MoebiusTest" }, "TestMethodName": "testHelloFromStaging", "NumLinesCovered": 2, "NumLinesUncovered": 8, "Coverage": { "coveredLines": [ 2, 6 ], "uncoveredLines": [ 10, 14, 18, 22, 26, 30, 34, 38 ] } } ] }';
        result.content = mockCoverageByTestMethod;

        return result;
    }
    
    private static SalesforceAPIProxyResponse getMockNoCoverageResponse() {
        SalesforceAPIProxyResponse result = new SalesforceAPIProxyResponse();

        String mockCoverageByTestMethod = '{"size": 1,"totalSize": 1,"done": true,"queryLocator": null,"entityTypeName": "ApexCodeCoverage","records": [{"attributes": {"type": "ApexCodeCoverage","url": "/services/data/v52.0/tooling/sobjects/ApexCodeCoverage/7140900000GvY4HAAV"},"ApexClassOrTrigger": {"attributes": {"type": "Name","url": "/services/data/v52.0/tooling/sobjects/ApexTrigger/01q09000000pDITAA2"},"Name": "AccountTrigger"},"ApexTestClass": {"attributes": {"type": "ApexClass","url": "/services/data/v52.0/tooling/sobjects/ApexClass/01p0900000NQTLmAAP"},"Name": "US001ClassTest"},"TestMethodName": "pipelineDev1FuncTest","NumLinesCovered": 0,"NumLinesUncovered": 0,"Coverage":{ "coveredLines": [],"uncoveredLines": []}}]}';
        result.content = mockCoverageByTestMethod;

        return result;
    }

    private static SalesforceAPIProxyResponse getMockGlobalCoverageResponse() {
        SalesforceAPIProxyResponse result = new SalesforceAPIProxyResponse();

        String mockGlobalCoverage = '{ "size": 3, "totalSize": 3, "done": true, "queryLocator": null, "entityTypeName": "ApexCodeCoverageAggregate", "records": [ { "attributes": { "type": "ApexCodeCoverageAggregate", "url": "/services/data/v52.0/tooling/sobjects/ApexCodeCoverageAggregate/71509000000qcKQAAY" }, "ApexClassOrTrigger": { "attributes": { "type": "Name", "url": "/services/data/v52.0/tooling/sobjects/ApexTrigger/01q09000000pDITAA2" }, "Name": "FibonacciTrigger" }, "NumLinesCovered": 5, "NumLinesUncovered": 2, "Coverage": { "coveredLines": [ 2, 4, 5, 8, 12 ], "uncoveredLines": [ 9, 13 ] } }, { "attributes": { "type": "ApexCodeCoverageAggregate", "url": "/services/data/v52.0/tooling/sobjects/ApexCodeCoverageAggregate/71509000000q2SlAAI" }, "ApexClassOrTrigger": { "attributes": { "type": "Name", "url": "/services/data/v52.0/tooling/sobjects/ApexClass/01p0900000DUCrJAAX" }, "Name": "BlitzClass" }, "NumLinesCovered": 0, "NumLinesUncovered": 1, "Coverage": { "coveredLines": [], "uncoveredLines": [] } }, { "attributes": { "type": "ApexCodeCoverageAggregate", "url": "/services/data/v52.0/tooling/sobjects/ApexCodeCoverageAggregate/71509000000qjb4AAA" }, "ApexClassOrTrigger": { "attributes": { "type": "Name", "url": "/services/data/v52.0/tooling/sobjects/ApexClass/01p0900000NTDg5AAH" }, "Name": "Moebius" }, "NumLinesCovered": 2, "NumLinesUncovered": 8, "Coverage": { "coveredLines": [ 2, 6 ], "uncoveredLines": [ 10, 14, 18, 22, 26, 30, 34, 38 ] } } ] }';
        result.content = mockGlobalCoverage;

        return result;
    }
    
    private static SalesforceAPIProxyResponse getMockGlobalNoCoverageResponse() {
        SalesforceAPIProxyResponse result = new SalesforceAPIProxyResponse();

        String mockGlobalCoverage = '{ "size": 1, "totalSize": 1, "done": true, "queryLocator": null, "entityTypeName": "ApexCodeCoverageAggregate", "records": [ { "attributes": { "type": "ApexCodeCoverageAggregate", "url": "/services/data/v52.0/tooling/sobjects/ApexCodeCoverageAggregate/71509000000qcKQAAY" }, "ApexClassOrTrigger": { "attributes": { "type": "Name", "url": "url=/services/data/v52.0/tooling/sobjects/ApexTrigger/01q5g0000006h7MAAQ" }, "Name": "AccountTrigger" }, "NumLinesCovered": 0, "NumLinesUncovered": 0,"Coverage": { } } ] }';
        result.content = mockGlobalCoverage;

        return result;
    }

    private static List<User_Story__c> getMockUserStory() {
        return [SELECT Id FROM User_Story__c LIMIT 2];
    }

    @TestSetup
    private static void setupData() {
        insertData();
    }

    private static void insertData() {
        User adminUser = setupUser();
        System.runAs(adminUser) {
            User_Story__c mockUserStory = new User_Story__c();
            insert mockUserStory;
            
            User_Story__c mockUserStory1 = new User_Story__c();
            insert mockUserStory1;

            Attachment attachment = new Attachment();
            String gitMetadata = '[{"t":"ApexClass","n":"Moebius","b":"Manuel Moya Ferrer","d":"2021-09-02","cb":"Manuel Moya Ferrer","cd":"2021-09-02","r":false,"cmm":"updated","snapshotCommitId":"a0g09000001EJLHAA4"},{"t":"ApexTrigger","n":"FibonacciTrigger","b":"Manuel Moya Ferrer","d":"2021-09-02","cb":"Manuel Moya Ferrer","cd":"2021-09-02","r":false,"cmm":"updated","snapshotCommitId":"a0g09000001EJLHAA4"},{"t":"ApexClass","n":"BlitzClass","b":"Manuel Moya Ferrer","d":"2021-08-18","cb":"Manuel Moya Ferrer","cd":"2021-07-05","r":false,"cmm":"updated","snapshotCommitId":"a0g09000001EJcqAAG"}]';
            attachment.Body = Blob.valueOf(gitMetadata);
            attachment.Name = 'Git Metadata';
            attachment.ParentId = mockUserStory.Id;
            insert attachment;
            
            Attachment attachment1 = new Attachment();
            String gitMetadata1 = '[{"t":"ApexTrigger","n":"AccountTrigger","b":"Mahi","d":"2021-09-02","cb":"Mahi","cd":"2021-09-02","r":false,"cmm":"updated","snapshotCommitId":"a0g09000001EJLHAA4"}]';
            attachment1.Body = Blob.valueOf(gitMetadata1);
            attachment1.Name = 'Git Metadata';
            attachment1.ParentId = mockUserStory1.Id;
            insert attachment1;
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