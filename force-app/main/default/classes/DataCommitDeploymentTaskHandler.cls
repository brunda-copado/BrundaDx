public virtual with sharing class DataCommitDeploymentTaskHandler {
    private Map<Id, List<Deployment_Task__c>> existingDeploymentTasksByUserStory {
        get {
            if (existingDeploymentTasksByUserStory == null) {
                existingDeploymentTasksByUserStory = new DeploymentTasksSelector().byUserStory(this.dataCommitsByUserStory.keySet());
            }
            return existingDeploymentTasksByUserStory;
        }
        set;
    }

    private Map<Id, List<User_Story_Data_Commit__c>> existingDataCommitsByUserStory {
        get {
            if (existingDataCommitsByUserStory == null) {
                existingDataCommitsByUserStory = new UserStoryDataCommitsSelector().byUserStory(this.dataCommitsByUserStory.keySet());
            }
            return existingDataCommitsByUserStory;
        }
        set;
    }

    private Map<Id, Data_Set__c> dataSetsById {
        get {
            if (dataSetsById == null) {
                Set<Id> dataSetIds = new Set<Id>();
                for (Id userStoryId : this.dataCommitsByUserStory.keySet()) {
                    for (User_Story_Data_Commit__c dataCommit : this.dataCommitsByUserStory.get(userStoryId)) {
                        dataSetIds.add(dataCommit.Data_Set__c);
                    }
                }
                dataSetsById = new Map<Id, Data_Set__c>(new DataSetsSelector().byId(dataSetIds));
            }
            return dataSetsById;
        }
        set;
    }

    private Map<Id, List<User_Story_Data_Commit__c>> dataCommitsByUserStory;

    public DataCommitDeploymentTaskHandler(List<User_Story_Data_Commit__c> records) {
        this.dataCommitsByUserStory = getDataCommitsByUserStory(records);
    }

    protected Map<Id, List<User_Story_Data_Commit__c>> getRecords() {
        return this.dataCommitsByUserStory;
    }

    protected List<Deployment_Task__c> getDeploymentTasks(Id userStoryId) {
        return this.existingDeploymentTasksByUserStory.containsKey(userStoryId)
            ? this.existingDeploymentTasksByUserStory.get(userStoryId)
            : new List<Deployment_Task__c>();
    }

    protected Data_Set__c getDataSet(Id dataSetId) {
        return this.dataSetsById.get(dataSetId);
    }

    protected Deployment_Task__c getDeploymentTaskForDataSet(List<Deployment_Task__c> deploymentTasks, Id dataSetId) {
        Deployment_Task__c result = null;
        for (Deployment_Task__c deploymentTask : deploymentTasks) {
            if (deploymentTask.dataJSON__c != null) {
                DataStepData stepData = (DataStepData) JSON.deserialize(deploymentTask.dataJSON__c, DataStepData.class);
                Id sourceDataSet = stepData.source?.id != null && stepData.source?.id instanceof Id ? stepData.source.Id : null;
                if (sourceDataSet == dataSetId) {
                    result = deploymentTask;
                    break;
                }
            }
        }
        return result;
    }

    protected List<User_Story_Data_Commit__c> getRemainingDataCommits(Id userStoryId) {
        List<User_Story_Data_Commit__c> result = new List<User_Story_Data_Commit__c>(this.existingDataCommitsByUserStory.get(userStoryId));
        List<User_Story_Data_Commit__c> currentDataCommits = this.dataCommitsByUserStory.get(userStoryId);
        for (Integer i = (result.size() - 1); i >= 0; i--) {
            User_Story_Data_Commit__c dataCommit = result.get(i);
            for (User_Story_Data_Commit__c currentDataCommit : currentDataCommits) {
                if (dataCommit.Id == currentDataCommit.Id) {
                    result.remove(i);
                }
            }
        }
        return result;
    }

    protected Boolean isDataSetInAnotherDataCommit(List<User_Story_Data_Commit__c> dataCommits, Id dataSetId) {
        Boolean result = false;
        for (User_Story_Data_Commit__c dataCommit : dataCommits) {
            if (dataCommit.Data_Set__c == dataSetId) {
                result = true;
                break;
            }
        }
        return result;
    }

    private Map<Id, List<User_Story_Data_Commit__c>> getDataCommitsByUserStory(List<User_Story_Data_Commit__c> records) {
        Map<Id, List<User_Story_Data_Commit__c>> dataCommitsByUserStory = new Map<Id, List<User_Story_Data_Commit__c>>();
        for (User_Story_Data_Commit__c userStoryDataCommit : records) {
            Id userStoryId = userStoryDataCommit.User_Story__c;
            if (!dataCommitsByUserStory.containsKey(userStoryId)) {
                dataCommitsByUserStory.put(userStoryId, new List<User_Story_Data_Commit__c>());
            }
            dataCommitsByUserStory.get(userStoryId).add(userStoryDataCommit);
        }
        return dataCommitsByUserStory;
    }
}