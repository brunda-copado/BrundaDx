@SuppressWarnings('PMD.AvoidGlobalModifier')
global with sharing class RefreshOrgMetadataCache {
    /**
     * Custom object for storing InvocableVariables. InvocableMethods requires List<T> where T is a user defined type.
     * You cannot pass Boolean, String or any other primitive type as a variable to an Invocable method.
     * Custom Object types, sObjects or Ids are the only supported types.
     * @see InvocableVariable
     * @see InvocableMethod
     */
    global with sharing class InvocableVariables {
        @InvocableVariable(label='Org Credentials Id' required=true)
        global Id orgId;
        global Set<String> metadataTypesToBeRefreshed;
        global Boolean isMetadataSavedToFile;
        global Set<String> queryParameters;
    }
    /**
     * Invocable method for allowing users to call Copado webhook urls for running a selenium test from Process builder
     * @param  variables InvocableVariables
     * @return           void
     * @see InvocableVariable
     * @see InvocableMethod
     * @see RefreshOrgMetadataCache.doCallout
     */
    @InvocableMethod(label='Refresh Org Metadata Cache' description='Sends request to given Copado webhookUrl')
    global static void execute(List<InvocableVariables> variables) {
        String apiKey = DeployAPI.getUserAPIKey();
        String copadoURL = Settings.Server_URL;
        if (String.isBlank(apiKey)) {
            throw new AsyncException(System.Label.API_KEY_MISSING);
        }
        String url = copadoURL + '/json/v1/webhook/metadata/' + variables[0].orgId + '?api_key=' + apiKey;
        RefreshOrgMetadataCache.doCallout(url);
    }

    global static String executeRefresh(InvocableVariables params) {
        validateParams(params);
        String endpoint = getEndpoint(params);
        HttpRequest request = getHttpRequest(endpoint);
        HttpResponse response = makeCallout(request);
        return response.getBody();
    }

    /**
     * Future method that executes the HTTP request against given webhook.
     * Defined as future in order to avoid "You have uncommitted work pending. Please commit or rollback before calling out" issue
     * Since process builder depends on a DML on the given object there will always be an uncommited work for immediate actions
     * @param url     Complete copado webhook url that will appear as a required parameter while creating the process from process builder
     */
    @Future(callout=true)
    private static void doCallout(String url) {
        WebhookAPI.callGenericWebhook(url);
    }

    private static void validateParams(InvocableVariables params) {
        if (params == null) {
            throw new ApplicationException(Label.Metadata_Refresh_Invalid_Parameter);
        }
        if (String.isBlank(params.orgId)) {
            throw new ApplicationException(Label.Metadata_Refresh_Invalid_Credential);
        }
    }

    private static String getEndpoint(InvocableVariables params) {
        String endpointTemplate = '{0}/json/v1/metadata/{1}';
        List<Object> templateParams = new List<Object>();
        templateParams.add(Settings.server_url);
        templateParams.add(params.orgId);
        String result = String.format(endpointTemplate, templateParams);
        List<String> queryParameters = getQueryParameters(params);
        if (!queryParameters.isEmpty()) {
            result += '?' + String.join(queryParameters, '&');
        }
        return result;
    }

    private static HttpRequest getHttpRequest(String endpoint) {
        HttpRequest request = new HttpRequest();
        DeployAPI.setAuthHeaders(request);
        request.setEndpoint(endpoint);
        request.setMethod('GET');
        return request;
    }

    private static HttpResponse makeCallout(HttpRequest request) {
        Http http = new Http();
        HttpResponse response = http.send(request);
        if (response.getStatusCode() != 200) {
            throw new ApplicationException(response.getBody());
        }
        return response;
    }

    private static List<String> getQueryParameters(InvocableVariables params) {
        List<String> result = new List<String>();
        if (params.isMetadataSavedToFile != null && params.isMetadataSavedToFile) {
            result.add('createSalesforceFile=true');
        }
        if (params.metadataTypesToBeRefreshed != null && !params.metadataTypesToBeRefreshed.isEmpty()) {
            result.add('filter=' + EncodingUtil.urlEncode(String.join(new List<String>(params.metadataTypesToBeRefreshed), ','), 'UTF-8'));
            result.add('mergeIndex=true');
        }
        if (params.queryParameters != null && !params.queryParameters.isEmpty()) {
            result.addAll(params.queryParameters);
        }
        return result;
    }
}