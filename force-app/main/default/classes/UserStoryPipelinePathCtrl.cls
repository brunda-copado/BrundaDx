/**
 * This will be used as a controller for userStoryPipelinePath LWC Component
 */
// Note: These parameters are returned to a javascript controller so they need to be public
@SuppressWarnings('PMD.ExcessivePublicCount')
public with sharing class UserStoryPipelinePathCtrl {

    // CONSTANTS

    private static final String ALERT_VARIANT_INFO = 'info';
    private static final String ALERT_VARIANT_WARNING = 'warning';
    private static final String ALERT_VARIANT_ERROR = 'error';

    private static final String SNAPSHOT_COMMIT_STATUS_NO_CHANGES = 'No changes';
    private static final String DATA_COMMIT_STATUS_DRAFT = 'Draft';
    private static final String DATA_COMMIT_STATUS_SCHEDULED = 'Scheduled';
    private static final String DATA_COMMIT_STATUS_IN_PROGRESS = 'In progress';
    private static final String DATA_COMMIT_STATUS_CANCELLED = 'Cancelled';
    private static final String DATA_COMMIT_STATUS_COMPLETED_WITH_ERRORS = 'Completed with Errors';
    private static final String DATA_COMMIT_STATUS_MERGE_CONFLICT = 'Merge Conflict';
    private static final String DATA_COMMIT_STATUS_COMPLETED_SUCCESSFULLY = 'Completed Successfully';

    private static final String CURRENT_STEP_STYLE = 'slds-is-current';

    private static final String LICENSE_ACTION_NAME = 'viewUserStoryPage';
    private static final String LICENSE_NAME_PLACEHOLDER = '__License__';


    // PUBLIC 
    
    /**
     * This is used to validate License, commits and commit object access and show  warning message
     *
     * @param userStoryId recordId of the User Story, to query and verify the related commits.
     */
    @AuraEnabled(cacheable=true)
    public static List<UIDesignHelper.AlertWrapper> validate(String userStoryId) {
        List<UIDesignHelper.AlertWrapper> responseAlerts = isLicenseAndFeatureEnabled();

        if (responseAlerts != null && !responseAlerts.isEmpty()) {
            return responseAlerts;
        }
        if (userStoryId != null) {
            // Note: MC user stories have a separate progress component to track commit status, do not duplicate the warning in that case
            List<User_Story__c> userStories = new UserStoriesSelector().byId(new Set<Id>{ userStoryId });
            String platform = !userStories.isEmpty() ? userStories[0].Platform__c : null;
            if (String.isBlank(platform) || platform == 'Salesforce') {
                responseAlerts.addAll(checkForLastCommitNoChanges(userStoryId));
            }
            responseAlerts.addAll(checkDataCommitsStatus(userStoryId));
        }
        return responseAlerts;
    }

    /**
     * This is used to show deployment path for the User Story
     *
     * @param userStoryId recordId of the User Story, to query related deployment path & environments.
     */
    @AuraEnabled
    public static PipelinePathWrapper getDeploymentFlowSteps(Id userStoryId) {
        List<GlobalUtilities.flowStepWrapper> visualFlowSteps = new List<GlobalUtilities.flowStepWrapper>();
        List<UIDesignHelper.AlertWrapper> responseAlerts = new List<UIDesignHelper.AlertWrapper> ();
        String userStoriesAheadBehindTitle = '';
        try {
            List<User_Story__c> userStories = [
                SELECT Id, Org_Credential__c, Project__c, Environment__c, Release__c, Project__r.Deployment_Flow__c,
                Release__r.Project__r.Deployment_Flow__c, Release__r.Base_Branch__c, Base_Branch__c, Org_Credential__r.Org_Type__c
                FROM User_Story__c
                WHERE Id = :userStoryId
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];
            visualFlowSteps = GlobalUtilities.getDeploymentFlowSteps(userStories[0]);
            userStoriesAheadBehindTitle = GlobalUtilities.userStoriesAheadBehindTitle;
            if (visualFlowSteps.isEmpty() && String.isNotBlank(userStories[0].Org_Credential__c) && String.isNotBlank(userStories[0].Project__c)) {
                responseAlerts.add(UIDesignHelper.genericWarningAlert(ApexPages.Severity.WARNING, Label.Org_Credential_Not_Included_In_Deployment_Flow));
            }
        } catch (QueryException queryException) {
            responseAlerts = UIDesignHelper.warningAlertsOLSFLS(Schema.SObjectType.User_Story__c.label);
        } catch (Exception exceptions) {
            responseAlerts.add(UIDesignHelper.genericWarningAlert(ApexPages.Severity.ERROR, exceptions.getMessage()));
        }
        return new PipelinePathWrapper(visualFlowSteps, userStoriesAheadBehindTitle, responseAlerts);
    }

    // PRIVATE

    private static List<UIDesignHelper.AlertWrapper> isLicenseAndFeatureEnabled() {
        List<UIDesignHelper.AlertWrapper> responseAlerts = new List<UIDesignHelper.AlertWrapper> ();
        if (!LicenseHelper.actionIsLicenseEnabled(LICENSE_ACTION_NAME)) {
            responseAlerts.add(UIDesignHelper.genericWarningAlert(ApexPages.Severity.WARNING, Label.CE_License_Restriction.replace(LICENSE_NAME_PLACEHOLDER, Label.CCM_or_CAD_License), true));
        }
        if (!FeatureHelper.isChangeChangeManagementEnabled()) {
            responseAlerts.add(UIDesignHelper.genericWarningAlert(ApexPages.Severity.WARNING, Label.Change_Management_Feature_Not_Enabled, true));
        }
        return responseAlerts;
    }

    private static List<UIDesignHelper.AlertWrapper> checkForLastCommitNoChanges(Id usId) {
        List<UIDesignHelper.AlertWrapper> responseAlerts = new List<UIDesignHelper.AlertWrapper> ();
        try {
            List<User_Story_Commit__c> commits = [
                SELECT Id, Snapshot_Commit__r.Status__c
                FROM User_Story_Commit__c
                WHERE User_Story__c = :usId
                WITH SECURITY_ENFORCED
                ORDER BY Snapshot_Commit__r.Commit_Date__c DESC
                LIMIT 1
            ];
            if (!commits.isEmpty() && commits[0].Snapshot_Commit__r.Status__c == SNAPSHOT_COMMIT_STATUS_NO_CHANGES) {
                responseAlerts.add(UIDesignHelper.genericWarningAlert(ApexPages.Severity.INFO, Label.COMMIT_NO_CHANGES));
            }
        } catch (QueryException queryException) {
            responseAlerts = UIDesignHelper.warningAlertsOLSFLS(Schema.SObjectType.User_Story__c.label);
        } catch (Exception exceptions) {
            responseAlerts.add(UIDesignHelper.genericWarningAlert(ApexPages.Severity.ERROR, exceptions.getMessage()));
        }
        return responseAlerts;
    }

    private static List<UIDesignHelper.AlertWrapper> checkDataCommitsStatus(Id userStoryId) {
        List<UIDesignHelper.AlertWrapper> responseAlerts = new List<UIDesignHelper.AlertWrapper> ();
        if (Schema.SObjectType.User_Story_Data_Commit__c.isAccessible() && Schema.SObjectType.User_Story_Data_Commit__c.isQueryable()) {
            Map<Id, List<User_Story_Data_Commit__c>> dataCommitsByDataSet = new UserStoryDataCommitsSelector()
                .byUserStoryGroupByDataSet(new Set<Id>{ userStoryId })
                .get(userStoryId);

            for (Id dataSetId : dataCommitsByDataSet.keySet()) {
                responseAlerts.addAll(checkDataCommitsStatusByDataSet(dataCommitsByDataSet.get(dataSetId)));
            }
        } else {
            responseAlerts = UIDesignHelper.warningAlertsOLSFLS(Schema.SObjectType.User_Story__c.label);
        }
        return responseAlerts;
    }

    private static List<UIDesignHelper.AlertWrapper> checkDataCommitsStatusByDataSet(List<User_Story_Data_Commit__c> dataSetDataCommits) {
        List<UIDesignHelper.AlertWrapper> responseAlerts = new List<UIDesignHelper.AlertWrapper> ();
        
        // Note: we are sorting data commits by descending date
        for (User_Story_Data_Commit__c dataCommit : dataSetDataCommits) {
            if (isRunningCommit(dataCommit)) {
                continue;
            }
            if (isFailedCommit(dataCommit)) {
                responseAlerts.add(UIDesignHelper.genericWarningAlert(ApexPages.Severity.ERROR, Label.DataCommitNoChanges));
                break;
            }
            if (isSuccessCommit(dataCommit)) {
                break;
            }
        }
        return responseAlerts;
    }

    private static Boolean isRunningCommit(User_Story_Data_Commit__c dataCommit) {
        return dataCommit.Status__c == DATA_COMMIT_STATUS_DRAFT || dataCommit.Status__c == DATA_COMMIT_STATUS_SCHEDULED || dataCommit.Status__c == DATA_COMMIT_STATUS_IN_PROGRESS;
    }

    private static Boolean isFailedCommit(User_Story_Data_Commit__c dataCommit) {
        return dataCommit.Status__c == DATA_COMMIT_STATUS_CANCELLED || dataCommit.Status__c == DATA_COMMIT_STATUS_COMPLETED_WITH_ERRORS || dataCommit.Status__c == DATA_COMMIT_STATUS_MERGE_CONFLICT;
    }

    private static Boolean isSuccessCommit(User_Story_Data_Commit__c dataCommit) {
        return dataCommit.Status__c == DATA_COMMIT_STATUS_COMPLETED_SUCCESSFULLY;
    }

    // WRAPPER

    public class PipelinePathWrapper {
        @AuraEnabled
        public List<PathWrapper> path { get; set; }
        @AuraEnabled
        public String userStoriesAheadBehindTitle { get; set; }
        @AuraEnabled
        public List<UIDesignHelper.AlertWrapper> alerts { get; set; }

        // CTOR

        public PipelinePathWrapper(List<GlobalUtilities.flowStepWrapper> path, String userStoriesAheadBehindTitle, List<UIDesignHelper.AlertWrapper> alerts) {
            this.path = new List<PathWrapper>();
            this.userStoriesAheadBehindTitle = userStoriesAheadBehindTitle;
            this.alerts = alerts;

            if(path != null){
                for(GlobalUtilities.flowStepWrapper eachStep : path) {
                    eachStep.environment = eachStep.environment.escapeHtml3().escapeHtml4();
                    if(eachStep.style == CURRENT_STEP_STYLE && String.isNotBlank(this.userStoriesAheadBehindTitle)) {                    
                        eachStep.environment += ' ' + this.userStoriesAheadBehindTitle;
                    }
                    this.path.add(new PathWrapper(eachStep.style, eachStep.environment));
                }
            }
        }
    }

    public class PathWrapper {
        @AuraEnabled
        public String style { get; set; }
        @AuraEnabled
        public String environment { get; set; }
        @AuraEnabled
        public Boolean isCurrent { get; set; }

        // CTOR

        public PathWrapper(String style, String environment) {
            this.style = style;
            this.environment = environment;
            this.isCurrent = false;
            if (this.style == CURRENT_STEP_STYLE) {
                this.isCurrent = true;
            }
        }
    }
}