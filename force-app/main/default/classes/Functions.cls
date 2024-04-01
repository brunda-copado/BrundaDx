public with sharing class Functions extends fflib_SObjectDomain {
    // CONSTRUCTOR

    public Functions(List<Function__c> records) {
        super(records);
    }

    // PUBLIC

    public override void onBeforeInsert() {
        new VerifyThatFunctions(records).areNotStandard();
        new VerifyCallbacks(records).execute();
        new FormatFunctions(records).jsonFields();
    }

    public override void onBeforeUpdate(Map<Id, SObject> old) {
        new VerifyThatFunctions(records, (Map<Id, Function__c>) old).areNotStandard();
        new VerifyCallbacks(records, (Map<Id, Function__c>) old).execute();
        new FormatFunctions(records).jsonFields();
    }

    public override void onBeforeDelete() {
        new VerifyThatFunctions(records).areNotStandard();
    }

    // INNER

    public class Constructor implements fflib_SObjectDomain.IConstructable {
        public fflib_SObjectDomain construct(List<SObject> records) {
            return new Functions(records);
        }
    }
}