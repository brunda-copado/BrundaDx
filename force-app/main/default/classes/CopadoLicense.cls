@IsTest
public with sharing class CopadoLicense extends DomainBuilder {
    public CopadoLicense() {
        super(Copado_License__c.SObjectType);
    }

    public CopadoLicense user(User user) {
        set(Copado_License__c.SetupOwnerId, user.Id);
        return this;
    }

    public CopadoLicense enableAll() {
        enableCopado();
        enableCCM();
        enableCST();
        enableCAD();
        enableCCH();
        enableADD();
        return this;
    }

    public CopadoLicense enableCopado() {
        set(Copado_License__c.Enable_Copado__c, true);
        return this;
    }
    public CopadoLicense enableCCM() {
        set(Copado_License__c.Enable_CCM__c, true);
        return this;
    }
    public CopadoLicense enableCST() {
        set(Copado_License__c.Enable_CST__c, true);
        return this;
    }
    public CopadoLicense enableCAD() {
        set(Copado_License__c.Enable_CAD__c, true);
        return this;
    }
    public CopadoLicense enableCCH() {
        set(Copado_License__c.Enable_CCH__c, true);
        return this;
    }
    public CopadoLicense enableADD() {
        set(Copado_License__c.Enable_ADD__c, true);
        return this;
    }
}