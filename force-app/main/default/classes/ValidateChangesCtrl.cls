@SuppressWarnings('PMD.CyclomaticComplexity,PMD.CognitiveComplexity')
public with sharing class ValidateChangesCtrl {
    private static final String VALIDATION_ENABLED = 'ValidationEnabled';
    private static final String IN_PROGRESS = 'In Progress';
    private static final String NOT_STARTED = 'Not Started';
    private static final String CANCELLED = 'Cancelled';
    private static final String QUEUED = 'Queued';
    private static final String SALESFORCE_PLATFORM = 'Salesforce';

    public static Boolean isStepCreation = false;

    // PUBLIC

    @AuraEnabled
    public static ValidationSetting getValidationSetting(Id recordId) {
        ValidationSetting result;

        try {
            String objectName = objectName(recordId);

            if (objectName == Schema.SObjectType.Promotion__c.getName()) {
                result = getSettingsFromPromotion(recordId);
            } else if (objectName == Schema.SObjectType.User_Story__c.getName()) {
                result = getSettingsFromUserStory(recordId);
            } else {
                throw new ApplicationException(Label.InvalidValidationContextId);
            }
        } catch (Exception e) {
            result = new ValidationSetting(e.getMessage());
        }

        return result;
    }

    @AuraEnabled
    public static Id validateChanges(Id recordId, List<Id> deploymentStepIds) {
        Id result;

        try {
            String objectName = objectName(recordId);
            if (objectName == Schema.SObjectType.Promotion__c.getName()) {
                updatePromotion(recordId, IN_PROGRESS);
                validatePromotion(recordId, deploymentStepIds);
                result = recordId;
            } else if (objectName == Schema.SObjectType.User_Story__c.getName()) {
                PromoteAction.Response response = validateUserStory(recordId, deploymentStepIds);
                result = response.promotion.Id;
                updateLastValidationPromotion(recordId, result);
            } else {
                throw new ApplicationException(Label.InvalidValidationContextId);
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }

        return result;
    }

    // PRIVATE

    private static PromoteAction.Response validatePromotion(Id promotionId, List<Id> deploymentStepIds) {
        PromoteAction.Request request = request(deploymentStepIds);
        request.promotionId = promotionId;
        return PromoteAction.promote(new List<PromoteAction.Request>{ request })[0];
    }

    // PMD False positive, as WITH USER_MODE is not supported yet
    @SuppressWarnings('PMD.ApexCRUDViolation')
    private static PromoteAction.Response validateUserStory(Id userStoryId, List<Id> deploymentStepIds) {
        PromoteAction.Request request = request(deploymentStepIds);
        User_Story__c userStory = [
            SELECT Environment__c, Project__c, Project__r.Deployment_Flow__c, Release__c, Release__r.Project__r.Deployment_Flow__c
            FROM User_Story__C
            WHERE Id = :userStoryId
            WITH USER_MODE
        ];
        request.userStoryIds = new List<Id>{ userStoryId };
        request.isBackPromotion = false;
        request.projectId = userStory.Project__c;
        request.sourceEnvironmentId = userStory.Environment__c;
        return PromoteAction.promote(new List<PromoteAction.Request>{ request })[0];
    }

    private static PromoteAction.Request request(List<Id> deploymentStepIds) {
        PromoteAction.Request request = new PromoteAction.Request();
        request.executePromotion = true;
        request.executeDeployment = true;
        request.deploymentDryRun = true;

        PromotionOtherInformation otherInformation = new PromotionOtherInformation();
        otherInformation.doNotRunJob = false;
        otherInformation.deploymentSteps = deploymentStepIds;
        request.otherInformation = JSON.serialize(otherInformation);
        return request;
    }

    public static void updatePromotion(Id promotionId, String status) {
        List<SObject> records = new List<SObject>{ new Promotion__c(Id = promotionId, Status__c = status) };

        PromotionTriggerHelper.bypassPromotionTrigger = true;
        update Security.stripInaccessible(AccessType.UPDATABLE, records).getRecords();
    }

    private static void updateLastValidationPromotion(Set<Id> userStoryIds, Id promotionId) {
        List<User_Story__c> userStories = new List<User_Story__c>();

        for (Id userStoryId : userStoryIds) {
            userStories.add(new User_Story__c(Id = userStoryId, Last_Validation_Promotion__c = promotionId));
        }

        update Security.stripInaccessible(AccessType.UPDATABLE, userStories).getRecords();
    }

    private static void updateLastValidationPromotion(Id userStoryId, Id promotionId) {
        updateLastValidationPromotion(new Set<Id>{ userStoryId }, promotionId);
    }

    // PMD False positive, as WITH USER_MODE is not supported yet
    @SuppressWarnings('PMD.ApexCRUDViolation')
    private static ValidationSetting getSettingsFromPromotion(Id promotionId) {
        ValidationSetting result;
        Promotion__c promotion = [
            SELECT Status__c, Platform__c, Destination_Environment__r.Name
            FROM Promotion__c
            WHERE Id = :promotionId
            WITH USER_MODE
        ];

        if (isPlatformPromotion(promotion)) {
            Boolean validationEnabled = validationEnabled(promotion.Platform__c);
            result = new ValidationSetting(validationEnabled, promotion);
        } else {
            result = new ValidationSetting(Label.Validate_Changes_Button_Not_Supported);
        }

        return result;
    }

    // PMD False positive, as WITH USER_MODE is not supported yet
    @SuppressWarnings('PMD.ApexCRUDViolation')
    private static ValidationSetting getSettingsFromUserStory(Id userStoryId) {
        ValidationSetting result;
        User_Story__c userStory = [
            SELECT
                Id,
                Platform__c,
                Environment__r.Name,
                Environment__c,
                Release__c,
                Release__r.Project__r.Deployment_Flow__c,
                Project__r.Deployment_Flow__c
            FROM User_Story__c
            WHERE Id = :userStoryId
            WITH USER_MODE
        ];

        if (isPlatformUserStory(userStory)) {
            Boolean validationEnabled = validationEnabled(userStory.Platform__c);
            result = new ValidationSetting(validationEnabled, userStory);
        } else {
            result = new ValidationSetting(Label.Validate_Changes_Button_Not_Supported);
        }

        return result;
    }

    private static String objectName(Id recordId) {
        return recordId?.getSobjectType().getDescribe(SObjectDescribeOptions.DEFAULT).getName();
    }

    private static Boolean validationEnabled(String platform) {
        List<ExtensionKeyValueSetting__mdt> settings = new ExtensionKeyValueSettingsSelector().byPlatformAndKey(platform, VALIDATION_ENABLED);
        return settings.isEmpty() ? false : Boolean.valueOf(settings[0].Value__c);
    }

    // PMD False positive, as WITH USER_MODE is not supported yet
    @SuppressWarnings('PMD.ApexCRUDViolation')
    private static Boolean isUserStoryMetadataCreated(List<Id> userStoryIds) {
        return ([SELECT Id FROM User_Story_Metadata__c WHERE User_Story__c IN :userStoryIds WITH USER_MODE]).size() > 0;
    }

    // PMD False positive, as WITH USER_MODE is not supported yet
    @SuppressWarnings('PMD.ApexCRUDViolation')
    private static Boolean isPromotionUserStoriesMetadataCreated(Id promotionId) {
        List<Id> userStoryIds = new List<Id>();
        List<Promoted_User_Story__c> promotedUserStories = [
            SELECT User_Story__c
            FROM Promoted_User_Story__c
            WHERE Promotion__c = :promotionId
            WITH USER_MODE
        ];
        for (Promoted_User_Story__c promotedStory : promotedUserStories) {
            userStoryIds.add(promotedStory.User_Story__c);
        }
        return isUserStoryMetadataCreated(userStoryIds) || !OrderDeploymentStepsController.getFilteredDeploymentSteps(promotionId, true).isEmpty();
    }

    // PMD False positive, as WITH USER_MODE is not supported yet
    @SuppressWarnings('PMD.ApexCRUDViolation')
    private static Boolean isDeploymentStepsCreated(Id userStoryId) {
        return OrderDeploymentStepsController.getFilteredDeploymentSteps(userStoryId, true).size() > 0;
    }

    // PMD False positive, as WITH USER_MODE is not supported yet
    @SuppressWarnings('PMD.ApexCRUDViolation')
    private static Boolean isPromotedUserStoriesCreated(Id promotionId) {
        return [SELECT User_Story__c FROM Promoted_User_Story__c WHERE Promotion__c = :promotionId WITH USER_MODE].size() > 0;
    }

    private static Boolean jobInProgress(String promotionId) {
        JobExecution__c promotionJob = promotionJob(promotionId);
        JobExecution__c deploymentJob = deploymentJob(promotionId);
        return promotionJob?.Status__c == IN_PROGRESS ||
            deploymentJob?.Status__c == IN_PROGRESS ||
            promotionJob?.Status__c == NOT_STARTED ||
            deploymentJob?.Status__c == NOT_STARTED ||
            promotionJob?.Status__c == QUEUED ||
            deploymentJob?.Status__c == QUEUED;
    }

    // PMD False positive, as WITH USER_MODE is not supported yet
    @SuppressWarnings('PMD.ApexCRUDViolation')
    private static JobExecution__c promotionJob(String promotionId) {
        JobExecution__c result = null;
        List<JobExecution__c> promotionJobExecutions = [
            SELECT Id, Status__c
            FROM JobExecution__c
            WHERE Promotion__c = :promotionId AND Job_Step__c = NULL
            WITH USER_MODE
            ORDER BY CreatedDate DESC
        ];
        if (!promotionJobExecutions.isEmpty()) {
            result = promotionJobExecutions[0];
        }
        return result;
    }

    // PMD False positive, as WITH USER_MODE is not supported yet
    @SuppressWarnings('PMD.ApexCRUDViolation')
    private static JobExecution__c deploymentJob(String promotionId) {
        JobExecution__c result = null;
        List<Deployment__c> deployments = [
            SELECT Id, Status__c
            FROM Deployment__c
            WHERE Promotion__c = :promotionId
            WITH USER_MODE
            ORDER BY CreatedDate DESC
        ];
        if (!deployments.isEmpty()) {
            List<JobExecution__c> deploymentJobExecutions = [
                SELECT Id, Status__c
                FROM JobExecution__c
                WHERE Deployment__c = :deployments[0].Id AND Job_Step__c = NULL
                WITH USER_MODE
            ];
            if (!deploymentJobExecutions.isEmpty()) {
                result = deploymentJobExecutions[0];
            }
        }
        return result;
    }

    private static Boolean isPlatformUserStory(User_Story__c userStory) {
        return String.isNotBlank(userStory.Platform__c) && userStory.Platform__c != SALESFORCE_PLATFORM;
    }

    private static Boolean isPlatformPromotion(Promotion__c promotion) {
        return String.isNotBlank(promotion.Platform__c) && promotion.Platform__c != SALESFORCE_PLATFORM;
    }

    // INNER
    @SuppressWarnings('PMD.CognitiveComplexity,PMD.StdCyclomaticComplexity')
    public with sharing class ValidationSetting {
        @AuraEnabled
        public String title;

        @AuraEnabled
        public String message;

        @AuraEnabled
        public Boolean validationEnabled;

        public ValidationSetting(Boolean validationEnabled, Promotion__c promotion) {
            Boolean promotedUserStoriesCreated = isPromotedUserStoriesCreated(promotion.Id);
            Boolean jobInProgress = jobInProgress(promotion.Id);
            Boolean promotedUserStorieshasMetadata = isPromotionUserStoriesMetadataCreated(promotion.Id);
            Boolean promotionIsCancelled = promotion.Status__c == CANCELLED;

            this.validationEnabled =
                validationEnabled &&
                promotedUserStoriesCreated &&
                promotedUserStorieshasMetadata &&
                !jobInProgress &&
                !promotionIsCancelled;
            title = validationEnabled
                ? (!promotedUserStoriesCreated
                      ? Label.There_are_not_User_Stories_in_this_Promotion
                      : (jobInProgress
                            ? Label.There_is_a_job_execution_in_progress_for_this_Promotion
                            : (promotionIsCancelled
                                  ? Label.Unable_to + ' ' + Label.ValidateChanges
                                  : format(Label.ValidatePromotionTitle, promotion.Destination_Environment__r.Name))))
                : format(Label.ValidateChangesInactiveTitle, promotion.Platform__c);
            message = validationEnabled
                ? (!promotedUserStoriesCreated
                      ? Label.ValidateChangesNoUserStoriesBody
                      : (jobInProgress
                            ? Label.Wait_until_job_execution_finished
                            : (promotionIsCancelled
                                  ? Label.CANCELLED_PROMOTIONS_ACTION
                                  : (promotedUserStorieshasMetadata
                                        ? format(Label.ValidatePromotionBody, promotion.Destination_Environment__r.Name)
                                        : Label.ValidateChangesNoUserStoryMetadataBody))))
                : format(Label.ValidateChangesInactiveBody, promotion.Platform__c);
        }

        // PMD False positive, as WITH USER_MODE is not supported yet
        @SuppressWarnings('PMD.ApexCRUDViolation')
        public ValidationSetting(Boolean validationEnabled, User_Story__c userStory) {
            Boolean hasMetadata = isUserStoryMetadataCreated(new List<Id>{ userStory.Id });
            Boolean hasDeploymentSteps = isDeploymentStepsCreated(userStory.Id);
            this.validationEnabled = validationEnabled && (isStepCreation || hasMetadata || hasDeploymentSteps);
            List<Deployment_Flow_Step__c> connections = [
                SELECT Id, Destination_Environment__r.Name, Source_Environment__c
                FROM Deployment_Flow_Step__c
                WHERE
                    (Deployment_Flow__c = :userStory.Project__r.Deployment_Flow__c
                    OR Deployment_Flow__c = :userStory.Release__r.Project__r.Deployment_Flow__c)
                    AND Source_Environment__c = :userStory.Environment__c
                WITH USER_MODE
            ];
            String destinationEnvironment = connections.isEmpty() ? null : connections[0].Destination_Environment__r.Name;

            if (destinationEnvironment == null) {
                this.validationEnabled = false;
                title = Label.ValidateChangesNoNextEnvironmentTitle;
                message = Label.ValidateChangesNoNextEnvironmentBody;
            } else {
                title = validationEnabled
                    ? format(Label.ValidateChangesTitle, destinationEnvironment)
                    : format(Label.ValidateChangesInactiveTitle, userStory.Platform__c);
                message = validationEnabled
                    ? ((hasMetadata || hasDeploymentSteps)
                          ? format(Label.ValidateChangesBody, destinationEnvironment)
                          : Label.ValidateChangesNoUserStoryMetadataBody)
                    : format(Label.ValidateChangesInactiveBody, userStory.Platform__c);
            }
        }

        public ValidationSetting(String message) {
            this.message = message;
            this.validationEnabled = false;
            this.title = label.ValidateChangeError;
        }

        private String format(String label, String parameter) {
            return String.format(Label, new List<String>{ parameter });
        }
    }
}