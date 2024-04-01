public inherited sharing class UiSectionsSelector extends fflib_SObjectSelector {
    @TestVisible
    private static List<UISection__mdt> mocks = new List<UISection__mdt>();

    // PUBLIC

    public Schema.SObjectType getSObjectType() {
        return UISection__mdt.SObjectType;
    }

    public List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField>{
            UISection__mdt.Id,
            UISection__mdt.MasterLabel,
            UISection__mdt.NamespacePrefix,
            UISection__mdt.Component__c,
            UISection__mdt.Location__c,
            UISection__mdt.TestTool__c
        };
    }

    public List<UISection__mdt> byPlatformAndLocation(String platform, String location) {
        return Test.isRunningTest()
            ? mocks
            : (List<UISection__mdt>) Database.query(
                  newQueryFactory()
                      .setEnforceFLS(true)
                      .setCondition('Extension_Package_Configuration__r.Platform__c = :platform AND Location__c = :location')
                      .toSOQL()
              );
    }

    public List<UISection__mdt> byLocationOnly(String location) {
        return Test.isRunningTest()
            ? mocks
            : (List<UISection__mdt>) Database.query(
                  newQueryFactory()
                      .setEnforceFLS(true)
                      .setCondition('Location__c = :location')
                      .toSOQL()
              );
    }

    public List<UISection__mdt> byTestToolAndLocation(String testTool, String location) {
        return byTestToolsAndLocation(new List<String>{ testTool }, location);
    }

    public List<UISection__mdt> byTestToolsAndLocation(List<String> testTools, String location) {
        return Test.isRunningTest()
            ? mocks
            : (List<UISection__mdt>) Database.query(
                  newQueryFactory()
                      .setEnforceFLS(true)
                      .selectField('TestTool__r.MasterLabel')
                      .setCondition('TestTool__r.MasterLabel IN :testTools AND Location__c = :location')
                      .toSOQL()
              );
    }

    public static void mock(List<UISection__mdt> providers) {
        mocks = providers;
    }
}