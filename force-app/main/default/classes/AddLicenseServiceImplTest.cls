@isTest
private class AddLicenseServiceImplTest {
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
    private static void addCopadoLicense() {
        System.runAs(getRunAsUser()) {
            // Setup
            Persona.AddLicenseRequest request = new Persona.AddLicenseRequest();
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
            AddLicenseServiceImpl.addCopadoLicense(request);
            AddLicenseServiceImpl.add2CopadoLicense(request);
            Test.stopTest();

            List<Copado_License__c> updatedLicenses = [
                SELECT Id, Enable_Copado__c, Enable_CCM__c, Enable_CAD__c, Enable_CCH__c, Enable_ADD__c
                FROM Copado_License__c
            ];

            // Assertions
            System.assertEquals(true, updatedLicenses[0].Enable_Copado__c, 'The Copado license should be enabled.');
            System.assertEquals(true, updatedLicenses[0].Enable_CCM__c, 'The Copado license should be enabled.');
            System.assertEquals(true, updatedLicenses[0].Enable_CAD__c, 'The Copado license should be enabled.');
            System.assertEquals(true, updatedLicenses[0].Enable_CCH__c, 'The Copado license should be enabled.');
            System.assertEquals(true, updatedLicenses[0].Enable_ADD__c, 'The Copado license should be enabled.');
        }
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    private static void addPackageLicense() {
        System.runAs(getRunAsUser()) {
            // Setup
            Persona.AddLicenseRequest request = new Persona.AddLicenseRequest();
            request.personaId = getPersonaDefinition();
            request.licenses = new List<String>{ LicenseConstants.LICENSE_NAMES_BY_NAMESPACE.get(PackageNamespace.copado.name()) };

            // Exercise
            Test.startTest();
            AddLicenseServiceImpl.addPackageLicense(request);
            Test.stopTest();

            // Assertions
            // Can not put assertion based on package licenses since they will be available after manage package installation
        }
    }

    @SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts')
    @isTest
    private static void add2PackageLicense() {
        System.runAs(getRunAsUser()) {
            // Setup
            Persona.AddLicenseRequest request = new Persona.AddLicenseRequest();
            request.personaId = getPersonaDefinition();
            request.licenses = new List<String>{ LicenseConstants.LICENSE_NAMES_BY_NAMESPACE.get(PackageNamespace.copado.name()) };
            AddLicenseServiceImpl.addPackageLicense(request);

            // Exercise
            Test.startTest();

            AddLicenseServiceImpl.add2PackageLicense(request);
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
        copadoLicense.Enable_Copado__c = false;
        copadoLicense.Enable_CCM__c = false;
        copadoLicense.Enable_CAD__c = false;
        copadoLicense.Enable_CCH__c = false;
        copadoLicense.Enable_ADD__c = false;
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