@SuppressWarnings('PMD.AvoidGlobalModifier')
// AvoidGlobalModifier: As we want to expose the services as global, thus the modifier

global inherited sharing class APIProxy {
    private static final Integer TWO_MINUTES = 120000;
    // GLOBAL
    /*
        SENSITIVE METHOD
        - Changes in this method will potentially impact many usages and use cases.
        - Please get an architect approval before changing this method.
        - [TDD] If the change is approved please start by creating a Unit test for your change first.
        - When the change is done execute the APIProxyTest.
        - Pull request for changes happened in this method must contain an architect approval.
    */

    global static HttpResponse callAI(String payload) {
        String path = '/copadoai/open-ai/chat/completions';
        assertRequest(path);

        return new Callout(namedCredential())
                        .header('userId', UserInfo.getUserId())
                        .header('copado-url', Settings.server_url)
                        .header('copado-namespace', Settings.ns)
                        .header('Content-Type', 'application/json')
                        .header('token2', DeployAPI.getAuthToken2(UserInfo.getUserId()))
                        .header('orgId', UserInfo.getOrganizationId())
                        .header('copado-api-key', new Settings().mySettings.API_Key__c)
                        .body(payload)
                        .path(path)
                        .timeout(TWO_MINUTES)
                        .request()
                        .response();
    }


    /*
        SENSITIVE METHOD
        - Changes in this method will potentially impact many usages and use cases.
        - Please get an architect approval before changing this method.
        - [TDD] If the change is approved please start by creating a Unit test for your change first.
        - When the change is done execute the APIProxyTest.
        - Pull request for changes happened in this method must contain an architect approval.
    */

    global static HttpResponse getAISession(String payload) {
        String path = '/copadoai/aicompanion/auth_token';
        assertRequest(path);

        String companionAPIKey = Settings__c.getOrgDefaults().AI_Companion_API_Key__c;

        return new Callout(namedCredential())
                        .header('userId', UserInfo.getUserId())
                        .header('copado-url', Settings.server_url)
                        .header('copado-namespace', Settings.ns)
                        .header('Content-Type', 'application/json')
                        .header('Authorization', 'Bearer ' + companionAPIKey)
                        .header('orgId', UserInfo.getOrganizationId())
                        .body(payload)
                        .path(path)
                        .timeout(TWO_MINUTES)
                        .request()
                        .response();
    }


    // PRIVATE

    private static void assertRequest(String path) {
        String featureParameterName = featureParameterName(path);

        if(String.isBlank(featureParameterName)) {
            throw new ApplicationException(Label.InvalidEndpoint + path);
        }

        Integer apiLimit = FeatureManagement.checkPackageIntegerValue(featureParameterName);
        if(apiLimit == 0) {
            throw new ApplicationException(Label.FEATURE_NOT_SUPPORTED + featureParameterName);
        }
    }


    private static String namedCredential() {
        String result = Settings.functionsNamedCredential;

        // Note: for Default credential(mc_backend) namespace needs to be added in packaged org
        if (result == Settings.DEFAULT_FUNCTIONS_NAMED_CREDENTIAL) {
            result = Settings.ns + result;
        }

        return result;
    }


	private static String featureParameterName(String path) {
        String result = null;

        if(path.startsWith('/copadoai')) {
            result = 'AI_Enabled';
        }

		return result;
	}


    // INNER

    private inherited sharing class Callout extends HttpCallout {
        private Boolean namedCredentialExists {
            get {
                if (namedCredentialExists == null) {
                    namedCredentialExists = namedCredentialExists();
                }
                return namedCredentialExists;
            }
            private set;
        }

        // CONSTRUCTOR

        private Callout(String namedCredential) {
            if (namedCredentialExists) {
                super('callout:' + namedCredential, HttpMethod.POST);
            } else {
                throw new CopadoFunctionException(
                    String.format(Label.Endpoint_not_Found, new List<String>{ String.valueOf(Settings.functionsNamedCredential) })
                );
            }
        }


        // PRIVATE

        // To avoid creating remote site settings for the named credential endpoint, we only query it to check if it exists
        // and then reference it using the 'callout:namedCredential' notation. This will allow us to throw our own expection,
        // as opposed to having Salesforce throw an UnexpectedException, which cannot be caught.
        @SuppressWarnings('PMD.ApexCRUDViolation')
        private Boolean namedCredentialExists() {
            List<NamedCredential> result = [SELECT Id FROM NamedCredential WHERE DeveloperName = :Settings.functionsNamedCredential];

            return !result.isEmpty();
        }
    }
}