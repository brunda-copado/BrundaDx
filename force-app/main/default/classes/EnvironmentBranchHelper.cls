@SuppressWarnings('PMD.ApexSOQLInjection')
public with sharing class EnvironmentBranchHelper {

    private JobStep__c step;
    private List<Deployment_Flow_Step__c> connections;

    // CONSTRUCTOR

    public EnvironmentBranchHelper(Id contextId) {
        step = [SELECT Id, Pipeline_Id__c, Source_Id__c, Destination_Id__c
                    FROM JobStep__c
                    WHERE Id = :contextId
                    WITH SECURITY_ENFORCED];

        connections = [SELECT Id, Branch__c, Deployment_Flow__r.Main_Branch__c, Source_Environment__c, Destination_Environment__c
                            FROM Deployment_Flow_Step__c
                            WHERE Deployment_Flow__c = :step.Pipeline_Id__c
                            WITH SECURITY_ENFORCED];
    }


    // PUBLIC

    public String getSourceBranchName() {
        String result = null;

        if(step.Source_Id__c == finalEnvironmentId()) {
            result = connections[0].Deployment_Flow__r.Main_Branch__c;
        } else {
            result = getEnvironmentBranch(step.Source_Id__c);
        }

        return result;
    }


    public String getDestinationBranchName() {
        return getEnvironmentBranch(step.Destination_Id__c);
    }


    // PRIVATE

    private String getEnvironmentBranch(Id environmentId) {
        String result = null;

        for(Deployment_Flow_Step__c connection : connections) {
            if(connection.Source_Environment__c == environmentId) {
                result = connection.Branch__c;
                break;
            }
        }

        return result;
    }


    private Id finalEnvironmentId() {
        Id result = null;

        Set<Id> sourceEnvironments = new Set<Id>();
        Set<Id> destinationEnvironments = new Set<Id>();

        for (Deployment_Flow_Step__c connection : connections) {
            sourceEnvironments.add(connection.Source_Environment__c);
            destinationEnvironments.add(connection.Destination_Environment__c);
        }

        for (Id destinationEnvironment : destinationEnvironments) {
            if (!sourceEnvironments.contains(destinationEnvironment)) {
                result = destinationEnvironment;
                break;
            }
        }

        return result;
    }
}