public with sharing class CreateLocalConnection {
    private Id targetId;
    private Deployment_Flow__c pipeline;


    // CONSTRUCTOR

    public CreateLocalConnection(Deployment_Flow__c pipeline, Id targetId) {
        this.pipeline = pipeline;
        this.targetId = targetId;
    }


    // PUBLIC

    public Id execute() {
        Savepoint sp = Database.setSavepoint();

        try {
            Environment__c source = environment();
         
            List<Deployment_Flow_Step__c> localConnections = new DeploymentFlowStepsSelector().byParentIds(pipeline.Id, source.Id, targetId);
            
            if(!localConnections.isEmpty()) {
                throw new CliException(Label.LocalEnvironmentExists + localConnections[0].Id);
            }

            return createConnection(source.Id);
        } catch (Exception ex) {
            Database.rollback(sp);
            throw new CliException(ex.getMessage());
        }
    }

    
    // PRIVATE

    private Id createConnection(Id sourceId) {
        Deployment_Flow_Step__c result = new Deployment_Flow_Step__c();
        result.Deployment_Flow__c = pipeline.Id;
        result.Source_Environment__c = sourceId;
        result.Destination_Environment__c = targetId;
        result.Branch__c = 'copado-local-dev-user-' + UserInfo.getUserId();
        insert result;

        return result.Id;
    }

    private Environment__c environment() {
        Environment__c result;

        String environmentName = environmentName();
        List<Environment__c> environments = [SELECT Id FROM Environment__c WHERE Name = :environmentName WITH SECURITY_ENFORCED];

        if(environments.isEmpty()) {
            result = createEnvironment();
            createSnapshot(result.Id);
        } else {
            result = environments[0];
        }

        return result;
    }

    private Environment__c createEnvironment() {
        Environment__c result = new Environment__c();
        result.Name = environmentName();
        result.Platform__c = pipeline.Platform__c;
        result.Connection_Behavior__c = connectionBehaviour().Id;
        insert result;
        
        return result;
    }

    private String environmentName() {
        return 'Local Dev(' + pipeline.Platform__c + '): ' + UserInfo.getName();
    }

    private Connection_Behavior__c connectionBehaviour() {
        List<Connection_Behavior__c> connectionBehaviours = [SELECT Id FROM Connection_Behavior__c WHERE Name = 'local' WITH SECURITY_ENFORCED];
       
        return connectionBehaviours.isEmpty() ? createConnectionBehaviour() : connectionBehaviours[0];
    }

    private Connection_Behavior__c createConnectionBehaviour() {
        Connection_Behavior__c result = new Connection_Behavior__c();
        result.Name = 'local';
        result.Back_Promotion_Behavior__c = 'Disabled';
        result.DisableEnvironmentBranch__c = true;
        insert result;

        return result;
    }

    private void createSnapshot(Id environmentId) {
        Org__c org = [SELECT Id, Name FROM Org__c WHERE Environment__c = :environmentId WITH SECURITY_ENFORCED LIMIT 1];

        Git_Backup__c result = new Git_Backup__c();
        result.Org__c = org.Id;
        result.Frequency__c = 'None';
        result.Branch__c = branchName();
        result.Name = org.Id + ' Git Snapshot';
        result.Git_Repository__c = pipeline.Git_Repository__c;
        result.Git_Snapshot_Permissions__c = 'Allow Commits Only';

        insert result;
    }

    private String branchName() {
        return environmentName().toLowerCase().trim().replaceAll('[^a-z0-9\\s]+', '').replaceAll('[\\s]+', '-');
    }
}