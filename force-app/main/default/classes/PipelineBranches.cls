public with sharing class PipelineBranches implements ParameterExpressionCallable {

    public String execute(Id contextId) {
        List<String> branches = new List<String>();

        List<Deployment_Flow__c> pipelines = [SELECT Main_Branch__c, (SELECT Branch__c FROM Deployment_Flow_Steps__r) FROM Deployment_Flow__c WHERE Id = :contextId WITH USER_MODE];

        if(pipelines.isEmpty()) {
            return '';
        }

        for(Deployment_Flow_Step__c connection : pipelines[0].Deployment_Flow_Steps__r) {
            branches.add(connection.Branch__c);
        }

        branches.add(pipelines[0].Main_Branch__c);

        return String.join(branches, ', ');
    }
}