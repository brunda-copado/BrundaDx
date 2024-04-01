public inherited sharing class StaticResourcesSelector {

    @TestVisible
    private static List<StaticResource> mock = new List<StaticResource>();

    public List<StaticResource> byId(Id recordId) {
        return (Test.isRunningTest() && !mock.isEmpty()) ? mock : 
                                                            [SELECT Id, Name, Body FROM StaticResource WHERE Id = :recordId];    
    }

    public List<StaticResource> byName(String name) {
        return byName(new Set<String> { name });
    }

    public List<StaticResource> byName(Set<String> names) {
        return (Test.isRunningTest() && !mock.isEmpty()) ? mock : [SELECT Id, Name, Body FROM StaticResource WHERE Name IN :names];
    }
}