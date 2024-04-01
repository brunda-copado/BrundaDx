public inherited sharing class TestToolsSelector extends fflib_SObjectSelector {
    @TestVisible
    private static List<TestTool__mdt> mock;

    // PUBLIC

    public Schema.SObjectType getSObjectType() {
        return TestTool__mdt.SObjectType;
    }

    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{
            TestTool__mdt.Id,
            TestTool__mdt.MasterLabel,
            TestTool__mdt.TestType__c,
            TestTool__mdt.JobTemplate__c,
            TestTool__mdt.Automate_Test_Readiness__c,
            TestTool__mdt.Test_Readiness_Logic__c,
            TestTool__mdt.UserStoryBundleTestsUnifierLogic__c
        };
    }

    public List<TestTool__mdt> getAll() {
        return (Test.isRunningTest() && mock != null) ? mock : (List<TestTool__mdt>) Database.query(newQueryFactory().setEnforceFLS(true).toSOQL());
    }

    public TestTool__mdt byName(String name) {
        TestTool__mdt result;

        if (Test.isRunningTest() && mock != null) {
            if (!mock.isEmpty()) {
                result = mock[0];
            }
        } else {
            List<TestTool__mdt> tools = byNames(new List<String>{ name });
            if (!tools.isEmpty()) {
                result = tools[0];
            }
        }

        return result;
    }

    public List<TestTool__mdt> byNames(List<String> names) {
        return (Test.isRunningTest() && mock != null)
            ? mock
            : (List<TestTool__mdt>) Database.query(newQueryFactory().setEnforceFLS(true).setCondition('MasterLabel IN :names').toSOQL());
    }

    public static void mock(List<TestTool__mdt> providers) {
        mock = providers;
    }

    // DONT COMMIT THIS - MOCKING CRT
    public Database.QueryLocator getAllQueryLocator() {
        return Database.getQueryLocator(newQueryFactory().setEnforceFLS(true).toSOQL());
    }
}