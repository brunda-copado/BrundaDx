public with sharing class CredentialsButtonsHandler {
    private static String featureName { get; set; }
    private static Id credentialId { get; set; }

    public final static String APEX_TEST = 'Apex Test';
    public final static String COMPLIANCE_HUB = 'Compliance Hub';
    public final static String STATIC_CODE_ANALYSIS = 'Static Code Analysis';

    public static void callNecessaryOperation(Id credentialIdParameter, String featureNameParameter) {
        credentialId = credentialIdParameter;
        featureName = featureNameParameter;
        doGeneralValidations();
        executeFeature();
    }

    private static void doGeneralValidations() {
        if (!FeatureHelper.isFeatureEnabled(featureName)) {
            throw new CredentialsButtonsHandlerException(Label.FEATURE_NOT_SUPPORTED + ': ' + featureName);
        }

        if (!DeployAPI.validateOrg(credentialId)) {
            throw new CredentialsButtonsHandlerException(Label.WRONG_CREDENTIALS);
        }

        if (featureName == COMPLIANCE_HUB && !LicenseHelper.isCCHEnabled()) {
            throw new CredentialsButtonsHandlerException(Label.CCH_LICENSE_NOT_ENABLED);
        }
    }

    private static void executeFeature() {
        if (featureName == APEX_TEST) {
            DeployAPI.testNow(credentialId);
        } else if (featureName == STATIC_CODE_ANALYSIS) {
            DeployAPI.orgCodeAnalysis(credentialId);
        } else if (featureName == COMPLIANCE_HUB) {
            DeployAPI.orgComplianceScan(credentialId);
        }
    }

    public class CredentialsButtonsHandlerException extends Exception {
    }
}