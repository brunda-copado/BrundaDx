public with sharing class DeleteDataCommitDeploymentTask extends DataCommitDeploymentTaskHandler {
    public DeleteDataCommitDeploymentTask(List<User_Story_Data_Commit__c> records) {
        super(records);
    }

    public void execute() {
        Set<Id> deploymentTaskIdsToDelete = new Set<Id>();
        Set<Id> dataSetIdsToDelete = new Set<Id>();

        Map<Id, List<User_Story_Data_Commit__c>> dataCommitsByUserStory = getRecords();
        for (Id userStoryId : dataCommitsByUserStory.keySet()) {
            List<User_Story_Data_Commit__c> dataCommitsToDelete = dataCommitsByUserStory.get(userStoryId);

            if (!dataCommitsToDelete.isEmpty()) {
                List<User_Story_Data_Commit__c> remainingDataCommits = getRemainingDataCommits(userStoryId);
                List<Deployment_Task__c> existingDeploymentTasks = getDeploymentTasks(userStoryId);

                for (User_Story_Data_Commit__c dataCommitToDelete : dataCommitsToDelete) {
                    Id dataSetId = dataCommitToDelete.Data_Set__c;

                    Deployment_Task__c deploymentTaskForDataSet = getDeploymentTaskForDataSet(existingDeploymentTasks, dataSetId);
                    if (deploymentTaskForDataSet != null) {
                        Boolean deleteTask = !isDataSetInAnotherDataCommit(remainingDataCommits, dataSetId);

                        if (deleteTask) {
                            deploymentTaskIdsToDelete.add(deploymentTaskForDataSet.Id);
                            dataSetIdsToDelete.add(dataSetId);
                        }
                    }
                }
            }
        }

        List<sObject> deploymentTasksToDelete = createDeletionRecords(deploymentTaskIdsToDelete);
        List<sObject> dataSetsToDelete = createDeletionRecords(dataSetIdsToDelete);

        Utilities.Secure_DML(deploymentTasksToDelete, Utilities.DML_Action.DEL, Schema.SObjectType.Deployment_Task__c);
        Utilities.Secure_DML(dataSetsToDelete, Utilities.DML_Action.DEL, Schema.SObjectType.Data_Set__c);
    }

    private List<sObject> createDeletionRecords(Set<Id> recordIds) {
        List<sObject> result = new List<sObject>();

        for (Id recordId : recordIds) {
            sObject deletionRecord = recordId.getSobjectType().newSobject(recordId);
            result.add(deletionRecord);
        }
        
        return result;
    }
}