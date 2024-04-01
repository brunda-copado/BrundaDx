@SuppressWarnings('PMD')
public with sharing class CopadoCredentialValidatorCtrl {
    @AuraEnabled
    public static List<ValidationResult> validate(string credentialId) {
        try {
            return validateOrgAndReturnResult(credentialId);
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }
    }

    private static List<ValidationResult> validateOrgAndReturnResult(String credentialId) {
        List<ValidationResult> results = new List<ValidationResult>();
        if (String.isNotBlank(credentialId)) {
            Org__c credential = new OrgsSelector().byId(new Set<Id>{ credentialId }).get(0);
            if (credential.Platform__c != null && (credential.Platform__c != 'Salesforce' && credential.Platform__c != 'SFDX')) {
                results.add(createValidationResult(ValidationType.NON_SALESFORCE_CRED, Label.Non_Salesforce_Credential));
                return results;
            }

            Boolean isScratchOrg = String.isNotBlank(credential.Org_Type__c) && credential.Org_Type__c.startsWithIgnoreCase('Scratch Org');
            if (!credential.Disable_Validation__c && !isScratchOrg) {
                if (credential.Oauth_Signature__c == null) {
                    results.add(createValidationResult(ValidationType.ADD_AUTHENTICATION, Label.ADD_AUTHENTICATION));
                    return results;
                } else {
                    if (!DeployAPI.validateOrg(credential.Id)) {
                        results.add(createValidationResult(ValidationType.WRONG_CREDENTIAL, Label.WRONG_CREDENTIALS));
                        return results;
                    } else {
                        results.add(createValidationResult(ValidationType.OK, Label.OK_CREDENTIALS));
                    }
                }
                if (credential.Test_Frequency__c != null && credential.Test_Frequency__c != 'None') {
                    Org__c copadoOrg = DeployAPI.getCustomerOrg();
                    if (copadoOrg == null) {
                        results.add(createValidationResult(ValidationType.CUSTOMER_ORG_NOT_EXISTS, Label.CUSTOMER_ORG_NOT_EXISTS));
                        return results;
                    }
                    if (!DeployAPI.validateOrg(copadoOrg.Id)) {
                        results.add(createValidationResult(ValidationType.CUSTOMER_ORG_NOT_VALIDATED, Label.CUSTOMER_ORG_NOT_VALIDATED));
                    }
                }
            }
        }
        return results;
    }

    private static ValidationResult createValidationResult(ValidationType validationType, String message) {
        ValidationResult result = new ValidationResult();
        result.validationType = String.valueOf(validationType);
        result.message = message;
        return result;
    }

    public with sharing class ValidationResult {
        @AuraEnabled
        public String message;
        @AuraEnabled
        public String validationType;
    }

    private enum ValidationType {
        OK,
        NON_SALESFORCE_CRED,
        ADD_AUTHENTICATION,
        WRONG_CREDENTIAL,
        CUSTOMER_ORG_NOT_EXISTS,
        CUSTOMER_ORG_NOT_VALIDATED
    }
}