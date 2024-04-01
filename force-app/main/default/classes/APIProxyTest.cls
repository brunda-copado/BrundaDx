@IsTest
private class APIProxyTest {

    @IsTest
    private static void callAIWithFeatureDisabled() {
        // Setup
        String featureName = 'AI_Enabled';
        Exception expectedException = null;
        FeatureManagement.setPackageIntegerValue(featureName, 0);

        // Exercise
        try {
            APIProxy.callAI(null);
        } catch (Exception ex) {
            expectedException = ex;
        }

        // Verify
        Assert.isNotNull(expectedException);
        Assert.areEqual(Label.FEATURE_NOT_SUPPORTED + featureName, expectedException.getMessage());
    }


    @IsTest
    private static void callAIWithFeatureEnabled() {
        // Setup
        FeatureManagement.setPackageIntegerValue('AI_Enabled', 1);
        String mockResponse = 'Finding the "best" pizza is highly subjective and can vary based on personal preferences and tastes.';

        Test.setMock(HttpCalloutMock.class, new MockCopadoAPIResponse(mockResponse));

        // Exercise
        Test.startTest();
        HttpResponse response = APIProxy.callAi('{copadoai: "where the best pizza is sold" }');
        Test.stopTest();

        // Verify
        Assert.areEqual(200, response.getStatusCode());
        Assert.areEqual(mockResponse, response.getBody());
    }

    @IsTest
    private static void getAISessionWithFeatureDisabled() {
        // Setup
        String featureName = 'AI_Enabled';
        Exception expectedException = null;
        FeatureManagement.setPackageIntegerValue(featureName, 0);

        // Exercise
        try {
            APIProxy.getAISession(null);
        } catch (Exception ex) {
            expectedException = ex;
        }

        // Verify
        Assert.isNotNull(expectedException);
        Assert.areEqual(Label.FEATURE_NOT_SUPPORTED + featureName, expectedException.getMessage());
    }


    @IsTest
    private static void getAISessionWithFeatureEnabled() {
        // Setup
        FeatureManagement.setPackageIntegerValue('AI_Enabled', 1);
        String mockResponse = '{ "auth_token": "TOKEN" }';

        Test.setMock(HttpCalloutMock.class, new MockCopadoAPIResponse(mockResponse));

        // Exercise
        Test.startTest();
        HttpResponse response = APIProxy.getAISession('');
        Test.stopTest();

        // Verify
        Assert.areEqual(200, response.getStatusCode());
        Assert.areEqual(mockResponse, response.getBody());
    }


    public class MockCopadoAPIResponse implements HttpCalloutMock {
        private String mockResponse;

        public MockCopadoAPIResponse(String mockResponse) {
            this.mockResponse = mockResponse;
        }

        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody(mockResponse);
            res.setStatusCode(200);

            return res;
        }
    }
}