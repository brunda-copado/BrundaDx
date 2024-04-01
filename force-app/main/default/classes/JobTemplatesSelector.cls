public inherited sharing class JobTemplatesSelector extends fflib_SObjectSelector {
    public SObjectType getSObjectType() {
        return JobTemplate__c.sObjectType;
    }

    public List<SObjectField> getSObjectFieldList() {
        return new List<SObjectField>{
            JobTemplate__c.Id,
            JobTemplate__c.Name,
            JobTemplate__c.Type__c,
            JobTemplate__c.ApiName__c,
            JobTemplate__c.VolumeOptions__c
        };
    }

    public List<JobTemplate__c> byId(Set<Id> recordIds) {
        return selectSObjectsById(recordIds);
    }

    public JobTemplate__c byApiName(String name) {
        return byApiName(new Set<String>{ name }).get(0);
    }

    public List<JobTemplate__c> byApiName(Set<String> names) {
        fflib_QueryFactory query = newQueryFactory().setCondition(JobTemplate__c.ApiName__c + ' IN :names');

        new JobStepsSelector().addQueryFactorySubselect(query).setOrdering(JobStep__c.Order__c, fflib_QueryFactory.SortOrder.ASCENDING);

        return Database.query(query.toSOQL());
    }

    public JobTemplate__c byIdWithSteps(Id id) {
        return byIdWithSteps(new Set<Id>{ id }).get(0);
    }

    public List<JobTemplate__c> byIdWithSteps(Set<Id> ids) {
        fflib_QueryFactory query = newQueryFactory().setCondition(JobTemplate__c.Id + ' IN :ids');

        JobStepsSelector jobSteps = new JobStepsSelector();
        jobSteps.addQueryFactorySubselect(query)
            .selectFields(jobSteps.writableFields())
            .setOrdering(JobStep__c.Order__c, fflib_QueryFactory.SortOrder.ASCENDING);

        return Database.query(query.toSOQL());
    }

    public List<JobTemplate__c> byApiNameWithSteps(String apiName) {
        fflib_QueryFactory query = newQueryFactory().setCondition(JobTemplate__c.ApiName__c + ' = :apiName');

        JobStepsSelector jobSteps = new JobStepsSelector();
        jobSteps.addQueryFactorySubselect(query)
            .selectFields(jobSteps.writableFields())
            .setOrdering(JobStep__c.Order__c, fflib_QueryFactory.SortOrder.ASCENDING);

        return Database.query(query.toSOQL());
    }
}