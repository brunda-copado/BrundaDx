public without sharing class EnvironmentTriggerHandler extends fflib_SObjectDomain {

    // CONSTRUCTOR

    public EnvironmentTriggerHandler(List<Environment__c> records) {
        super(records);
    }


    // PUBLIC

    public override void onValidate() {
        validateOrgId(records);
    }


    public override void onAfterInsert() {
        new CreateDefaultOrg(records).execute();
    }


    public override void onAfterUpdate(Map<Id, SObject> old) {
        new EnvironmentTriggerHelper(records, (Map<Id, Environment__c>) old).execute();
    }


    // PRIVATE

    private void validateOrgId(List<Environment__c> environments) {
        for(Environment__c environment : environments) {
            if(String.isNotBlank(environment.Org_ID__c) && environment.Org_ID__c.length() < 18) {
                environment.Org_ID__c.addError(Label.Org_Id_Validation);
            }
        }
    }


    // INNER

    public class Constructor implements fflib_SObjectDomain.IConstructable {
        public fflib_SObjectDomain construct(List<SObject> records) {
            return new EnvironmentTriggerHandler(records);
        }
    }
}