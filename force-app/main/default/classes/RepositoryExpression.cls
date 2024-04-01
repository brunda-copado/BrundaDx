@SuppressWarnings('PMD')
public inherited sharing class RepositoryExpression extends DynamicExpression {
    private static final String HTTPS = 'https';
    private static final String SSH = 'ssh';

    private static final Pattern pattern1 = Pattern.compile('(?i)\\{\\$?(Context).(Repository).Credential\\}');
    private Git_Repository__c repository;

    // CONSTRUCTOR

    public RepositoryExpression(String contextId) {
        this.contextId = contextId;
    }

    // PUBLIC

    public override void prepare() {
        repository = repository();
    }

    public override Boolean matches(String expression) {
        return matches(pattern1, expression);
    }

    public override Jobs.DynamicExpressionEvaluateResult parse(String expression) {
        String result = null;
        if (matches(pattern1, expression)) {
            result = (repository == null) ? null : JSON.serialize(credential(repository));
        }

        return new Jobs.DynamicExpressionEvaluateResult(expression, result, true);
    }

    // PRIVATE

    private Git_Repository__c repository() {
        Git_Repository__c result = null;
        Id repositoryId = repositoryId();

        if (repositoryId != null) {
            result = [SELECT Id, URI__c, Allow_Functions_Git_Cache__c FROM Git_Repository__c WHERE Id = :repositoryId WITH SECURITY_ENFORCED];
        }

        return result;
    }

    private Id repositoryId() {
        Id result = null;

        for (String expression : expressions) {
            if (matches(pattern1, expression)) {
                result = toRepositoryId(contextId);
                break;
            }
        }

        return result;
    }

    private Id toRepositoryId(String repositoryId) {
        Id result = recordId();

        String sObjectName = result?.getSobjectType()?.getDescribe()?.getLocalName();

        if(sObjectName.equalsIgnoreCase('JobStep__c')) {
            JobStep__c step = [SELECT Git_Repository__c, JobExecution__r.Snapshot__r.Git_Repository__c FROM JobStep__c WHERE Id = :result WITH USER_MODE];
            result = step?.JobExecution__r?.Snapshot__r?.Git_Repository__c != null ? step?.JobExecution__r?.Snapshot__r?.Git_Repository__c : step.Git_Repository__c;
        } else if (!sObjectName.equalsIgnoreCase('Git_Repository__c')) {
            String query = 'SELECT Git_Repository__c FROM ' + String.escapeSingleQuotes(sObjectName) + ' WHERE Id = :result WITH SECURITY_ENFORCED';
            SObject parentRecord = Database.query(query);

            result = (Id) parentRecord.get('Git_Repository__c');
        }

        return result;
    }

    private Credential credential(Git_Repository__c repository) {
        Credential result = new Credential();

        result.url = repository.URI__c;
        result.type = repository.URI__c.startsWith(HTTPS) ? HTTPS : SSH;
        result.gitCache = repository.Allow_Functions_Git_Cache__c;

        if (result.type == SSH) {
            setSSHKey(repository, result);
        } else if (result.type == HTTPS) {
            setUserNamePassword(repository, result);
        }

        return result;
    }

    private void setSSHKey(Git_Repository__c repository, Credential Credential) {
        for (Attachment attachment : [
            SELECT Name, Body
            FROM Attachment
            WHERE ParentId = :repository.Id AND Name IN ('id_rsa', 'id_rsa.pub')
            WITH SECURITY_ENFORCED
        ]) {
            if (attachment.Name == 'id_rsa') {
                final String privateKey = attachment.Body?.toString();
                final Boolean isNotEncrypted = Pattern.compile('^\\s*-+BEGIN ').matcher(privateKey).find();
                Credential.privateKey = isNotEncrypted ? privateKey : DeployAPI.decryptAPIKey(privateKey);
            } else {
                Credential.publicKey = attachment.Body?.toString();
            }
        }
    }

    private void setUserNamePassword(Git_Repository__c repository, Credential Credential) {
        Sensitive_Information__c gitRepositoryConfiguration = Sensitive_Information__c.getValues(repository.Id);
        Credential.username = gitRepositoryConfiguration?.Username__c;
        Credential.password = DeployAPI.decryptAPIKey(gitRepositoryConfiguration?.Password__c);
        Credential.extraheaders = String.isNotBlank(gitRepositoryConfiguration?.Extra_Header__c) ? DeployAPI.decryptAPIKey(gitRepositoryConfiguration.Extra_Header__c) : '';
    }

    // INNER

    public class Credential {
        public String type;
        public String url;
        public String branch;
        public Boolean gitCache;

        public String publicKey;
        public String privateKey;

        public String username;
        public String password;
        public String extraheaders;
    }
}