public with sharing class JobExecutionsSelector extends fflib_SObjectSelector {
    public SObjectType getSObjectType() {
        return JobExecution__c.sObjectType;
    }

    public List<SObjectField> getSObjectFieldList() {
        return new List<SObjectField>{
            JobExecution__c.Id,
            JobExecution__c.Name,
            JobExecution__c.OwnerId,
            JobExecution__c.Status__c,
            JobExecution__c.ParentId__c,
            JobExecution__c.Promotion__c,
            JobExecution__c.Deployment__c,
            JobExecution__c.Destination__c,
            JobExecution__c.Callback__c,
            JobExecution__c.DataJson__c,
            JobExecution__c.Pipeline__c,
            JobExecution__c.VolumeOptions__c,
            JobExecution__c.ParentRecord_Id__c,
            JobExecution__c.ErrorMessage__c,
            JobExecution__c.LastModifiedDate,
            JobExecution__c.Job_Step__c
        };
    }

    public JobExecution__c byId(Id recordId) {
        List<JobExecution__c> result = byId(new Set<Id>{ recordId });

        return (result.isEmpty() ? null : result[0]);
    }

    public List<JobExecution__c> byId(Set<Id> recordIds) {
        return Database.query(
            newQueryFactory().selectFields(new List<String>{ 'Template__c', 'Template__r.Name' }).setCondition(' Id IN :recordIds ').toSOQL()
        );
    }

    public JobExecution__c byIdWithSteps(Id recordId) {
        fflib_QueryFactory query = newQueryFactory()
            .setCondition('Id = :recordId')
            .selectFields(new List<String>{ 'Pipeline__r.Git_Repository__c' })
            .setOrdering('CreatedDate', fflib_QueryFactory.SortOrder.DESCENDING);

        new JobStepsSelector().addQueryFactorySubselect(query);

        List<JobExecution__c> result = (List<JobExecution__c>) Database.query(query.toSOQL());

        return (result.isEmpty() ? null : result[0]);
    }

    public JobExecution__c byPromotionId(Id promotionId) {
        fflib_QueryFactory query = newQueryFactory()
            .setCondition(JobExecution__c.Promotion__c + ' = :promotionId AND Job_Step__c = null')
            .setOrdering('CreatedDate', fflib_QueryFactory.SortOrder.DESCENDING);

        new JobStepsSelector().addQueryFactorySubselect(query);

        List<JobExecution__c> result = (List<JobExecution__c>) Database.query(query.toSOQL());

        result = discardQualityCheckJobs(result);

        return (result.isEmpty() ? null : result[0]);
    }

    public JobExecution__c byDeploymentId(Id deploymentId) {
        fflib_QueryFactory query = newQueryFactory()
            .setCondition(JobExecution__c.Deployment__c + ' = :deploymentId AND Job_Step__c = null')
            .setOrdering('CreatedDate', fflib_QueryFactory.SortOrder.DESCENDING);

        new JobStepsSelector().addQueryFactorySubselect(query);

        List<JobExecution__c> result = (List<JobExecution__c>) Database.query(query.toSOQL());

        result = discardQualityCheckJobs(result);

        return (result.isEmpty() ? null : result[0]);
    }

    public List<JobExecution__c> byUserStory(Id userStoryId) {
        List<JobExecution__c> result = (List<JobExecution__c>) Database.query(
            newQueryFactory()
                .selectFields(new List<String>{ 'UserStoryCommit__c', 'UserStoryCommit__r.Status__c' })
                .setCondition('UserStoryCommit__r.User_Story__c = :userStoryId ')
                .setOrdering('LastModifiedDate', fflib_QueryFactory.SortOrder.DESCENDING)
                .toSOQL()
        );
        result = discardQualityCheckJobs(result);
        return result;
    }

    public List<JobExecution__c> byUserStoryAndStatus(Id userStoryId, String status) {
        List<JobExecution__c> result = (List<JobExecution__c>) Database.query(
            newQueryFactory()
                .selectField('UserStoryCommit__c')
                .setCondition('UserStoryCommit__r.User_Story__c = :userStoryId AND Status__c =: status')
                .setOrdering('LastModifiedDate', fflib_QueryFactory.SortOrder.DESCENDING)
                .toSOQL()
        );
        result = discardQualityCheckJobs(result);
        return result;
    }

    public List<JobExecution__c> byIdForCommit(Set<Id> recordIds) {
        return (List<JobExecution__c>) Database.query(
            newQueryFactory()
                .selectFields(
                    new List<String>{
                        'UserStoryCommit__c',
                        'UserStoryCommit__r.Name',
                        'UserStoryCommit__r.User_Story__c',
                        'UserStoryCommit__r.User_Story__r.Name',
                        'UserStoryCommit__r.Snapshot_Commit__c'
                    }
                )
                .setCondition('Id IN :recordIds')
                .toSOQL()
        );
    }

    public List<JobExecution__c> byIdsWithLastRunStep(Set<Id> ids) {
        fflib_QueryFactory query = newQueryFactory().setCondition(JobExecution__c.Id + ' IN :ids');

        new JobStepsSelector()
            .addQueryFactorySubselect(query)
            .selectFields(new Set<String>{ 'Result__r.Progress_Status__c' })
            .setCondition(JobStep__c.Result__c + ' != null')
            .setOrdering(JobStep__c.Order__c, fflib_QueryFactory.SortOrder.DESCENDING, true)
            .setLimit(1);

        return Database.query(query.toSOQL());
    }

    private List<JobExecution__c> discardQualityCheckJobs(List<JobExecution__c> jobExecutions) {
        for (Integer i = (jobExecutions.size() - 1); i >= 0; i--) {
            JobExecution__c jobExecution = jobExecutions[i];
            if (String.isNotBlank(jobExecution.DataJson__c)) {
                JobExecutionData data = (JobExecutionData) JSON.deserialize(jobExecution.DataJson__c, JobExecutionData.class);
                if (String.isNotBlank(data.parentJobExecutionId)) {
                    jobExecutions.remove(i);
                }
            }
        }
        return jobExecutions;
    }

    private with sharing class JobExecutionData {
        private String parentJobExecutionId;
    }
}