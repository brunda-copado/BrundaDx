public with sharing class StageConnections extends fflib_SObjectDomain {
    // CTOR

    public StageConnections(List<Stage_Connection__c> records) {
        super(records);
    }

    // PUBLIC

    public override void onBeforeInsert() {
        new DuplicateStageConnectionCheck(records).execute();
    }

    public override void onBeforeUpdate(Map<Id, SObject> old) {
        new DuplicateStageConnectionCheck(records).execute();
    }

    // INNER

    public class Constructor implements fflib_SObjectDomain.IConstructable {
        public fflib_SObjectDomain construct(List<SObject> records) {
            return new StageConnections(records);
        }
    }
}