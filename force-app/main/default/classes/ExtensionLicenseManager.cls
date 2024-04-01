public with sharing class ExtensionLicenseManager {
    private static List<ExtensionKeyValueSetting__mdt> getExtensionLicenseRecords() {
        return new ExtensionKeyValueSettingsSelector().byKey('ExtensionLicense');
    }

    public static List<ExtensionKeyValueSetting__mdt> getFeatureLicenseRecords() {
        return new ExtensionKeyValueSettingsSelector().byKey('FeatureLicense');
    }

    public static List<LicenseInfo> getExtLicenseInfo() {
        List<LicenseInfo> licInfo = new List<LicenseInfo>();
        Set<String> apexClassNames = new Set<String>();
        for (ExtensionKeyValueSetting__mdt extLic : getExtensionLicenseRecords()) {
            apexClassNames.add(extLic.Value__c);
        }
        for (String className : apexClassNames) {
            try {
                CopadoExtLicenseInterface extClass = (CopadoExtLicenseInterface) Type.forName(className).newInstance();
                List<ExtLicenseInfo> extLicenses = extClass.getTotalLicense();
                if (!extLicenses.isEmpty()) {
                    for (ExtLicenseInfo extlicInfo : extLicenses) {
                        licInfo.add(new LicenseInfo(extlicInfo.label, extlicInfo.used, extlicInfo.available));
                    }
                }
            } catch (Exception ex) {
                Logger.error(null, 'ExtensionLicenseManager.getExtLicenseInfo', className + ' apex class failed to get license info', className, ex);
                continue; // Continue processing next extension
            }
        }
        return licInfo;
    }

    public static Map<Id, List<String>> getUserLicenseInfo() {
        Map<Id, List<String>> usersWithExtLicense = new Map<Id, List<String>>();
        Set<String> apexClassNames = new Set<String>();
        for (ExtensionKeyValueSetting__mdt extLic : getExtensionLicenseRecords()) {
            apexClassNames.add(extLic.Value__c);
        }

        for (String className : apexClassNames) {
            try {
                CopadoExtLicenseInterface extClass = (CopadoExtLicenseInterface) Type.forName(className).newInstance();
                List<ExtLicenseInfo> extLicenses = extClass.getLicenseAssigned();
                if (!extLicenses.isEmpty()) {
                    for (ExtLicenseInfo extlicInfo : extLicenses) {
                        Id usrId = Id.valueOf(extlicInfo.userId);
                        if (!usersWithExtLicense.containsKey(usrId)) {
                            usersWithExtLicense.put(usrId, new List<String>());
                        }
                        usersWithExtLicense.get(usrId).add(extlicInfo.name);
                    }
                }
            } catch (Exception ex) {
                Logger.error(null, 'ExtensionLicenseManager.getUserLicenseInfo', className + ' apex class failed to get license info', className, ex);
                continue; // Continue processing next extension
            }
        }

        return usersWithExtLicense;
    }

    public static void validateAndSetExtLicense(Boolean validate, Map<String, List<Id>> addToExtPackage, Map<String, List<Id>> removeFromExtPackage) {
        Map<String, Set<String>> apexClassNames = new Map<String, Set<String>>();
        Set<String> extLicenseNames = new Set<String>();
        extLicenseNames.addAll(addToExtPackage.keySet());
        extLicenseNames.addAll(removeFromExtPackage.keySet());
        populateApexClassWithLicense(apexClassNames, extLicenseNames);

        for (String className : apexClassNames.keySet()) {
            List<ExtLicenseAssignment> addToExtPack = new List<ExtLicenseAssignment>();
            List<ExtLicenseAssignment> removeFromExtPack = new List<ExtLicenseAssignment>();

            for (String licName : apexClassNames.get(className)) {
                if (addToExtPackage.containsKey(licName)) {
                    addToExtPack.add(new ExtLicenseAssignment(licName, addToExtPackage.get(licName)));
                }
                if (removeFromExtPackage.containsKey(licName)) {
                    removeFromExtPack.add(new ExtLicenseAssignment(licName, removeFromExtPackage.get(licName)));
                }
            }

            CopadoExtLicenseInterface extClass = (CopadoExtLicenseInterface) Type.forName(className).newInstance();
            if (validate) {
                extClass.validateExtLicense(addToExtPack, removeFromExtPack);
            } else {
                extClass.setExtLicense(addToExtPack, removeFromExtPack);
            }
        }
    }

    private static void populateApexClassWithLicense(Map<String, Set<String>> apexClassNames, Set<String> extLicenseNames) {
        Map<String, String> mapExtensionWithClass = new Map<String, String>();
        for (ExtensionKeyValueSetting__mdt extLic : getExtensionLicenseRecords()) {
            mapExtensionWithClass.put(extLic.Extension__r.DeveloperName, extLic.Value__c);
        }
        Map<String, String> mapLicenseNameWithExtension = new Map<String, String>();
        for (ExtensionKeyValueSetting__mdt extLic : getFeatureLicenseRecords()) {
            mapLicenseNameWithExtension.put(extLic.Value__c, extLic.Extension__r.DeveloperName);
        }

        for (String licenseName : extLicenseNames) {
            String extName = mapLicenseNameWithExtension.get(licenseName);
            String className = mapExtensionWithClass.get(extName);
            if (!apexClassNames.containsKey(className)) {
                apexClassNames.put(className, new Set<String>{ licenseName });
            }
            apexClassNames.get(className).add(licenseName);
        }
    }
}