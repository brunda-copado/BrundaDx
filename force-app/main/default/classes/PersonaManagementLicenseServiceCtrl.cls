public with sharing class PersonaManagementLicenseServiceCtrl {
    @AuraEnabled
    public static List<LicenseServiceHelper.LicenseDefinition> getLicenses() {
        return LicenseServiceHelper.getLicenseDefinitions();
    }

    @AuraEnabled
    public static List<LicenseServiceHelper.LicenseDefinition> getLicensesForPersona(String personaId) {
        return LicenseServiceHelper.getLicensesForPersona(personaId);
    }

    @AuraEnabled
    public static void addPackageLicense(String personaId, List<String> licenses) {
        Persona.AddLicenseRequest request = new Persona.AddLicenseRequest();
        request.personaId = personaId;
        request.licenses = licenses;
        Persona.LicenseService.addPackageLicense(request);
    }

    @AuraEnabled
    public static void addCopadoLicense(String personaId, List<String> licenses) {
        Persona.AddLicenseRequest request = new Persona.AddLicenseRequest();
        request.personaId = personaId;
        request.licenses = licenses;
        Persona.LicenseService.addCopadoLicense(request);
    }

    @AuraEnabled
    public static void addPackageLicense2(String personaId, List<String> licenses) {
        Persona.AddLicenseRequest request = new Persona.AddLicenseRequest();
        request.personaId = personaId;
        request.licenses = licenses;
        Persona.LicenseService.add2PackageLicense(request);
    }

    @AuraEnabled
    public static void addCopadoLicense2(String personaId, List<String> licenses) {
        Persona.AddLicenseRequest request = new Persona.AddLicenseRequest();
        request.personaId = personaId;
        request.licenses = licenses;
        Persona.LicenseService.add2CopadoLicense(request);
    }

    @AuraEnabled
    public static void removePackageLicense(String personaId, List<String> licenses) {
        Persona.RemoveLicenseRequest request = new Persona.RemoveLicenseRequest();
        request.personaId = personaId;
        request.licenses = licenses;
        Persona.LicenseService.removePackageLicense(request);
    }

    @AuraEnabled
    public static void removeCopadoLicense(String personaId, List<String> licenses) {
        Persona.RemoveLicenseRequest request = new Persona.RemoveLicenseRequest();
        request.personaId = personaId;
        request.licenses = licenses;
        Persona.LicenseService.removeCopadoLicense(request);
    }

    @AuraEnabled
    public static void removePackageLicense2(String personaId, List<String> licenses) {
        Persona.RemoveLicenseRequest request = new Persona.RemoveLicenseRequest();
        request.personaId = personaId;
        request.licenses = licenses;
        Persona.LicenseService.remove2PackageLicense(request);
    }

    @AuraEnabled
    public static void removeCopadoLicense2(String personaId, List<String> licenses) {
        Persona.RemoveLicenseRequest request = new Persona.RemoveLicenseRequest();
        request.personaId = personaId;
        request.licenses = licenses;
        Persona.LicenseService.remove2CopadoLicense(request);
    }
}