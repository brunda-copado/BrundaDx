public with sharing class StepTriggerHandler extends fflib_SObjectDomain {

    // CONSTRUCTOR

    public StepTriggerHandler(List<Step__c> records) {
        super(records);
    }

    // PUBLIC

    @SuppressWarnings('PMD.EmptyStatementBlock')
    public override void onApplyDefaults() {
    }

    public override void onValidate() {
        new StepTriggerHelper(records).validate();
    }

    public override void onValidate(Map<Id, SObject> oldMap) {
        new StepTriggerHelper(records).validate();
    }

    public override void onAfterInsert() {
        new StepTriggerHelper(records).afterInsert();
        new AddStepHistory(records).execute();
    }

    public override void onBeforeUpdate(Map<Id, SObject> oldMap) {
        new StepTriggerHelper(records).notifyManualStepOwner();
    }

    public override void onAfterUpdate(Map<Id, SObject> oldMap) {
        Map<Id, Step__c> oldSteps = (Map<Id, Step__c>)oldMap;

        new UpdatePausedStatusOnDeployment(records, oldSteps).execute();
        new AddStepHistory(records, oldSteps, 'Updated').execute();
    }

    public override void onAfterDelete() {
        new AddStepHistory(records, (Map<Id, Step__c>)Trigger.oldMap, 'Deleted').execute();
    }

    // INNER

    public class Constructor implements fflib_SObjectDomain.IConstructable {
        public fflib_SObjectDomain construct(List<SObject> records) {
            return new StepTriggerHandler(records);
        }
    }
}