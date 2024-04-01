@IsTest
private with sharing class PersonaManagementCredentialServiceTest {
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
    private static void getAllCredentials() {
        System.runAs(getRunAsUser()) {
            // Exercise
            Test.startTest();
            List<Org__c> credentials = PersonaManagementCredentialServiceCtrl.getCredentials();
            Test.stopTest();

            // Verify
            System.assertEquals(5, credentials.size(), 'All credentials should be returned');
        }
    }

    @IsTest
    private static void shareCredentials() {
        System.runAs(getRunAsUser()) {
            // Setup
            Persona_Definition__c personaDefinition = createPersona('Developer');
            List<Org__c> credentials = getCredentials();

            // Exercise
            Test.startTest();
            PersonaManagementCredentialServiceCtrl.shareCredentials(
                personaDefinition.Id,
                new List<String>((new Map<String, Org__c>(credentials)).keySet())
            );
            Test.stopTest();

            // Verify
            PersonaDefinitionConfig config = (PersonaDefinitionConfig) JSON.deserialize(
                personaDefinition.Config_Json__c,
                PersonaDefinitionConfig.class
            );
            List<Org__Share> orgShares = [SELECT Id FROM Org__Share WHERE UserOrGroupId = :config.publicGroupId];
            System.assertEquals(credentials.size(), orgShares.size(), 'Credentials should be shared with the public group');
            List<PersonaManagementCredentialServiceCtrl.PersonaCredential> personaCredentials = PersonaManagementCredentialServiceCtrl.getCredentialsForPersona(
                personaDefinition.Id
            );
            System.assertEquals(credentials.size(), personaCredentials.size(), 'Credentials should be shared with the public group');
        }
    }

    @IsTest
    private static void removeCredential() {
        System.runAs(getRunAsUser()) {
            // Setup
            Persona_Definition__c personaDefinition = createPersona('Developer');
            List<Org__c> credentials = getCredentials();
            Persona.ShareCredentialRequest request = new Persona.ShareCredentialRequest();
            request.credentialIds = new List<String>((new Map<String, Org__c>(credentials)).keySet());
            request.personaId = personaDefinition.Id;
            PersonaCredentialServiceImpl.share(request);

            List<Org__c> credentialsToRemove = new List<Org__c>();
            for (Integer i = 0; i < credentials.size() / 2; i++) {
                credentialsToRemove.add(credentials[i]);
            }

            // Exercise
            Test.startTest();
            PersonaManagementCredentialServiceCtrl.removeCredential(
                personaDefinition.Id,
                new List<String>((new Map<String, Org__c>(credentialsToRemove)).keySet())
            );
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
    private static void changeCredentialAccessLevel() {
        System.runAs(getRunAsUser()) {
            // Setup
            Persona_Definition__c personaDefinition = createPersona('Developer');
            List<Org__c> credentials = getCredentials();
            Persona.ShareCredentialRequest request = new Persona.ShareCredentialRequest();
            request.credentialIds = new List<String>((new Map<String, Org__c>(credentials)).keySet());
            request.personaId = personaDefinition.Id;
            PersonaCredentialServiceImpl.share(request);

            // Exercise
            Test.startTest();
            PersonaManagementCredentialServiceCtrl.changeCredentialAccessLevel(personaDefinition.Id, credentials[0].Id, 'Edit');
            Test.stopTest();

            // Verify
            PersonaDefinitionConfig config = (PersonaDefinitionConfig) JSON.deserialize(
                personaDefinition.Config_Json__c,
                PersonaDefinitionConfig.class
            );
            List<Org__Share> orgShares = [
                SELECT Id, AccessLevel
                FROM Org__Share
                WHERE UserOrGroupId = :config.publicGroupId AND ParentId = :credentials[0].Id
            ];
            System.assertEquals('Edit', orgShares[0].AccessLevel, 'Credentials should be shared with the correct access level');
        }
    }

    // PRIVATE

    private static User getRunAsUser() {
        return [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' ORDER BY CreatedDate DESC LIMIT 1];
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
        new Environment().name('dev1').type('Sandbox').platform('Other');
        new Environment().name('dev2').type('Sandbox').platform('Other');
        new Environment().name('int').type('Sandbox').platform('Other');
        new Environment().name('uat').type('Sandbox').platform('Other');
        new Environment().name('prod').type('Sandbox').platform('Other').persist();
    }
}