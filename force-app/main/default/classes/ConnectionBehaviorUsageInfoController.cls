public with sharing class ConnectionBehaviorUsageInfoController {
    public Integer totalRelation { get; private set; }

    public ConnectionBehaviorUsageInfoController(ApexPages.StandardController stdController) {
        if (String.isNotBlank(stdController.getId())) {
            Id recordId = stdController.getId();
            List<AggregateResult> environments = (List<AggregateResult>) Database.query(
                'SELECT count(Id) envCount FROM Environment__c WHERE Connection_Behavior__c = :recordId WITH SYSTEM_MODE'
            );
            List<AggregateResult> flowStepList = (List<AggregateResult>) Database.query(
                'SELECT count(Id) dfsCount FROM Deployment_Flow_Step__c WHERE Connection_Behavior_Override__c = :recordId WITH SYSTEM_MODE'
            );
            totalRelation = ((Integer) environments.get(0).get('envCount')) + ((Integer) flowStepList.get(0).get('dfsCount'));
        }
    }
}