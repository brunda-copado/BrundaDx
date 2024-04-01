public with sharing class FunctionCallout extends HttpCallout {
    private static final String NAMESPACE = Settings.ns;
    private static final String NAMED_CREDENTIAL = Settings.functionsNamedCredential;
    private Integer timeout = 120000;
    private String resultId;
    private String payload;
    private String apiKey;
    private Boolean isStandard = false;
    private Id userId = UserInfo.getUserId();

    private Boolean namedCredentialExists {
        get {
            if (namedCredentialExists == null) {
                namedCredentialExists = namedCredentialExists();
            }
            return namedCredentialExists;
        }
        private set;
    }

    public FunctionCallout(String resultId) {
        if (namedCredentialExists) {
            super('callout:' + namedCredential(), HttpMethod.POST);
            this.resultId = resultId;
        } else {
            throw new CopadoFunctionException(
                String.format(Label.Endpoint_not_Found, new List<String>{ String.valueOf(Settings.functionsNamedCredential) })
            );
        }
    }

    public FunctionCallout payload(String value) {
        this.payload = EncodingUtil.base64Encode(Crypto.encryptWithManagedIV('AES256', DeployAPI.getCryptoKey(), Blob.valueOf(value)));
        return this;
    }

    public FunctionCallout apiKey(String value) {
        this.apiKey = value;
        return this;
    }

    public FunctionCallout userId(Id value) {
        this.userId = value;
        return this;
    }

    public FunctionCallout requestTimeout(Integer value) {
        this.timeout = value;
        return this;
    }

    public FunctionCallout isStandard(Boolean value) {
        this.isStandard = value;
        return this;
    }

    /**
     * @exception throws Exception. Make sure to handle it from the calling context.
     */
    public FunctionCallout build() {
        setHeaders();
        body(payload);
        path('/function/' + resultId);
        timeout(timeout);

        return this;
    }

    public override Object processResponse() {
        HttpResponse response = response();
        Integer statusCode = response.getStatusCode();

        if (statusCode != 200 && statusCode != 201) {
            DML.safeUpdate(
                new Result__c(
                    Id = resultId,
                    End_Time__c = Datetime.now(),
                    Status__c = 'Failed',
                    Progress_Status__c = Label.Error,
                    Error_Message__c = errorMessage(response),
                    Error_Code__c = String.valueOf(statusCode)
                ),
                'Could not update a Result object to a Failed status for a Function response ( FunctionCallout.processResponse class )'
            );

            Result__c result = new ResultsSelector().byId(resultId);
            CallbackHelper.resultCallback(new FunctionsSelector().byId(result.Function__c), resultId, 'Error');
        } else {
            DML.safeUpdate(
                new Result__c(Id = resultId, Start_Time__c = Datetime.now(), Status__c = 'In Progress'),
                'Could not update a Result object to a In Progress status for a Function response ( FunctionCallout.processResponse class )'
            );

            FunctionResultMonitor.schedule();
        }

        return response;
    }

    // PRIVATE

    private String errorMessage(HttpResponse response) {
        Map<Integer, String> messageByErrorCode = new Map<Integer, String>{
            400 => Label.functionCalloutError400,
            401 => Label.functionCalloutError401,
            403 => Label.functionCalloutError403,
            500 => Label.functionCalloutError500
        };

        String message = messageByErrorCode.containsKey(response.getStatusCode()) ? messageByErrorCode.get(response.getStatusCode()) : '';
        message += String.format(Label.calloutError, new List<String>{ String.valueOf(response.getStatusCode()), response.getBody() });

        return message;
    }

    private void setHeaders() {
        header('userId', userId);
        header('copado-url', Settings.server_url);
        header('copado-namespace', NAMESPACE);
        header('Content-Type', 'application/json');
        header('token2', DeployAPI.getAuthToken2(userId));
        header('orgId', UserInfo.getOrganizationId());
        header('copado-api-key', apiKey);
        header('copado-standard-function', String.valueOf(isStandard));
        header('copado-encrypted', 'true');
    }

    // To avoid creating remote site settings for the named credential endpoint, we only query it to check if it exists
    // and then reference it using the 'callout:namedCredential' notation. This will allow us to throw our own expection,
    // as opposed to having Salesforce throw an UnexpectedException, which cannot be caught.
    @SuppressWarnings('PMD.ApexCRUDViolation')
    private Boolean namedCredentialExists() {
        List<NamedCredential> result = [SELECT Id FROM NamedCredential WHERE DeveloperName = :NAMED_CREDENTIAL];

        return !result.isEmpty();
    }

    private static String namedCredential() {
        String result = NAMED_CREDENTIAL;

        if (result == Settings.DEFAULT_FUNCTIONS_NAMED_CREDENTIAL) {
            result = NAMESPACE + result;
        }

        return result;
    }
}