public with sharing class ExtensionConfigurationSettingsCtrl {
    // PUBLIC

    @AuraEnabled
    public static List<Boolean> checkForUiSections(Id extensionConfigId) {
        List<Boolean> results = new List<Boolean>{ false, false };
        ExtensionConfiguration__c extensionConfiguration = new ExtensionConfigurationsSelector().byIds(new Set<Id>{ extensionConfigId })[0];
        List<UISection__mdt> uiSectionsForSettings = new UiSectionsSelector()
            .byTestToolAndLocation(extensionConfiguration.ExtensionTool__c, 'ATF.ExtensionConfiguration.Settings');
        if (!uiSectionsForSettings.isEmpty()) {
            results[0] = true;
        }
        List<UISection__mdt> uiSectionsForAcceptanceCriteria = new UiSectionsSelector()
            .byTestToolAndLocation(extensionConfiguration.ExtensionTool__c, 'ATF.ExtensionConfiguration.AcceptanceCriteria');
        if (!uiSectionsForAcceptanceCriteria.isEmpty()) {
            results[1] = true;
        }
        return results;
    }
}