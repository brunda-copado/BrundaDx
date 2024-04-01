@SuppressWarnings('PMD.CyclomaticComplexity')
public inherited sharing class CredentialExpression extends DynamicExpression {
    private static final Pattern CONTEXT_PATTERN1 = Pattern.compile('(?i)\\{\\s*\\$?Context\\.Credential\\.(Endpoint|EndpointURL|SessionId)\\s*\\}');
    private static final Pattern CONTEXT_PATTERN2 = Pattern.compile('(?i)\\{\\s*\\$?(Source|Destination)\\.Credential\\.(Endpoint|EndpointURL|SessionId)\\s*\\}');

    private SObject record;
    private String expression;
    private String objectName;
    private Map<Id, Org__c> credentialByEnvironment = new Map<Id, Org__c>();

    // CONSTRUCTOR

    public CredentialExpression(String contextId) {
        this.contextId = contextId;
    }

    // PUBLIC

    public override Boolean matches(String expression) {
        this.expression = expression;
        return (CONTEXT_PATTERN1.matcher(expression).matches() || CONTEXT_PATTERN2.matcher(expression).matches());
    }

    public override void prepare() {
        objectName = objectName(recordId());

        if (String.isNotBlank(objectName)) {
            if (objectName.equalsIgnoreCase('Deployment_Job__c')) {
                record = [SELECT Source_Id__c, Destination_Id__c FROM Deployment_Job__c WHERE Id = :contextId WITH SECURITY_ENFORCED];
            } else if (objectName.equalsIgnoreCase('JobStep__c')) {
                record = [SELECT Source_Id__c, Destination_Id__c, JobExecution__r.ParentId__c FROM JobStep__c WHERE Id = :contextId WITH SECURITY_ENFORCED];
            } else if (objectName.equalsIgnoreCase('Org__c')) {
                record = new Org__c(Id = (Id) contextId);
            } else if (objectName.equalsIgnoreCase('Environment__c')) {
                record = new Environment__c(Id = (Id) contextId);
            } else {
                throw new ApplicationException(String.format(Label.Context_Id_Not_Supported_For_Expression, new List<String>{ expression }));
            }
        } else {
            throw new ApplicationException(String.format(Label.Context_Id_Not_Supported_For_Expression, new List<String>{ expression }));
        }

        if (!objectName.equalsIgnoreCase('Org__c')) {
            credentialByEnvironment = credentialByEnvironment();
        }

        assertRecordIdExpression();
    }

    public override Jobs.DynamicExpressionEvaluateResult parse(String expression) {
        Matcher contextMatcher1 = CONTEXT_PATTERN1.matcher(expression);
        Matcher contextMatcher2 = CONTEXT_PATTERN2.matcher(expression);
        String value = null;
        String orgType;
        String propertyName;
        Id recordId;

        if (contextMatcher1.matches() && objectName.equalsIgnoreCase('JobStep__c')) {
            String contextEnvironmentField = contextEnvironmentField();
            propertyName = contextMatcher1.group(1);
            recordId = (Id) record.get(contextEnvironmentField);
        } else if (contextMatcher1.matches()) {
            orgType = 'Context';
            propertyName = contextMatcher1.group(1);
            recordId = (Id) record.get('Id');
        } else if (contextMatcher2.matches()) {
            orgType = contextMatcher2.group(1);
            propertyName = contextMatcher2.group(2);
            recordId = orgType == 'Source' ? getSourceId() : getDestinationId();
        }

        WebhookCallout.Credential credential = getCredentialCallout(
            objectName.equalsIgnoreCase('Org__c') ? recordId : getCredentialIdByEnvironment(recordId),
            orgType
        );
        value = propertyName.equalsIgnoreCase('SessionId') ? credential.sessionId : getEndpoint(propertyName, credential.endPoint);

        return new Jobs.DynamicExpressionEvaluateResult(expression, value, true);
    }

    // PRIVATE

    private String contextEnvironmentField() {
        Id parentId = (Id) getValue(record, 'JobExecution__r.ParentId__c');
        String parentObjectName = objectName(parentId);

        if (parentObjectName == 'User_Story_Commit__c' || parentObjectName == 'Promotion__c') {
            return 'Source_Id__c';
        } else if (parentObjectName == 'Deployment__c') {
            return 'Destination_Id__c';
        }

        throw new ApplicationException(Label.InvalidContextForBranchExpression);
    }

    private Id getSourceId() {
        return (Id) record.get('Source_Id__c');
    }

    private Id getDestinationId() {
        return (Id) record.get('Destination_Id__c');
    }

    public static String getEndpoint(String propertyName, String endpoint) {
        return propertyName.equalsIgnoreCase('Endpoint') ? endpoint : new Url(endpoint).getProtocol() + '://' + new Url(endpoint).getHost();
    }

    private Map<Id, Org__c> credentialByEnvironment() {
        Map<Id, Org__c> result = new Map<Id, Org__c>();

        Set<Id> environmentIds = environmentIds();

        for (Environment__c environment : [
            SELECT
                Id,
                (
                    SELECT Id, Default_Credential__c, OwnerId, Environment__r.Platform__c
                    FROM Org_Credentials__r
                    WHERE OwnerId = :UserInfo.getUserId() OR Default_Credential__c = TRUE
                )
            FROM Environment__c
            WHERE Id IN :environmentIds
            WITH SECURITY_ENFORCED
        ]) {
            result.put(environment.Id, userCredential(environment.Org_Credentials__r));
        }

        return result;
    }

    private Org__c userCredential(List<Org__c> orgs) {
        Org__c result;

        for (Org__c org : orgs) {
            if (org.OwnerId == UserInfo.getUserId()) {
                result = org;
                break;
            } else if (org.Default_Credential__c == true) {
                result = org;
            }
        }

        return result;
    }

    private void assertRecordIdExpression() {
        for (String expression : expressions) {
            Matcher contextMatcher1 = CONTEXT_PATTERN1.matcher(expression);
            String objectName = objectName(contextId);
            if (contextMatcher1.matches() && objectName != 'Environment__c' && objectName != 'JobStep__c' && objectName != 'Org__c') {
                throw new ApplicationException(String.format(Label.invalidContextId, new List<String>{ expression, Label.Org_Credential }));
            }
        }
    }

    private Set<Id> environmentIds() {
        Set<Id> result = new Set<Id>();
        String objectName = objectName(contextId);
        
        if (objectName == 'Environment__c') {
            result.add(contextId);
        }

        if (objectName == 'Deployment_Job__c' || objectName == 'JobStep__c') {
            result.add(getSourceId());
            result.add(getDestinationId());
        }

        return result;
    }

    private Id getCredentialIdByEnvironment(Id environmentId) {
        Org__c org = credentialByEnvironment.get(environmentId);

        if (org == null) {
            throw new ApplicationException(String.format(Label.credentialNotAvailable, new List<String>{ environmentId }));
        }
        return org.Id;
    }

    private WebhookCallout.Credential getCredentialCallout(Id orgId, String orgType) {
        Integer maxTimeout = 120000;
        String clientKey = [SELECT Text_Field__c FROM Copado_Protected_Settiing__mdt WHERE DeveloperName = 'FunctionCredentialClientKey' LIMIT 1]
        .Text_Field__c;

        HttpCallout callout = new WebhookCallout(path(orgId))
            .type(WebhookCallout.Credential.class)
            .timeout(maxTimeout)
            .header('Content-Type', 'application/json')
            .header('X-Client-Key', clientKey)
            .request();

        // TODO: ADD API KEY ERROR AND OTHER DETAILS
        if (callout.response().getStatusCode() == 401) {
            throw new ApplicationException(Label.ApiKeyExpired);
        } else if (callout.response().getStatusCode() != 200) {
            throw new ApplicationException(String.format(Label.InvalidRequest, new List<String>{ orgType }));
        }

        WebhookCallout.Credential result = (WebhookCallout.Credential) callout.parseResponse();

        if (result.isSuccess != true) {
            throw new ApplicationException(result.error);
        }

        return result;
    }

    private String path(Id orgId) {
        return Settings.server_url + '/json/v1/webhook/copadoSession/' + orgId + '?api_key=' + apiKey();
    }

    // Note: this runs as an Automated process user so not CRUD check needed
    @SuppressWarnings('PMD.ApexCRUDViolation')
    private String apiKey() {
        Id loggedInUserId = UserInfo.getUserId();

        List<Personal_Settings__c> settings = [SELECT API_Key__c FROM Personal_Settings__c WHERE SetupOwnerId = :loggedInUserId LIMIT 1];

        if (settings.isEmpty() || String.isBlank(settings[0].API_Key__c)) {
            throw new ApplicationException(String.format(Label.APIKeyNotFound, new List<String>{ UserInfo.getName() }));
        }

        return DeployAPI.decryptAPIKey(settings[0].API_Key__c);
    }
}