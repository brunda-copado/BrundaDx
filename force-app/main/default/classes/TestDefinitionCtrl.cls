public with sharing class TestDefinitionCtrl {
    // PUBLIC

    @AuraEnabled
    public static List<Boolean> checkForUiSections(Id testId) {
        List<Boolean> results = new List<Boolean>{ false, false };
        Test__c test = new TestsSelector().byIds(new Set<Id>{ testId })[0];
        List<UISection__mdt> uiSectionsForSettings = new UiSectionsSelector()
            .byTestToolAndLocation(test.ExtensionConfiguration__r.ExtensionTool__c, 'CCM.Test.TestDefinition');
        if (!uiSectionsForSettings.isEmpty()) {
            results[0] = true;
        }
        List<UISection__mdt> uiSectionsForAcceptanceCriteria = new UiSectionsSelector()
            .byTestToolAndLocation(test.ExtensionConfiguration__r.ExtensionTool__c, 'ATF.Test.AcceptanceCriteria');
        if (!uiSectionsForAcceptanceCriteria.isEmpty()) {
            results[1] = true;
        }
        return results;
    }
}