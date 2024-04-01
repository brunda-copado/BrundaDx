public class DeploymentTriggerHandler extends fflib_SObjectDomain {
    // CONSTRUCTOR

    public DeploymentTriggerHandler(List<Deployment__c> records) {
        super(records);
    }

    // PUBLIC

    public override void onBeforeInsert() {
        new DeploymentTriggerHelper(records, false).beforeInsert();
    }

    public override void onBeforeUpdate(Map<Id, SObject> oldDeploymentsByIds) {
        new DeploymentTriggerHelper(records, (Map<Id, Deployment__c>) oldDeploymentsByIds, false).beforeUpdate();
    }

    public override void onBeforeDelete() {
        new DeploymentTriggerHelper(records, false).beforeDelete();
    }

    public override void onAfterInsert() {
        new DeploymentTriggerHelper(records, true).afterInsert();
    }

    public override void onAfterUpdate(Map<Id, SObject> oldDeploymentsByIds) {
        new DeploymentTriggerHelper(records, (Map<Id, Deployment__c>) oldDeploymentsByIds, true).afterUpdate();
    }

    public override void onAfterDelete() {
        new DeploymentTriggerHelper(records, false).afterDelete();
    }

    // INNER

    public class Constructor implements fflib_SObjectDomain.IConstructable {
        public fflib_SObjectDomain construct(List<SObject> records) {
            return new DeploymentTriggerHandler(records);
        }
    }
}