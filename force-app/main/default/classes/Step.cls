@IsTest
public class Step extends DomainBuilder {
    public Step(Deployment dep) {
        super(Step__c.SObjectType);
        setParent(Step__c.Deployment__c, dep);
    }

    public Step() {
        this(new Deployment());
    }

    public Step order(Integer value) {
        return (Step) set(Step__c.Order__c, value);
    }

    public Step name(String value) {
        return (Step) set(Step__c.Name, value);
    }

    public Step type(String value) {
        return (Step) set(Step__c.Type__c, value);
    }

    public Step status(String value) {
        return (Step) set(Step__c.Status__c, value);
    }

    public Step dataJson(String value) {
        return (Step) set(Step__c.dataJson__c, value);
    }
}