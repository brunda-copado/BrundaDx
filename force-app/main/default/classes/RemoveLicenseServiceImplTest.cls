@isTest
private class RemoveLicenseServiceImplTest {
    @TestSetup
    private static void setupData() {
        TestUtilities.getAllMultilicense();
        User user = (User) new User_t()
            .admin()
            .assign(new PermissionSetAssignment_t().copadoUser())
            .assign(new PermissionSetAssignment_t().personaManagement())
            .persist();
        System.runAs(user) {
            new CopadoLicense().user(user).enableAll().persist();
            createData();
        }
    }

    @isTest
    private static void removeCopadoLicense() {
        System.runAs(getRunAsUser()) {
            // Setup
            Persona.RemoveLicenseRequest request = new Persona.RemoveLicenseRequest();
            request.personaId = getPersonaDefinition();
            request.licenses = new List<String>{
                LicenseConstants.EE_LICENSES_ENABLED,
                LicenseConstants.CCM_LICENSES_ENABLED,
                LicenseConstants.CAD_LICENSES_ENABLED,
                LicenseConstants.CCH_LICENSES_ENABLED,
                LicenseConstants.ADD_LICENSES_ENABLED
            };

            // Exercise
            Test.startTest();
            RemoveLicenseServiceImpl.removeCopadoLicense(request);
            RemoveLicenseServiceImpl.remove2CopadoLicense(request);
            Test.stopTest();

            List<Copado_License__c> updatedLicenses = [
                SELECT Id, Enable_Copado__c, Enable_CCM__c, Enable_CST__c, Enable_CAD__c, Enable_CCH__c, Enable_ADD__c
                FROM Copado_License__c
            ];

            // Assertions
            System.assertEquals(false, updatedLicenses[0].Enable_Copado__c, 'The Copado license should be disabled.');
            System.assertEquals(false, updatedLicenses[0].Enable_CCM__c, 'The Copado license should be disabled.');
            System.assertEquals(false, updatedLicenses[0].Enable_CAD__c, 'The Copado license should be disabled.');
            System.assertEquals(false, updatedLicenses[0].Enable_CCH__c, 'The Copado license should be disabled.');
            System.assertEquals(false, updatedLicenses[0].Enable_ADD__c, 'The Copado license should be disabled.');
        }
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    private static void removePackageLicense() {
        System.runAs(getRunAsUser()) {
            // Setup
            Persona.RemoveLicenseRequest request = new Persona.RemoveLicenseRequest();
            request.personaId = getPersonaDefinition();
            request.licenses = new List<String>{ LicenseConstants.LICENSE_NAMES_BY_NAMESPACE.get(PackageNamespace.copado.name()) };

            // Exercise
            Test.startTest();
            RemoveLicenseServiceImpl.removePackageLicense(request);
            Test.stopTest();

            // Assertions
            // Can not put assertion based on package licenses since they will be available after manage package installation
        }
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    private static void remove2PackageLicense() {
        System.runAs(getRunAsUser()) {
            // Setup
            Persona.RemoveLicenseRequest request = new Persona.RemoveLicenseRequest();
            request.personaId = getPersonaDefinition();
            request.licenses = new List<String>{ LicenseConstants.LICENSE_NAMES_BY_NAMESPACE.get(PackageNamespace.copado.name()) };
            RemoveLicenseServiceImpl.removePackageLicense(request);

            // Exercise
            Test.startTest();
            RemoveLicenseServiceImpl.remove2PackageLicense(request);
            Test.stopTest();

            // Assertions
            // Can not put assertion based on package licenses since they will be available after manage package installation
        }
    }

    // HELPERS

    private static Id getPersonaDefinition() {
        return [SELECT Id FROM Persona_Definition__c LIMIT 1].Id;
    }

    private static User getRunAsUser() {
        return [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' ORDER BY CreatedDate DESC LIMIT 1];
    }

    private static void createData() {
        Group testGroup = new Group(Name = 'Test Group', Type = 'Regular');
        insert testGroup;

        GroupMember testGroupMember = new GroupMember(GroupId = testGroup.Id, UserOrGroupId = getRunAsUser().Id);
        insert testGroupMember;

        PersonaDefinitionConfig config = new PersonaDefinitionConfig();
        config.publicGroupId = testGroup.Id;
        config.licenses = new List<PersonaDefinitionConfig.ConfigEntry>();

        Persona_Definition__c personaDef = new Persona_Definition__c(Config_JSON__c = JSON.serialize(config));
        insert personaDef;

        Copado_License__c copadoLicense = Copado_License__c.getInstance(getRunAsUser().Id);
        copadoLicense.Enable_Copado__c = true;
        copadoLicense.Enable_CCM__c = true;
        copadoLicense.Enable_CAD__c = true;
        copadoLicense.Enable_CCH__c = true;
        copadoLicense.Enable_ADD__c = true;
        upsert copadoLicense;

        List<UserPackageLicense> userPackageLicenses = new List<UserPackageLicense>();
        for (PackageLicense packageLicense : [
            SELECT NamespacePrefix
            FROM PackageLicense
            WHERE NamespacePrefix IN :LicenseConstants.LICENSE_NAMES_BY_NAMESPACE.keySet()
        ]) {
            userPackageLicenses.add(new UserPackageLicense(PackageLicenseId = packageLicense.Id, UserId = getRunAsUser().Id));
        }
        insert userPackageLicenses;
    }
}