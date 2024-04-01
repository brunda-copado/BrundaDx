public with sharing class LicenseAssignmentValidator {
    private List<Copado_License__c> incomingLicenses;
    private Map<Id, Copado_License__c> existingLicensesById;
    private Map<String, Integer> remainingLicensesByName;
    private Map<String, String> featuresByfield = new Map<String, String>{
        'Enable_Copado__c' => Label.Copado_Admin,
        'Enable_CCM__c' => Label.Copado_User,
        'Enable_CAD__c' => Label.Copado_Guest,
        'Enable_CCH__c' => Label.Compliance_Hub,
        'Enable_ADD__c' => Label.Data_Deployer,
        'Enable_CST__c' => Label.Selenium_Testing
    };

    // CTOR

    public LicenseAssignmentValidator(List<Copado_License__c> licenses) {
        incomingLicenses = licenses;
        existingLicensesById = getExistingLicensesById();
        remainingLicensesByName = getRemainingLicensesByName();
    }

    // PUBLIC

    public List<String> execute() {
        Map<String, Integer> incresedLicensesByName = getIncreasedLicenses();

        List<String> result = new List<String>();
        for (String license : incresedLicensesByName.keySet()) {
            if (incresedLicensesByName.get(license) > remainingLicensesByName.get(license)) {
                result.add(license);
            }
        }
        return result;
    }

    // PRIVATE

    private Map<Id, Copado_License__c> getExistingLicensesById() {
        // False positive: protected custom setting
        return new Map<Id, Copado_License__c>(
            [
                SELECT Enable_CCM__c, Enable_CAD__c, Enable_CST__c, Enable_Copado__c, Enable_CCH__c, Enable_ADD__c
                FROM Copado_License__c
                WHERE Id IN :incomingLicenses
            ]
        );
    }

    private Map<String, Integer> getRemainingLicensesByName() {
        LicenseManagerController lmc = new LicenseManagerController();
        return new Map<String, Integer>{
            Label.Copado_Admin => (lmc.copadoLicensesAvailable - lmc.copadoLicensesUsed),
            Label.Copado_User => (lmc.ccmLicensesAvailable - lmc.ccmLicensesUsed),
            Label.Copado_Guest => (lmc.cadLicensesAvailable - lmc.cadLicensesUsed),
            Label.Compliance_Hub => (lmc.cchLicensesAvailable - lmc.cchLicensesUsed),
            Label.Data_Deployer => (lmc.addLicensesAvailable - lmc.addLicensesUsed),
            Label.Selenium_Testing => (lmc.cstLicensesAvailable - lmc.cstLicensesUsed)
        };
    }

    private Map<String, Integer> getIncreasedLicenses() {
        Map<String, Integer> result = new Map<String, Integer>{
            Label.Copado_Admin => 0,
            Label.Copado_User => 0,
            Label.Copado_Guest => 0,
            Label.Compliance_Hub => 0,
            Label.Data_Deployer => 0,
            Label.Selenium_Testing => 0
        };

        for (Copado_License__c license : incomingLicenses) {
            for (String field : featuresByfield.keySet()) {
                String feature = featuresByfield.get(field);
                result.put(feature, result.get(feature) + increaseBy(license, field));
            }
        }
        return result;
    }

    private Integer increaseBy(Copado_License__c license, String feature) {
        Object incomingValue = license.get(feature);
        Copado_License__c existingLicense = existingLicensesById.get(license.Id);
        Boolean wasEnabled = existingLicense != null ? Boolean.valueOf(existingLicense.get(feature)) : false;
        Integer result = 0;
        if (incomingValue != null) {
            Boolean isEnabled = Boolean.valueOf(incomingValue);
            result = isEnabled ^ wasEnabled ? integerOf(isEnabled) - integerOf(wasEnabled) : 0;
        }
        return result;
    }

    private Integer integerOf(Boolean b) {
        return b ? 1 : 0;
    }
}