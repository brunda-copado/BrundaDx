public with sharing class ExtensionConfigurations extends fflib_SObjectDomain {
    // CTOR

    public ExtensionConfigurations(List<ExtensionConfiguration__c> records) {
        super(records);
    }

    // PUBLIC

    public override void onBeforeInsert() {
        upsertTestType((List<ExtensionConfiguration__c>) records);
    }

    public override void onBeforeUpdate(Map<Id, SObject> oldExtensionConfigurations) {
        upsertTestType((List<ExtensionConfiguration__c>) records);
    }

    public override void onBeforeDelete() {
        restrictDeletionAfterActivation((List<ExtensionConfiguration__c>) records);
    }

    // PRIVATE

    private static void upsertTestType(List<ExtensionConfiguration__c> extensionConfigurations) {
        Map<String, String> testTypesByTools = getTestTypesByTools(extensionConfigurations);

        for (ExtensionConfiguration__c extensionConfiguration : extensionConfigurations) {
            extensionConfiguration.TestType__c = testTypesByTools.get(extensionConfiguration.ExtensionTool__c);
        }
    }

    private static Map<String, String> getTestTypesByTools(List<ExtensionConfiguration__c> extConfigurations) {
        Map<String, String> result = new Map<String, String>();

        List<String> configurationsTools = new List<String>();

        for (ExtensionConfiguration__c config : extConfigurations) {
            configurationsTools.add(config.ExtensionTool__c);
        }

        List<TestTool__mdt> testTools = new TestToolsSelector().byNames(configurationsTools);

        for (TestTool__mdt testTool : testTools) {
            result.put(testTool.MasterLabel, testTool.TestType__c);
        }

        return result;
    }

    private static void restrictDeletionAfterActivation(List<ExtensionConfiguration__c> extensionConfigurations) {
        for (ExtensionConfiguration__c extensionConfiguration : extensionConfigurations) {
            if (extensionConfiguration.Active__c) {
                extensionConfiguration.addError(Label.RestrictExtensionConfigDeletion);
            }
        }
    }

    // INNER

    public class Constructor implements fflib_SObjectDomain.IConstructable {
        public fflib_SObjectDomain construct(List<SObject> records) {
            return new ExtensionConfigurations(records);
        }
    }
}