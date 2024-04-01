@IsTest
public with sharing class MockUserStoryBundleTestUnifier extends UserStoryBundleTestsUnifier{
    public override List<Test__c> unifyTests(List<Test__c> testToUnify) {
        List<Test__c> result = new List<Test__c>();

        if (!testToUnify.isEmpty()) {
            Test__c originalTest = testToUnify[0];

            result.add(
                new Test__c(
                    Name = 'Unified Test for ' + originalTest.Test_Tool__c,
                    Parent_Id__c = originalTest.Parent_Id__c,
                    Priority__c = originalTest.Priority__c,
                    ReadyToRun__c = originalTest.ReadyToRun__c,
                    ExtensionConfiguration__c = originalTest.ExtensionConfiguration__c,
                    AcceptanceCriteria__c = originalTest.AcceptanceCriteria__c,
                    Configuration__c = originalTest.Configuration__c,
                    Application__c = originalTest.Application__c,
                    Feature__c = originalTest.Feature__c,
                    HasExtraConfiguration__c = originalTest.HasExtraConfiguration__c
                )
            );
        }

        return result;
    }

}