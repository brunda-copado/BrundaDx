@SuppressWarnings('PMD.StdCyclomaticComplexity, PMD.NcssMethodCount, PMD.CognitiveComplexity, PMD.CyclomaticComplexity')
public with sharing class ValidateGitSnapshot {
    private static final String SALESFORCE = 'Salesforce';
    private static final String SCHEDULE = 'Schedule';

    private List<Git_Backup__c> gitSnapshots;
    private Set<Id> credentialIds;
    private Set<Id> pipelineIds;
    private Set<Id> userIds;
    private ValidationMode mode;

    private Map<Id, Org__c> credentialById {
        get {
            if (credentialById == null) {
                credentialById = new Map<Id, Org__c>(
                    [SELECT Platform__c, Environment__c FROM Org__c WHERE Id IN :credentialIds WITH SECURITY_ENFORCED]
                );
            }
            return credentialById;
        }
        set;
    }
    private Map<Id, Deployment_Flow__c> pipelineById {
        get {
            if (pipelineById == null) {
                pipelineById = new Map<Id, Deployment_Flow__c>(
                    [
                        SELECT
                            Active__c,
                            Platform__c,
                            (SELECT Branch__c, Source_Environment__c, Destination_Environment__c FROM Deployment_Flow_Steps__r),
                            (SELECT Id FROM Pipeline_Actions__r WHERE Action__c = :ActionConstants.TAKE_SNAPSHOT)
                        FROM Deployment_Flow__c
                        WHERE Id IN :pipelineIds
                        WITH SECURITY_ENFORCED
                    ]
                );
            }
            return pipelineById;
        }
        set;
    }
    private Map<Id, User> userById {
        get {
            if (userById == null) {
                userById = new Map<Id, User>([SELECT IsActive FROM User WHERE Id IN :userIds WITH SECURITY_ENFORCED]);
            }
            return userById;
        }
        set;
    }

    // PUBLIC

    public ValidateGitSnapshot() {
        this.mode = ValidationMode.ACTION_MODE;
    }

    public ValidateGitSnapshot mode(ValidationMode mode) {
        this.mode = mode;
        return this;
    }

    public ValidateGitSnapshot forTrigger(List<Git_Backup__c> gitSnapshots) {
        gitSnapshots(gitSnapshots);
        mode(ValidationMode.TRIGGER_MODE);
        return this;
    }

    public List<String> execute(Git_Backup__c gitSnapshot) {
        if (gitSnapshots == null) {
            gitSnapshots(new List<Git_Backup__c>{ gitSnapshot });
        }

        List<String> errorMessages = new List<String>();

        switch on mode {
            when TRIGGER_MODE {
                Id userId = UserInfo.getUserId();
                if (!hasLicense(userId)) {
                    errorMessages.add(Label.CopadoAdminLicenseIsRequiredCurrentUser);
                }
                if (!hasPermission(userId)) {
                    errorMessages.add(Label.ConfigureSnapshotPermIsRequiredCurrentUser);
                }
                if (!pipelineIsActive(gitSnapshot)) {
                    errorMessages.add(Label.PipelineIsNotActive);
                }
                if (!pipelineIsMulticloud(gitSnapshot)) {
                    errorMessages.add(Label.SecondGenPlatformShouldBeAssociated);
                }
                if (!credentialIsMulticloud(gitSnapshot)) {
                    errorMessages.add(Label.SecondGenCredentialShouldBeAssociated);
                }
                if (!credentialBelongsToPipeline(gitSnapshot)) {
                    errorMessages.add(Label.EnvironmentMustBeAssociatedToPipeline);
                }
                if (!cronExpressionPopulatedForScheduled(gitSnapshot)) {
                    errorMessages.add(Label.CronExpressionIsRequired);
                }
            }
            when ACTION_MODE {
                Id userId = UserInfo.getUserId();
                if (!hasLicense(userId)) {
                    errorMessages.add(Label.CopadoAdminLicenseIsRequired);
                }
                if (!hasPermission(userId)) {
                    errorMessages.add(Label.ConfigureSnapshotPermIsRequiredCurrentUser);
                }
                if (!pipelineIsActive(gitSnapshot)) {
                    errorMessages.add(Label.SnapshotPipelineNotActive);
                }
                if (!credentialBelongsToPipeline(gitSnapshot)) {
                    errorMessages.add(Label.EnvironmentMustBeAssociatedToPipeline);
                }
                if (alreadyRunning(gitSnapshot)) {
                    errorMessages.add(Label.SnapshotAlreadyRunning);
                }
            }
            when PAGE_MODE {
                Id userId = getUser(gitSnapshot);
                if (!userActive(userId)) {
                    errorMessages.add(Label.UserIsNotActive);
                } else if (!hasLicense(userId)) {
                    errorMessages.add(Label.CopadoAdminLicenseIsRequired);
                } else if (!hasPermission(userId)) {
                    errorMessages.add(Label.ConfigureSnapshotPermIsRequiredOwner);
                } else if (!pipelineIsActive(gitSnapshot)) {
                    errorMessages.add(Label.SnapshotPipelineNotActive);
                } else if (!credentialBelongsToPipeline(gitSnapshot)) {
                    errorMessages.add(Label.EnvironmentMustBeAssociatedToPipeline);
                } else if (!pipelineActionDefined(gitSnapshot)) {
                    errorMessages.add(Label.SnapshotActionNotDefined);
                } else if (!validRepository(gitSnapshot)) {
                    errorMessages.add(
                        String.format(Label.SnapshotRepositoryNotAuthenticated, new List<String>{ gitSnapshot.Git_Repository__r.Name })
                    );
                }
            }
        }

        return errorMessages;
    }

    // PRIVATE

    private ValidateGitSnapshot gitSnapshots(List<Git_Backup__c> gitSnapshots) {
        this.gitSnapshots = gitSnapshots;
        this.credentialIds = new Set<Id>();
        this.pipelineIds = new Set<Id>();
        this.userIds = new Set<Id>();
        for (Git_Backup__c gitSnapshot : gitSnapshots) {
            this.credentialIds.add(gitSnapshot.Org__c);
            this.pipelineIds.add(gitSnapshot.Pipeline__c);
            this.userIds.add(gitSnapshot.CreatedById);
            this.userIds.add(UserInfo.getUserId());
        }
        return this;
    }

    private Boolean hasLicense(Id userId) {
        LicenseHelper.automatedProcessTriggeringUserId = userId;
        return LicenseHelper.isCopadoEnabled();
    }

    private Boolean hasPermission(Id userId) {
        return Utilities.checkPermission('Configure_Snapshot', new Set<Id>{userId}, false);
    }

    private Boolean pipelineIsActive(Git_Backup__c gitSnapshot) {
        return pipelineById.get(gitSnapshot.Pipeline__c).Active__c == true;
    }

    private Boolean pipelineIsMulticloud(Git_Backup__c gitSnapshot) {
        String platform = pipelineById.get(gitSnapshot.Pipeline__c).Platform__c;
        return String.isNotBlank(platform) && platform != SALESFORCE;
    }

    private Boolean credentialIsMulticloud(Git_Backup__c gitSnapshot) {
        String platform = credentialById.get(gitSnapshot.Org__c).Platform__c;
        return String.isNotBlank(platform) && platform != SALESFORCE;
    }

    private Boolean credentialBelongsToPipeline(Git_Backup__c gitSnapshot) {
        Id snapshotEnvironment = credentialById.get(gitSnapshot.Org__c).Environment__c;
        for (Deployment_Flow_Step__c connection : pipelineById.get(gitSnapshot.Pipeline__c).Deployment_Flow_Steps__r) {
            if (connection.Source_Environment__c == snapshotEnvironment || connection.Destination_Environment__c == snapshotEnvironment) {
                return true;
            }
        }
        return false;
    }

    private Boolean cronExpressionPopulatedForScheduled(Git_Backup__c gitSnapshot) {
        return !isScheduled(gitSnapshot) || (isScheduled(gitSnapshot) && String.isNotBlank(gitSnapshot.Cron_Expression__c));
    }

    private Boolean alreadyRunning(Git_Backup__c gitSnapshot) {
        return [
                SELECT COUNT()
                FROM JobExecution__c
                WHERE Snapshot__c = :gitSnapshot.Id AND Status__c = :JobExecutionConstants.STATUS_IN_PROGRESS
                WITH SECURITY_ENFORCED
            ] > 0;
    }

    private Boolean validRepository(Git_Backup__c gitSnapshot) {
        DeployAPI.validateGitResult validation = DeployAPI.validateGit(gitSnapshot.Git_Repository__c);
        return validation.success;
    }

    private Boolean pipelineActionDefined(Git_Backup__c gitSnapshot) {
        return !pipelineById.get(gitSnapshot.Pipeline__c).Pipeline_Actions__r.isEmpty();
    }

    private Boolean userActive(Id userId) {
        return userById.get(userId).IsActive;
    }

    private Boolean isScheduled(Git_Backup__c gitSnapshot) {
        return gitSnapshot.Snapshot_Frequency__c == SCHEDULE;
    }

    private Id getUser(Git_Backup__c gitSnapshot) {
        return isScheduled(gitSnapshot) ? gitSnapshot.CreatedById : UserInfo.getUserId();
    }

    // INNER

    public enum ValidationMode {
        TRIGGER_MODE,
        ACTION_MODE,
        PAGE_MODE
    }
}