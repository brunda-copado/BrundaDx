public with sharing class UpsertTestsAcceptanceCriteria {
    List<Test__c> newtests;
    Map<Id, Test__c> oldTests;

    public UpsertTestsAcceptanceCriteria(List<Test__c> newtests, Map<Id, Test__c> oldTests) {
        this.newtests = newtests;
        this.oldTests = oldTests;
    }

    public void execute() {
        Map<Id, ExtensionConfiguration__c> extensionConfigById = new ExtensionConfigurationsSelector().getExtensionConfigsByIds(newtests, oldTests);

        for (Test__c test : newtests) {
            if (oldTests == null ? true : test.ExtensionConfiguration__c != oldTests.get(test.Id).ExtensionConfiguration__c) {
                ExtensionConfiguration__c extensionConfig = extensionConfigById.get(test.ExtensionConfiguration__c);

                if (extensionConfig != null) {
                    test.AcceptanceCriteria__c = extensionConfig.AcceptanceCriteria__c;
                }
            }
        }
    }
}