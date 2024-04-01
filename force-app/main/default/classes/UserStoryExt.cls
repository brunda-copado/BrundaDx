public with sharing class UserStoryExt {
    public User_Story__c userStory { get; set; }
    public String userStoriesAheadBehindTitle { get; set; }
    public Boolean showLicenseError { get; set; }

    @SuppressWarnings('PMD.NcssConstructorCount')
    public UserStoryExt(ApexPages.StandardController stdController) {
        isLicenseAndFeatureEnabled();

        if (showLicenseError) {
            return;
        }

        if (!Test.isRunningTest()) {
            stdController.addFields(fields());
        }

        this.userStory = (User_Story__c) stdController.getRecord();

        if (userStory.Id != null) {
            if (String.isBlank(userStory.Platform__c) || userStory.Platform__c == 'Salesforce') {
                checkForLastCommitNoChanges(userStory.Id);
            }
            checkDataCommitsStatus(userStory.Id);
        }
    }

    public void isLicenseAndFeatureEnabled() {
        showLicenseError = false;

        if (!LicenseHelper.actionIsLicenseEnabled('viewUserStoryPage')) {
            showLicenseError = true;
            ApexPages.addMessage(
                new ApexPages.Message(ApexPages.Severity.WARNING, Label.CE_License_Restriction.replace('__License__', Label.CCM_or_CAD_License))
            );
        }

        if (!FeatureHelper.isChangeChangeManagementEnabled()) {
            showLicenseError = true;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.Change_Management_Feature_Not_Enabled));
        }
    }

    public List<GlobalUtilities.flowStepWrapper> getDeploymentFlowSteps() {
        List<GlobalUtilities.flowStepWrapper> visualFlowSteps = GlobalUtilities.getDeploymentFlowSteps(userStory);
        userStoriesAheadBehindTitle = GlobalUtilities.userStoriesAheadBehindTitle;
        if (visualFlowSteps.isEmpty() && String.isNotBlank(userStory.Org_Credential__c) && String.isNotBlank(userStory.Project__c)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, Label.Org_Credential_Not_Included_In_Deployment_Flow));
        }
        return visualFlowSteps;
    }

    @SuppressWarnings('PMD.ApexCRUDViolation')
    private void checkForLastCommitNoChanges(Id usId) {
        if (Schema.SObjectType.User_Story_Commit__c.isAccessible() && Schema.SObjectType.User_Story_Commit__c.isQueryable()) {
            List<User_Story_Commit__c> commits = [
                SELECT Id, Snapshot_Commit__r.Status__c
                FROM User_Story_Commit__c
                WHERE User_Story__c = :usId
                ORDER BY Snapshot_Commit__r.Commit_Date__c DESC
                LIMIT 1
            ];
            if (!commits.isEmpty() && commits[0].Snapshot_Commit__r.Status__c == 'No changes') {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, Label.COMMIT_NO_CHANGES));
            }
        } else {
            UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.User_Story_Commit__c.label);
        }
    }

    private void checkDataCommitsStatus(Id userStoryId) {
        if (Schema.SObjectType.User_Story_Data_Commit__c.isAccessible() && Schema.SObjectType.User_Story_Data_Commit__c.isQueryable()) {
            Map<Id, List<User_Story_Data_Commit__c>> dataCommitsByDataSet = new UserStoryDataCommitsSelector()
                .byUserStoryGroupByDataSet(new Set<Id>{ userStoryId })
                .get(userStoryId);

            for (Id dataSetId : dataCommitsByDataSet.keySet()) {
                // Note: we are sorting data commits by descending date
                List<User_Story_Data_Commit__c> dataSetDataCommits = dataCommitsByDataSet.get(dataSetId);
                checkDataCommitsStatusByDataSet(dataSetDataCommits);
            }
        } else {
            UIDesignHelper.warningMessageOLSFLS(Schema.SObjectType.User_Story_Data_Commit__c.label);
        }
    }

    private void checkDataCommitsStatusByDataSet(List<User_Story_Data_Commit__c> dataSetDataCommits) {
        for (User_Story_Data_Commit__c dataCommit : dataSetDataCommits) {
            if (isRunningCommit(dataCommit)) {
                continue;
            }
            if (isFailedCommit(dataCommit)) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.DataCommitNoChanges));
                break;
            }
            if (isSuccessCommit(dataCommit)) {
                break;
            }
        }
    }

    private Boolean isRunningCommit(User_Story_Data_Commit__c dataCommit) {
        return dataCommit.Status__c == 'Draft' || dataCommit.Status__c == 'Scheduled' || dataCommit.Status__c == 'In progress';
    }

    private Boolean isFailedCommit(User_Story_Data_Commit__c dataCommit) {
        return dataCommit.Status__c == 'Cancelled' || dataCommit.Status__c == 'Completed with Errors' || dataCommit.Status__c == 'Merge Conflict';
    }

    private Boolean isSuccessCommit(User_Story_Data_Commit__c dataCommit) {
        return dataCommit.Status__c == 'Completed Successfully';
    }

    @TestVisible
    private List<String> fields() {
        String ns = Settings.ns;

        return new List<String>{
            ns + 'Base_Branch__c',
            ns +
            'Project__r.' +
            ns +
            'Deployment_Flow__c',
            ns +
            'Release__r.' +
            ns +
            'Project__r.' +
            ns +
            'Deployment_Flow__c',
            ns +
            'Release__r.' +
            ns +
            'Base_Branch__c',
            ns + 'Environment__r.Name',
            ns +
            'Org_Credential__r.' +
            ns +
            'Org_Type__c',
            ns + 'Platform__c'
        };
    }
}