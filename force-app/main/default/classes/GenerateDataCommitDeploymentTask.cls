public with sharing class GenerateDataCommitDeploymentTask extends DataCommitDeploymentTaskHandler {

    public GenerateDataCommitDeploymentTask(List<User_Story_Data_Commit__c> records) {
        super(records);
    }

    public void execute() {
        Map<Id, List<Deployment_Task__c>> deploymentTasksToInsertByUserStory = new Map<Id, List<Deployment_Task__c>>();

        Map<Id, List<User_Story_Data_Commit__c>> dataCommitsByUserStory = getRecords();

        for (Id userStoryId : dataCommitsByUserStory.keySet()) {
            if (!deploymentTasksToInsertByUserStory.containsKey(userStoryId)) {
                deploymentTasksToInsertByUserStory.put(userStoryId, new List<Deployment_Task__c>());
            }

            List<User_Story_Data_Commit__c> dataCommitsInserted = dataCommitsByUserStory.get(userStoryId);
            if (!dataCommitsInserted.isEmpty()) {
                List<Deployment_Task__c> existingDeploymentTasks = getDeploymentTasks(userStoryId);

                Integer order = getMaxOrder(existingDeploymentTasks) + 1;

                for (User_Story_Data_Commit__c dataCommitInserted : dataCommitsInserted) {
                    Id dataSetId = dataCommitInserted.Data_Set__c;

                    Boolean deploymentTaskAlreadyExists = getDeploymentTaskForDataSet(existingDeploymentTasks, dataSetId) != null;
                    Boolean deploymentTaskAlreadyCreated =
                        getDeploymentTaskForDataSet(deploymentTasksToInsertByUserStory.get(userStoryId), dataSetId) != null;

                    if (!deploymentTaskAlreadyExists && !deploymentTaskAlreadyCreated) {
                        Deployment_Task__c deploymentTask = createDeploymentTask(userStoryId, dataSetId, order);
                        deploymentTasksToInsertByUserStory.get(userStoryId).add(deploymentTask);
                        order++;
                    }
                }
            }
        }

        List<Deployment_Task__c> deploymentTasksToInsert = new List<Deployment_Task__c>();
        for (Id userStoryId : deploymentTasksToInsertByUserStory.keySet()) {
            deploymentTasksToInsert.addAll(deploymentTasksToInsertByUserStory.get(userStoryId));
        }

        Utilities.Secure_DML(deploymentTasksToInsert, Utilities.DML_Action.INS, Schema.SObjectType.Deployment_Task__c);
    }

    private Integer getMaxOrder(List<Deployment_Task__c> deploymentTasks) {
        Integer result = 0;
        for (Deployment_Task__c deploymentTask : deploymentTasks) {
            result = Integer.valueOf(Math.max(result, deploymentTask.Order__c));
        }
        return result;
    }

    private Deployment_Task__c createDeploymentTask(Id userStoryId, Id dataSetId, Integer order) {
        String dataSetName = getDataSet(dataSetId)?.Name;
        String taskName = 'Deploy' + ' ' + dataSetName;
        String dataJSON = generateDataJson(dataSetId);

        Deployment_Task__c deploymentTask = new Deployment_Task__c(
            dataJSON__c = dataJSON,
            Name = taskName,
            Order__c = order,
            Perform_Manual_Task__c = 'After Deployment',
            Type__c = 'Data Template',
            User_Story__c = userStoryId,
            Status__c = 'Pending'
        );
        return deploymentTask;
    }

    private String generateDataJson(Id dataSetId) {
        DataDeployRequest request = new DataDeployRequest()
            .sourceType(DataDeployRequest.Source.DATASET)
            .sourceDataSetId(dataSetId)
            .destinationType(DataDeployRequest.Destination.ENVIRONMENT);
        DataStepData data = new DataStepData(request);
        return JSON.serialize(data, true);
    }
}