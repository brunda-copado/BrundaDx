public with sharing class ComplianceRulePermissionsValidator {
    // PUBLIC

    public ValidationResult execute() {
        ValidationResult result = new ValidationResult();

        if (isApiKeyMissing()) {
            result.addError(Label.CCH_MISSING_API_KEY);
        } else if (isInvalidFLS()) {
            result.addError(Label.COMPLIANCE_RULE_MISSING_FLS);
        } else if (isComplianceFeatureDisabled()) {
            result.addError(Label.FEATURE_NOT_SUPPORTED);
        } else if (isComplianceLicenseDisabled()) {
            result.addError(Label.CCH_LICENSE_NOT_ENABLED);
        }

        return result;
    }

    // PRIVATE

    private Boolean isApiKeyMissing() {
        return String.isBlank(Personal_Settings__c.getInstance().API_Key__c);
    }

    private Boolean isInvalidFLS() {
        Set<DescribeFieldResult> fields = new Set<DescribeFieldResult>{
            SObjectType.Compliance_Rule__c.fields.Metadata_Type__c,
            SObjectType.Compliance_Rule__c.fields.Filter_Criteria__c,
            SObjectType.Compliance_Rule__c.fields.Is_Valid__c
        };

        return !isAccessible(fields);
    }

    private Boolean isAccessible(Set<DescribeFieldResult> fields) {
        Boolean result = true;

        for (DescribeFieldResult field : fields) {
            if (!field.isAccessible()) {
                result = false;
                break;
            }
        }

        return result;
    }

    private Boolean isComplianceFeatureDisabled() {
        return !FeatureHelper.isComplianceHubEnabled();
    }

    private Boolean isComplianceLicenseDisabled() {
        return !LicenseHelper.isCCHEnabled();
    }
}