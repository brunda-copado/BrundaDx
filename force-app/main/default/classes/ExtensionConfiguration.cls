@IsTest
public with sharing class ExtensionConfiguration extends DomainBuilder {
    public ExtensionConfiguration() {
        super(ExtensionConfiguration__c.SObjectType);
    }

    public ExtensionConfiguration application(String application) {
        return (ExtensionConfiguration) set(ExtensionConfiguration__c.ExtensionApplication__c, application);
    }

    public ExtensionConfiguration tool(String tool) {
        return (ExtensionConfiguration) set(ExtensionConfiguration__c.ExtensionTool__c, tool);
    }

    public ExtensionConfiguration active(Boolean active) {
        return (ExtensionConfiguration) set(ExtensionConfiguration__c.Active__c, active);
    }
}