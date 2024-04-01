@IsTest
public class JobStep extends DomainBuilder {
    public JobStep() {
        super(JobStep__c.SObjectType);

        name(new Random().string());
        set(JobStep__c.Type__c, 'Flow');
        set(JobStep__c.ConfigJson__c, '{"flowName" : "MockedFlow"}');
    }

    public JobStep resourceObservations(String value) {
        return (JobStep) set(JobStep__c.Resource_Observations__c, value);
    }

    public JobStep executionSequence(String value) {
        return (JobStep) set(JobStep__c.ExecutionSequence__c, value);
    }

    public JobStep userStory(Id value) {
        return (JobStep) set(JobStep__c.UserStory__c, value);
    }

    public JobStep repository(Id value) {
        return (JobStep) set(JobStep__c.Git_RepositoryId__c, value);
    }

    public JobStep type(String value) {
        return (JobStep) set(JobStep__c.Type__c, value);
    }

    public JobStep name(String value) {
        return (JobStep) set(JobStep__c.Name, value);
    }

    public JobStep order(Integer value) {
        return (JobStep) set(JobStep__c.Order__c, value);
    }

    public JobStep pipeline(Id value) {
        return (JobStep) set(JobStep__c.PipelineId__c, value);
    }

    public JobStep configJson(String value) {
        return (JobStep) set(JobStep__c.ConfigJson__c, value);
    }

    public JobStep resultDataJson(String value) {
        return (JobStep) set(JobStep__c.ResultDataJson__c, value);
    }

    public JobStep resultViewerComponent(String value) {
        return (JobStep) set(JobStep__c.Result_Viewer_Component__c, value);
    }

    public JobStep skipCondition(String value) {
        return (JobStep) set(JobStep__c.SkipCondition__c, value);
    }

    public JobStep isSkipped(Boolean value) {
        return (JobStep) set(JobStep__c.IsSkipped__c, value);
    }

    public JobStep qualityRuleCondition(QualityGateRuleCondition c) {
        setParent(JobStep__c.Quality_Gate_Rule_Condition__c, c);
        return this;
    }

    public JobStep result(Result r) {
        setParent(JobStep__c.Result__c, r);
        return this;
    }

    public JobStep add(Result result) {
        return (JobStep) result.setParent(Result__c.JobStep__c, this);
    }
}