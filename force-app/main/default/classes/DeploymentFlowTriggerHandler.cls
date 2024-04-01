public without sharing class DeploymentFlowTriggerHandler extends fflib_SObjectDomain {
    // CONSTRUCTOR

    public DeploymentFlowTriggerHandler(List<Deployment_Flow__c> records) {
        super(records);
    }

    // PUBLIC

    public override void onValidate() {
        checkLicenseLimit();
        new CheckCBMLicense(records).execute();
    }

    public override void onValidate(Map<Id, SObject> old) {
        checkLicenseLimit();
        new CheckCBMLicense(records).execute();
        new RestrictPlatformChange(records, (Map<Id, Deployment_Flow__c>) old).run();
    }

    public override void onBeforeInsert() {
        new DeploymentFlowTriggerHelper(records).execute();
    }

    public override void onBeforeUpdate(Map<Id, SObject> oldMap) {
        new DeploymentFlowTriggerHelper(records).execute();
    }

    public override void onAfterInsert() {
        new CreatePipelineActions(records).run();
        FeatureHelper.updateNumberOfProductionEnvironmentFeatureParameter();
    }

    public override void onAfterUpdate(Map<Id, SObject> oldMap) {
        FeatureHelper.updateNumberOfProductionEnvironmentFeatureParameter();
    }

    // PRIVATE

    private void checkLicenseLimit() {
        if (LicenseHelper.isLicensesExceeded()) {
            for (SObject record : records) {
                record.addError(Label.LICENSES_EXCEEDED);
            }
        }
    }

    // INNER

    public class Constructor implements fflib_SObjectDomain.IConstructable {
        public fflib_SObjectDomain construct(List<SObject> records) {
            return new DeploymentFlowTriggerHandler(records);
        }
    }
}