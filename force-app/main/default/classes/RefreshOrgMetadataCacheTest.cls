@IsTest
private class RefreshOrgMetadataCacheTest {
    @TestSetup
    private static void testSetup() {
        TestUtilities.getAllMultilicense();
        User user = (User) new User_t()
            .assign(new PermissionSetAssignment_t().copadoUser())
            .assign(new PermissionSetAssignment_t().functions())
            .assign(new PermissionSetAssignment_t().jobEngine())
            .assign(new PermissionSetAssignment_t().qualityGatesAdmin())
            .assign(new PermissionSetAssignment_t().configureAutomations())
            .assign(new PermissionSetAssignment_t().executeAutomations())
            .persist();
        System.runAs(user) {
            new CopadoLicense().user(user).enableAll().persist();
            createData();
        }
    }

    @IsTest
    private static void executeRefreshWithoutParams() {
        System.runAs(getUser()) {
            // SETUP

            Exception exceptionMessage;

            // EXERCISE

            Test.startTest();
            try {
                RefreshOrgMetadataCache.executeRefresh(null);
            } catch (Exception ex) {
                exceptionMessage = ex;
            }
            Test.stopTest();

            // VERIFY

            Assert.isTrue(
                exceptionMessage.getMessage().contains(Label.Metadata_Refresh_Invalid_Parameter),
                'The exception message should be ' + Label.Metadata_Refresh_Invalid_Parameter
            );
        }
    }

    @IsTest
    private static void executeRefreshWithoutCredentialId() {
        System.runAs(getUser()) {
            // SETUP

            Exception exceptionMessage;
            RefreshOrgMetadataCache.InvocableVariables param = new RefreshOrgMetadataCache.InvocableVariables();

            // EXERCISE

            Test.startTest();
            try {
                RefreshOrgMetadataCache.executeRefresh(param);
            } catch (Exception ex) {
                exceptionMessage = ex;
            }
            Test.stopTest();

            // VERIFY

            Assert.isTrue(
                exceptionMessage.getMessage().contains(Label.Metadata_Refresh_Invalid_Credential),
                'The exception message should be ' + Label.Metadata_Refresh_Invalid_Credential
            );
        }
    }

    @IsTest
    private static void successfullyExecuteRefresh() {
        System.runAs(getUser()) {
            // SETUP

            RefreshOrgMetadataCache.InvocableVariables param = new RefreshOrgMetadataCache.InvocableVariables();
            param.orgId = getCredential('dev').Id;
            String endpoint = Settings.server_url + '/json/v1/metadata/' + param.orgId;
            String response = getPartialRefreshApiResponse();
            Test.setMock(HttpCalloutMock.class, new TestHttpCalloutMock(200, response, endpoint));

            // EXERCISE

            Test.startTest();
            String apiResponse = RefreshOrgMetadataCache.executeRefresh(param);
            Test.stopTest();

            // VERIFY

            Assert.areEqual(getPartialRefreshApiResponse(), apiResponse, 'The metadata refresh api response is invalid');
        }
    }

    @IsTest
    private static void successfullyExecuteRefreshWithMetadataTypes() {
        System.runAs(getUser()) {
            // SETUP

            RefreshOrgMetadataCache.InvocableVariables param = new RefreshOrgMetadataCache.InvocableVariables();
            param.orgId = getCredential('dev').Id;
            param.metadataTypesToBeRefreshed = new Set<String>{ 'ApexClass' };
            String endpoint =
                Settings.server_url +
                '/json/v1/metadata/' +
                param.orgId +
                '?filter=' +
                EncodingUtil.urlEncode(String.join(new List<String>(param.metadataTypesToBeRefreshed), ','), 'UTF-8') +
                '&mergeIndex=true';
            String response = getPartialRefreshApiResponse();
            Test.setMock(HttpCalloutMock.class, new TestHttpCalloutMock(200, response, endpoint));

            // EXERCISE

            Test.startTest();
            String apiResponse = RefreshOrgMetadataCache.executeRefresh(param);
            Test.stopTest();

            // VERIFY

            Assert.areEqual(getPartialRefreshApiResponse(), apiResponse, 'The metadata refresh api response is invalid');
        }
    }

