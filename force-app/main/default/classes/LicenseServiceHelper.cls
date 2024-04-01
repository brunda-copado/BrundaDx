@SuppressWarnings('PMD.ExcessivePublicCount, PMD.CognitiveComplexity')
public with sharing class LicenseServiceHelper {
    // PUBLIC

    // False positive: protected custom settings
    public static List<Copado_License__c> getCopadoLicenses() {
        return [
            SELECT Enable_CCM__c, Enable_CAD__c, Enable_Copado__c, Enable_CCH__c, Enable_ADD__c, SetupOwnerId
            FROM Copado_License__c
            WITH USER_MODE
            ORDER BY SetupOwner.Name
        ];
    }

    // NOPMD : False positive: setup object
    @SuppressWarnings('PMD.ApexCRUDViolation')
    public static List<PackageLicense> getPackageLicenses() {
        return [
            SELECT Id, AllowedLicenses, UsedLicenses, NamespacePrefix
            FROM PackageLicense
            WHERE NamespacePrefix IN :LicenseConstants.LICENSE_NAMES_BY_NAMESPACE.keySet() AND AllowedLicenses > 0
            ORDER BY NamespacePrefix
        ];
    }

    // NOPMD : False positive: setup object
    @SuppressWarnings('PMD.ApexCRUDViolation')
    public static List<UserPackageLicense> getUserPackageLicenses(Set<Id> packageLicenseIds) {
        return [SELECT UserId, PackageLicenseId FROM UserPackageLicense WHERE PackageLicenseId IN :packageLicenseIds];
    }

    public static List<LicenseDefinition> getLicenseDefinitions() {
        return getLicenseDefinitions(getCopadoLicenses(), getPackageLicenses());
    }

    public static List<LicenseDefinition> getLicenseDefinitions(List<Copado_License__c> copadoLicenses, List<PackageLicense> packageLicenses) {
        List<LicenseDefinition> result = getCopadoLicenseDefinitions(copadoLicenses);
        result.addAll(getPackageLicenseDefinitions(packageLicenses));

        return result;
    }

    public static Map<String, UserLicense> getLicensesByUser(List<Copado_License__c> copadoLicenses, List<PackageLicense> packageLicenses) {
        return getUserLicenses(copadoLicenses, packageLicenses);
    }

    public static List<LicenseDefinition> getLicensesForPersona(String personaId) {
        Map<String, Boolean> licenseNamesAndStandardInformation = new Map<String, Boolean>();
        PersonaDefinitionConfig config = PersonaServiceHelper.getPersonaDefinition(personaId);

        for (PersonaDefinitionConfig.ConfigEntry entry : config.licenses) {
            licenseNamesAndStandardInformation.put(entry.name, entry.isStandard);
        }
        for (PersonaDefinitionConfig.ConfigEntry entry : config.packageLicenses) {
            licenseNamesAndStandardInformation.put(entry.name, entry.isStandard);
        }

        List<LicenseDefinition> result = getLicenseDefinitions();
        for (Integer index = (result.size() - 1); index >= 0; index--) {
            if (!licenseNamesAndStandardInformation.keySet().contains(result[index].name)) {
                result.remove(index);
            } else {
                result[index].isStandard = licenseNamesAndStandardInformation.get(result[index].name);
            }
        }
        return result;
    }

    public static void updateCopadoLicense(Copado_License__c copadoLicense, String licenseName) {
        if (LicenseConstants.EE_LICENSES_ENABLED == licenseName) {
            copadoLicense.Enable_Copado__c = true;
            return;
        }
        if (LicenseConstants.CCM_LICENSES_ENABLED == licenseName) {
            copadoLicense.Enable_CCM__c = true;
            return;
        }
        if (LicenseConstants.CAD_LICENSES_ENABLED == licenseName) {
            copadoLicense.Enable_CAD__c = true;
            return;
        }
        if (LicenseConstants.CCH_LICENSES_ENABLED == licenseName) {
            copadoLicense.Enable_CCH__c = true;
            return;
        }
        if (LicenseConstants.ADD_LICENSES_ENABLED == licenseName) {
            copadoLicense.Enable_ADD__c = true;
            return;
        }
    }

    // PRIVATE

    private static List<LicenseDefinition> getCopadoLicenseDefinitions(List<Copado_License__c> copadoLicenses) {
        List<LicenseDefinition> licenseDefinitions = initialize();
        for (Copado_License__c copadoLicense : copadoLicenses) {
            updateLicenseUsage(copadoLicense, licenseDefinitions);
        }
        updateRemainingLicense(licenseDefinitions);

        return licenseDefinitions;
    }

    private static List<LicenseDefinition> getPackageLicenseDefinitions(List<PackageLicense> packageLicenses) {
        List<LicenseDefinition> licenseDefinitions = new List<LicenseDefinition>();
        for (PackageLicense license : packageLicenses) {
            licenseDefinitions.add(
                new LicenseDefinition()
                    .name(license.NamespacePrefix)
                    .label(LicenseConstants.LICENSE_NAMES_BY_NAMESPACE.get(license.NamespacePrefix))
                    .available(license.AllowedLicenses)
                    .used(license.UsedLicenses)
                    .remaining(license.AllowedLicenses - license.UsedLicenses)
                    .isPackageLicense()
                    .namespacePrefix(license.NamespacePrefix)
                    .packageLicenseId(license.Id)
            );
        }

        return licenseDefinitions;
    }

    private static List<LicenseDefinition> initialize() {
        List<LicenseDefinition> licenseDefinitions = new List<LicenseDefinition>();
        List<String> licenseKeys = new List<String>{
            LicenseConstants.EE_LICENSES_ENABLED,
            LicenseConstants.CCM_LICENSES_ENABLED,
            LicenseConstants.CAD_LICENSES_ENABLED,
            LicenseConstants.CCH_LICENSES_ENABLED,
            LicenseConstants.ADD_LICENSES_ENABLED
        };

        for (String licenseKey : licenseKeys) {
            licenseDefinitions.add(
                new LicenseDefinition()
                    .name(licenseKey)
                    .label(LicenseConstants.LABEL_BY_LICENSE_NAMES.get(licenseKey))
                    .available(FeatureManagement.checkPackageIntegerValue(licenseKey))
            );
        }
        return licenseDefinitions;
    }

    private static void updateLicenseUsage(Copado_License__c copadoLicense, List<LicenseDefinition> licenseDefinitions) {
        Map<String, Boolean> licenseMap = new Map<String, Boolean>{
            LicenseConstants.EE_LICENSES_ENABLED => copadoLicense.Enable_Copado__c,
            LicenseConstants.CCM_LICENSES_ENABLED => copadoLicense.Enable_CCM__c,
            LicenseConstants.CAD_LICENSES_ENABLED => copadoLicense.Enable_CAD__c,
            LicenseConstants.CCH_LICENSES_ENABLED => copadoLicense.Enable_CCH__c,
            LicenseConstants.ADD_LICENSES_ENABLED => copadoLicense.Enable_ADD__c
        };

        for (LicenseDefinition licenseRecord : licenseDefinitions) {
            if (licenseMap.containsKey(licenseRecord.name) && licenseMap.get(licenseRecord.name)) {
                licenseRecord.used++;
            }
        }
    }

    private static void updateRemainingLicense(List<LicenseDefinition> licenseDefinitions) {
        for (LicenseDefinition licenseRecord : licenseDefinitions) {
            licenseRecord.remaining = licenseRecord.available - licenseRecord.used;
        }
    }

    private static Map<String, UserLicense> getUserLicenses(List<Copado_License__c> copadoLicenses, List<PackageLicense> packageLicenses) {
        Map<String, UserLicense> result = new Map<String, UserLicense>();

        // User Licenses (Copado Licenses)
        for (Copado_License__c copadoLicense : copadoLicenses) {
            UserLicense userLicense = new UserLicense().userId(copadoLicense.SetupOwnerId);
            userLicense.copadoLicenses.add(copadoLicense);
            result.put(copadoLicense.SetupOwnerId, userLicense);
        }

        Set<Id> packageLicenseIds = new Set<Id>();
        for (PackageLicense license : packageLicenses) {
            packageLicenseIds.add(license.Id);
        }

        // User Licenses (Package Licenses)
        for (UserPackageLicense userPackageLicense : getUserPackageLicenses(packageLicenseIds)) {
            if (result.containsKey(userPackageLicense.UserId)) {
                result.get(userPackageLicense.UserId).packageLicenses.add(userPackageLicense);
            } else {
                UserLicense userLicense = new UserLicense().userId(userPackageLicense.UserId);
                userLicense.packageLicenses.add(userPackageLicense);
                result.put(userPackageLicense.UserId, userLicense);
            }
        }

        return result;
    }

    private static List<LicenseDefinition> filterByPersona(String personaId, List<LicenseDefinition> licenseDefinitions) {
        Set<String> licenseNames = new Set<String>();
        PersonaDefinitionConfig config = PersonaServiceHelper.getPersonaDefinition(personaId);

        for (PersonaDefinitionConfig.ConfigEntry entry : config.licenses) {
            licenseNames.add(entry.name);
        }
        for (PersonaDefinitionConfig.ConfigEntry entry : config.packageLicenses) {
            licenseNames.add(entry.name);
        }

        for (Integer index = (licenseDefinitions.size() - 1); index >= 0; index--) {
            if (!licenseNames.contains(licenseDefinitions[index].name)) {
                licenseDefinitions.remove(index);
            }
        }
        return licenseDefinitions;
    }

    // WRAPPERS

    public with sharing class LicenseDefinition {
        @AuraEnabled
        public String label;
        @AuraEnabled
        public String name;

        // Allowed Licenses or Total feature licenses
        @AuraEnabled
        public Integer available;
        @AuraEnabled
        public Integer remaining;
        @AuraEnabled
        public Integer used;
        @AuraEnabled
        public Boolean isStandard;

        @AuraEnabled
        public Boolean isPackageLicense;
        @AuraEnabled
        public String namespacePrefix;
        @AuraEnabled
        public String packageLicenseId;

        public LicenseDefinition() {
            this.isPackageLicense = false;
            this.isStandard = false;
            this.used = 0;
        }

        public LicenseDefinition label(String label) {
            this.label = label;
            return this;
        }

        public LicenseDefinition name(String name) {
            this.name = name;
            return this;
        }

        public LicenseDefinition available(Integer available) {
            this.available = available;
            return this;
        }

        public LicenseDefinition remaining(Integer remaining) {
            this.remaining = remaining;
            return this;
        }

        public LicenseDefinition used(Integer used) {
            this.used = used;
            return this;
        }

        public LicenseDefinition isPackageLicense() {
            this.isPackageLicense = true;
            return this;
        }

        public LicenseDefinition namespacePrefix(String namespacePrefix) {
            this.namespacePrefix = namespacePrefix;
            return this;
        }

        public LicenseDefinition packageLicenseId(String packageLicenseId) {
            this.packageLicenseId = packageLicenseId;
            return this;
        }
    }

    public with sharing class UserLicense {
        public String userId;
        public List<Copado_License__c> copadoLicenses;
        public List<UserPackageLicense> packageLicenses;
        public UserLicense() {
            copadoLicenses = new List<Copado_License__c>();
            packageLicenses = new List<UserPackageLicense>();
        }

        public UserLicense userId(String userId) {
            this.userId = userId;
            return this;
        }
    }
}