@isTest
public class TestStaticCodeAnalysisSettingsExt {

    @SuppressWarnings('PMD.ApexUnitTestMethodShouldHaveIsTestAnnotation,PMD.ApexUnitTestClassShouldHaveAsserts')
    static testMethod void testCodeScan() {

        Static_Code_Analysis_Settings__c scaSettings = new Static_Code_Analysis_Settings__c(
                Name = 'CodeScan',
                RecordTypeId = Schema.SObjectType.Static_Code_Analysis_Settings__c.getRecordTypeInfosByDeveloperName().get('CodeScan').getRecordTypeId(),
                CodeScan_Token__c = 'CodeScanTokenTest',
                CodeScan_Version__c = 'Cloud',
                CodeScan_URL__c = 'test.url.com',
                Cloud_Organization__c = 'Test Org'
        );
        insert scaSettings;

        PageReference pref = Page.StaticCodeAnalysisSettingsEdit;
        pref.getParameters().put('id', scaSettings.Id);
        Test.setCurrentPage(pref);

        StaticCodeAnalysisSettingsExt extension = new StaticCodeAnalysisSettingsExt(new ApexPages.StandardController(scaSettings));

        Test.startTest();
        Assert.areEqual(false, extension.getIsPMD());
        System.debug('Controller: ' + extension);
        extension.saveWithCustomSetting();
        List<Static_Code_Analysis_Settings__c> staticCodeAnalysisSettings = [SELECT Id, CodeScan_Token__c FROM Static_Code_Analysis_Settings__c WHERE Id = :scaSettings.Id];
        System.debug('Controller: ' + staticCodeAnalysisSettings);
        Assert.areEqual(1, staticCodeAnalysisSettings.size());
        Assert.areEqual(StaticCodeAnalysisSettingsExt.tokenMask, staticCodeAnalysisSettings[0].CodeScan_Token__c);
        List<Sensitive_Information__c> sensitiveInformations = [SELECT API_Token__c, Name FROM Sensitive_Information__c WHERE Name = :staticCodeAnalysisSettings[0].Id];
        Assert.areEqual(1, sensitiveInformations.size());
        Assert.areEqual(staticCodeAnalysisSettings[0].Id, sensitiveInformations[0].Name);
        Assert.areEqual('CodeScanTokenTest', sensitiveInformations[0].API_Token__c);
        Test.stopTest();
    }

    @SuppressWarnings('PMD.ApexUnitTestMethodShouldHaveIsTestAnnotation,PMD.ApexUnitTestClassShouldHaveAsserts')
    static testMethod void testPMD() {

        Static_Code_Analysis_Settings__c scaSettings = new Static_Code_Analysis_Settings__c(
                Name = 'CodeScan',
                RecordTypeId = Schema.SObjectType.Static_Code_Analysis_Settings__c.getRecordTypeInfosByDeveloperName().get('PMD').getRecordTypeId(),
        CodeScan_Token__c = 'CodeScanTokenTest');
        insert scaSettings;

        PageReference pref = Page.StaticCodeAnalysisSettingsEdit;
        pref.getParameters().put('id', scaSettings.Id);
        Test.setCurrentPage(pref);

        StaticCodeAnalysisSettingsExt extension = new StaticCodeAnalysisSettingsExt(new ApexPages.StandardController(scaSettings));

        Test.startTest();
        Assert.areEqual(true, extension.getIsPMD());
        extension.saveWithCustomSetting();
        List<Static_Code_Analysis_Settings__c> staticCodeAnalysisSettings = [SELECT Id, CodeScan_Token__c FROM Static_Code_Analysis_Settings__c WHERE Id = :scaSettings.Id];
        Assert.areEqual(1, staticCodeAnalysisSettings.size());
        Assert.areEqual('CodeScanTokenTest', staticCodeAnalysisSettings[0].CodeScan_Token__c);
        List<Sensitive_Information__c> sensitiveInformations = [SELECT API_Token__c, Name FROM Sensitive_Information__c WHERE Name = :staticCodeAnalysisSettings[0].Id];
        Assert.areEqual(0, sensitiveInformations.size());
        Test.stopTest();
    }

    @SuppressWarnings('PMD.ApexUnitTestMethodShouldHaveIsTestAnnotation,PMD.ApexUnitTestClassShouldHaveAsserts')
    static testMethod void testCheckRequiredFieldsValidation(){
        Static_Code_Analysis_Settings__c scaSettings = new Static_Code_Analysis_Settings__c(
                RecordTypeId = Schema.SObjectType.Static_Code_Analysis_Settings__c.getRecordTypeInfosByDeveloperName().get('CodeScan').getRecordTypeId());

        StaticCodeAnalysisSettingsExt extension = new StaticCodeAnalysisSettingsExt(new ApexPages.StandardController(scaSettings));
        
        Test.startTest();
        Assert.areEqual(false, extension.getIsPMD());
        extension.saveWithCustomSetting();
        Test.stopTest();
    }
}