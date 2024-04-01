@IsTest
public class Connection extends DomainBuilder {
    public Connection(Pipeline pip, Environment source, Environment destination) {
        super(Deployment_Flow_Step__c.SObjectType);
        setParent(Deployment_Flow_Step__c.Deployment_Flow__c, pip);
        setParent(Deployment_Flow_Step__c.Source_Environment__c, source);
        setParent(Deployment_Flow_Step__c.Destination_Environment__c, destination);
    }

    public Connection() {
        super(Deployment_Flow_Step__c.SObjectType);
    }

    public Connection(Pipeline pip) {
        this(pip, new Environment(), new Environment());
    }

    public Connection(Environment source, Environment destination) {
        this(new Pipeline(), source, destination);
    }

    public Connection branch(String branch) {
        return (Connection) set(Deployment_Flow_Step__c.Branch__c, branch);
    }

    public Connection sourceId(Id sourceId) {
        return (Connection) set(Deployment_Flow_Step__c.Source_Environment__c, sourceId);
    }

    public Connection destinationId(Id destinationId) {
        return (Connection) set(Deployment_Flow_Step__c.Destination_Environment__c, destinationId);
    }

    public Connection stageConnection(StageConnection stageConnection) {
        setParent(Deployment_Flow_Step__c.Stage_Connection__c, stageConnection);
        return this;
    }

}