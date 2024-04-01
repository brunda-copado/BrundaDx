public with sharing class LicenseConstants {
    // LICENSE NAMES

    public static final String EE_LICENSES_ENABLED = 'EE_Licenses_Enabled';
    public static final String CCM_LICENSES_ENABLED = 'CCM_Licenses_Enabled';
    public static final String CST_LICENSES_ENABLED = 'CST_Licenses_Enabled';
    public static final String CAD_LICENSES_ENABLED = 'CAD_Licenses_Enabled';
    public static final String CCH_LICENSES_ENABLED = 'CCH_Licenses_Enabled';
    public static final String ADD_LICENSES_ENABLED = 'ADD_Licenses_Enabled';

    // PACKAGE NAMESPACES
    public static final Map<String, String> LICENSE_NAMES_BY_NAMESPACE = new Map<String, String>{
        PackageNamespace.copado.name() => Label.Copado_Managed_Package,
        PackageNamespace.copadometrics.name() => Label.Copado_Analytics,
        PackageNamespace.copadovsm.name() => Label.Copado_VSM
    };

    public static final Map<String, String> NAMESPACE_BY_LICENSE_NAMES = new Map<String, String>{
        Label.Copado_Managed_Package => PackageNamespace.copado.name(),
        Label.Copado_Analytics => PackageNamespace.copadometrics.name(),
        Label.Copado_VSM => PackageNamespace.copadovsm.name()
    };

    public static final Map<String, String> LABEL_BY_LICENSE_NAMES = new Map<String, String>{
        EE_LICENSES_ENABLED => Label.Copado_Admin,
        CCM_LICENSES_ENABLED => Label.Copado_User,
        CST_LICENSES_ENABLED => Label.Selenium_Testing,
        CAD_LICENSES_ENABLED => Label.Copado_Guest,
        CCH_LICENSES_ENABLED => Label.Compliance_Hub,
        ADD_LICENSES_ENABLED => Label.Data_Deployer
    };
}