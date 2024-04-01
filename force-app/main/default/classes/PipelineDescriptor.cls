public with sharing class PipelineDescriptor {
    private Id pipelineId;

    private List<Deployment_Flow_Step__c> pipelineConnections {
        get {
            if (pipelineConnections == null) {
                pipelineConnections = [
                    SELECT
                        Stage_Connection__c,
                        Stage_Connection__r.Stage__c,
                        Stage_Connection__r.Stage__r.Display_Name__c,
                        Stage_Connection__r.Next_Stage_Connection__r.Stage__c,
                        Stage_Connection__r.Next_Stage_Connection__r.Stage__r.Display_Name__c,
                        Source_Environment__c,
                        Source_Environment__r.Name,
                        Destination_Environment__c,
                        Destination_Environment__r.Name
                    FROM Deployment_Flow_Step__c
                    WHERE Deployment_Flow__c = :pipelineId
                    WITH SECURITY_ENFORCED
                ];
            }
            return pipelineConnections;
        }
        set;
    }

    public PipelineDescriptor(Id pipelineId) {
        this.pipelineId = pipelineId;
    }

    // PUBLIC

    public Map<Id, Stage> stages() {
        Map<Id, Stage> result = new Map<Id, Stage>();
        Set<Id> consideredEnvironments = new Set<Id>();

        for (Deployment_Flow_Step__c pipelineConnection : pipelineConnections) {
            Id sourceEnvironmentId = pipelineConnection.Source_Environment__c;
            Stage_Connection__c stageConnection = pipelineConnection.Stage_Connection__r;
            if (stageConnection == null) {
                continue;
            }
            Stage stage = addStage(result, stageConnection.Stage__r);
            if (!consideredEnvironments.contains(sourceEnvironmentId)) {
                stage.addEnvironment(pipelineConnection.Source_Environment__r);
                consideredEnvironments.add(sourceEnvironmentId);
            }
        }

        for (Deployment_Flow_Step__c pipelineConnection : pipelineConnections) {
            if (!consideredEnvironments.contains(pipelineConnection.Destination_Environment__c)) {
                Stage_Connection__c nextStageConnection = pipelineConnection.Stage_Connection__r.Next_Stage_Connection__r;
                if (nextStageConnection == null) {
                    continue;
                }
                Stage nextStage = addStage(result, nextStageConnection.Stage__r);
                nextStage.addEnvironment(pipelineConnection.Destination_Environment__r);
            }
        }

        return result;
    }

    public Map<Id, Environment__c> environments() {
        Map<Id, Environment__c> result = new Map<Id, Environment__c>();

        for (Deployment_Flow_Step__c pipelineConnection : pipelineConnections) {
            Id sourceEnvironmentId = pipelineConnection.Source_Environment__c;
            Environment__c sourceEnvironment = pipelineConnection.Source_Environment__r;
            Id destinationEnvironmentId = pipelineConnection.Destination_Environment__c;
            Environment__c destinationEnvironment = pipelineConnection.Destination_Environment__r;
            if (!result.containsKey(sourceEnvironmentId)) {
                result.put(sourceEnvironmentId, sourceEnvironment);
            }

            if (!result.containsKey(destinationEnvironmentId)) {
                result.put(destinationEnvironmentId, destinationEnvironment);
            }
        }

        return result;
    }

    public Map<Id, Environment__c> allButFinalEnvironments() {
        Map<Id, Environment__c> result = new Map<Id, Environment__c>();

        Set<Id> sourceEnvironments = new Set<Id>();
        Set<Id> destinationEnvironments = new Set<Id>();
        Set<Id> finalEnvironments = new Set<Id>();

        for (Deployment_Flow_Step__c pipelineConnection : pipelineConnections) {
            Id sourceEnvironmentId = pipelineConnection.Source_Environment__c;
            Environment__c sourceEnvironment = pipelineConnection.Source_Environment__r;
            Id destinationEnvironmentId = pipelineConnection.Destination_Environment__c;
            Environment__c destinationEnvironment = pipelineConnection.Destination_Environment__r;
            if (!result.containsKey(sourceEnvironmentId)) {
                result.put(sourceEnvironmentId, sourceEnvironment);
            }

            if (!result.containsKey(destinationEnvironmentId)) {
                result.put(destinationEnvironmentId, destinationEnvironment);
            }

            sourceEnvironments.add(sourceEnvironmentId);
            destinationEnvironments.add(destinationEnvironmentId);
        }

        for (Id destEnv : destinationEnvironments) {
            if (!sourceEnvironments.contains(destEnv)) {
                finalEnvironments.add(destEnv);
            }
        }

        for (Id finalEnv : finalEnvironments) {
            if (result.containsKey(finalEnv)) {
                result.remove(finalEnv);
            }
        }

        return result;
    }

    public Stage__c getStage(Id environmentId) {
        Stage__c result;

        Map<Id, Stage> stagesById = stages();
        for (Id stageId : stagesById.keySet()) {
            if (stagesById.get(stageId).environmentsById.keySet().contains(environmentId)) {
                result = stagesById.get(stageId).stage;
                break;
            }
        }
        return result;
    }

    public String getStageId(Id environmentId) {
        Stage__c stage = getStage(environmentId);
        return stage?.Id;
    }

    // PRIVATE

    private Stage addStage(Map<Id, Stage> stagesById, Stage__c stage) {
        Id stageId = stage.Id;
        if (!stagesById.containsKey(stageId)) {
            stagesById.put(stageId, new Stage(stage));
        }
        return stagesById.get(stageId);
    }

    // INNER

    public with sharing class Stage {
        @AuraEnabled
        public Stage__c stage;
        @AuraEnabled
        public Map<Id, Environment__c> environmentsById;

        public Stage(Stage__c stage) {
            this.stage = stage;
            this.environmentsById = new Map<Id, Environment__c>();
        }

        public Stage addEnvironment(Environment__c environment) {
            this.environmentsById.put(environment.Id, environment);
            return this;
        }
    }
}