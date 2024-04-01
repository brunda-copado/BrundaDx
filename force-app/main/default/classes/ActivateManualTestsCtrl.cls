public with sharing class ActivateManualTestsCtrl {
    //PUBLIC

    @AuraEnabled
    public static Boolean activate(Id extensionConfigId) {
        Boolean result;

        try {
            String acceptanceCriteria = getAcceptanceCriteriaFrom(extensionConfigId);

            if (String.isNotBlank(acceptanceCriteria) && acceptanceCriteria != '{}') {
                updateExtensionConfig(extensionConfigId);
                result = true;
            } else {
                result = false;
            }
        } catch (Exception ex) {
            throw new ApplicationException().auraHandled(ex);
        }

        return result;
    }

    //PRIVATE

    private static void updateExtensionConfig(Id extensionConfigId) {
        ExtensionConfiguration__c extensionConfig = new ExtensionConfiguration__c(Id = extensionConfigId);
        extensionConfig.Active__c = true;

        DML.safeUpdate(extensionConfig, 'Could not update the extension configuration');
    }

    private static String getAcceptanceCriteriaFrom(Id extensionConfigId) {
        return new ExtensionConfigurationsSelector().byIds(new Set<Id>{ extensionConfigId })[0].AcceptanceCriteria__c;
    }
}