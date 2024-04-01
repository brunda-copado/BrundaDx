public with sharing class QualityGateRuleConditions extends fflib_SObjectDomain {
    // CTOR

    public QualityGateRuleConditions(List<Quality_Gate_Rule_Condition__c> records) {
        super(records);
    }

    // PUBLIC

    public override void onBeforeInsert() {
        new CheckEnvironmentBelongsToPipeline(records).execute();
        new SetQgrcAcceptanceCriteria(records, null).execute();
    }

    public override void onBeforeUpdate(Map<Id, SObject> old) {
        new CheckEnvironmentBelongsToPipeline(records).execute();
        new SetQgrcAcceptanceCriteria(records, old).execute();
    }

    public override void onBeforeDelete(){
        new RestrictQualityGateUpdateOrDelete(records, null).execute();
    }

    public override void onValidate() {
        new RestrictQualityGateUpdateOrDelete(records, null).execute();
        new RestrictQgrcDuplicate(records).execute();
    }

    public override void onValidate(Map<Id, SObject> old) {
        new RestrictQualityGateUpdateOrDelete(records, old).execute();
        new RestrictQgrcDuplicate(records).execute();
    }

    // INNER

    public class Constructor implements fflib_SObjectDomain.IConstructable {
        public fflib_SObjectDomain construct(List<SObject> records) {
            return new QualityGateRuleConditions(records);
        }
    }
}