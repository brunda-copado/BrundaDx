public class UserStoryDependencyTriggerHandler extends fflib_SObjectDomain {
    // CONSTRUCTOR

    public UserStoryDependencyTriggerHandler(List<Team_Dependency__c> records) {
        super(records);
    }

    // PUBLIC

    public override void onValidate() {
        new RestrictUserStoryDependencyDuplicate(records).execute();
    }

    public override void onValidate(Map<Id, SObject> old) {
        new RestrictUserStoryDependencyDuplicate(records, (Map<Id, Team_Dependency__c>) old).execute();
    }


    // INNER

    public class Constructor implements fflib_SObjectDomain.IConstructable {
        public fflib_SObjectDomain construct(List<SObject> records) {
            return new UserStoryDependencyTriggerHandler(records);
        }
    }
}