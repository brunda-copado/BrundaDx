@isTest
private with sharing class ApexTestsServiceTest {
    private static String mockFiles = 'ClassOne, TriggerOne';
    private static String mockAsyncJobId = '1234567890';
    private static String mockCredentialId = '0987654321';

    @isTest
    private static void delegateRun() {
        System.runAs(getTestUser()) {
            // Setup
            SalesforceAPIProxyResponse mockResponse = new SalesforceAPIProxyResponse();
            mockResponse.content = '"' + mockAsyncJobId + '"';

            new HttpMock().post('/json/v1/proxyOrgRequest/', mockResponse).mock();

            // Exercise
            Test.startTest();
            String asyncJobId = new ApexTestsService(mockCredentialId).delegateRun(mockFiles);
            Test.stopTest();

            // Verify
            System.assertEquals(mockAsyncJobId, asyncJobId, 'Async job id should be properly returned in the response');
        }
    }

    @isTest
    private static void delegateRunAlreadyInProcess() {
        System.runAs(getTestUser()) {
            // Setup
            SalesforceAPIProxyResponse mockResponse = new SalesforceAPIProxyResponse();
            mockResponse.statusCode = 400;
            mockResponse.errorCode = 'ALREADY_IN_PROCESS';

            new HttpMock().post('/json/v1/proxyOrgRequest/', mockResponse, 400).mock();

            // Exercise
            Exception ex;
            Test.startTest();
            try {
                new ApexTestsService(mockCredentialId).delegateRun(mockFiles);
            } catch (Exception e) {
                ex = e;
            }
            Test.stopTest();

            // Verify
            System.assertEquals(Label.ApexTestAlreadyInProcess, ex.getMessage(), 'Already in process exception should be managed');
        }
    }

    @isTest
    private static void queryRunStatus() {
        System.runAs(getTestUser()) {
            // Setup
            String mockStatus = 'MockProgress';
            String mockStatusResponse =
                '{ "size": 1, "totalSize": 1, "done": true, "queryLocator": null, "entityTypeName": "ApexTestRunResult", "records": [ { "attributes": { "type": "ApexTestRunResult", "url": "/services/data/v52.0/tooling/sobjects/ApexTestRunResult/05m09000000oVXZAA2" }, "ClassesCompleted": 1, "ClassesEnqueued": 1, "Status": "' +
                mockStatus +
                '" } ] }';

            SalesforceAPIProxyResponse mockResponse = new SalesforceAPIProxyResponse();
            mockResponse.content = mockStatusResponse;

            new HttpMock().post('/json/v1/proxyOrgRequest/', mockResponse).mock();

            // Exercise
            Test.startTest();
            String runStatus = new ApexTestsService(mockCredentialId).queryRunStatus(mockAsyncJobId);
            Test.stopTest();

            // Verify
            System.assertEquals(mockStatus, runStatus, 'Status should be correctly extracted from the request response');
        }
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    private static void queryResults() {
        System.runAs(getTestUser()) {
            // Setup
            String mockResults = '{"size":3,"totalSize":3,"done":true,"queryLocator":null,"entityTypeName":"ApexTestResult","records":[{"attributes":{"type":"ApexTestResult","url":"/services/data/v52.0/tooling/sobjects/ApexTestResult/07M09000000wVLLEA2"},"ApexClass":{"attributes":{"type":"ApexClass","url":"/services/data/v52.0/tooling/sobjects/ApexClass/01p0900000NTDgAAAX"},"Name":"MockTestClass1"},"MethodName":"testMethod1","Outcome":"Fail","RunTime":1,"Message":"System.AssertException: Assertion Failed","StackTrace":"Class.MockTestClass1.testMethod1: line 22, column 1"},{"attributes":{"type":"ApexTestResult","url":"/services/data/v52.0/tooling/sobjects/ApexTestResult/07M09000000wVLMEA2"},"ApexClass":{"attributes":{"type":"ApexClass","url":"/services/data/v52.0/tooling/sobjects/ApexClass/01p0900000NTDgAAAX"},"Name":"MockTestClass1"},"MethodName":"testMethod2","Outcome":"Pass","RunTime":2,"Message":null,"StackTrace":null},{"attributes":{"type":"ApexTestResult","url":"/services/data/v52.0/tooling/sobjects/ApexTestResult/07M09000000wVLNEA2"},"ApexClass":{"attributes":{"type":"ApexClass","url":"/services/data/v52.0/tooling/sobjects/ApexClass/01p0900000NTDgAAAE"},"Name":"MockTestClass2"},"MethodName":"testMethod1","Outcome":"Pass","RunTime":3,"Message":null,"StackTrace":null}]}';

            SalesforceAPIProxyResponse mockResponse = new SalesforceAPIProxyResponse();
            mockResponse.content = mockResults;

            new HttpMock().post('/json/v1/proxyOrgRequest/', mockResponse).mock();

            // Exercise
            Test.startTest();
            ApexTestRunResult runResult = new ApexTestsService(mockCredentialId).queryResults(mockAsyncJobId);
            Test.stopTest();

            // Verify
            assertTestMethodResults(runResult.records);
        }
    }

    @SuppressWarnings('PMD.ApexUnitTestMethodShouldHaveIsTestAnnotation')
    private static void assertTestMethodResults(List<ApexTestRunResult.TestMethodResult> testMethodResults) {
        ApexTestRunResult.TestMethodResult testClassOneMethodOneResult = testMethodResults[0];
        System.assertEquals('MockTestClass1', testClassOneMethodOneResult.ApexClass.Name, 'Test class name must match');
        System.assertEquals('testMethod1', testClassOneMethodOneResult.MethodName, 'Test method name must match');
        System.assertEquals(1, testClassOneMethodOneResult.RunTime, 'Test method duration must match');
        System.assertEquals('Fail', testClassOneMethodOneResult.Outcome, 'Test method outcome must match');
        System.assertEquals('System.AssertException: Assertion Failed', testClassOneMethodOneResult.Message, 'Test method message must match');

        ApexTestRunResult.TestMethodResult testClassOneMethodTwoResult = testMethodResults[1];
        System.assertEquals('MockTestClass1', testClassOneMethodTwoResult.ApexClass.Name, 'Test class name must match');
        System.assertEquals('testMethod2', testClassOneMethodTwoResult.MethodName, 'Test method name must match');
        System.assertEquals(2, testClassOneMethodTwoResult.RunTime, 'Test method duration must match');
        System.assertEquals('Pass', testClassOneMethodTwoResult.Outcome, 'Test method outcome must match');
        System.assertEquals(null, testClassOneMethodTwoResult.Message, 'Test method message must match');

        ApexTestRunResult.TestMethodResult testClassTwoMethodOneResult = testMethodResults[2];
        System.assertEquals('MockTestClass2', testClassTwoMethodOneResult.ApexClass.Name, 'Test class name must match');
        System.assertEquals('testMethod1', testClassTwoMethodOneResult.MethodName, 'Test method name must match');
        System.assertEquals(3, testClassTwoMethodOneResult.RunTime, 'Test method duration must match');
        System.assertEquals('Pass', testClassTwoMethodOneResult.Outcome, 'Test method outcome must match');
        System.assertEquals(null, testClassTwoMethodOneResult.Message, 'Test method message must match');
    }

    @TestSetup
    private static void setupUser() {
        new CopadoSetupTestDefaults.UserDefaults().createRunAsUsers().executeDML();
    }

    private static User getTestUser() {
        return [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test@test.org' LIMIT 1].get(0);
    }
}