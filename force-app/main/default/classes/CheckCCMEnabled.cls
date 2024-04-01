public with sharing class CheckCCMEnabled {
    public static Boolean execute() {
        Boolean result = false;

        Boolean isChangeManagementFeatureEnabled = FeatureHelper.isChangeChangeManagementEnabled();
        Boolean isChangeManagementLicenseEnabled = LicenseHelper.isCCMEnabled();

        if (isChangeManagementFeatureEnabled && isChangeManagementLicenseEnabled) {
            result = true;
        } else {
            if (!isChangeManagementFeatureEnabled) {
                throw new ApplicationException(Label.FEATURE_NOT_SUPPORTED + ': ' + Label.COPADO_CHANGE_MANAGEMENT);
            }
            if (!isChangeManagementLicenseEnabled) {
                throw new ApplicationException(Label.CCM_License_Restriction);
            }
        }

        return result;
    }
}