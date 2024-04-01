public with sharing class PromotionProgressAlertsController {
    @AuraEnabled(cacheable=false)
    public static JobExecution__c getPromotionJob(String promotionId) {
        List<JobExecution__c> result = getPromotionJobExecutions(promotionId);

        result = discardQualityCheckJobs(result);
        return (result.isEmpty() ? null : result[0]);
    }

    @AuraEnabled(cacheable=false)
    public static JobExecution__c getDeploymentJob(String promotionId) {
        JobExecution__c result;
        Deployment__c deployment = getDeploymentByPromotionId(promotionId);

        if (deployment != null) {
            List<JobExecution__c> jobExecutions = getDeploymentJobExecutions(deployment.Id);
            jobExecutions = discardQualityCheckJobs(jobExecutions);
            result = jobExecutions.isEmpty() ? null : jobExecutions[0];
        }
        return result;
    }

    // PRIVATE

    // PMD False positive, as WITH USER_MODE is not supported yet
    private static List<JobExecution__c> getPromotionJobExecutions(String promotionId) {
        return [
            SELECT Id, Status__c, DataJson__c
            FROM JobExecution__c
            WHERE Promotion__c = :promotionId AND Job_Step__c = NULL
            WITH USER_MODE
            ORDER BY CreatedDate DESC
        ];
    }

    // PMD False positive, as WITH USER_MODE is not supported yet
    private static List<JobExecution__c> getDeploymentJobExecutions(String deploymentId) {
        return [
            SELECT Id, Status__c, DataJson__c
            FROM JobExecution__c
            WHERE Deployment__c = :deploymentId AND Job_Step__c = NULL
            WITH USER_MODE
            ORDER BY CreatedDate DESC
        ];
    }

    // PMD False positive, as WITH USER_MODE is not supported yet
    private static Deployment__c getDeploymentByPromotionId(String promotionId) {
        List<Deployment__c> result = [SELECT Id FROM Deployment__c WHERE Promotion__c = :promotionId WITH USER_MODE ORDER BY CreatedDate DESC];

        return result.isEmpty() ? null : result[0];
    }

    private static List<JobExecution__c> discardQualityCheckJobs(List<JobExecution__c> jobExecutions) {
        for (Integer index = (jobExecutions.size() - 1); index >= 0; index--) {
            JobExecution__c jobExecution = jobExecutions[index];
            if (String.isNotBlank(jobExecution.DataJson__c)) {
                JobExecutionData data = (JobExecutionData) JSON.deserialize(jobExecution.DataJson__c, JobExecutionData.class);
                if (String.isNotBlank(data.parentJobExecutionId)) {
                    jobExecutions.remove(index);
                }
            }
        }
        return jobExecutions;
    }

    private with sharing class JobExecutionData {
        private String parentJobExecutionId;
    }
}