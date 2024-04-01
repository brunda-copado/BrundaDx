@IsTest
public class Destination extends DomainBuilder {

    public Destination(Deployment dep, Credential cred) {
        super(Destination_Org__c.SObjectType);
        setParent(Destination_Org__c.Deployment__c, dep);
        setParent(Destination_Org__c.To_Org__c, cred);
    }

    public Destination(Deployment dep) {
        super(Destination_Org__c.SObjectType);
        setParent(Destination_Org__c.Deployment__c, dep);
    }
}