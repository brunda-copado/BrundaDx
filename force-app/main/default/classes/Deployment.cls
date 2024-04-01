@IsTest
public class Deployment extends DomainBuilder {

    Promotion__c pro;

    public Deployment() {
        super(Deployment__c.SObjectType);
    }

    public Deployment(Promotion pro) {
        this();
        this.pro = (Promotion__c) pro.record;
        new Destination(this).set(Destination_Org__c.To_Org__c, this.pro.Source_Org_Credential__c);
        set(Deployment__c.Promotion__c, this.pro.Id);
        set(Deployment__c.From_Org__c, this.pro.Source_Org_Credential__c);
    }

    public Deployment name(String value) {
        return (Deployment) set(Deployment__c.Name, value);
    }

    public Deployment description(String value) {
        return (Deployment) set(Deployment__c.Description__c, value);
    }

    public Deployment promotion(String promotionId) {
        return (Deployment) set(Deployment__c.Promotion__c, promotionId);
    }

    public Deployment add(Step step) {
        return (Deployment) step.setParent(Step__c.Deployment__c, this);
    }

    public Deployment add(UserStory us) {
        us.set(User_Story__c.Project__c, this.pro.Project__c);
        us.set(User_Story__c.Release__c,  this.pro.Release__c);
        us.set(User_Story__c.Org_Credential__c,  this.pro.Source_Org_Credential__c);
        us.set(User_Story__c.Environment__c,  this.pro.Source_Environment__c);
        us.set(User_Story__c.Last_Validation_Promotion__c,  this.pro.Id);
        return (Deployment) us.setParent(User_Story__c.Last_Validation_Deployment__c, this);
    }
}