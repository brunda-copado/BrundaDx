public inherited sharing class StandardResourcesSelector extends fflib_SObjectSelector {

    @TestVisible
    private static List<StandardResources__mdt> mock = new List<StandardResources__mdt>();
    
    public Schema.SObjectType getSObjectType() {
        return StandardResources__mdt.SObjectType;
    }


    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{
            StandardResources__mdt.Id,
            StandardResources__mdt.Provider__c,
            StandardResources__mdt.StaticResourceName__c
        };
    }


    public Set<String> all() {
        List<StandardResources__mdt> result = Test.isRunningTest() ? mock : 
                                                (List<StandardResources__mdt>) Database.query( newQueryFactory().toSOQL() );

        return resourceNames(result);
    }
    
    
    public static void mock(List<StandardResources__mdt> resourceNames) {
        mock = resourceNames;
    }


    private Set<String> resourceNames(List<StandardResources__mdt> resources) {
        Set<String> result = new Set<String>();

        for(StandardResources__mdt resource : resources) {
            result.add(resource.StaticResourceName__c);
        }

        return result;
    }
}