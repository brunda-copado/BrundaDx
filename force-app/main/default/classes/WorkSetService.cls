public with sharing class WorkSetService implements CLIInterface {
    private static final Pattern TEMPLATE_PATTERN = Pattern.compile(
        '\\{\\$?[a-zA-Z_][a-zA-Z0-9_]*\\.[a-zA-Z_][a-zA-Z0-9_.]*(\\.[a-zA-Z_][a-zA-Z0-9_]*)?\\}'
    );

    // PUBLIC

    @SuppressWarnings('PMD.CyclomaticComplexity')
    public String run(CliProxy.CLIWrapper record) {
        Savepoint savePoint = Database.setSavepoint();

        try {
            assertAccess();

            Request request = (Request) JSON.deserialize(record.body, Request.class);
            User_Story__c userStory = selectUserStoryBy(request.criteria, request.value);

            if (String.isNotBlank(request.credentialName)) {
                updateCredential(userStory, request.credentialName);
                userStory = selectUserStoryBy(request.criteria, request.value);
            } else if (String.isBlank(userStory.Org_Credential__c)) {
                throw new CliException(Label.Credential_Not_Included_in_User_Story);
            } else if (String.isBlank(userStory.Project__c)) {
                throw new CliException(Label.Project_Not_Included_in_User_Story);
            }

            List<Deployment_Flow_Step__c> pipelineConnList = [
                SELECT Id, Branch__c
                FROM Deployment_Flow_Step__c
                WHERE Deployment_Flow__c = :userStory.Project__r.Deployment_Flow__c AND Source_Environment__c = :userStory.Environment__c
                WITH SECURITY_ENFORCED
            ];

            if (pipelineConnList.isEmpty()) {
                throw new CliException(Label.Org_Credential_Not_Included_In_Deployment_Flow);
            }
            String configFile = getConfigFile(userStory);

            return toResponse(userStory, pipelineConnList[0].Branch__c, configFile);
        } catch (Exception ex) {
            Database.rollback(savepoint);
            throw new CliException(ex.getMessage());
        }
    }

    // PRIVATE

    private static String getConfigFile(User_Story__c userStory) {
        String result;
        List<ExtensionKeyValueSetting__mdt> settings = new ExtensionKeyValueSettingsSelector()
            .byPlatformAndKey(userStory.Platform__c, 'CliConfiguration');

        String configFileName = !settings.isEmpty() ? settings[0].Value__c : '';

        if (!String.isBlank(configFileName)) {
            List<StaticResource> resources = new StaticResourcesSelector().byName(configFileName);

            result = resources.size() > 0 ? replaceDynamicExpressions(resources[0].Body.toString(), userStory.Project__r.Deployment_Flow__c) : null;
        }

        return result;
    }

    private static String replaceDynamicExpressions(String body, Id contextId) {
        List<String> dynamicExpressions = dynamicExpressions(body);
        String result = body;

        if (dynamicExpressions.isEmpty()) {
            return result;
        }

        Jobs.DynamicExpressionEvaluateRequest request = new Jobs.DynamicExpressionEvaluateRequest(contextId, dynamicExpressions);
        List<Jobs.DynamicExpressionEvaluateResult> responses = new Jobs.DynamicExpression().evaluate(request);

        for (Jobs.DynamicExpressionEvaluateResult response : responses) {
            String value = response.value == null ? '' : response.value;

            result = result.replace(response.dynamicExpression, value);
        }

        return result;
    }

    private static List<String> dynamicExpressions(String content) {
        List<String> result = new List<String>();

        Matcher m = TEMPLATE_PATTERN.matcher(content);

        while (m.find()) {
            result.add(m.group());
        }

        return result;
    }

    private String toResponse(User_Story__c userStory, String branch, String configFile) {
        Response result = new Response()
            .status(CliSfDataWrapper.StatusResult.OK.name())
            .environmentBranch(branch)
            .userStory(userStory)
            .configFile(configFile);

        return (JSON.serialize(result));
    }

    private void updateCredential(User_Story__c userStory, String credentialName) {
        List<Org__c> orgs = [SELECT Id, Name FROM Org__c WHERE Name = :credentialName WITH SECURITY_ENFORCED];

        if (orgs.isEmpty()) {
            throw new CliException(Label.InvalidOrgCredential);
        }
        userStory.Org_Credential__c = orgs[0].Id;
        userStory.Environment__c = null;

        DML.safeUpdate(
            new User_Story__c(Id = userStory.Id, Org_Credential__c = userStory.Org_Credential__c, Environment__c = userStory.Environment__c),
            'Could not update an User Story object on the Work Set process ( WorkSetService.updateCredential class )'
        );
    }

    private User_Story__c selectUserStoryBy(String field, String value) {
        String soqlString = 'SELECT Id, Name, Platform__c, Org_Credential__c, Environment__c, Base_Branch__c, Project__c, Project__r.Deployment_Flow__c, Project__r.Deployment_Flow__r.Main_Branch__c, Release__r.Base_Branch__c, (SELECT External_Id__c FROM User_Story_Commits__r ORDER BY Snapshot_Commit__r.Commit_Date__c DESC LIMIT 1) FROM User_Story__c WHERE {0} = :value LIMIT 1';
        String dynamicQuery = String.format(soqlString, new List<String>{ String.escapeSingleQuotes(field) });

        List<User_Story__c> result = Database.query(dynamicQuery);

        if (result.isEmpty()) {
            throw new CliException(String.format(Label.NoUserStoryFound, new List<String>{ field, value }));
        }

        return result[0];
    }

    private void assertAccess() {
        List<String> checkOlsList = CliSecurityService.checkOLS(
            new List<String>{ Schema.SObjectType.User_Story__c.getName(), Schema.SObjectType.Deployment_Flow_Step__c.getName() }
        );

        if (!checkOlsList.isEmpty()) {
            throw new CliException(Label.Insufficient_Access + checkOlsList);
        }
    }

    @TestVisible
    private class Request {
        public String value;
        public String criteria;
        public String credentialName;
    }

    @TestVisible
    private class Response extends CliSfDataWrapper {
        public User_Story__c userStory;
        public String environmentBranch;
        public String configFile;

        public Response status(String status) {
            this.status = status;
            return this;
        }

        public Response environmentBranch(String environmentBranch) {
            this.environmentBranch = environmentBranch;
            return this;
        }
        public Response userStory(User_Story__c userStory) {
            this.userStory = userStory;
            return this;
        }
        public Response configFile(String configFile) {
            this.configFile = configFile;
            return this;
        }
    }
}