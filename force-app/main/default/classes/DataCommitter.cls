public with sharing class DataCommitter {
    private DataCommitRequest commitRequest;

    private UserStoriesService userStoriesService;
    private DataTemplatesService dataTemplatesService;

    public DataCommitter(DataCommitRequest commitRequest) {
        ValidationResult result = validateRequest(commitRequest);
        if (result.isError()) {
            throw new ApplicationException(result);
        }
        this.commitRequest = commitRequest;
        initUserStoriesService();
        initDataTemplatesService();
    }

    public Id execute() {
        Id dataSetId;
        Id deploymentId;

        switch on this.commitRequest.getSourceType() {
            when ENVIRONMENT {
                dataSetId = findExistingDataSet();
                if (dataSetId == null) {
                    Data_Set__c dataSet = createDataSet();
                    Utilities.Secure_DML(dataSet, Utilities.DML_Action.INS, Schema.SObjectType.Data_Set__c);
                    dataSetId = dataSet.Id;
                }
                deploymentId = generateDataSet(dataSetId);
            }
            when DATASET {
                dataSetId = this.commitRequest.getDataSetId();
            }
        }

        User_Story_Data_Commit__c dataCommit = createDataCommit(dataSetId, deploymentId);
        Utilities.Secure_DML(dataCommit, Utilities.DML_Action.INS, Schema.SObjectType.User_Story_Data_Commit__c);

        return dataCommit.Id;
    }

    private ValidationResult validateRequest(DataCommitRequest request) {
        ValidationResult result = new ValidationResult();
        if (request.getUserStoryId() == null) {
            result.addError(Label.User_Story_Required);
        }
        if (request.getSourceType() == null) {
            result.addError(Label.Data_Source_Required);
        }
        if (request.getSourceType() == DataCommitRequest.Source.ENVIRONMENT && request.getDataTemplateId() == null) {
            result.addError(Label.Data_Template_Id_Required);
        }
        if (request.getSourceType() == DataCommitRequest.Source.DATASET && request.getDataSetId() == null) {
            result.addError(Label.Source_Data_Set_Id_Required);
        }
        if (String.isBlank(request.getCommitMessage())) {
            result.addError(Label.Commit_Message_Required);
        }
        return result;
    }

    private void initUserStoriesService() {
        Set<Id> userStoryIds = new Set<Id>{ this.commitRequest.getUserStoryId() };
        this.userStoriesService = new UserStoriesService(userStoryIds);
    }

    private void initDataTemplatesService() {
        Set<Id> dataTemplateIds = new Set<Id>{ this.commitRequest.getDataTemplateId() };
        this.dataTemplatesService = new DataTemplatesService(dataTemplateIds);
    }

    private Id findExistingDataSet() {
        Id dataSetId;

        List<User_Story_Data_Commit__c> dataCommits = getUserStoryDataCommits();
        for (User_Story_Data_Commit__c dataCommit : dataCommits) {
            if (dataCommit.Data_Set__r.Data_Template__c == this.commitRequest.getDataTemplateId()) {
                dataSetId = dataCommit.Data_Set__c;
                break;
            }
        }

        return dataSetId;
    }

    private Data_Set__c createDataSet() {
        String userStoryName = getUserStory()?.Name;
        String dataTemplateName = getDataTemplate()?.Name;

        Data_Set__c dataSet = new Data_Set__c(
            Name = userStoryName + '/' + dataTemplateName,
            Data_Template__c = this.commitRequest.getDataTemplateId()
        );

        return dataSet;
    }

    private Id generateDataSet(Id dataSetId) {
        Id orgId = getUserStory()?.Org_Credential__c;

        DataDeployRequest request = new DataDeployRequest()
            .dataTemplateId(this.commitRequest.getDataTemplateId())
            .sourceType(DataDeployRequest.Source.ENVIRONMENT)
            .sourceCredentialId(orgId)
            .destinationType(DataDeployRequest.Destination.DATASET)
            .destinationDataSetId(dataSetId)
            .overrideFilters(true)
            .filters(this.commitRequest.getFilters())
            .filterLogic(this.commitRequest.getFilterLogic())
            .commitMessage(this.commitRequest.getCommitMessage())
            .deployNow(true);

        DataDeployer dataDeployer = new DataDeployer(request);
        Id deploymentId = dataDeployer.execute();

        return deploymentId;
    }

    private User_Story_Data_Commit__c createDataCommit(Id dataSetId, Id deploymentId) {
        User_Story_Data_Commit__c dataCommit = new User_Story_Data_Commit__c(
            Commit_Date__c = Datetime.now(),
            Commit_Message__c = this.commitRequest.getCommitMessage(),
            Data_Set__c = dataSetId,
            Execution_Job__c = deploymentId,
            User_Story__c = this.commitRequest.getUserStoryId()
        );

        return dataCommit;
    }

    private User_Story__c getUserStory() {
        Id userStoryId = this.commitRequest.getUserStoryId();
        return this.userStoriesService.getUserStory(userStoryId);
    }

    private List<User_Story_Data_Commit__c> getUserStoryDataCommits() {
        Id userStoryId = this.commitRequest.getUserStoryId();
        return this.userStoriesService.getDataCommits(userStoryId);
    }

    private Data_Template__c getDataTemplate() {
        Id dataTemplateId = this.commitRequest.getDataTemplateId();
        return this.dataTemplatesService.getDataTemplate(dataTemplateId);
    }
}