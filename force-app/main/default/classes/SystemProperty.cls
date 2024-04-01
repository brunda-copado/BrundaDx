@IsTest
public with sharing class SystemProperty extends DomainBuilder {
    public SystemProperty() {
        super(System_Property__c.SObjectType);
    }

    public SystemProperty apiName(String apiName) {
        return (SystemProperty) set(System_Property__c.API_Name__c, apiName);
    }

    public SystemProperty value(String value) {
        return (SystemProperty) set(System_Property__c.Value__c, value);
    }

    public SystemProperty pipeline(Pipeline pipeline) {
        setParent(System_Property__c.Pipeline__c, pipeline);
        return this;
    }

    public SystemProperty sensitive(Boolean value) {
        return (SystemProperty) set(System_Property__c.Is_Sensitive__c, value);
    }

    public SystemProperty parent(String value) {
        return (SystemProperty) set(System_Property__c.ParentId__c, value);
    }

    public SystemProperty globalProperty(Boolean value) {
        return (SystemProperty) set(System_Property__c.Is_Global__c, value);
    }

    public SystemProperty environment(Environment environment) {
        setParent(System_Property__c.Environment__c, environment);
        return this;
    }

    public SystemProperty isPublic(Boolean value) {
        return (SystemProperty) set(System_Property__c.Is_Public__c, value);
    }
}