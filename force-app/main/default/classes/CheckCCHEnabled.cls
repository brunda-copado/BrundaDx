public with sharing class CheckCCHEnabled {
    public static Boolean execute() {
        Boolean result = false;

        Boolean isComplianceFeatureEnabled = FeatureHelper.isComplianceHubEnabled();
        Boolean isComplianceLicenseEnabled = LicenseHelper.isCCHEnabled();

        if (isComplianceFeatureEnabled && isComplianceLicenseEnabled) {
            result = true;
        } else {
            if (!isComplianceFeatureEnabled) {
                throw new ApplicationException(Label.FEATURE_NOT_SUPPORTED + ': ' + Label.Compliance_Hub);
            }
            if (!isComplianceLicenseEnabled) {
                throw new ApplicationException(Label.CCH_LICENSE_NOT_ENABLED);
            }
        }

        return result;
    }
}