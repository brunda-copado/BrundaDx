/**
 * Extension Class for VF Page overriding the Standard Layout of Static Code Analysis Settings depending on the Record Type
 * This will help hide Cloud Scan Api Token in a Protected Custom Setting on Save, while keeping the standard layout for PMD.
 * @author Alberto Ojedo
 * @version 1.0
 * @since Copado v11
 */
public with sharing class StaticCodeAnalysisSettingsExt {
    public Static_Code_Analysis_Settings__c staticCodeAnalysisSettings { get; set; }
    @testVisible
    private static String tokenMask = '**************************';
    public Boolean hideRequired { get; set; }
    private String sensitiveToken;
    private static String namespace;

    public StaticCodeAnalysisSettingsExt(ApexPages.StandardController stdController) {
        staticCodeAnalysisSettings = (Static_Code_Analysis_Settings__c) stdController.getRecord();
        namespace = Settings.ns;
        hideRequired = true;
        List<Static_Code_Analysis_Settings__c> scaSettingsList = [
            SELECT
                RecordTypeId,
                Id,
                Name,
                Cloud_Organization__c,
                CodeScan_Token__c,
                CodeScan_URL__c,
                CodeScan_Version__c,
                ReportIssuesFromLatestCommit__c
            FROM Static_Code_Analysis_Settings__c
            WHERE Id = :staticCodeAnalysisSettings.Id
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];
        if (!scaSettingsList.isEmpty()) {
            staticCodeAnalysisSettings = scaSettingsList[0];
            String apiToken = [
                SELECT API_Token__c
                FROM Sensitive_Information__c
                WHERE Name = :staticCodeAnalysisSettings.Id
                WITH SECURITY_ENFORCED
                LIMIT 1
            ]
            ?.API_Token__c;

            if (!String.isEmpty(apiToken)) {
                staticCodeAnalysisSettings.CodeScan_Token__c = apiToken;
            }
        }
    }

    public Boolean getIsPMD() {
        if (
            staticCodeAnalysisSettings.RecordTypeId !=
            Schema.SObjectType.Static_Code_Analysis_Settings__c.getRecordTypeInfosByDeveloperName().get('CodeScan').getRecordTypeId()
        ) {
            //Hides specific CodeScan fields.
            return true;
        } else {
            return false;
        }
    }

    public PageReference saveWithCustomSetting() {
        //Specific CodeScan logic for protecting the API Token in a Protected Custom Setting handled by Apex
        if (null != staticCodeAnalysisSettings.Id && !Utilities.HasEditAccess(staticCodeAnalysisSettings.Id)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.Insufficient_Access_Rights));
            return null;
        }
        /*so.getProperAuthorization().doUpdateCheck(staticCodeAnalysisSettings, new List<String>{
                namespace + 'CodeScan_Token__c','Id'
        });*/
        checkRequiredFields();
        if (ApexPages.hasMessages()) {
            return null;
        }
        if (!getIsPMD()) {
            sensitiveToken = staticCodeAnalysisSettings.CodeScan_Token__c;
            staticCodeAnalysisSettings.CodeScan_Token__c = tokenMask;
        }
        Utilities.Secure_DML(staticCodeAnalysisSettings, Utilities.DML_Action.UPS, schema.SObjectType.Static_Code_Analysis_Settings__c);
        if (!getIsPMD()) {
            List<Sensitive_Information__c> sensitiveInformations = [
                SELECT API_Token__c
                FROM Sensitive_Information__c
                WHERE Name = :staticCodeAnalysisSettings.Id
                WITH SECURITY_ENFORCED
            ];
            if (sensitiveInformations.isEmpty()) {
                Sensitive_Information__c si = new Sensitive_Information__c(
                    Name = String.valueOf(staticCodeAnalysisSettings.Id),
                    API_Token__c = sensitiveToken
                );
                Utilities.Secure_DML(si, Utilities.DML_Action.INS, schema.SObjectType.Sensitive_Information__c);
            } else {
                sensitiveInformations[0].API_Token__c = sensitiveToken;
                Utilities.Secure_DML(sensitiveInformations, Utilities.DML_Action.UPD, schema.SObjectType.Sensitive_Information__c);
            }
        }
        return new ApexPages.StandardController(staticCodeAnalysisSettings).view();
    }

    public void checkRequiredFields() {
        ApexPages.getMessages().clear();
        if (String.isBlank(staticCodeAnalysisSettings.Name)) {
            ApexPages.addMessage(
                new ApexPages.Message(
                    ApexPages.Severity.ERROR,
                    Schema.SObjectType.Static_Code_Analysis_Settings__c.fields.Name.getName() + ': ' + Label.Required_Field
                )
            );
        }
        if (!getIsPMD()) {
            if (String.isBlank(staticCodeAnalysisSettings.CodeScan_Version__c)) {
                ApexPages.addMessage(
                    new ApexPages.Message(
                        ApexPages.Severity.ERROR,
                        Schema.SObjectType.Static_Code_Analysis_Settings__c.fields.CodeScan_Version__c.getName() + ': ' + Label.Required_Field
                    )
                );
            }
            if (String.isBlank(staticCodeAnalysisSettings.CodeScan_Token__c)) {
                ApexPages.addMessage(
                    new ApexPages.Message(
                        ApexPages.Severity.ERROR,
                        Schema.SObjectType.Static_Code_Analysis_Settings__c.fields.CodeScan_Token__c.getName() + ': ' + Label.Required_Field
                    )
                );
            }
            if (String.isBlank(staticCodeAnalysisSettings.CodeScan_URL__c)) {
                ApexPages.addMessage(
                    new ApexPages.Message(
                        ApexPages.Severity.ERROR,
                        Schema.SObjectType.Static_Code_Analysis_Settings__c.fields.CodeScan_URL__c.getName() + ': ' + Label.Required_Field
                    )
                );
            }
            if (String.isBlank(staticCodeAnalysisSettings.Cloud_Organization__c) && staticCodeAnalysisSettings.CodeScan_Version__c == 'Cloud') {
                ApexPages.addMessage(
                    new ApexPages.Message(
                        ApexPages.Severity.ERROR,
                        Schema.SObjectType.Static_Code_Analysis_Settings__c.fields.Cloud_Organization__c.getName() + ': ' + Label.Required_Field
                    )
                );
            }
        }
    }
}