public with sharing class CreateRegularConnection {
    private Map<Id, Deployment_Flow_Step__c> destinationConnectionByEnvironmentId = new Map<Id, Deployment_Flow_Step__c>();
    private Map<Id, Deployment_Flow_Step__c> sourceConnectionBySourceEnvId = new Map<Id, Deployment_Flow_Step__c>();

    private Org__c org;

    private Deployment_Flow__c pipeline;
    private PipelineConnectionCreateService.Config config;

    // CONSTRUCTOR

    public CreateRegularConnection(Deployment_Flow__c pipeline, PipelineConnectionCreateService.Config config) {
        this.config = config;
        this.pipeline = pipeline;
        this.org = defaultOrg(config.sourceEnvironmentId);
    }

    // PUBLIC

    public Id execute() {
        if(String.isBlank(pipeline.Platform__c) || pipeline.Platform__c == 'Salesforce') {
            config.sourceBranch = config.sourceBranch == null ? defaultDxBranch() : config.sourceBranch;
        }

        checkPipelineConnectionInfo();

        Deployment_Flow_Step__c connection = connection();
        DML.safeInsert(connection, 'Failed to create pipeline connection');

        createSnapshot();

        return connection.Id;
    }


    // PRIVATE

    private Org__c defaultOrg(Id environmentId) {
        List<Org__c> result = [SELECT Id, Name, Environment__c FROM Org__c WHERE Environment__c = :config.sourceEnvironmentId OR Environment__r.Org_ID__c = :config.sourceEnvironmentId WITH SECURITY_ENFORCED];
        if(result.isEmpty()) {
            throw new CliException(Label.DefaultOrgNotRegistered);
        }

        return result[0];
    }

    @SuppressWarnings('PMD.CyclomaticComplexity')
    private void checkPipelineConnectionInfo() {

        setPipelineConnections();

        if (sourceConnectionBySourceEnvId.containsKey(config.sourceEnvironmentId)) {
            throw new CliException('Source Environment exists in Pipeline');
        }
        else if (config.isScratchOrg == true &&
                    destinationConnectionByEnvironmentId.containsKey(config.destinationEnvironmentId) &&
                    String.isBlank(destinationConnectionByEnvironmentId.get(config.destinationEnvironmentId).Enable_as_Scratch_Org_Destination__c)) {
                throw new CliException('Destination Environment is not enabled as DX Target');
        }
        else if(!destinationConnectionByEnvironmentId.containsKey(config.destinationEnvironmentId) && String.isBlank(config.destinationBranch)) {
            throw new CliException(Label.targetBranchRequired);
        }
        else if(!destinationConnectionByEnvironmentId.containsKey(config.sourceEnvironmentId) && String.isBlank(config.sourceBranch)) {
            throw new CliException(Label.sourceBranchRequired);
        }
    }

    private Deployment_Flow_Step__c connection() {
        Deployment_Flow_Step__c result = new Deployment_Flow_Step__c();
        result.Branch__c = sourceBranch();
        result.Deployment_Flow__c = config.pipelineId;
        result.Destination_Branch__c = destinationBranch();
        result.Source_Environment__c = org.Environment__c;
        result.Destination_Environment__c = config.destinationEnvironmentId;

        return result;
    }

    private String sourceBranch() {
        return sourceConnectionBySourceEnvId.containsKey(config.sourceEnvironmentId) ?
                    sourceConnectionBySourceEnvId.get(config.sourceEnvironmentId).Branch__c :
                    config.sourceBranch;
    }

    private String destinationBranch() {
        return destinationConnectionByEnvironmentId.containsKey(config.destinationEnvironmentId) ?
                    destinationConnectionByEnvironmentId.get(config.destinationEnvironmentId).Destination_Branch__c :
                    config.destinationBranch;
    }

    private void createSnapshot() {
        if (config.createSnapShotRecord && !config.sourceBranch.contains('project/DX-')) {
            Git_Backup__c snapShot = new Git_Backup__c();
            snapShot.Org__c = org.Id;
            snapShot.Name = org.Id + ' Git Snapshot';
            snapShot.Branch__c = config.sourceBranch;
            snapShot.Git_Snapshot_Permissions__c = 'Allow Commits Only';
            snapShot.Git_Repository__c = pipeline.Git_Repository__c;

            DML.safeInsert(snapShot, 'Failed to create snapshot');
        }
    }

    private void setPipelineConnections() {
        List<Deployment_Flow_Step__c> pipelineConns = [
            SELECT
                Id,
                Source_Environment__c,
                Destination_Environment__c,
                Destination_Branch__c,
                Branch__c,
                Enable_as_Scratch_Org_Destination__c,
                Deployment_Flow__r.Git_Repository__c
            FROM Deployment_Flow_Step__c
            WHERE Deployment_Flow__c = :config.pipelineId
            WITH USER_MODE
        ];

        for (Deployment_Flow_Step__c pipelineConnItem : pipelineConns) {
            sourceConnectionBySourceEnvId.put(pipelineConnItem.Source_Environment__c, pipelineConnItem);
            destinationConnectionByEnvironmentId.put(pipelineConnItem.Destination_Environment__c, pipelineConnItem);
        }
    }

    private String defaultDxBranch() {
        return 'project/DX-' + String.valueOf(org.Id).substring(3, 15);
    }
}