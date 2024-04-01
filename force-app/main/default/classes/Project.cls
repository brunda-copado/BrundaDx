@IsTest
public class Project extends DomainBuilder {
    public Project() {
        super(Project__c.SObjectType);
        setParent(Project__c.Deployment_Flow__c, new Pipeline());
    }

    public Project(Pipeline pip) {
        this(pip);
    }

    public Project name(String name) {
        return (Project) set(Project__c.Name, name);
    }

    public Project add(Release rel) {
        return (Project) rel.setParent(Release__c.Project__c, this);
    }

    public Project add(Promotion pro) {
        return (Project) pro.setParent(Promotion__c.Project__c, this);
    }

    public Project add(UserStory us) {
        return (Project) us.setParent(User_Story__c.Project__c, this);
    }
}