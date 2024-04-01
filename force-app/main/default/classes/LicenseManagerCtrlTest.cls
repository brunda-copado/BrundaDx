@IsTest
private with sharing class LicenseManagerCtrlTest {
    private static final Set<String> PACKAGE_NAMESPACES = new Set<String>{
        PackageNamespace.copado.name(),
        PackageNamespace.copadovsm.name(),
        PackageNamespace.copadometrics.name()
    };

    @TestSetup
    private static void makeData() {
        TestUtilities.enableLicenses(1, 1, 1, 1, 1, 1, 1);

        TestUtilities.insertUser('license_adm@copado.com', 'System Administrator');
        TestUtilities.insertUser('license-std1@copado.com', 'Standard User');
        TestUtilities.insertUser('license-std2@copado.com', 'Standard User');
        TestUtilities.insertUser('license-std3@copado.com', 'Standard User');

        User usr1 = [SELECT Id FROM User WHERE username = 'license-std1@copado.com'];
        User usr2 = [SELECT Id FROM User WHERE username = 'license-std2@copado.com'];
        User usr3 = [SELECT Id FROM User WHERE username = 'license-std3@copado.com'];
        User adminUser = [SELECT Id, Username FROM User WHERE Username = 'license_adm@copado.com'];

        System.runAs(adminUser) {
            Copado_License__c license1 = Copado_License__c.getInstance(usr1.Id);
            license1.Enable_Copado__c = true;
            license1.Enable_CCM__c = true;
            license1.Enable_CAD__c = true;
            license1.Enable_CCH__c = false;
            license1.Enable_CST__c = false;

            Copado_License__c license2 = Copado_License__c.getInstance(usr2.Id);
            license2.Enable_Copado__c = false;
            license2.Enable_CCM__c = false;
            license2.Enable_CAD__c = false;
            license2.Enable_CCH__c = false;
            license2.Enable_CST__c = false;

            Copado_License__c license3 = Copado_License__c.getInstance(usr3.Id);
            license3.Enable_Copado__c = false;
            license3.Enable_CCM__c = false;
            license3.Enable_CAD__c = false;
            license3.Enable_CCH__c = true;
            license3.Enable_CST__c = true;

            upsert new List<Copado_License__c>{ license1, license2, license3 };
        }
    }

    @IsTest
    private static void fetchLicensesInfo() {
        //Setup
        ExtensionPackageConfiguration__mdt ExtensionPackageName = new ExtensionPackageConfiguration__mdt(DeveloperName = 'ExtensionPack');
        ExtensionKeyValueSettingsSelector.mock = new List<ExtensionKeyValueSetting__mdt>{
            new ExtensionKeyValueSetting__mdt(
                Key__c = 'ExtensionLicense',
                Value__c = 'ExtensionLicenseManagerTest',
                Extension__r = ExtensionPackageName
            ),
            new ExtensionKeyValueSetting__mdt(Key__c = 'ExtensionLicense', Value__c = 'InvalidClass'),
            new ExtensionKeyValueSetting__mdt(
                Key__c = 'FeatureLicense',
                Value__c = 'ExtensionLicense',
                Label = 'Extension License',
                Extension__r = ExtensionPackageName
            )
        };
        // Exercise

        Test.startTest();
        List<LicenseInfo> result = LicenseManagerCtrl.fetchLicensesInfo();
        Map<String, String> extLicNames = LicenseManagerCtrl.fetchExtLicenseNames();
        Test.stopTest();

        // Verify

        // Exact amount of records can not be asserted due to non test data dependencies on the actual features available in the suscriber org
        System.assert(!result.isEmpty(), 'There should be sat least 1 license available');
        System.assert(extLicNames.containsKey('Extension License'), 'Extension license not found');
    }

    @IsTest
    private static void fetchData() {
        //Setup

        ExtensionPackageConfiguration__mdt ExtensionPackageName = new ExtensionPackageConfiguration__mdt(DeveloperName = 'ExtensionPack');
        ExtensionKeyValueSettingsSelector.mock = new List<ExtensionKeyValueSetting__mdt>{
            new ExtensionKeyValueSetting__mdt(
                Key__c = 'ExtensionLicense',
                Value__c = 'ExtensionLicenseManagerTest',
                Extension__r = ExtensionPackageName
            ),
            new ExtensionKeyValueSetting__mdt(Key__c = 'ExtensionLicense', Value__c = 'InvalidClass'),
            new ExtensionKeyValueSetting__mdt(
                Key__c = 'FeatureLicense',
                Value__c = 'ExtensionLicense',
                Label = 'Extension License',
                Extension__r = ExtensionPackageName
            )
        };
        // Exercise

        Test.startTest();
        List<UserWithLicense> result = LicenseManagerCtrl.fetchData('License_Manager');
        Test.stopTest();

        // Verify

        // Exact amount of records can not be asserted due to non test data dependencies of UserPackageLicense records
        System.assert(result.size() >= 3, 'There should be at least 3 records');
    }

    @IsTest
    private static void validateLicensesSuccess() {
        // Setup

        User usr2 = [SELECT Id FROM User WHERE username = 'license-std2@copado.com'];
        User usr3 = [SELECT Id FROM User WHERE username = 'license-std3@copado.com'];

        Copado_License__c license = Copado_License__c.getInstance(usr3.Id);
        license.Enable_CCH__c = false;
        license.Enable_CST__c = false;

        Map<String, List<Id>> addToPackage = new Map<String, List<Id>>();
        Map<String, List<Id>> removeFromPackage = new Map<String, List<Id>>();
        for (PackageLicense packageLicense : [
            SELECT NamespacePrefix
            FROM PackageLicense
            WHERE NamespacePrefix IN :PACKAGE_NAMESPACES
        ]) {
            addToPackage.put(packageLicense.NamespacePrefix, new List<Id>{ usr3.Id });
            removeFromPackage.put(packageLicense.NamespacePrefix, new List<Id>{ usr2.Id });
        }

        // Exercise

        Test.startTest();
        LicenseManagerCtrl.validateLicenses(JSON.serialize(new List<Copado_License__c>{ license }), addToPackage, removeFromPackage);
        Test.stopTest();

        // Verify

        System.assert(true, 'No exception due to insufficient licenses should have been thrown at this point');
    }

    @IsTest
    private static void validateLicensesException() {
        // Setup

        User usr2 = [SELECT Id FROM User WHERE username = 'license-std2@copado.com'];
        User usr3 = [SELECT Id FROM User WHERE username = 'license-std3@copado.com'];

        Copado_License__c license = Copado_License__c.getInstance(usr3.Id);
        license.Enable_Copado__c = true;

        Map<String, List<Id>> addToPackage = new Map<String, List<Id>>();
        Map<String, List<Id>> removeFromPackage = new Map<String, List<Id>>();
        for (PackageLicense packageLicense : [
            SELECT NamespacePrefix
            FROM PackageLicense
            WHERE NamespacePrefix IN :PACKAGE_NAMESPACES
        ]) {
            addToPackage.put(packageLicense.NamespacePrefix, new List<Id>{ usr3.Id });
            removeFromPackage.put(packageLicense.NamespacePrefix, new List<Id>{ usr2.Id });
        }

        String exceptionMessage;

        // Exercise

        Test.startTest();
        try {
            LicenseManagerCtrl.validateLicenses(JSON.serialize(new List<Copado_License__c>{ license }), addToPackage, removeFromPackage);
        } catch (AuraHandledException e) {
            exceptionMessage = e.getMessage();
        }
        Test.stopTest();

        // Verify

        System.assertEquals(
            String.format(Label.LICENSE_LIMIT_MESSAGE, new List<Object>{ 'Copado Admin' }),
            exceptionMessage,
            'There should not be enough Copado Admin licenses available to assign to the selected users'
        );
    }

    @IsTest
    private static void updatePackageLicenses() {
        // Setup

        User usr2 = [SELECT Id FROM User WHERE username = 'license-std2@copado.com'];
        User usr3 = [SELECT Id FROM User WHERE username = 'license-std3@copado.com'];

        Map<String, List<Id>> addToPackage = new Map<String, List<Id>>();
        Map<String, List<Id>> removeFromPackage = new Map<String, List<Id>>();
        for (PackageLicense packageLicense : [
            SELECT NamespacePrefix
            FROM PackageLicense
            WHERE NamespacePrefix IN :PACKAGE_NAMESPACES
        ]) {
            addToPackage.put(packageLicense.NamespacePrefix, new List<Id>{ usr2.Id, usr3.Id });
            removeFromPackage.put(packageLicense.NamespacePrefix, new List<Id>{ usr2.Id, usr3.Id });
        }

        Integer currentLicensesAssignments = [SELECT COUNT() FROM UserPackageLicense];

        // Exercise

        Test.startTest();
        try {
            LicenseManagerCtrl.updatePackageLicenses(addToPackage, new Map<String, List<Id>>());
        } catch (AuraHandledException e) {
            // Not possible to assign package licenses in test context
        }
        LicenseManagerCtrl.updatePackageLicenses(new Map<String, List<Id>>(), removeFromPackage);
        Integer licensesAssignmentsAfterRemove = [SELECT COUNT() FROM UserPackageLicense];
        Test.stopTest();

        // Verify

        System.assertEquals(currentLicensesAssignments, licensesAssignmentsAfterRemove, 'Number of licenses assigned should match');
    }

    @IsTest
    private static void validateAndUpdateExtPackageLicenses() {
        // Setup

        ExtensionPackageConfiguration__mdt ExtensionPackageName = new ExtensionPackageConfiguration__mdt(DeveloperName = 'ExtensionPack');
        ExtensionKeyValueSettingsSelector.mock = new List<ExtensionKeyValueSetting__mdt>{
            new ExtensionKeyValueSetting__mdt(
                Key__c = 'ExtensionLicense',
                Value__c = 'ExtensionLicenseManagerTest',
                Extension__r = ExtensionPackageName
            ),
            new ExtensionKeyValueSetting__mdt(
                Key__c = 'FeatureLicense',
                Value__c = 'ExtensionLicense',
                Label = 'Extension License',
                Extension__r = ExtensionPackageName
            )
        };

        User usr2 = [SELECT Id FROM User WHERE username = 'license-std2@copado.com'];
        User usr3 = [SELECT Id FROM User WHERE username = 'license-std3@copado.com'];

        Map<String, List<Id>> addToExtPackage = new Map<String, List<Id>>();
        addToExtPackage.put('ExtensionLicense', new List<Id>{ usr2.Id });

        Map<String, List<Id>> removeFromExtPackage = new Map<String, List<Id>>();
        removeFromExtPackage.put('ExtensionLicense', new List<Id>{ usr3.Id });

        String validateSuccessMsg;
        String updateSuccessMsg;

        // Exercise

        Test.startTest();
        try {
            LicenseManagerCtrl.validateExtLicenses(addToExtPackage, removeFromExtPackage);
        } catch (Exception e) {
            validateSuccessMsg = e.getMessage();
        }
        try {
            LicenseManagerCtrl.updateExtPackageLicenses(addToExtPackage, removeFromExtPackage);
        } catch (Exception e) {
            updateSuccessMsg = e.getMessage();
        }
        Test.stopTest();

        // Verify

        System.assertEquals('Extension validation was successfull', validateSuccessMsg, 'License validation info not passed to extension package');
        System.assertEquals('Extension license assignment was successfull', updateSuccessMsg, 'License update info not passed to extension package');
    }

    private static void updateUsersWithLicenses() {
        // Setup

        User usr3 = [SELECT Id FROM User WHERE username = 'license-std3@copado.com'];
        usr3.FirstName = 'testUpdate';

        Copado_License__c license = Copado_License__c.getInstance(usr3.Id);
        license.Enable_CCH__c = false;
        license.Enable_CST__c = false;

        // Exercise

        Test.startTest();
        LicenseManagerCtrl.updateUsersWithLicenses(new List<User>{ usr3 }, JSON.serialize(new List<Copado_License__c>{ license }));
        Test.stopTest();

        // Verify

        usr3 = [SELECT FirstName FROM User WHERE username = 'license-std3@copado.com'];

        System.assertEquals('testUpdate', usr3.FirstName, 'User FirstName should have been updated');
        LicenseManagerController lc = new LicenseManagerController();
        System.assertEquals(0, lc.cchLicensesUsed, 'Used compliance Hub licenses should be 0');
        System.assertEquals(0, lc.cstLicensesUsed, 'Used selenium testing licenses should be 0');
    }

    @IsTest
    private static void removeAllPackageLicenses() {
        // Setup

        User usr3 = [SELECT Id FROM User WHERE username = 'license-std3@copado.com'];

        Integer currentLicensesAssignments = [SELECT COUNT() FROM UserPackageLicense];

        // Exercise

        Test.startTest();
        LicenseManagerCtrl.removeAllPackageLicenses(new List<Id>{ usr3.Id });
        Test.stopTest();

        // Verify

        // Not possible to assign package licenses in test context

        Integer licensesAssignmentsAfterRemove = [SELECT COUNT() FROM UserPackageLicense];

        System.assertEquals(currentLicensesAssignments, licensesAssignmentsAfterRemove, 'Number of licenses assigned should match');
    }

    @IsTest
    private static void removeAllLicenses() {
        // Setup

        User usr3 = [SELECT Id FROM User WHERE username = 'license-std3@copado.com'];

        // Exercise

        Test.startTest();
        LicenseManagerCtrl.removeAllLicenses(new List<Id>{ usr3.Id });
        Test.stopTest();

        // Verify

        LicenseManagerController lc = new LicenseManagerController();
        System.assertEquals(0, lc.cchLicensesUsed, 'Used compliance Hub licenses should be 0');
        System.assertEquals(0, lc.cstLicensesUsed, 'Used selenium testing licenses should be 0');
    }

    @IsTest
    private static void removeAllExtPackageLicenses() {
        // Setup

        User usr3 = [SELECT Id FROM User WHERE username = 'license-std3@copado.com'];
        ExtensionPackageConfiguration__mdt ExtensionPackageName = new ExtensionPackageConfiguration__mdt(DeveloperName = 'ExtensionPack');
        ExtensionKeyValueSettingsSelector.mock = new List<ExtensionKeyValueSetting__mdt>{
            new ExtensionKeyValueSetting__mdt(
                Key__c = 'ExtensionLicense',
                Value__c = 'ExtensionLicenseManagerTest',
                Extension__r = ExtensionPackageName
            ),
            new ExtensionKeyValueSetting__mdt(
                Key__c = 'FeatureLicense',
                Value__c = 'ExtensionLicense',
                Label = 'Extension License',
                Extension__r = ExtensionPackageName
            )
        };

        // Exercise
        String removeSuccessMsg;
        Test.startTest();
        try {
            LicenseManagerCtrl.removeAllExtPackageLicenses(new List<Id>{ usr3.Id });
        } catch (Exception e) {
            removeSuccessMsg = e.getMessage();
        }
        Test.stopTest();

        // Verify
        System.assertEquals('Extension license assignment was successfull', removeSuccessMsg, 'License update info not passed to extension package');
    }

    @IsTest
    private static void deleteUnusedLicenses() {
        // Exercise

        Test.startTest();
        LicenseManagerCtrl.deleteUnusedLicenses();
        List<UserWithLicense> result = LicenseManagerCtrl.fetchData('License_Manager');
        Test.stopTest();

        // Verify

        // Exact amount of records can not be asserted due to non test data dependencies of UserPackageLicense records
        System.assert(result.size() >= 2, 'There should be at least 2 records');
    }

    @IsTest
    private static void search() {
        // Setup

        User usr3 = [SELECT Id FROM User WHERE username = 'license-std3@copado.com'];

        // Exercise

        Test.startTest();
        List<LookupSearchResult> result = LicenseManagerCtrl.search('Future', new List<Id>{ usr3.Id });
        Test.stopTest();

        // Verify

        System.assertEquals(3, result.size(), 'Exactly 3 users should have been found');
    }
}