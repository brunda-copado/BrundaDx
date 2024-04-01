@isTest
private with sharing class DelegateApexTestsExecutionActionTest {
    @isTest
    private static void execute() {
        System.runAs(getTestUser()) {
            // Setup
            String mockAsyncJobId = 'Mock1234';
            SalesforceAPIProxyResponse mockResponse = new SalesforceAPIProxyResponse();
            mockResponse.content = '"' + mockAsyncJobId + '"';

            new HttpMock().post('/json/v1/proxyOrgRequest/', mockResponse).mock();

            DelegateApexTestsExecutionAction.Request request = new DelegateApexTestsExecutionAction.Request();
            request.credentialId = '1234567890';
            request.testClassNames = 'MockClass1,MockClass2';

            List<DelegateApexTestsExecutionAction.Request> requests = new List<DelegateApexTestsExecutionAction.Request>{ request };

            // Exercise
            Test.startTest();
            List<DelegateApexTestsExecutionAction.Result> results = DelegateApexTestsExecutionAction.execute(requests);
            Test.stopTest();

            // Verify
            System.assertEquals(mockAsyncJobId, results[0].asyncJobId, 'Async job id should be properly returned in the action result');
            System.assertEquals(
                true,
                results[0].isSuccess,
                '\'Is Success\' should return True, when there is no exception while running test classes'
            );
        }
    }

    @isTest
    private static void executeWithException() {
        System.runAs(getTestUser()) {
            // Setup
            SalesforceAPIProxyResponse mockResponse = new SalesforceAPIProxyResponse();
            mockResponse.errorCode = '400';
            new HttpMock().post('/json/v1/proxyOrgRequest/', mockResponse).mock();

            DelegateApexTestsExecutionAction.Request request = new DelegateApexTestsExecutionAction.Request();
            request.credentialId = '1234567890';
            request.testClassNames = 'MockClass1,MockClass2';

            List<DelegateApexTestsExecutionAction.Request> requests = new List<DelegateApexTestsExecutionAction.Request>{ request };

            // Exercise
            Test.startTest();
            List<DelegateApexTestsExecutionAction.Result> results = DelegateApexTestsExecutionAction.execute(requests);
            Test.stopTest();

            // Verify
            System.assertEquals(
                false,
                results[0].isSuccess,
                '\'Is Success\' should return False, when there is an exception while running test classes'
            );
        }

    }

    @TestSetup
    private static void setupUser() {
        new CopadoSetupTestDefaults.UserDefaults().createRunAsUsers().executeDML();
    }

    private static User getTestUser() {
        return [SELECT Id, Name, LastName, Email, Username FROM User WHERE Email = 'test@test.org' LIMIT 1].get(0);
    }
}