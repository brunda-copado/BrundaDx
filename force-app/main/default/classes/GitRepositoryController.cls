@SuppressWarnings('PMD.CyclomaticComplexity, PMD.CognitiveComplexity')
public with sharing class GitRepositoryController {
    private static final Integer EXTRA_HEADER_LENGTH_LIMIT = 255;
    private static final String HTTPS = 'HTTPS';
    private static final String SSH = 'SSH';
    private static final String EXTRA_HEADERS = 'Extra Headers';
    private static final String SSH_KEY_NAME = 'id_rsa.pub';

    // PUBLIC

    @AuraEnabled(cacheable=false)
    public static String init(Id repositoryId) {
        String result = '';

        try {
            if (!hasLicense()) {
                throw new AuraHandledException(Label.CE_License_Restriction.replace('__License__', Label.CCH_License));
            }

            Git_Repository__c repository = repository(repositoryId);

            if (repository != null) {
                result = JSON.serialize(new Configuration(repository));
            }
        } catch (Exception error) {
            throw new ApplicationException().auraHandled(error);
        }

        return result;
    }

    @AuraEnabled(cacheable=false)
    public static String validateGitConnection(Id repositoryId) {
        String result = '';

        try {
            DeployAPI.validateGitResult response = DeployAPI.validateGit(repositoryId);

            if (response != null) {
                result = JSON.serialize(response);
            }
        } catch (Exception error) {
            throw new ApplicationException().auraHandled(error);
        }

        return result;
    }

    @AuraEnabled
    public static String createSSHKey(Id repositoryId) {
        String result = '';

        try {
            if (String.isNotBlank(repositoryId)) {
                result = DeployAPI.createSSHKeyForLWC(repositoryId);
            }
        } catch (Exception error) {
            throw new ApplicationException().auraHandled(error);
        }

        return result;
    }

    @AuraEnabled(cacheable=false)
    public static void deleteSSHKey(Id attachmentId) {
        try {
            if (String.isNotBlank(attachmentId)) {
                List<Attachment> attachments = new AttachmentsSelector().byId(new Set<Id>{ attachmentId });

                if (!attachments.isEmpty()) {
                    Utilities.Secure_DML(attachments, Utilities.DML_Action.DEL, SObjectType.Attachment);
                }
            }
        } catch (Exception error) {
            throw new ApplicationException().auraHandled(error);
        }
    }

    @AuraEnabled(cacheable=false)
    public static String getSSHKey(Id repositoryId) {
        String result = '';

        try {
            if (String.isNotBlank(repositoryId)) {
                result = JSON.serialize(new SSHKey(repositoryId));
            }
        } catch (Exception error) {
            throw new ApplicationException().auraHandled(error);
        }

        return result;
    }

    @AuraEnabled(cacheable=false)
    @SuppressWarnings('PMD.ExcessiveParameterList')
    public static void save(Id repositoryId, String authType, String username, String password, String extraHeaders) {
        try {
            if (String.isNotBlank(repositoryId) && !Utilities.HasEditAccess(repositoryId)) {
                throw new AuraHandledException(Label.InSuffPriv);
            }

            Sensitive_Information__c configuration = configuration(repositoryId, authType, username, password);

            String encryptedHeaders = DeployAPI.encryptAPIKey(extraHeaders);
            Boolean hasNotesDeleted = false;

            if (String.isNotBlank(encryptedHeaders)) {
                if (encryptedHeaders.length() > EXTRA_HEADER_LENGTH_LIMIT) {
                    List<Note> notes = notes(repositoryId);

                    Note note = notes.isEmpty() ? new Note(Title = EXTRA_HEADERS, ParentId = repositoryId) : notes[0];
                    note.Body = encryptedHeaders;

                    Utilities.Secure_DML(note, Utilities.DML_Action.UPS, SObjectType.Note);
                } else {
                    configuration.Extra_Header__c = encryptedHeaders;
                    hasNotesDeleted = true;
                }
            } else {
                hasNotesDeleted = true;
            }

            if (hasNotesDeleted) {
                Utilities.Secure_DML(notes(repositoryId), Utilities.DML_Action.DEL, SObjectType.Note);
            }

            Utilities.Secure_DML(configuration, Utilities.DML_Action.UPS, SObjectType.Sensitive_Information__c);
        } catch (Exception error) {
            throw new ApplicationException().auraHandled(error);
        }
    }

    // PRIVATE

    private static Boolean hasLicense() {
        return LicenseHelper.actionIsLicenseEnabled('viewEditGitRepository');
    }

    private static Git_Repository__c repository(Id id) {
        Git_Repository__c result;

        List<Git_Repository__c> repositories = new GitRepositoriesSelector().byId(new Set<Id>{ id });

        if (!repositories.isEmpty()) {
            result = repositories[0];
        }

        return result;
    }

    @SuppressWarnings('PMD.ExcessiveParameterList')
    private static Sensitive_Information__c configuration(Id repositoryId, String authType, String username, String password) {
        Sensitive_Information__c result = Sensitive_Information__c.getInstance(repositoryId);

        if (result == null) {
            result = new Sensitive_Information__c(Name = repositoryId);
        }

        if (authType == HTTPS) {
            result.Username__c = username;
            result.Password__c = DeployAPI.encryptAPIKey(password);
        }

        return result;
    }

    private static List<Note> notes(Id parentId) {
        return [SELECT Title, Body FROM Note WHERE ParentId = :parentId AND Title = :EXTRA_HEADERS WITH USER_MODE];
    }

    private with sharing class Configuration {
        private String username;
        private String headers;
        private String authType;
        private SSHKey sshKey;

        public Configuration(Git_Repository__c repository) {
            Sensitive_Information__c configuration = Sensitive_Information__c.getInstance(repository.Id);

            if (configuration != null) {
                this.username = configuration.Username__c;

                if (!repository.URI__c.startsWith('https')) {
                    this.authType = GitRepositoryController.SSH;
                    this.sshKey = new SSHKey(repository.Id);
                } else {
                    this.authType = GitRepositoryController.HTTPS;
                    this.headers = headers(repository, configuration);
                }
            }
        }

        // PRIVATE

        private String headers(Git_Repository__c repository, Sensitive_Information__c configuration) {
            String result = '';

            if (String.isNotBlank(configuration.Extra_Header__c)) {
                result = configuration.Extra_Header__c;
            } else {
                List<Note> notes = GitRepositoryController.notes(repository.Id);

                if (!notes.isEmpty()) {
                    result = notes[0].Body;
                }
            }

            return result;
        }
    }

    private with sharing class SSHKey {
        private String key;
        private String attachmentId;

        public SSHKey(Id repositoryId) {
            List<Attachment> attachments = attachments(repositoryId);

            if (!attachments.isEmpty()) {
                this.key = attachments[0].Body?.toString();
                this.attachmentId = attachments[0].Id;
            }
        }

        // PRIVATE

        private List<Attachment> attachments(Id repositoryId) {
            return new AttachmentsSelector().byParentIdAndName(new Set<Id>{ repositoryId }, new Set<String>{ GitRepositoryController.SSH_KEY_NAME });
        }
    }
}