public inherited sharing class JobStepsSelector extends fflib_SObjectSelector {
    public SObjectType getSObjectType() {
        return JobStep__c.sObjectType;
    }

    public List<SObjectField> getSObjectFieldList() {
        return new List<SObjectField>{
            JobStep__c.Id,
            JobStep__c.Name,
            JobStep__c.Type__c,
            JobStep__c.Order__c,
            JobStep__c.Result__c,
            JobStep__c.Status__c,
            JobStep__c.ApiName__c,
            JobStep__c.UserStory__c,
            JobStep__c.ConfigJson__c,
            JobStep__c.CustomType__c,
            JobStep__c.JobTemplate__c,
            JobStep__c.JobExecution__c,
            JobStep__c.ResultDataJson__c,
            JobStep__c.ExecutionSequence__c,
            JobStep__c.Resource_Observations__c,
            JobStep__c.Sub_Job_Execution__c,
            JobStep__c.Pipeline_Id__c,
            JobStep__c.Source_Id__c,
            JobStep__c.Destination_Id__c,
            JobStep__c.Quality_Gate_Rule__c,
            JobStep__c.Quality_Gate_Rule_Condition__c,
            JobStep__c.Git_RepositoryId__c,
            JobStep__c.PipelineId__c,
            JobStep__c.Result_Viewer_Component__c,
            JobStep__c.SkipCondition__c,
            JobStep__c.IsSkipped__c
        };
    }

    public JobStep__c byId(Id recordId) {
        return byId(new Set<Id>{ recordId }).get(0);
    }

    public List<JobStep__c> byId(Set<Id> recordIds) {
        return (List<JobStep__c>) selectSObjectsById(new Set<Id>(recordIds));
    }

    public List<JobStep__c> byJob(Id jobId) {
        fflib_QueryFactory query = newQueryFactory()
            .setCondition('JobExecution__c = :jobId')
            .setOrdering('Order__c', fflib_QueryFactory.SortOrder.ASCENDING);

        return Database.query(query.toSOQL());
    }

    public List<JobStep__c> byJobAndStatus(Id jobId, String status) {
        fflib_QueryFactory query = newQueryFactory()
            .setCondition('JobExecution__c = :jobId AND Status__c = :status')
            .setOrdering('Order__c', fflib_QueryFactory.SortOrder.ASCENDING);

        return Database.query(query.toSOQL());
    }

    public List<JobStep__c> byJobWithResults(Set<String> jobExecutionIds) {
        fflib_QueryFactory query = newQueryFactory()
            .selectFields(new List<String>{ 'Result__r.Status__c' })
            .selectFields(new List<String>{ 'Result__r.Error_Message__c' })
            .selectFields(new List<String>{ 'Result__r.Name' })
            .setCondition('JobExecution__c IN :jobExecutionIds')
            .setOrdering('Order__c', fflib_QueryFactory.SortOrder.ASCENDING);

        return (List<JobStep__c>) Database.query(query.toSOQL());
    }

    public List<JobStep__c> byUserStoryId(Set<Id> userStoryIds) {
        fflib_QueryFactory query = newQueryFactory()
            .setCondition('UserStory__c IN :userStoryIds')
            .setOrdering('Order__c', fflib_QueryFactory.SortOrder.ASCENDING)
            .addOrdering('UserStory__r.Name', fflib_QueryFactory.SortOrder.ASCENDING);

        return Database.query(query.toSOQL());
    }

    public List<JobStep__c> byUserStoryIdAndExecutionSequence(Id userStoryId, String sequence) {
        fflib_QueryFactory query = newQueryFactory()
            .setCondition('UserStory__c = :userStoryId AND ExecutionSequence__c = :sequence')
            .setOrdering('Order__c', fflib_QueryFactory.SortOrder.ASCENDING)
            .addOrdering('UserStory__r.Name', fflib_QueryFactory.SortOrder.ASCENDING);

        return Database.query(query.toSOQL());
    }

    public List<JobStep__c> byTemplateApiName(String templateName) {
        fflib_QueryFactory query = newQueryFactory()
            .setCondition('JobTemplate__r.ApiName__c = :templateName')
            .setOrdering('Order__c', fflib_QueryFactory.SortOrder.ASCENDING);

        return Database.query(query.toSOQL());
    }

    public List<JobStep__c> byParent(Id parentId) {
        return Database.query(
            newQueryFactory()
                .selectField('Result__r.Name')
                .setCondition('JobExecution__c = :parentId OR JobTemplate__c = :parentId OR UserStory__c = :parentId')
                .setOrdering('ExecutionSequence__c', fflib_QueryFactory.SortOrder.ASCENDING)
                .setOrdering('Order__c', fflib_QueryFactory.SortOrder.ASCENDING)
                .toSOQL()
        );
    }

    public List<JobStep__c> byIdWithExtensionConfiguration(Id recordId) {
        fflib_QueryFactory query = newQueryFactory()
            .selectFields(new List<String>{ 'Quality_Gate_Rule_Condition__r.Extension_Configuration__c' })
            .selectFields(new List<String>{ 'Quality_Gate_Rule_Condition__r.AcceptanceCriteria__c' })
            .setCondition('Id = :recordId AND Quality_Gate_Rule_Condition__c != null');
        return (List<JobStep__c>) Database.query(query.toSOQL());
    }

    public Set<Schema.SObjectField> writableFields() {
        Set<Schema.SObjectField> result = new Set<Schema.SObjectField>();

        for (Schema.SObjectField field : Schema.JobStep__c.sObjectType.getDescribe().fields.getMap().values()) {
            Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
            if (fieldDescribe.isCreateable() || fieldDescribe.isUpdateable()) {
                result.add(fieldDescribe.getSObjectField());
            }
        }

        return result;
    }

    public override String getOrderBy() {
        return 'Order__c ASC';
    }

    /** TO BE IMPLEMENTED LATER */
    /*public JobStep__c byResultId(Id resultId) {
        fflib_QueryFactory query = newQueryFactory().setCondition('Result__c = :resultId').setLimit(1);

        List<JobStep__c> result = Database.query(query.toSOQL());

        return (result.isEmpty() ? null : result[0]);
    }

    public List<JobStep__c> byTemplate(Id templateId) {
        fflib_QueryFactory query = newQueryFactory()
            .setCondition('JobTemplate__c = :templateId')
            .setOrdering('Order__c', fflib_QueryFactory.SortOrder.ASCENDING);

        return Database.query(query.toSOQL());
    }

    public JobStep__c getNext(Id jobId) {
        fflib_QueryFactory query = newQueryFactory()
            .setCondition('JobExecution__c = :jobId AND Status__c = \'Pending\'')
            .setOrdering('Order__c', fflib_QueryFactory.SortOrder.ASCENDING)
            .setLimit(1);

        List<JobStep__c> result = Database.query(query.toSOQL());

        return (result.isEmpty() ? null : result[0]);
    }*/
}