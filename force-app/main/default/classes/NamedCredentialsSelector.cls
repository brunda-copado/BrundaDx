public inherited sharing class NamedCredentialsSelector extends fflib_SObjectSelector {
    @TestVisible
    private static List<NamedCredential> mock = new List<NamedCredential>();

    //CONSTRUCTOR

    public NamedCredentialsSelector() {
        this(true);
    }

    public NamedCredentialsSelector(Boolean enforceFLS) {
        super(false, true, enforceFLS, false);
    }

    // PUBLIC

    public SObjectType getSObjectType() {
        return NamedCredential.sObjectType;
    }

    public List<SObjectField> getSObjectFieldList() {
        return new List<SObjectField>{ NamedCredential.Id, NamedCredential.DeveloperName, NamedCredential.MasterLabel, NamedCredential.EndPoint };
    }

    public List<NamedCredential> selectAll() {
        List<NamedCredential> result = Test.isRunningTest() ? mock : (List<NamedCredential>) Database.query(newQueryFactory().toSOQL());

        return result;
    }

    public List<sObject> byIds(Set<Id> recordIds) {
        return Test.isRunningTest() ? mock : (List<NamedCredential>) selectSObjectsById(recordIds);
    }

    public static void mock(List<NamedCredential> providers) {
        mock = providers;
    }
}