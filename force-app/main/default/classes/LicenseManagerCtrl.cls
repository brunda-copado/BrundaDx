public with sharing class LicenseManagerCtrl {
    private static final Set<String> PACKAGE_NAMESPACES = new Set<String>{
        PackageNamespace.copado.name(),
        PackageNamespace.copadometrics.name(),
        PackageNamespace.copadovsm.name()
    };

    private static Map<String, Schema.SObjectField> userFields {
        get {
            if (userFields == null) {
                userFields = SObjectType.User.fields.getMap();
            }
            return userFields;
        }
        set;
    }

    // PUBLIC

    @AuraEnabled
    public static List<LicenseInfo> fetchLicensesInfo() {
        try {
            LicenseManagerController lmc = new LicenseManagerController();

            List<LicenseInfo> result = new List<LicenseInfo>();

            if (lmc.cbmBranchesAvailable > 0) {
                result.add(new LicenseInfo(Label.Branch_Management, lmc.cbmLicensesUsed, lmc.cbmBranchesAvailable));
            }

            result.addAll(getPackageLicensesInfo());

            if (lmc.copadoLicensesAvailable > 0) {
                result.add(new LicenseInfo(Label.Copado_Admin, lmc.copadoLicensesUsed, lmc.copadoLicensesAvailable));
            }

            if (lmc.ccmLicensesAvailable > 0) {
                result.add(new LicenseInfo(Label.Copado_User, lmc.ccmLicensesUsed, lmc.ccmLicensesAvailable));
            }

            if (lmc.cadLicensesAvailable > 0) {
                result.add(new LicenseInfo(Label.Copado_Guest, lmc.cadLicensesUsed, lmc.cadLicensesAvailable));
            }

            if (lmc.cchLicensesAvailable > 0) {
                result.add(new LicenseInfo(Label.Compliance_Hub, lmc.cchLicensesUsed, lmc.cchLicensesAvailable));
            }

            if (lmc.addLicensesAvailable > 0) {
                result.add(new LicenseInfo(Label.Data_Deployer, lmc.addLicensesUsed, lmc.addLicensesAvailable));
            }

            if (lmc.cstLicensesAvailable > 0) {
                result.add(new LicenseInfo(Label.Selenium_Testing, lmc.cstLicensesUsed, lmc.cstLicensesAvailable));
            }

            result.addAll(ExtensionLicenseManager.getExtLicenseInfo());

            return result;
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }
    }

    @AuraEnabled
    public static List<UserWithLicense> fetchData(String selectFieldSet) {
        try {
            Map<Id, List<String>> usersWithPackageLicenses = getUsersWithPackageLicenses();
            LicenseManagerController lmc = new LicenseManagerController();
            Map<Id, Copado_License__c> licensesByOwnerId = lmc.licenseMap;
            Map<Id, List<String>> usersWithExtLicenses = ExtensionLicenseManager.getUserLicenseInfo();
            Set<Id> allUserIds = new Set<Id>();
            allUserIds.addAll(usersWithPackageLicenses.keySet());
            allUserIds.addAll(licensesByOwnerId.keySet());

            Map<Id, User> usersById = new UsersSelector().byIdWithFields(allUserIds, getProcessedFields(selectFieldSet));

            List<UserWithLicense> result = new List<UserWithLicense>();
            for (Id ownerId : usersById.keySet()) {
                result.add(
                    new UserWithLicense(
                        usersById.get(ownerId),
                        usersWithPackageLicenses.get(ownerId),
                        licensesByOwnerId.get(ownerId),
                        usersWithExtLicenses.get(ownerId)
                    )
                );
            }
            return result;
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }
    }

    @AuraEnabled
    public static void validateLicenses(String jsonLicenses, Map<String, List<Id>> addToPackage, Map<String, List<Id>> removeFromPackage) {
        try {
            List<Copado_License__c> licenses = (List<Copado_License__c>) JSON.deserialize(jsonLicenses, List<Copado_License__c>.class);
            List<String> licensesExceeded = new List<String>();

            PackageLicenseManager plm = new PackageLicenseManager(addToPackage, removeFromPackage);

            licensesExceeded.addAll(plm.validateAssignment());

            if (!licenses.isEmpty()) {
                licensesExceeded.addAll(new LicenseAssignmentValidator(licenses).execute());
            }

            if (!licensesExceeded.isEmpty()) {
                throw new ApplicationException(String.format(Label.LICENSE_LIMIT_MESSAGE, new List<Object>{ String.join(licensesExceeded, ', ') }));
            }
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }
    }
    @AuraEnabled
    public static void validateExtLicenses(Map<String, List<Id>> addToExtPackage, Map<String, List<Id>> removeFromExtPackage) {
        try {
            ExtensionLicenseManager.validateAndSetExtLicense(true, addToExtPackage, removeFromExtPackage);
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }
    }

    @AuraEnabled
    public static void updatePackageLicenses(Map<String, List<Id>> addToPackage, Map<String, List<Id>> removeFromPackage) {
        try {
            PackageLicenseManager plm = new PackageLicenseManager(addToPackage, removeFromPackage);

            if (!plm.validateAssignment().isEmpty()) {
                throw new ApplicationException(String.format(Label.LICENSE_LIMIT_MESSAGE, new List<Object>{ 'Copado Managed Package' }));
            }

            plm.remove();

            plm.assign();
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }
    }

    @AuraEnabled
    public static void updateExtPackageLicenses(Map<String, List<Id>> addToExtPackage, Map<String, List<Id>> removeFromExtPackage) {
        try {
            ExtensionLicenseManager.validateAndSetExtLicense(false, addToExtPackage, removeFromExtPackage);
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }
    }

    @AuraEnabled
    public static void updateUsersWithLicenses(List<User> users, String jsonLicenses) {
        try {
            List<Copado_License__c> licenses = (List<Copado_License__c>) JSON.deserialize(jsonLicenses, List<Copado_License__c>.class);
            List<String> licensesExceeded = new LicenseAssignmentValidator(licenses).execute();

            if (!licensesExceeded.isEmpty()) {
                throw new ApplicationException(String.format(Label.LICENSE_LIMIT_MESSAGE, new List<Object>{ String.join(licensesExceeded, ', ') }));
            }
            // FALSE POSITIVE: protected custom setting
            upsert licenses;
            // TODO: Trigger afterUpdate to delete copado_license__c record if all fields are false?

            // FALSE POSITIVE: OLS and FLS checks are already performed by the LWC where this method is being used
            update users;
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }
    }

    @AuraEnabled
    public static void removeAllPackageLicenses(List<Id> userIds) {
        try {
            Map<String, List<Id>> removeFromPackage = new Map<String, List<Id>>();
            for (PackageLicense license : [
                SELECT NamespacePrefix
                FROM PackageLicense
                WHERE NamespacePrefix IN :PACKAGE_NAMESPACES
                ORDER BY NamespacePrefix
            ]) {
                removeFromPackage.put(license.NamespacePrefix, userIds);
            }

            PackageLicenseManager plm = new PackageLicenseManager(new Map<String, List<Id>>(), removeFromPackage);
            plm.remove();
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }
    }

    @AuraEnabled
    public static void removeAllExtPackageLicenses(List<Id> userIds) {
        try {
            Map<String, String> extLicNamesMap = fetchExtLicenseNames();
            Map<String, List<Id>> removeFromExtPackage = new Map<String, List<Id>>();
            for (String extLicName : extLicNamesMap.keySet()) {
                removeFromExtPackage.put(extLicNamesMap.get(extLicName), userIds);
            }
            ExtensionLicenseManager.validateAndSetExtLicense(false, new Map<String, List<Id>>(), removeFromExtPackage);
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }
    }

    @AuraEnabled
    public static void removeAllLicenses(List<Id> userIds) {
        try {
            if (!userIds.isEmpty()) {
                LicenseManagerController lmc = new LicenseManagerController();
                Map<Id, Copado_License__c> licensesByOwnerId = lmc.licenseMap;

                List<Copado_License__c> licenses = new List<Copado_License__c>();
                for (Id userId : userIds) {
                    Copado_License__c license = licensesByOwnerId.get(userId);
                    if (license != null) {
                        licenses.add(license);
                    }
                }
                // FALSE POSITIVE: protected custom setting
                delete licenses;
            }
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }
    }

    @AuraEnabled
    public static void deleteUnusedLicenses() {
        try {
            new DeleteUnusedLicenses().execute();
        } catch (Exception e) {
            // Skip silently, if it fails, it should not affect user experience
        }
    }

    @AuraEnabled(Cacheable=true)
    public static List<LookupSearchResult> search(String searchTerm, List<String> selectedIds) {
        try {
            List<User> users = new UsersSelector().byPartialNameExcludingSelected(searchTerm, selectedIds);

            List<LookupSearchResult> result = new List<LookupSearchResult>();

            String icon = 'standard:user';
            for (User user : users) {
                String subtitle = 'User • ' + user.Name;
                result.add(new LookupSearchResult(user.Id, 'User', icon, user.Name, subtitle));
            }

            return result;
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }
    }

    // PRIVATE

    private static List<LicenseInfo> getPackageLicensesInfo() {
        Map<String, String> licenseNamesByNamespace = new Map<String, String>{
            PackageNamespace.copado.name() => 'Copado Managed Package',
            PackageNamespace.copadometrics.name() => 'Copado Analytics',
            PackageNamespace.copadovsm.name() => 'Copado VSM'
        };

        // FALSE POSITIVE: setup object
        List<LicenseInfo> result = new List<LicenseInfo>();
        for (PackageLicense license : [
            SELECT AllowedLicenses, UsedLicenses, NamespacePrefix
            FROM PackageLicense
            WHERE NamespacePrefix IN :PACKAGE_NAMESPACES AND AllowedLicenses > 0
            ORDER BY NamespacePrefix
        ]) {
            result.add(new LicenseInfo(licenseNamesByNamespace.get(license.NamespacePrefix), license.UsedLicenses, license.AllowedLicenses));
        }
        return result;
    }

    private static Map<Id, List<String>> getUsersWithPackageLicenses() {
        Map<Id, List<String>> result = new Map<Id, List<String>>();

        // FALSE POSITIVE: setup object
        for (UserPackageLicense upl : [
            SELECT UserId, PackageLicense.NamespacePrefix
            FROM UserPackageLicense
            WHERE PackageLicense.NamespacePrefix IN :PACKAGE_NAMESPACES
        ]) {
            if (!result.containsKey(upl.userId)) {
                result.put(upl.userId, new List<String>());
            }

            result.get(upl.userId).add(upl.PackageLicense.NamespacePrefix);
        }
        return result;
    }

    /**
     * Note: we need to check access even if later we are stripping inaccessible fields because,
     *       if we add the reference field to the query in first place, even if it is stripped
     *       and does not appear in debug logs, the object reference remains in the object and
     *       it is passed to the JS controller, which parses it
     */
    private static Set<String> getProcessedFields(String fieldSet) {
        Set<String> result = new Set<String>();
        for (FieldSetMember field : getFieldSetFields(fieldSet)) {
            String fieldToAdd = field.getFieldPath();
            if (field.getType() == DisplayType.REFERENCE && hasAccess(fieldToAdd)) {
                if (field.getFieldPath().endsWith('__c')) {
                    fieldToAdd = field.getFieldPath().replace('__c', '__r.Name');
                } else if (field.getFieldPath().endsWith('Id')) {
                    // Trick to no to replace other possible appearances of 'Id' in the field name
                    fieldToAdd = field.getFieldPath() + '__';
                    fieldToAdd = fieldToAdd.replace('Id__', '.Name');
                }
            }
            result.add(fieldToAdd);
        }
        return result;
    }

    private static List<FieldSetMember> getFieldSetFields(String fieldSet) {
        return fflib_SObjectDescribe.getDescribe(User.SObjectType).getFieldSets().get(fieldSet).getFields();
    }

    private static Boolean hasAccess(String field) {
        return userFields.get(field).getDescribe().isAccessible();
    }

    @AuraEnabled
    public static Map<String, String> fetchExtLicenseNames() {
        try {
            Map<String, String> extLicNamesMap = new Map<String, String>();
            for (ExtensionKeyValueSetting__mdt extLic : ExtensionLicenseManager.getFeatureLicenseRecords()) {
                extLicNamesMap.put(extLic.Label, extLic.Value__c);
            }
            return extLicNamesMap;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}