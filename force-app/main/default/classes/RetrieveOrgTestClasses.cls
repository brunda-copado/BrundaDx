public with sharing class RetrieveOrgTestClasses {
    private static final String TOOLING_API_PATH = '/services/data/v52.0/tooling';

    // CTOR

    // Note: We need to add it to use the remote action from apexTestResult.js
    public RetrieveOrgTestClasses(Settings settings) {} // NOPMD

    // PUBLIC

    @RemoteAction
    public static String execute(String credentialId) {
        try {
            String query = 'FIND+%7B@isTest+OR+@+isTest+OR+testMethod+void%7D+IN+ALL+FIELDS+RETURNING+ApexClass+(Name,NamespacePrefix+WHERE+Status=\'Active\'+ORDER+BY+LastModifiedDate+DESC)';
            SalesforceAPIProxyResponse response = queryOrg('Query Org Test Classes', query, credentialId);
            return response.content;
        } catch (Exception e) {
            return null;
        }
    }

    // Note: This is a temporary method until new apex test logic is GA
    @RemoteAction
    public static Boolean isApexTestsV2ToggleOff() {
        return new UniversalFeatureToggle().isDisabled(UniversalFeatureToggle.Feature.APEX_TESTS_WITH_V2);
    }

    // PRIVATE

    private static SalesforceAPIProxyResponse queryOrg(String queryIdentifier, String query, String credentialId) {
        String queryPath = '/search/?q=';

        SalesforceAPIProxyRequest proxyPayload = new SalesforceAPIProxyRequest(TOOLING_API_PATH + queryPath + query, credentialId)
            .logLabelIdentifier(queryIdentifier);
		
        return (SalesforceAPIProxyResponse) new SalesforceAPIProxyCallout()
            .default()
            .body(proxyPayload)
            .request()
            .type(SalesforceAPIProxyResponse.class)
            .parseResponse();
    }
}