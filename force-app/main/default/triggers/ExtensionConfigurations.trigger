trigger ExtensionConfigurations on ExtensionConfiguration__c(before insert, before update, before delete) {
    fflib_SObjectDomain.triggerHandler(ExtensionConfigurations.class);
}