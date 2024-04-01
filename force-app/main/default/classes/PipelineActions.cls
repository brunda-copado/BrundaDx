public with sharing class PipelineActions extends fflib_SObjectDomain {
    // CTOR

    public PipelineActions(List<Pipeline_Action__c> records) {
        super(records);
    }

    // PUBLIC

    public override void onBeforeInsert() {
        new CheckEnvironmentBelongsToPipeline(records).execute();
        new CheckDuplicatedPipelineActions(records).execute();
        new SetOverridesPipelineAction(records).execute();
        new PreventForbiddenPipelineActions(records, null).execute();
    }

    public override void onBeforeUpdate(Map<Id, SObject> old) {
        new CheckEnvironmentBelongsToPipeline(records).execute();
        new CheckDuplicatedPipelineActions(records).execute();
        new SetOverridesPipelineAction(records).execute();
        new PreventAlteringDefaultPipelineActions(records, old).execute();
        new PreventForbiddenPipelineActions(records, old).execute();
    }

    public override void onBeforeDelete() {
        new PreventDeletingDefaultPipelineActions(records).execute();
    }

    // INNER

    public class Constructor implements fflib_SObjectDomain.IConstructable {
        public fflib_SObjectDomain construct(List<SObject> records) {
            return new PipelineActions(records);
        }
    }
}