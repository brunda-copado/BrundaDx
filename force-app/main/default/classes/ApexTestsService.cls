public with sharing class ApexTestsService {
    private static final String TOOLING_API_PATH = '/services/data/v52.0/tooling';

    private String credentialId;

    // CTOR

    public ApexTestsService(String credentialId) {
        this.credentialId = credentialId;
    }

    // PUBLIC

    public String delegateRun(String testClassNames) {
        SalesforceAPIProxyRequest proxyPayload = new SalesforceAPIProxyRequest(TOOLING_API_PATH + '/runTestsAsynchronous', credentialId)
            .requestType(HttpMethod.POST.name())
            .logLabelIdentifier('Delegate Apex Tests Execution')
            .requestPayload('{"classNames": "' + testClassNames + '"}');

        SalesforceAPIProxyResponse response = (SalesforceAPIProxyResponse) new SalesforceAPIProxyCallout()
            .default()
            .body(proxyPayload)
            .request()
            .type(SalesforceAPIProxyResponse.class)
            .parseResponse();

        if (response.statusCode != null && response.errorCode == 'ALREADY_IN_PROCESS') {
            throw new ApplicationException(Label.ApexTestAlreadyInProcess);
        }

        return response.content.remove('"');
    }

    public String queryRunStatus(String asyncJobId) {
        String query = 'SELECT+Status+FROM+ApexTestRunResult+WHERE+AsyncApexJobId=\'' + asyncJobId + '\'';

        SalesforceAPIProxyResponse response = queryOrg('Get Test Run Status', query, credentialId);

        Map<String, Object> json = (Map<String, Object>) JSON.deserializeUntyped(response.content);
        List<Object> queryRecords = (List<Object>) json.get('records');
        Map<String, Object> testRun = (Map<String, Object>) queryRecords[0];
        String status = (String) testRun.get('Status');

        return status;
    }

    public ApexTestRunResult queryResults(String asyncJobId) {
        String query =
            'SELECT+Apexclass.Name,MethodName,Outcome,RunTime,Message,StackTrace+FROM+ApexTestResult+WHERE+AsyncApexJobId=\'' +
            asyncJobId +
            '\'';

        SalesforceAPIProxyResponse response = queryOrg('Query Apex Tests Results', query, credentialId);

        return (ApexTestRunResult) JSON.deserialize(response.content, ApexTestRunResult.class);
    }

    // PRIVATE

    private static SalesforceAPIProxyResponse queryOrg(String queryIdentifier, String query, String credentialId) {
        String queryPath = '/query/?q=';

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