@IsTest
public with sharing class Stage extends DomainBuilder {
    public Stage() {
        super(Stage__c.SObjectType);
    }

    public Stage name(String name) {
        set(Stage__c.Name, name);
        return (Stage) set(Stage__c.Display_Name__c, name);
    }

    public Stage metaStage(String metaStage) {
        return (Stage) set(Stage__c.Meta_Stage__c, metaStage);
    }
}