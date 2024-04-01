@IsTest
public class JobExecution extends DomainBuilder {
    public JobExecution() {
        super(JobExecution__c.sObjectType);

        status('Draft');
    }

    public JobExecution status(String value) {
        return (JobExecution) set(JobExecution__c.Status__c, value);
    }

    public JobExecution errorMsg(String value) {
        return (JobExecution) set(JobExecution__c.ErrorMessage__c, value);
    }

    public JobExecution dataJson(String value) {
        return (JobExecution) set(JobExecution__c.DataJSON__c, value);
    }

    public JobExecution pipeline(Pipeline pipeline) {
        setParent(JobExecution__c.Pipeline__c, pipeline);
        return this;
    }

    public JobExecution destination(Environment destination) {
        setParent(JobExecution__c.Destination__c, destination);
        return this;
    }

    public JobExecution source(Environment source) {
        setParent(JobExecution__c.Source__c, source);
        return this;
    }

    public JobExecution pipeline(Id value) {
        return (JobExecution) set(JobExecution__c.Pipeline__c, value);
    }

    public JobExecution destination(Id value) {
        return (JobExecution) set(JobExecution__c.Destination__c, value);
    }

    public JobExecution source(Id value) {
        return (JobExecution) set(JobExecution__c.Source__c, value);
    }

    public JobExecution template(Id value) {
        return (JobExecution) set(JobExecution__c.Template__c, value);
    }

    public JobExecution add(JobStep step) {
        return (JobExecution) step.setParent(JobStep__c.JobExecution__c, this);
    }

    public JobExecution promotion(Id value) {
        return (JobExecution) set(JobExecution__c.Promotion__c, value);
    }

    public JobExecution deployment(Id value) {
        return (JobExecution) set(JobExecution__c.Deployment__c, value);
    }

    public JobExecution volumeOptions(String value) {
        return (JobExecution) set(JobExecution__c.VolumeOptions__c, value);
    }

    public JobExecution parentRecord(String value) {
        return (JobExecution) set(JobExecution__c.ParentRecord_Id__c, value);
    }

    public JobExecution userStoryCommit(String value) {
        return (JobExecution) set(JobExecution__c.UserStoryCommit__c, value);
    }

    public JobExecution consolidatedStep(JobStep step) {
        setParent(JobExecution__c.Job_Step__c, step);
        return this;
    }

    public JobExecution consolidatedStep(String value) {
        return (JobExecution) set(JobExecution__c.Job_Step__c, value);
    }

    public JobExecution snapshot(String value) {
        return (JobExecution) set(JobExecution__c.Snapshot__c, value);
    }
}