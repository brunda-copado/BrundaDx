public with sharing class AddLicenseServiceImpl {
    private static List<Id> userIds;
    private static Map<String, LicenseServiceHelper.LicenseDefinition> licenseDefinitionByName;
    private static Map<String, LicenseServiceHelper.UserLicense> licensesByUser;

    // PUBLIC

    public static void addPackageLicense(Persona.AddLicenseRequest request) {
        PersonaDefinitionConfig personaConfig = PersonaServiceHelper.getPersonaDefinition(request.personaId);
        validations(request, personaConfig);
        processPackageLicenses(request.licenses);
    }

    public static void addCopadoLicense(Persona.AddLicenseRequest request) {
        PersonaDefinitionConfig personaConfig = PersonaServiceHelper.getPersonaDefinition(request.personaId);
        validations(request, personaConfig);
        processCopadoLicenses(request.licenses);
    }

    public static void add2PackageLicense(Persona.AddLicenseRequest request) {
        PersonaDefinitionConfig personaConfig = PersonaServiceHelper.getPersonaDefinition(request.personaId);
        List<PersonaDefinitionConfig.ConfigEntry> configEntries = getConfigEntries(request.licenses);
        personaConfig.packageLicenses.addAll(configEntries);
        PersonaServiceHelper.updatePersonaConfig(request.personaId, personaConfig);
    }

    public static void add2CopadoLicense(Persona.AddLicenseRequest request) {
        PersonaDefinitionConfig personaConfig = PersonaServiceHelper.getPersonaDefinition(request.personaId);
        List<PersonaDefinitionConfig.ConfigEntry> configEntries = getConfigEntries(request.licenses);
        personaConfig.licenses.addAll(configEntries);
        PersonaServiceHelper.updatePersonaConfig(request.personaId, personaConfig);
    }

    // PRIVATE

    private static void validations(Persona.AddLicenseRequest request, PersonaDefinitionConfig personaConfig) {
        userIds = PersonaServiceHelper.findUsersInGroup(personaConfig.publicGroupId);
        Integer userCount = userIds.size();
        populateLicenseDefinitionByName();
        validateLicenseAvailability(request, userCount);
    }

    private static Map<String, LicenseServiceHelper.LicenseDefinition> populateLicenseDefinitionByName() {
        List<Copado_License__c> copadoLicenses = LicenseServiceHelper.getCopadoLicenses();
        List<PackageLicense> packageLicenses = LicenseServiceHelper.getPackageLicenses();

        licensesByUser = LicenseServiceHelper.getLicensesByUser(copadoLicenses, packageLicenses);
        licenseDefinitionByName = new Map<String, LicenseServiceHelper.LicenseDefinition>();

        for (LicenseServiceHelper.LicenseDefinition license : LicenseServiceHelper.getLicenseDefinitions(copadoLicenses, packageLicenses)) {
            licenseDefinitionByName.put(license.name, license);
        }
        return licenseDefinitionByName;
    }

    private static void validateLicenseAvailability(Persona.AddLicenseRequest request, Integer userCount) {
        for (String licenseName : request.licenses) {
            if (licenseDefinitionByName.containsKey(licenseName)) {
                LicenseServiceHelper.LicenseDefinition license = licenseDefinitionByName.get(licenseName);
                Integer remainedLicense = license.available - license.used;
                if (userCount > remainedLicense) {
                    throw new ApplicationException(Label.Not_Enough_Licenses_Available);
                }
            }
        }
    }

    private static void processPackageLicenses(List<String> licenseNames) {
        List<SObject> records = new List<SObject>();

        for (String name : licenseNames) {
            if (licenseDefinitionByName.containsKey(name)) {
                LicenseServiceHelper.LicenseDefinition definition = licenseDefinitionByName.get(name);
                processPackageLicense(definition.packageLicenseId, records);
            }
        }
        // False positive: UserPackageLicense setup object
        upsert records; // NOPMD
    }

    private static void processCopadoLicenses(List<String> licenseNames) {
        Map<String, Copado_License__c> copadoLicenseByUser = new Map<String, Copado_License__c>();

        for (String name : licenseNames) {
            if (licenseDefinitionByName.containsKey(name)) {
                processCopadoLicense(name, copadoLicenseByUser);
            }
        }

        // False positive: Copado_License__c is protected custom settings
        upsert copadoLicenseByUser.values(); // NOPMD
    }

    private static void processPackageLicense(String packageLicenseId, List<SObject> records) {
        for (Id userId : userIds) {
            if (!packageLicenseExists(packageLicenseId, licensesByUser.get(userId))) {
                records.add(new UserPackageLicense(PackageLicenseId = packageLicenseId, UserId = userId));
            }
        }
    }

    private static Boolean packageLicenseExists(String packageLicenseId, LicenseServiceHelper.UserLicense userLicense) {
        Boolean result = false;
        if (userLicense != null && !userLicense.packageLicenses.isEmpty()) {
            for (UserPackageLicense userPackageLicense : userLicense.packageLicenses) {
                if (userPackageLicense.PackageLicenseId == packageLicenseId) {
                    result = true;
                    break;
                }
            }
        }

        return result;
    }

    private static void processCopadoLicense(String licenseName, Map<String, Copado_License__c> copadoLicenseByUser) {
        for (Id userId : userIds) {
            Copado_License__c copadoLicense = getCopadoLicenseForUser(userId, licensesByUser.get(userId), copadoLicenseByUser);
            LicenseServiceHelper.updateCopadoLicense(copadoLicense, licenseName);
            copadoLicenseByUser.put(userId, copadoLicense);
        }
    }

    private static Copado_License__c getCopadoLicenseForUser(
        String userId,
        LicenseServiceHelper.UserLicense userLicense,
        Map<String, Copado_License__c> copadoLicenseByUser
    ) {
        Copado_License__c result;
        if (userLicense != null && !userLicense.copadoLicenses.isEmpty()) {
            result = userLicense.copadoLicenses[0];
        } else if (copadoLicenseByUser.containsKey(userId)) {
            result = copadoLicenseByUser.get(userId);
        } else {
            result = new Copado_License__c(SetupOwnerId = userId);
        }

        return result;
    }

    private static List<PersonaDefinitionConfig.ConfigEntry> getConfigEntries(List<String> licenses) {
        List<PersonaDefinitionConfig.ConfigEntry> configEntries = new List<PersonaDefinitionConfig.ConfigEntry>();
        for (String name : licenses) {
            configEntries.add(new PersonaDefinitionConfig.ConfigEntry().name(name));
        }

        return configEntries;
    }
}