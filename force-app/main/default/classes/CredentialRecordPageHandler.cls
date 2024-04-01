public with sharing class CredentialRecordPageHandler {
    private static final String ACTION_INFO = 'action:info';
    private static final String ACTION_CLOSE = 'action:close';
    private static final String ACTION_APPROVAL = 'action:approval';

    @SuppressWarnings('PMD.EagerlyLoadedDescribeSObjectResult')
    @AuraEnabled
    public static String getMetadataTypesFieldHelpText() {
        return Org__c.Metadata_Types__c.getDescribe().getInlineHelpText();
    }

    @SuppressWarnings('PMD.NcssMethodCount')
    @AuraEnabled
    public static List<ValidationResult> validateOrgAndReturnResultWrapper(String credentialId) {
        List<ValidationResult> validationResults = new List<ValidationResult>();
        if (String.isBlank(credentialId)) {
            return validationResults;
        }
        Org__c credential = getCredential(credentialId);

        if (!isSalesforce(credential)) {
            validationResults.add(new ValidationResult(ACTION_INFO, Label.Non_Salesforce_Credential));
            return validationResults;
        }

        if (!canBeValidated(credential)) {
            return validationResults;
        }

        if (credential.Oauth_Signature__c == null) {
            validationResults.add(new ValidationResult(ACTION_INFO, Label.AUTHENTICATION));
            return validationResults;
        }
        if (!DeployAPI.validateOrg(credential.Id)) {
            validationResults.add(new ValidationResult(ACTION_CLOSE, Label.WRONG_CREDENTIALS));
            return validationResults;
        }
        validationResults.add(new ValidationResult(ACTION_APPROVAL, Label.OK_CREDENTIALS));

        if (hasTestFrequency(credential)) {
            Org__c copadoOrg = DeployAPI.getCustomerOrg();
            if (copadoOrg == null) {
                validationResults.add(new ValidationResult(ACTION_CLOSE, Label.CUSTOMER_ORG_NOT_EXISTS));
                return validationResults;
            }
            if (!DeployAPI.validateOrg(copadoOrg.Id)) {
                validationResults.add(new ValidationResult(ACTION_CLOSE, Label.CUSTOMER_ORG_NOT_VALIDATED));
            }
        }
        return validationResults;
    }

    @AuraEnabled
    public static List<String> getMetadataTypesForGivenCredentialId(String credentialId) {
        return MetadataTypesHelper.getMetadataTypesByOrgId(credentialId);
    }

    // PMD False positive, as WITH USER_MODE is not supported yet
    @SuppressWarnings('PMD.ApexCRUDViolation')
    private static Org__c getCredential(String recordId) {
        return [
            SELECT Id, Org_Type__c, Test_Frequency__c, Disable_Validation__c, Oauth_Signature__c, Platform__c
            FROM Org__c
            WHERE Id = :recordId
            WITH USER_MODE
            LIMIT 1
        ];
    }

    private static Boolean isSalesforce(Org__c credential) {
        return credential.Platform__c == null || credential.Platform__c == 'Salesforce' || credential.Platform__c == 'SFDX';
    }

    private static Boolean isScratchOrg(Org__c credential) {
        return String.isNotBlank(credential.Org_Type__c) && credential.Org_Type__c.startsWithIgnoreCase('Scratch Org');
    }

    private static Boolean canBeValidated(Org__c credential) {
        return !credential.Disable_Validation__c && !isScratchOrg(credential);
    }

    private static Boolean hasTestFrequency(Org__c credential) {
        return credential.Test_Frequency__c != null && credential.Test_Frequency__c != 'None';
    }

    public with sharing class ValidationResult {
        @AuraEnabled
        public String iconName;
        @AuraEnabled
        public String message;

        public ValidationResult(String iconName, String message) {
            this.iconName = iconName;
            this.message = message;
        }
    }
}