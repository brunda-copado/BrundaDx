@SuppressWarnings('PMD.CyclomaticComplexity')
public with sharing class ValidateCommitRequirements {
    private Id recordId;
    private User_Story__c userStory {
        get {
            if (userStory == null) {
                List<User_Story__c> userStories = new UserStoriesSelector().byIdsForMulticloud(new Set<Id>{ this.recordId });
                if (!userStories.isEmpty()) {
                    userStory = userStories[0];
                }
            }
            return userStory;
        }
        set;
    }

    // CTOR

    public ValidateCommitRequirements(Id recordId) {
        this.recordId = recordId;
    }

    public ValidateCommitRequirements(User_Story__c userStory) {
        this.userStory = userStory;
    }

    // PUBLIC

    public List<String> execute() {
        if (userStory == null) {
            throw new ApplicationException(Label.InvalidUserStoryForValidation);
        }

        List<String> result = new List<String>();

        List<String> validationErrors = validateRequirements(userStory);
        result.addAll(validationErrors);
        return result;
    }

    // PRIVATE

    private static List<String> validateRequirements(User_Story__c userStory) {
        List<String> result = new List<String>();

        List<Requirement> requirements = new List<Requirement>();
        requirements.addAll(hasRequiredLicenses());
        requirements.addAll(hasSobjectPermissions());
        requirements.addAll(pipelineIsValid(userStory));
        requirements.addAll(userStoryIsValid(userStory));
        requirements.addAll(commitNotInProgress(userStory));

        result.addAll(getValidationErrors(requirements));

        return result;
    }

    private static List<String> getValidationErrors(List<Requirement> requirements) {
        List<String> result = new List<String>();

        for (Requirement requirement : requirements) {
            if (requirement.getPriority() == 1) {
                result.add(requirement.getMesssage());
            }
        }
        if (result.isEmpty()) {
            for (Requirement requirement : requirements) {
                if (requirement.getPriority() == 2) {
                    result.add(requirement.getMesssage());
                }
            }
        }

        return result;
    }

    private static List<Requirement> commitNotInProgress(User_Story__c userStory) {
        List<Requirement> result = new List<Requirement>();

        List<JobExecution__c> jobExecution = new JobExecutionsSelector().byUserStoryAndStatus(userStory.Id, 'In Progress');

        if (!jobExecution.isEmpty()) {
            result.add(new Requirement().priority(1).message(Label.UserStoryCommitInProgress));
        }

        return result;
    }

    private static List<Requirement> hasRequiredLicenses() {
        List<Requirement> result = new List<Requirement>();

        if (LicenseHelper.isLicensesExceeded()) {
            result.add(new Requirement().priority(1).message(Label.LICENSES_EXCEEDED));
        }

        if (!LicenseHelper.actionIsLicenseEnabled('commitFiles')) {
            result.add(new Requirement().priority(1).message(Label.CCM_License_Restriction));
        }

        if (!FeatureHelper.isChangeChangeManagementEnabled()) {
            result.add(new Requirement().priority(1).message(Label.FEATURE_NOT_SUPPORTED + ' Change Management'));
        }

        return result;
    }

    private static List<Requirement> hasSobjectPermissions() {
        List<Requirement> result = new List<Requirement>();

        if (!Schema.SObjectType.User_Story__c.isUpdateable()) {
            result.add(new Requirement().priority(1).message(insufficientAccessOnObject(Schema.SObjectType.User_Story__c.Label)));
        }

        if (!Schema.SObjectType.Deployment_Flow__c.isAccessible()) {
            result.add(new Requirement().priority(1).message(Label.MISSING_PERMISSIONS_CBM_FLOW));
        }

        if (
            !Schema.SObjectType.User_Story_Metadata__c.isCreateable() ||
            !Schema.SObjectType.User_Story_Metadata__c.isUpdateable() ||
            !Schema.SObjectType.User_Story_Metadata__c.isDeletable()
        ) {
            result.add(new Requirement().priority(1).message(insufficientAccessOnObject(Schema.SObjectType.User_Story_Metadata__c.Label)));
        }

        if (!Schema.SObjectType.Git_Org_Commit__c.isCreateable()) {
            result.add(new Requirement().priority(1).message(insufficientAccessOnObject(Schema.SObjectType.Git_Org_Commit__c.Label)));
        }

        if (!Schema.SObjectType.User_Story_Commit__c.isCreateable()) {
            result.add(new Requirement().priority(1).message(insufficientAccessOnObject(Schema.SObjectType.User_Story_Commit__c.Label)));
        }

        return result;
    }

    private static String insufficientAccessOnObject(String objectLabel) {
        return String.format(Label.InsufficientAccessObject, new List<String>{ objectLabel });
    }

    private static List<Requirement> userStoryIsValid(User_Story__c userStory) {
        List<Requirement> result = new List<Requirement>();

        if (String.isBlank(userStory.Project__c) && String.isBlank(userStory.Release__r.Project__c)) {
            result.add(new Requirement().priority(2).message(Label.UserStoryWithoutProject));
        }

        if (String.isBlank(userStory.Environment__c) || String.isBlank(userStory.Org_Credential__c)) {
            result.add(new Requirement().priority(2).message(Label.USER_STORY_COMMIT_NO_ENVIRONMENT_OR_CREDENTIAL));
        }

        // Note: skip credential access validation for Multi-Cloud at the moment as Git Snapshot is not needed
        // result.addAll(hasEditAccesOnCredential(userStory));

        return result;
    }

    /*
    @SuppressWarnings('PMD.ApexCRUDViolation')
    private static List<Requirement> hasEditAccesOnCredential(User_Story__c userStory) {
        List<Requirement> result = new List<Requirement>();

        List<UserRecordAccess> credentialAccess = [
            SELECT RecordId, HasEditAccess
            FROM UserRecordAccess
            WHERE UserId = :UserInfo.getUserId() AND RecordId = :userStory.Org_Credential__c
        ];

        if (!credentialAccess.isEmpty() && !credentialAccess[0].HasEditAccess) {
            result.add(new Requirement().priority(2).message(Label.Read_Write_Access_Missing));
        }

        return result;
    }
    */

    private static List<Requirement> pipelineIsValid(User_Story__c userStory) {
        List<Requirement> result = new List<Requirement>();

        Deployment_Flow__c pipeline = pipeline(userStory);

        if (pipeline != null && pipeline.Block_Commits__c) {
            result.add(new Requirement().priority(1).message(Label.DEPLOYMENT_FLOW_COMMITS_BLOCKED));
        }

        if (pipeline == null || !pipeline.Active__c) {
            result.add(new Requirement().priority(2).message(Label.PROMOTION_FLOW_INACTIVE));
        }

        return result;
    }

    private static Deployment_Flow__c pipeline(User_Story__c userStory) {
        Id pipelineId = String.isNotBlank(userStory.Project__r.Deployment_Flow__c)
            ? userStory.Project__r.Deployment_Flow__c
            : String.isNotBlank(userStory.Release__r.Project__r.Deployment_Flow__c) ? userStory.Release__r.Project__r.Deployment_Flow__c : null;
        return pipelineId != null ? new PipelineSelector().byId(new Set<Id>{ pipelineId })[0] : null;
    }

    private with sharing class Requirement {
        private Integer priority;
        private String message;

        public Requirement priority(Integer priority) {
            this.priority = priority;
            return this;
        }

        public Integer getPriority() {
            return this.priority;
        }

        public Requirement message(String message) {
            this.message = message;
            return this;
        }

        public String getMesssage() {
            return this.message;
        }
    }
}