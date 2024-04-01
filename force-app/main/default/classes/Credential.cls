@IsTest
public class Credential extends DomainBuilder {
    public Credential(Environment env) {
        super(Org__c.SObjectType);
        set(Org__c.Validated_Date__c, System.now());
        orgId(new Random().string(15) + '_' + new Random().string(15));
        setParent(Org__c.Environment__c, env);
    }

    public Credential() {
        this(new Environment());
    }

    public Credential name(String name) {
        return (Credential) set(Org__c.Name, name);
    }

    public Credential oAuthSignature(String oAuthSignature) {
        return (Credential) set(Org__c.Oauth_Signature__c, oAuthSignature);
    }

    public Credential environment(string environment) {
        return (Credential) set(Org__c.Environment__c, environment);
    }

    public Credential orgId(string value) {
        return (Credential) set(Org__c.SFDC_Org_ID__c, value);
    }
}