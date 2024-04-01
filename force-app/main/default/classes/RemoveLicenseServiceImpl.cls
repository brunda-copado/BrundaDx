public with sharing class RemoveLicenseServiceImpl {
    // PUBLIC

    public static void removePackageLicense(Persona.RemoveLicenseRequest request) {
        PersonaDefinitionConfig personaConfig = PersonaServiceHelper.getPersonaDefinition(request.personaId);
        List<Id> userIds = PersonaServiceHelper.findUsersInGroup(personaConfig.publicGroupId);
        removePackageLicenses(request.licenses, userIds);
    }

    public static void removeCopadoLicense(Persona.RemoveLicenseRequest request) {
        PersonaDefinitionConfig personaConfig = PersonaServiceHelper.getPersonaDefinition(request.personaId);
        List<Id> userIds = PersonaServiceHelper.findUsersInGroup(personaConfig.publicGroupId);
        removeCopadoLicenses(request.licenses, userIds);
    }

    public static void remove2PackageLicense(Persona.RemoveLicenseRequest request) {
        PersonaDefinitionConfig personaConfig = PersonaServiceHelper.getPersonaDefinition(request.personaId);
        updatePackageLicenses(personaConfig, request);
    }

    public static void remove2CopadoLicense(Persona.RemoveLicenseRequest request) {
        PersonaDefinitionConfig personaConfig = PersonaServiceHelper.getPersonaDefinition(request.personaId);
        updateCopadoLicenses(personaConfig, request);
    }

    public static void removePackageLicenses(List<String> licenseNames, List<Id> userIds) {
        List<UserPackageLicense> packageLicenses = getUserPackageLicenses(licenseNames, userIds);

        if (!packageLicenses.isEmpty()) {
            delete packageLicenses; // NOPMD : False positive: setup object
        }
    }

    public static void removeCopadoLicenses(List<String> licenseNames, List<Id> userIds) {
        List<Copado_License__c> copadoLicenses = getCopadoLicenses(userIds);

        for (String name : licenseNames) {
            updateCopadoLicense(copadoLicenses, name);
        }

        if (!copadoLicenses.isEmpty()) {
            upsert copadoLicenses; // NOPMD : False positive: protected custom setting
        }
    }

    // PRIVATE

    @SuppressWarnings('PMD.ApexCRUDViolation')
    private static List<UserPackageLicense> getUserPackageLicenses(List<String> licenseNames, List<Id> userIds) {
        List<UserPackageLicense> result = new List<UserPackageLicense>();

        // NOPMD : False positive: setup object
        for (UserPackageLicense packageLicense : [
            SELECT UserId, PackageLicenseId
            FROM UserPackageLicense
            WHERE PackageLicenseId IN :getPackageLicenseIds(licenseNames) AND UserId IN :userIds
        ]) {
            result.add(packageLicense);
        }
        return result;
    }

    @SuppressWarnings('PMD.ApexCRUDViolation')
    private static List<PackageLicense> getPackageLicenseIds(List<String> licenseNames) {
        // NOPMD : False positive: setup object
        return [SELECT Id FROM PackageLicense WHERE NamespacePrefix IN :getNamespacePrefixes(licenseNames)];
    }

    private static List<String> getNamespacePrefixes(List<String> licenseNames) {
        List<String> result = new List<String>();
        for (String name : licenseNames) {
            if (LicenseConstants.NAMESPACE_BY_LICENSE_NAMES.containsKey(name)) {
                result.add(LicenseConstants.NAMESPACE_BY_LICENSE_NAMES.get(name));
            }
        }
        return result;
    }

    private static List<Copado_License__c> getCopadoLicenses(List<Id> userIds) {
        // NOPMD : False positive: protected custom settings
        return [
            SELECT Enable_CCM__c, Enable_CAD__c, Enable_Copado__c, Enable_CCH__c, Enable_ADD__c, SetupOwnerId
            FROM Copado_License__c
            WHERE SetupOwnerId IN :userIds
            WITH USER_MODE
        ];
    }

    private static void updateCopadoLicense(List<Copado_License__c> copadoLicenses, String licenseName) {
        for (Copado_License__c copadoLicense : copadoLicenses) {
            if (LicenseConstants.EE_LICENSES_ENABLED == licenseName) {
                copadoLicense.Enable_Copado__c = false;
                continue;
            }
            if (LicenseConstants.CCM_LICENSES_ENABLED == licenseName) {
                copadoLicense.Enable_CCM__c = false;
                continue;
            }
            if (LicenseConstants.CAD_LICENSES_ENABLED == licenseName) {
                copadoLicense.Enable_CAD__c = false;
                continue;
            }
            if (LicenseConstants.CCH_LICENSES_ENABLED == licenseName) {
                copadoLicense.Enable_CCH__c = false;
                continue;
            }
            if (LicenseConstants.ADD_LICENSES_ENABLED == licenseName) {
                copadoLicense.Enable_ADD__c = false;
                continue;
            }
        }
    }

    private static void updatePersonaDefinition(PersonaDefinitionConfig personaConfig, Persona.RemoveLicenseRequest request) {
        for (Integer i = (personaConfig.licenses.size() - 1); i >= 0; i--) {
            if (request.licenses.contains(personaConfig.licenses[i].name)) {
                personaConfig.licenses.remove(i);
            }
        }

        PersonaServiceHelper.updatePersonaConfig(request.personaId, personaConfig);
    }

    private static void updatePackageLicenses(PersonaDefinitionConfig personaConfig, Persona.RemoveLicenseRequest request) {
        for (Integer i = (personaConfig.packageLicenses.size() - 1); i >= 0; i--) {
            if (request.licenses.contains(personaConfig.packageLicenses[i].name)) {
                personaConfig.packageLicenses.remove(i);
            }
        }

        PersonaServiceHelper.updatePersonaConfig(request.personaId, personaConfig);
    }

    private static void updateCopadoLicenses(PersonaDefinitionConfig personaConfig, Persona.RemoveLicenseRequest request) {
        for (Integer i = (personaConfig.licenses.size() - 1); i >= 0; i--) {
            if (request.licenses.contains(personaConfig.licenses[i].name)) {
                personaConfig.licenses.remove(i);
            }
        }

        PersonaServiceHelper.updatePersonaConfig(request.personaId, personaConfig);
    }
}