    @IsTest
    private static void executeRefreshWithFailure() {
        System.runAs(getUser()) {
            // SETUP

            RefreshOrgMetadataCache.InvocableVariables param = new RefreshOrgMetadataCache.InvocableVariables();
            param.orgId = getCredential('dev').Id;
            param.metadataTypesToBeRefreshed = new Set<String>{ 'ApexClass' };
            String endpoint =
                Settings.server_url +
                '/json/v1/metadata/' +
                param.orgId +
                '?filter=' +
                EncodingUtil.urlEncode(String.join(new List<String>(param.metadataTypesToBeRefreshed), ','), 'UTF-8') +
                '&mergeIndex=true';
            String response = 'Internal Server Error';
            Exception exceptionMessage;
            Test.setMock(HttpCalloutMock.class, new TestHttpCalloutMock(500, response, endpoint));

            // EXERCISE

            Test.startTest();
            try {
                RefreshOrgMetadataCache.executeRefresh(param);
            } catch (Exception ex) {
                exceptionMessage = ex;
            }
            Test.stopTest();

            // VERIFY

            Assert.isTrue(exceptionMessage.getMessage().contains(response), 'The exception message must contain ' + response);
        }
    }

    @IsTest
    private static void executeRefreshWithOutputStoredInFiles() {
        System.runAs(getUser()) {
            // SETUP

            RefreshOrgMetadataCache.InvocableVariables param = new RefreshOrgMetadataCache.InvocableVariables();
            param.orgId = getCredential('dev').Id;
            param.metadataTypesToBeRefreshed = new Set<String>{ 'ApexClass' };
            param.isMetadataSavedToFile = true;
            String endpoint =
                Settings.server_url +
                '/json/v1/metadata/' +
                param.orgId +
                '?createSalesforceFile=true&filter=' +
                EncodingUtil.urlEncode(String.join(new List<String>(param.metadataTypesToBeRefreshed), ','), 'UTF-8') +
                '&mergeIndex=true';
            String response = getPartialRefreshApiResponse();
            Test.setMock(HttpCalloutMock.class, new TestHttpCalloutMock(200, response, endpoint));

            // EXERCISE

            Test.startTest();
            String apiResponse = RefreshOrgMetadataCache.executeRefresh(param);
            Test.stopTest();

            // VERIFY

            Assert.areEqual(getPartialRefreshApiResponse(), apiResponse, 'The metadata refresh api response is invalid');
        }
    }

    @IsTest
    private static void executeRefreshWithQueryParameters() {
        System.runAs(getUser()) {
            // SETUP

            RefreshOrgMetadataCache.InvocableVariables param = new RefreshOrgMetadataCache.InvocableVariables();
            param.orgId = getCredential('dev').Id;
            param.metadataTypesToBeRefreshed = new Set<String>{ 'ApexClass' };
            param.isMetadataSavedToFile = true;
            param.queryParameters = new Set<String>{ 'dates=format' };
            String endpoint =
                Settings.server_url +
                '/json/v1/metadata/' +
                param.orgId +
                '?createSalesforceFile=true&filter=' +
                EncodingUtil.urlEncode(String.join(new List<String>(param.metadataTypesToBeRefreshed), ','), 'UTF-8') +
                '&mergeIndex=true&dates=format';
            String response = getPartialRefreshApiResponse();
            Test.setMock(HttpCalloutMock.class, new TestHttpCalloutMock(200, response, endpoint));

            // EXERCISE

            Test.startTest();
            String apiResponse = RefreshOrgMetadataCache.executeRefresh(param);
            Test.stopTest();

            // VERIFY

            Assert.areEqual(getPartialRefreshApiResponse(), apiResponse, 'The metadata refresh api response is invalid');
        }
    }

    private static User getUser() {
        return [SELECT Id, Email FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1];
    }

    private static void createData() {
        new Credential().name('dev').persist();
    }

    private static Org__c getCredential(String name) {
        return [SELECT Id FROM Org__c WHERE Name = :name];
    }

    private static String getPartialRefreshApiResponse() {
        return '{"copadoJobId":"6e6e021f-6186-441e-af3b-0b9d9022e57a","ok":"Job has started!","status":"initializing"}';
    }

    private class TestHttpCalloutMock implements HttpCalloutMock {
        private Integer statusCode;
        private String response;
        private String endPoint;

        private TestHttpCalloutMock(Integer statusCode, String response, String endPoint) {
            this.statusCode = statusCode;
            this.response = response;
            this.endPoint = endPoint;
        }

        public HttpResponse respond(HttpRequest request) {
            Assert.areEqual(endPoint, request.getEndpoint(), 'The request endpoint should be ' + endPoint);
            HttpResponse response = new HttpResponse();
            response.setStatusCode(this.statusCode);
            response.setBody(this.response);
            return response;
        }
    }
}