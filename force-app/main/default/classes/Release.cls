@IsTest
public class Release extends DomainBuilder {

    public Release(Project prj) {
        super(Release__c.SObjectType);
        setParent(Release__c.Project__c, prj);
    }

    public Release() {
        this( new Project() );
    }

    public Release name(String name) {
        return (Release) set(Release__c.Name, name);
    }

    public Release add(UserStory us) {
        return (Release) us.setParent(User_Story__c.Release__c, this);
    }
}