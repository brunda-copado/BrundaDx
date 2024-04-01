public with sharing class QgrcAcceptanceCriteriaCtrl {
    // PUBLIC

    @AuraEnabled
    public static Boolean checkForUiSection(Id qualityGateConditionId) {
        Boolean result = false;
        Quality_Gate_Rule_Condition__c qualityGateCondition = new QualityGateRuleConditionsSelector().byIds(new Set<Id>{ qualityGateConditionId })[0];
        List<UISection__mdt> uiSectionsForSettings = new UiSectionsSelector()
            .byTestToolAndLocation(qualityGateCondition.Extension_Configuration__r.ExtensionTool__c, 'ATF.QGRC.AcceptanceCriteria');
        if (!uiSectionsForSettings.isEmpty()) {
            result = true;
        }
        return result;
    }
}