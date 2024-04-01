public with sharing class PipelineConnectionCreateService implements CLIInterface {

    // PUBLIC

    public CLIInterface getInstance() {
        return new PipelineConnectionCreateService();
    }

    public String run(CliProxy.CLIWrapper record) {
        Id result;
        
        checkFls();
        Config config = (Config) JSON.deserialize(record.body, Config.class);
        Deployment_Flow__c pipeline = pipeline(config.pipelineId);

        if(config.createLocalEnvironment == true) {
            result = new CreateLocalConnection(pipeline, config.destinationEnvironmentId).execute();
        }
        else {
            result = new CreateRegularConnection(pipeline, config).execute();
        }

        return toResponse(result);
    }

    // PRIVATE

    private Deployment_Flow__c pipeline(Id pipelineId) {
        List<Deployment_Flow__c> result = [SELECT Id, Git_Repository__c, Platform__c FROM Deployment_Flow__c WHERE Id = :pipelineId WITH SECURITY_ENFORCED];

        if(result.isEmpty()) {
            throw new CliException('Invalid Pipeline');
        }

        return result[0];
    }

    private String toResponse(Id connectionId) {
        Response result = new Response(CliSfDataWrapper.StatusResult.OK.name(), Label.ConnectionCreatedSuccessfully, connectionId);
        
        return (JSON.serialize(result));
    }

    
    private void checkFls() {
        // OLS check
        List<String> objectLevelSecurityCheck = CliSecurityService.checkOLS(
            new List<String>{
                Schema.SObjectType.Environment__c.getName(),
                Schema.SObjectType.Deployment_Flow_Step__c.getName(),
                Schema.SObjectType.Org__c.getName()
            }
        );
        if (!objectLevelSecurityCheck.isEmpty()) {
            throw new CliException(Label.Insufficient_Access + objectLevelSecurityCheck);
        }
        // FLS check
        List<String> fieldLevelSecurityCheck = new List<String>();
        List<String> checkFlsPipelineConn = CliSecurityService.checkFLS(
            Schema.SObjectType.Deployment_Flow_Step__c.getName(),
            new List<String>{
                Schema.SObjectType.Deployment_Flow_Step__c.fields.Deployment_Flow__c.getName(),
                Schema.SObjectType.Deployment_Flow_Step__c.fields.Branch__c.getName(),
                Schema.SObjectType.Deployment_Flow_Step__c.fields.Source_Environment__c.getName(),
                Schema.SObjectType.Deployment_Flow_Step__c.fields.Destination_Environment__c.getName(),
                Schema.SObjectType.Deployment_Flow_Step__c.fields.Destination_Branch__c.getName()
            },
            Utilities.DML_Action.INS
        );
        if (!checkFlsPipelineConn.isEmpty()) {
            fieldLevelSecurityCheck.addAll(checkFlsPipelineConn);
        }
        List<String> checkFlsGitSnapShot = CliSecurityService.checkFLS(
            Schema.SObjectType.Git_Backup__c.getName(),
            new List<String>{
                Schema.SObjectType.Git_Backup__c.fields.Name.getName(),
                Schema.SObjectType.Git_Backup__c.fields.Org__c.getName(),
                Schema.SObjectType.Git_Backup__c.fields.Git_Snapshot_Permissions__c.getName(),
                Schema.SObjectType.Git_Backup__c.fields.Git_Repository__c.getName(),
                Schema.SObjectType.Git_Backup__c.fields.Branch__c.getName()
            },
            Utilities.DML_Action.INS
        );
        if (!checkFlsGitSnapShot.isEmpty()) {
            fieldLevelSecurityCheck.addAll(checkFlsGitSnapShot);
        }

        if (!fieldLevelSecurityCheck.isEmpty()) {
            throw new CliException(Label.Insufficient_Access + fieldLevelSecurityCheck);
        }
    }

    // INNER

    @TestVisible
    private class Response extends CliSfDataWrapper {
        public String pipelineConnection;

        public Response(String stat, String msg, String connId) {
            status = stat;
            message = msg;
            pipelineConnection = connId;
        }
    }

    @TestVisible
    public class Config {
        public Id pipelineId;
        public String sourceBranch;
        public Boolean isScratchOrg;
        public Id sourceEnvironmentId;
        public String destinationBranch;
        public Id destinationEnvironmentId;
        public Boolean createSnapShotRecord;
        public Boolean createLocalEnvironment;
    }
}