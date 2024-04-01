@IsTest
@SuppressWarnings('PMD.ExcessiveParameterList')
public class Promotion extends DomainBuilder {
    public Promotion(Project prj, Release rls, Credential source, Environment sourceEnv, Credential dest, Environment destEnv) {
        super(Promotion__c.SObjectType);
        setParent(Promotion__c.Project__c, prj);
        setParent(Promotion__c.Release__c, rls);
        setParent(Promotion__c.Source_Org_Credential__c, source);
        setParent(Promotion__c.Source_Environment__c, sourceEnv);
        setParent(Promotion__c.Destination_Org_Credential__c, dest);
        setParent(Promotion__c.Destination_Environment__c, destEnv);

        Pipeline pip = (Pipeline) prj.parentByRelationship.get(Project__c.Deployment_Flow__c);

        new Connection(pip, sourceEnv, destEnv);
    }

    public Promotion(Release rls, Credential source, Credential dest) {
        this(
            (Project) rls.parentByRelationship.get(Release__c.Project__c),
            rls,
            source,
            (Environment) source.parentByRelationship.get(Org__c.Environment__c),
            dest,
            (Environment) dest.parentByRelationship.get(Org__c.Environment__c)
        );
    }

    public Promotion() {
        super(Promotion__c.SObjectType);
    }

    public Promotion sourceEnvId(Id sourceEnvId) {
        return (Promotion) set(Promotion__c.Source_Environment__c, sourceEnvId);
    }

    public Promotion destinationEnvId(Id destinationEnvId) {
        return (Promotion) set(Promotion__c.Destination_Environment__c, destinationEnvId);
    }

    public Promotion status(String status) {
        return (Promotion) set(Promotion__c.Status__c, status);
    }

    public Promotion projectId(Id projectId) {
        return (Promotion) set(Promotion__c.Project__c, projectId);
    }

    public Promotion backPromotion(Boolean backPromotion) {
        return (Promotion) set(Promotion__c.Back_Promotion__c, backPromotion);
    }

    public Promotion add(PromotedUserStory promotedUserStory) {
        promotedUserStory.setParent(Promoted_User_Story__c.Promotion__c, this);
        return this;
    }
}