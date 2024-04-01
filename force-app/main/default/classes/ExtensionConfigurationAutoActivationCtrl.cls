public with sharing class ExtensionConfigurationAutoActivationCtrl {
    private static final String MANUAL_TESTS_VALUE = 'Manual Tests'; // @Note: for testing purposes

    // PUBLIC

    @AuraEnabled
    public static Boolean requiresActivationLogic(Id extensionConfigId) {
        Boolean result = false;
        ExtensionConfiguration__c extensionConfiguration = new ExtensionConfigurationsSelector().byIds(new Set<Id>{ extensionConfigId })[0];

        if (additionalDataNotRequired(extensionConfiguration)) {
            result = autoActivateExtensionConfiguration(extensionConfiguration);
        } else {
            result = true;
        }
        return result;
    }

    // PRIVATE

    private static Boolean additionalDataNotRequired(ExtensionConfiguration__c extConfiguration) {
        Set<String> result = new Set<String>();

        List<UISection__mdt> uiSections = new UiSectionsSelector()
            .byTestToolAndLocation(extConfiguration.ExtensionTool__c, 'ATF.ExtensionConfiguration.Activation');

        for (UISection__mdt uiSection : uiSections) {
            if (Test.isRunningTest()) {
                result.add(MANUAL_TESTS_VALUE);
            } else {
                result.add(uiSection.TestTool__r.MasterLabel);
            }
        }

        return String.isNotBlank(extConfiguration.ExtensionTool__c) && !result.contains(extConfiguration.ExtensionTool__c);
    }

    private static Boolean autoActivateExtensionConfiguration(ExtensionConfiguration__c extensionConfiguration) {
        try {
            extensionConfiguration.Active__c = true;
            Utilities.Secure_DML(extensionConfiguration, Utilities.DML_Action.UPD, schema.SObjectType.ExtensionConfiguration__c);
            return false;
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }
    }
}