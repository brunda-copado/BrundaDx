@IsTest
public class Environment extends DomainBuilder {
    public Environment() {
        super(Environment__c.SObjectType);
    }

    public Environment name(String name) {
        return (Environment) set(Environment__c.Name, name);
    }

    public Environment type(String type) {
        return (Environment) set(Environment__c.Type__c, type);
    }

    public Environment platform(String platform) {
        return (Environment) set(Environment__c.Platform__c, platform);
    }

    public Environment add(Credential cred) {
        return (Environment) cred.setParent(Org__c.Environment__c, this);
    }

    public Environment add(Promotion pro) {
        return (Environment) pro.setParent(Promotion__c.Source_Environment__c, this);
    }

    public Environment add(SystemProperty systemProperty) {
        return (Environment) systemProperty.setParent(System_Property__c.Environment__c, this);
    }
}