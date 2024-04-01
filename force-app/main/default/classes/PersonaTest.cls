@SuppressWarnings('PMD.CognitiveComplexity,PMD.CyclomaticComplexity')
@IsTest
private class PersonaTest {
    private static final String PERSONA_NAME = 'CopadoTestDeveloper';

    @TestSetup
    private static void setup() {
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

    @IsTest
    private static void share() {
        System.runAs(getRunAsUser()) {
            // Setup
            Persona_Definition__c personaDefinition = createPersona(PERSONA_NAME);
            List<Org__c> credentials = getCredentials();
            Persona.ShareCredentialRequest request = new Persona.ShareCredentialRequest();
            request.credentialIds = new List<String>((new Map<String, Org__c>(credentials)).keySet());
            request.personaId = personaDefinition.Id;

            // Exercise
            Test.startTest();
            Persona.CredentialService.share(request);
            Test.stopTest();

            // Verify
            PersonaDefinitionConfig config = (PersonaDefinitionConfig) JSON.deserialize(
                personaDefinition.Config_Json__c,
                PersonaDefinitionConfig.class
            );
            List<Org__Share> orgShares = [SELECT Id FROM Org__Share WHERE UserOrGroupId = :config.publicGroupId];
            System.assertEquals(credentials.size(), orgShares.size(), 'Credentials should be shared with the public group');
        }
    }

    @IsTest
    private static void remove() {
        System.runAs(getRunAsUser()) {
            // Setup
            Persona_Definition__c personaDefinition = createPersona(PERSONA_NAME);
            List<Org__c> credentials = getCredentials();
            Persona.ShareCredentialRequest request = new Persona.ShareCredentialRequest();
            request.credentialIds = new List<String>((new Map<String, Org__c>(credentials)).keySet());
            request.personaId = personaDefinition.Id;
            PersonaCredentialServiceImpl.share(request);

            Persona.RemoveCredentialRequest removeRequest = new Persona.RemoveCredentialRequest();
            removeRequest.personaId = personaDefinition.Id;
            List<Org__c> credentialsToRemove = new List<Org__c>();
            for (Integer i = 0; i < credentials.size() / 2; i++) {
                credentialsToRemove.add(credentials[i]);
            }
            removeRequest.credentialIds = new List<String>((new Map<String, Org__c>(credentialsToRemove)).keySet());

            // Exercise
            Test.startTest();
            Persona.CredentialService.remove(removeRequest);
            Test.stopTest();

            // Verify
            PersonaDefinitionConfig config = (PersonaDefinitionConfig) JSON.deserialize(
                personaDefinition.Config_Json__c,
                PersonaDefinitionConfig.class
            );
            List<Org__Share> orgShares = [SELECT Id FROM Org__Share WHERE UserOrGroupId = :config.publicGroupId];
            System.assertEquals(
                credentials.size() - credentialsToRemove.size(),
                orgShares.size(),
                'Credentials should be shared with the public group'
            );
        }
    }

    @IsTest
    private static void updateAccessLevel() {
        System.runAs(getRunAsUser()) {
            // Setup
            Persona_Definition__c personaDefinition = createPersona(PERSONA_NAME);
            List<Org__c> credentials = getCredentials();
            Persona.ShareCredentialRequest request = new Persona.ShareCredentialRequest();
            request.credentialIds = new List<String>((new Map<String, Org__c>(credentials)).keySet());
            request.personaId = personaDefinition.Id;
            PersonaCredentialServiceImpl.share(request);

            Persona.UpdateAccessLevelRequest updateRequest = new Persona.UpdateAccessLevelRequest();
            updateRequest.personaId = personaDefinition.Id;
            updateRequest.credentialIds = new List<String>((new Map<String, Org__c>(credentials)).keySet());
            updateRequest.accessLevel = 'Edit';

            // Exercise
            Test.startTest();
            Persona.CredentialService.updateAccessLevel(updateRequest);
            Test.stopTest();

            // Verify
            PersonaDefinitionConfig config = (PersonaDefinitionConfig) JSON.deserialize(
                personaDefinition.Config_Json__c,
                PersonaDefinitionConfig.class
            );
            List<Org__Share> orgShares = [SELECT Id, AccessLevel FROM Org__Share WHERE UserOrGroupId = :config.publicGroupId];
            System.assertEquals(credentials.size(), orgShares.size(), 'Credentials should be shared with the public group');
            System.assertEquals('Edit', orgShares[0].AccessLevel, 'Credentials should be shared with the correct access level');
        }
    }

    @IsTest
    private static void createConfig() {
        System.runAs(getRunAsUser()) {
            // Setup
            Persona.CreateConfigRequest request = new Persona.CreateConfigRequest();
            request.personaName = PERSONA_NAME;

            // Exercise
            Test.startTest();
            Persona.CreateConfigResult result = Persona.createConfig(request);
            Test.stopTest();

            // Verify
            System.assertNotEquals(null, result.personaConfig, 'Config JSON should be returned');
            System.assertEquals(1, result.personaConfig.permissionSetGroups.size(), 'A Permission Set Group for the persona should be created');
            System.assertNotEquals(null, result.personaConfig.publicGroupId, 'A Group for the persona should be created');
        }
    }

    @IsTest
    private static void createRecord() {
        System.runAs(getRunAsUser()) {
            // Setup
            Persona.CreateConfigRequest request = new Persona.CreateConfigRequest();
            request.personaName = PERSONA_NAME;
            Persona.CreateConfigResult result = Persona.createConfig(request);

            Persona.CreateRecordRequest recordRequest = new Persona.CreateRecordRequest();
            recordRequest.personaName = PERSONA_NAME;
            recordRequest.personaConfig = result.personaConfig;
            recordRequest.isStandard = false;

            // Exercise
            Test.startTest();
            Persona.CreateRecordResult recordResult = Persona.createRecord(recordRequest);
            Test.stopTest();

            // Verify
            System.assertNotEquals(null, recordResult.persona, 'Persona record should be created');
        }
    }

    @IsTest
    private static void deletePersona() {
        System.runAs(getRunAsUser()) {
            // Setup
            Persona.CreateConfigRequest request = new Persona.CreateConfigRequest();
            request.personaName = PERSONA_NAME;
            Persona.CreateConfigResult result = Persona.createConfig(request);

            Persona.CreateRecordRequest recordRequest = new Persona.CreateRecordRequest();
            recordRequest.personaName = PERSONA_NAME;
            recordRequest.personaConfig = result.personaConfig;
            recordRequest.isStandard = false;
            Persona.CreateRecordResult recordResult = Persona.createRecord(recordRequest);

            Persona.DeletePersonaRequest deleteRequest = new Persona.DeletePersonaRequest();
            deleteRequest.personaId = recordResult.persona.Id;

            // Exercise
            Test.startTest();
            Persona.deletePersona(deleteRequest);
            Persona.deletePersona2(deleteRequest);
            Persona.deletePersona3(deleteRequest);
            Test.stopTest();

            // Verify
            List<Persona_Definition__c> personas = [SELECT Id FROM Persona_Definition__c WHERE Name = :PERSONA_NAME];
            System.assertEquals(0, personas.size(), 'The persona record should be deleted');
        }
    }

    @IsTest
    private static void deletePersonaFailure() {
        System.runAs(getRunAsUser()) {
            // Setup
            Persona.CreateConfigRequest request = new Persona.CreateConfigRequest();
            request.personaName = PERSONA_NAME;
            Persona.CreateConfigResult result = Persona.createConfig(request);

            Persona.CreateRecordRequest recordRequest = new Persona.CreateRecordRequest();
            recordRequest.personaName = PERSONA_NAME;
            recordRequest.personaConfig = result.personaConfig;
            recordRequest.isStandard = false;
            Persona.createRecord(recordRequest);

            Persona.DeletePersonaRequest deleteRequest = new Persona.DeletePersonaRequest();
            deleteRequest.personaId = getRunAsUser().Id; // Use an invalid Id to simulate failure

            // Exercise
            Boolean jobIsSuccess = false;
            Test.startTest();
            try {
                Persona.deletePersona(deleteRequest);
                Persona.deletePersona2(deleteRequest);
                Persona.deletePersona3(deleteRequest);
                jobIsSuccess = true;
            } catch (Exception e) {
                jobIsSuccess = false;
            }
            Test.stopTest();

            // Assertions
            System.assertEquals(false, jobIsSuccess, 'Expected ApplicationException was thrown.');  
        }
    }

    @IsTest
    private static void addLicenseSuccess() {
        System.runAs(getRunAsUser()) {
            // Setup
            Persona.AddLicenseRequest request = new Persona.AddLicenseRequest();
            request.personaId = getPersonaDefinition();
            request.licenses = new List<String>{ LicenseConstants.EE_LICENSES_ENABLED, LicenseConstants.CCM_LICENSES_ENABLED };

            // Exercise
            Boolean jobIsSuccess = false;
            Test.startTest();
            try {
                Persona.LicenseService.addCopadoLicense(request);
                Persona.LicenseService.add2CopadoLicense(request);
                jobIsSuccess = true;
            } catch (Exception e) {
                jobIsSuccess = false;
            }
            Test.stopTest();

            // Assertions
            System.assertEquals(true, jobIsSuccess, 'License added successfully.');
        }
    }

    @IsTest
    private static void addLicenseFailure() {
        System.runAs(getRunAsUser()) {
            // Setup
            Persona.AddLicenseRequest request = new Persona.AddLicenseRequest();
            request.personaId = getRunAsUser().Id; // Use an invalid Id to simulate failure
            request.licenses = new List<String>{ 'InvalidLicense' };

            // Exercise
            Boolean jobIsSuccess = false;
            Test.startTest();
            try {
                Persona.LicenseService.addCopadoLicense(request);
                Persona.LicenseService.add2CopadoLicense(request);
                jobIsSuccess = true;
            } catch (Exception e) {
                jobIsSuccess = false;
            }
            Test.stopTest();

            // Assertions
            System.assertEquals(false, jobIsSuccess, 'Expected ApplicationException was thrown.');
        }
    }

    @IsTest
    private static void add2LicenseFailure() {
        System.runAs(getRunAsUser()) {
            // Setup
            Persona.AddLicenseRequest request = new Persona.AddLicenseRequest();
            request.personaId = getRunAsUser().Id; // Use an invalid Id to simulate failure
            request.licenses = new List<String>{ 'InvalidLicense' };

            // Exercise
            Boolean jobIsSuccess = false;
            Test.startTest();
            try {
                Persona.LicenseService.add2CopadoLicense(request);
                jobIsSuccess = true;
            } catch (Exception e) {
                jobIsSuccess = false;
            }
            Test.stopTest();

            // Assertions
            System.assertEquals(false, jobIsSuccess, 'Expected ApplicationException was thrown.');
        }
    }

    @IsTest
    private static void addPackageLicenseSuccess() {
        System.runAs(getRunAsUser()) {
            // Setup
            Persona.AddLicenseRequest request = new Persona.AddLicenseRequest();
            request.personaId = getPersonaDefinition();
            request.licenses = new List<String>{ LicenseConstants.LICENSE_NAMES_BY_NAMESPACE.get(PackageNamespace.copado.name()) };

            // Exercise
            Boolean jobIsSuccess = false;
            Test.startTest();
            try {
                Persona.LicenseService.addPackageLicense(request);
                Persona.LicenseService.add2PackageLicense(request);
                jobIsSuccess = true;
            } catch (Exception e) {
                jobIsSuccess = false;
            }
            Test.stopTest();

            // Assertions
            System.assertEquals(true, jobIsSuccess, 'License added successfully.');
        }
    }

    @IsTest
    private static void addPackageLicenseFailure() {
        System.runAs(getRunAsUser()) {
            // Setup
            Persona.AddLicenseRequest request = new Persona.AddLicenseRequest();
            request.personaId = getRunAsUser().Id; // Use an invalid Id to simulate failure
            request.licenses = new List<String>{ 'InvalidLicense' };

            // Exercise
            Boolean jobIsSuccess = false;
            Test.startTest();
            try {
                Persona.LicenseService.addPackageLicense(request);
                Persona.LicenseService.add2PackageLicense(request);
                jobIsSuccess = true;
            } catch (Exception e) {
                jobIsSuccess = false;
            }
            Test.stopTest();

            // Assertions
            System.assertEquals(false, jobIsSuccess, 'Expected ApplicationException was thrown.');
        }
    }

    @IsTest
    private static void add2PackageLicenseFailure() {
        System.runAs(getRunAsUser()) {
            // Setup
            Persona.AddLicenseRequest request = new Persona.AddLicenseRequest();
            request.personaId = getRunAsUser().Id; // Use an invalid Id to simulate failure
            request.licenses = new List<String>{ 'InvalidLicense' };

            // Exercise
            Boolean jobIsSuccess = false;
            Test.startTest();
            try {
                Persona.LicenseService.add2PackageLicense(request);
                jobIsSuccess = true;
            } catch (Exception e) {
                jobIsSuccess = false;
            }
            Test.stopTest();

            // Assertions
            System.assertEquals(false, jobIsSuccess, 'Expected ApplicationException was thrown.');
        }
    }


    @IsTest
    private static void removeLicenseSuccess() {
        System.runAs(getRunAsUser()) {
            // Setup
            Persona.RemoveLicenseRequest request = new Persona.RemoveLicenseRequest();
            request.personaId = getPersonaDefinition(); // Use a valid Id
            request.licenses = new List<String>{ LicenseConstants.EE_LICENSES_ENABLED, LicenseConstants.CCM_LICENSES_ENABLED };

            // Exercise
            Boolean jobIsSuccess = false;
            Test.startTest();
            try {
                Persona.LicenseService.removeCopadoLicense(request);
                Persona.LicenseService.remove2CopadoLicense(request);
                jobIsSuccess = true;
            } catch (Exception e) {
                jobIsSuccess = false;
            }
            Test.stopTest();

            // Assertions
            System.assertEquals(true, jobIsSuccess, 'License removed successfully.');
        }
    }

    @IsTest
    private static void removeLicenseFailure() {
        System.runAs(getRunAsUser()) {
            // Setup
            Persona.RemoveLicenseRequest request = new Persona.RemoveLicenseRequest();
            request.personaId = getRunAsUser().Id; // Use an invalid Id to simulate failure
            request.licenses = new List<String>{ 'InvalidLicense' };

            // Exercise
            Boolean jobIsSuccess = false;
            Test.startTest();
            try {
                Persona.LicenseService.removeCopadoLicense(request);
                Persona.LicenseService.remove2CopadoLicense(request);
                jobIsSuccess = true;
            } catch (Exception e) {
                jobIsSuccess = false;
            }
            Test.stopTest();

            // Assertions
            System.assertEquals(false, jobIsSuccess, 'Expected ApplicationException was thrown.');
        }
    }

    @IsTest
    private static void remove2LicenseFailure() {
        System.runAs(getRunAsUser()) {
            // Setup
            Persona.RemoveLicenseRequest request = new Persona.RemoveLicenseRequest();
            request.personaId = getRunAsUser().Id; // Use an invalid Id to simulate failure
            request.licenses = new List<String>{ 'InvalidLicense' };

            // Exercise
            Boolean jobIsSuccess = false;
            Test.startTest();
            try {
                Persona.LicenseService.remove2CopadoLicense(request);
                jobIsSuccess = true;
            } catch (Exception e) {
                jobIsSuccess = false;
            }
            Test.stopTest();

            // Assertions
            System.assertEquals(false, jobIsSuccess, 'Expected ApplicationException was thrown.');
        }
    }


    @IsTest
    private static void removePackageLicenseSuccess() {
        System.runAs(getRunAsUser()) {
            // Setup
            Persona.RemoveLicenseRequest request = new Persona.RemoveLicenseRequest();
            request.personaId = getPersonaDefinition(); // Use a valid Id
            request.licenses = new List<String>{ LicenseConstants.LICENSE_NAMES_BY_NAMESPACE.get(PackageNamespace.copado.name()) };

            // Exercise
            Boolean jobIsSuccess = false;
            Test.startTest();
            try {
                Persona.LicenseService.removePackageLicense(request);
                Persona.LicenseService.remove2PackageLicense(request);
                jobIsSuccess = true;
            } catch (Exception e) {
                jobIsSuccess = false;
            }
            Test.stopTest();

            // Assertions
            System.assertEquals(true, jobIsSuccess, 'License removed successfully.');
        }
    }

    @IsTest
    private static void removePackageLicenseFailure() {
        System.runAs(getRunAsUser()) {
            // Setup
            Persona.RemoveLicenseRequest request = new Persona.RemoveLicenseRequest();
            request.personaId = getRunAsUser().Id; // Use an invalid Id to simulate failure
            request.licenses = new List<String>{ 'InvalidLicense' };

            // Exercise
            Boolean jobIsSuccess = false;
            Test.startTest();
            try {
                Persona.LicenseService.removePackageLicense(request);
                Persona.LicenseService.remove2PackageLicense(request);
                jobIsSuccess = true;
            } catch (Exception e) {
                jobIsSuccess = false;
            }
            Test.stopTest();

            // Assertions
            System.assertEquals(false, jobIsSuccess, 'Expected ApplicationException was thrown.');
        }
    }

    @IsTest
    private static void remove2PackageLicenseFailure() {
        System.runAs(getRunAsUser()) {
            // Setup
            Persona.RemoveLicenseRequest request = new Persona.RemoveLicenseRequest();
            request.personaId = getRunAsUser().Id; // Use an invalid Id to simulate failure
            request.licenses = new List<String>{ 'InvalidLicense' };

            // Exercise
            Boolean jobIsSuccess = false;
            Test.startTest();
            try {
                Persona.LicenseService.remove2PackageLicense(request);
                jobIsSuccess = true;
            } catch (Exception e) {
                jobIsSuccess = false;
            }
            Test.stopTest();

            // Assertions
            System.assertEquals(false, jobIsSuccess, 'Expected ApplicationException was thrown.');
        }
    }

    @IsTest
    private static void addUserSuccess() {
        System.runAs(getRunAsUser()) {
            // Setup
            Persona.CreateConfigRequest request = new Persona.CreateConfigRequest();
            request.personaName = PERSONA_NAME;
            Persona.CreateConfigResult result = Persona.createConfig(request);

            Persona.CreateRecordRequest recordRequest = new Persona.CreateRecordRequest();
            recordRequest.personaName = PERSONA_NAME;
            recordRequest.personaConfig = result.personaConfig;
            recordRequest.isStandard = false;
            Persona.CreateRecordResult recordResult = Persona.createRecord(recordRequest);

            PermissionSetGroup permissionSetGroup = [
                SELECT Id
                FROM PermissionSetGroup
                WHERE DeveloperName = :result.personaConfig.getPersonaPermissionSetGroup()
                LIMIT 1
            ];
            Test.calculatePermissionSetGroup(permissionSetGroup.Id);

            Persona.AddUserRequest userRequest = new Persona.AddUserRequest();
            userRequest.personaId = recordResult.persona.Id;
            userRequest.userIds = new List<Id>{ UserInfo.getUserId() };

            // Exercise
            Boolean jobIsSuccess = false;
            Test.startTest();
            try {
                Persona.UserService.add(userRequest);
                Persona.UserService.add2(userRequest);
                Persona.UserService.add3(userRequest);
                jobIsSuccess = true;
            } catch (Exception e) {
                jobIsSuccess = false;
            }
            Test.stopTest();

            // Verify
            System.assertEquals(true, jobIsSuccess, 'User added successfully.');
        }
    }

    @IsTest
    private static void addUserFailure() {
        System.runAs(getRunAsUser()) {
            // Setup
            Persona.CreateConfigRequest request = new Persona.CreateConfigRequest();
            request.personaName = PERSONA_NAME;
            Persona.CreateConfigResult result = Persona.createConfig(request);

            Persona.CreateRecordRequest recordRequest = new Persona.CreateRecordRequest();
            recordRequest.personaName = PERSONA_NAME;
            recordRequest.personaConfig = result.personaConfig;
            recordRequest.isStandard = false;
            Persona.createRecord(recordRequest);

            PermissionSetGroup permissionSetGroup = [
                SELECT Id
                FROM PermissionSetGroup
                WHERE DeveloperName = :result.personaConfig.getPersonaPermissionSetGroup()
                LIMIT 1
            ];
            Test.calculatePermissionSetGroup(permissionSetGroup.Id);

            Persona.AddUserRequest userRequest = new Persona.AddUserRequest();
            userRequest.personaId = getRunAsUser().Id; // Use an invalid Id to simulate failure
            userRequest.userIds = new List<Id>{ UserInfo.getUserId() };

            // Exercise
            Boolean jobIsSuccess = false;
            Test.startTest();
            try {
                Persona.UserService.add(userRequest);
                jobIsSuccess = true;
            } catch (Exception e) {
                jobIsSuccess = false;
            }
            Test.stopTest();

            // Verify
            System.assertEquals(false, jobIsSuccess, 'Expected ApplicationException was thrown.');
        }
    }

    @IsTest
    private static void removeUserSuccess() {
        System.runAs(getRunAsUser()) {
            // Setup
            Persona.CreateConfigRequest request = new Persona.CreateConfigRequest();
            request.personaName = PERSONA_NAME;
            Persona.CreateConfigResult result = Persona.createConfig(request);

            Persona.CreateRecordRequest recordRequest = new Persona.CreateRecordRequest();
            recordRequest.personaName = PERSONA_NAME;
            recordRequest.personaConfig = result.personaConfig;
            recordRequest.isStandard = false;
            Persona.CreateRecordResult recordResult = Persona.createRecord(recordRequest);

            PermissionSetGroup permissionSetGroup = [
                SELECT Id
                FROM PermissionSetGroup
                WHERE DeveloperName = :result.personaConfig.getPersonaPermissionSetGroup()
                LIMIT 1
            ];
            Test.calculatePermissionSetGroup(permissionSetGroup.Id);

            Persona.AddUserRequest userRequest = new Persona.AddUserRequest();
            userRequest.personaId = recordResult.persona.Id;
            userRequest.userIds = new List<Id>{ UserInfo.getUserId() };
            PersonaUserServiceImpl.add(userRequest);
            PersonaUserServiceImpl.add2(userRequest);
            PersonaUserServiceImpl.add3(userRequest);

            Persona.RemoveUserRequest removeUserRequest = new Persona.RemoveUserRequest();
            removeUserRequest.personaId = recordResult.persona.Id;
            removeUserRequest.userIds = new List<Id>{ UserInfo.getUserId() };
            PersonaUserServiceImpl.remove(removeUserRequest);
            PersonaUserServiceImpl.remove2(removeUserRequest);
            PersonaUserServiceImpl.remove3(removeUserRequest);

            // Exercise
            Boolean jobIsSuccess = false;
            Test.startTest();
            try {
                Persona.UserService.remove(removeUserRequest);
                Persona.UserService.remove2(removeUserRequest);
                Persona.UserService.remove3(removeUserRequest);
                jobIsSuccess = true;
            } catch (Exception e) {
                jobIsSuccess = false;
            }
            Test.stopTest();

            // Verify
            System.assertEquals(true, jobIsSuccess, 'User removed successfully.');
        }
    }

    @IsTest
    private static void addPermissionSuccess() {
        System.runAs(getRunAsUser()) {
            // Setup
            Persona.AddPermissionRequest request = new Persona.AddPermissionRequest();
            request.personaId = getPersonaDefinition();
            request.permissionSetGroups = new List<String>{ 'TESTPSG1' };

            // Exercise
            Boolean jobIsSuccess = false;
            Test.startTest();
            try {
                Persona.PermissionService.add(request);
                Persona.PermissionService.add2(request);
                jobIsSuccess = true;
            } catch (Exception e) {
                jobIsSuccess = false;
            }
            Test.stopTest();

            // Assertions
            System.assertEquals(true, jobIsSuccess, 'Permission added successfully.');
        }
    }

    @IsTest
    private static void addPermissionFailure() {
        System.runAs(getRunAsUser()) {
            // Setup
            Persona.AddPermissionRequest request = new Persona.AddPermissionRequest();
            request.personaId = getRunAsUser().Id; // Use an invalid Id to simulate failure
            request.permissionSetGroups = new List<String>{ 'TESTPSG1' };

            // Exercise
            Boolean jobIsSuccess = false;
            Test.startTest();
            try {
                Persona.PermissionService.add(request);
                Persona.PermissionService.add2(request);
                jobIsSuccess = true;
            } catch (Exception e) {
                jobIsSuccess = false;
            }
            Test.stopTest();

            // Assertions
            System.assertEquals(false, jobIsSuccess, 'Expected ApplicationException was thrown.');
        }
    }

    @IsTest
    private static void removePermissionSuccess() {
        System.runAs(getRunAsUser()) {
            // Setup
            Persona.RemovePermissionRequest request = new Persona.RemovePermissionRequest();
            request.personaId = getPersonaDefinition(); // Use a valid Id
            Persona.Permission permission = new Persona.Permission();
            permission.type = 'Permission Set Group';
            permission.name = 'TESTPSG2';
            request.permissions = new List<Persona.Permission>{ permission };

            // Exercise
            Boolean jobIsSuccess = false;
            Test.startTest();
            try {
                Persona.PermissionService.remove(request);
                Persona.PermissionService.remove2(request);
                jobIsSuccess = true;
            } catch (Exception e) {
                jobIsSuccess = false;
            }
            Test.stopTest();

            // Assertions
            System.assertEquals(true, jobIsSuccess, 'Permission removed successfully.');
        }
    }

    @IsTest
    private static void removePermissionFailure() {
        System.runAs(getRunAsUser()) {
            // Setup
            Persona.RemovePermissionRequest request = new Persona.RemovePermissionRequest();
            request.personaId = getRunAsUser().Id; // Use an invalid Id to simulate failure
            Persona.Permission permission = new Persona.Permission();
            permission.type = 'Permission Set Group';
            permission.name = 'InvalidPSG';
            request.permissions = new List<Persona.Permission>{ permission };

            // Exercise
            Boolean jobIsSuccess = false;
            Test.startTest();
            try {
                Persona.PermissionService.remove(request);
                Persona.PermissionService.remove2(request);
                jobIsSuccess = true;
            } catch (Exception e) {
                jobIsSuccess = false;
            }
            Test.stopTest();

            // Assertions
            System.assertEquals(false, jobIsSuccess, 'Expected ApplicationException was thrown.');
        }
    }

    private static User getRunAsUser() {
        return [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' ORDER BY CreatedDate DESC LIMIT 1];
    }

    private static Id getPersonaDefinition() {
        return [SELECT Id FROM Persona_Definition__c LIMIT 1].Id;
    }

    private static PermissionSetGroup getPermissionSetGroup(String name) {
        return [SELECT Id, Status FROM PermissionSetGroup WHERE DeveloperName = :name];
    }

    private static List<Org__c> getCredentials() {
        return [SELECT Id FROM Org__c];
    }

    private static Persona_Definition__c createPersona(String name) {
        Group personaGroup = new Group(Name = name, Type = 'Regular');
        insert personaGroup;
        PersonaDefinitionConfig config = new PersonaDefinitionConfig();
        config.publicGroupId = personaGroup.Id;
        Persona_Definition__c persona = new Persona_Definition__c(Name = name, Config_Json__c = JSON.serialize(config));
        insert persona;
        return persona;
    }

    private static void createData() {
        createPermissionSetGroup('TESTPSG1', 'TEST PSG1');

        PermissionSetGroup psg = createPermissionSetGroup('TESTPSG2', 'TEST PSG2');
        insert new PermissionSetAssignment(PermissionSetGroupId = psg.Id, AssigneeId = getRunAsUser().Id);

        Group testGroup = new Group(Name = 'Test Group', Type = 'Regular');
        insert testGroup;

        GroupMember testGroupMember = new GroupMember(GroupId = testGroup.Id, UserOrGroupId = getRunAsUser().Id);
        insert testGroupMember;

        PersonaDefinitionConfig config = new PersonaDefinitionConfig();
        config.publicGroupId = testGroup.Id;
        config.licenses = new List<PersonaDefinitionConfig.ConfigEntry>();
        config.permissionSetGroups = new List<PersonaDefinitionConfig.ConfigEntry>();
        config.permissionSetGroups.add(new PersonaDefinitionConfig.ConfigEntry().name('TESTPSG1'));
        config.permissionSetGroups.add(new PersonaDefinitionConfig.ConfigEntry().name('TESTPSG2'));
        config.permissionSets.add(new PersonaDefinitionConfig.ConfigEntry().name('TESTPSG1PS'));

        Persona_Definition__c personaDef = new Persona_Definition__c(Config_JSON__c = JSON.serialize(config));
        insert personaDef;

        Copado_License__c copadoLicense = Copado_License__c.getInstance(getRunAsUser().Id);
        copadoLicense.Enable_Copado__c = false;
        copadoLicense.Enable_CCM__c = false;
        copadoLicense.Enable_CST__c = false;
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

        new Environment().name('dev1').type('Sandbox').platform('Other').add(new Credential());
        new Environment().name('dev2').type('Sandbox').platform('Other').add(new Credential());
        new Environment().name('int').type('Sandbox').platform('Other').add(new Credential());
        new Environment().name('uat').type('Sandbox').platform('Other').add(new Credential());
        new Environment().name('prod').type('Sandbox').platform('Other').add(new Credential()).persist();
    }

    private static PermissionSetGroup createPermissionSetGroup(String name, String label) {
        PermissionSet ps = new PermissionSet();
        ps.label = label + 'PS';
        ps.name = name + 'PS';
        ps.PermissionsRunFlow = true;
        insert ps;

        ObjectPermissions op = new ObjectPermissions();
        op.parentid = ps.Id;
        op.permissionscreate = true;
        op.permissionsdelete = true;
        op.permissionsedit = true;
        op.permissionsread = true;
        op.sobjecttype = 'pushtopic';
        insert op;

        PermissionSetGroup psg = new PermissionSetGroup();
        psg.developername = name;
        psg.masterlabel = label;
        insert psg;

        PermissionSetGroupComponent psgc = new PermissionSetGroupComponent();
        psgc.PermissionSetGroupId = psg.Id;
        psgc.PermissionSetId = ps.Id;
        insert psgc;

        psg = getPermissionSetGroup(name);

        // force calculation of the PSG if it is not already Updated
        if (psg.Status != 'Updated') {
            Test.calculatePermissionSetGroup(psg.Id);
        }

        return psg;
    }
}