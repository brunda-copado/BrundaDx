@IsTest
public class Pipeline extends DomainBuilder {
    public Pipeline(Repository rep) {
        super(Deployment_Flow__c.SObjectType);
        setParent(Deployment_Flow__c.Git_Repository__c, rep);

        set(Deployment_Flow__c.Active__c, true);
        set(Deployment_Flow__c.Main_Branch__c, 'main');
    }

    public Pipeline() {
        this(new Repository());
    }

    public Pipeline active(Boolean active) {
        return (Pipeline) set(Deployment_Flow__c.Active__c, active);
    }

    public Pipeline repository(String value) {
        return (Pipeline) set(Deployment_Flow__c.Git_Repository__c, value);
    }

    public Pipeline mainBranch(String mainBranch) {
        return (Pipeline) set(Deployment_Flow__c.Main_Branch__c, mainBranch);
    }

    public Pipeline setPlatform(String platform) {
        return (Pipeline) set(Deployment_Flow__c.Platform__c, platform);
    }

    public Pipeline add(Connection con) {
        return (Pipeline) con.setParent(Deployment_Flow_Step__c.Deployment_Flow__c, this);
    }

    public Pipeline add(Project prj) {
        return (Pipeline) prj.setParent(Project__c.Deployment_Flow__c, this);
    }

    public Pipeline add(PipelineAction action) {
        return (Pipeline) action.setParent(Pipeline_Action__c.Pipeline__c, this);
    }

    public Pipeline add(StageConnection stageConnection) {
        return (Pipeline) stageConnection.setParent(Stage_Connection__c.Pipeline__c, this);
    }

    public Pipeline add(AutomationRule rule) {
        return (Pipeline) rule.setParent(Automation_Rule__c.Pipeline__c, this);
    }

    public Pipeline add(SystemProperty systemProperty) {
        return (Pipeline) systemProperty.setParent(System_Property__c.Pipeline__c, this);
    }

    public Pipeline add(GitSnapshot gitSnapshot) {
        return (Pipeline) gitSnapshot.setParent(Git_Backup__c.Pipeline__c, this);
    }
}