@SuppressWarnings('PMD.CognitiveComplexity')
@IsTest
private with sharing class PersonaManagementServiceCtrlTest {
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
        }
    }

    @IsTest
    private static void checkUserPermissions() {
        System.runAs(getRunAsUser()) {
            // Exercise
            Test.startTest();
            Boolean userHasPermission = PersonaManagementServiceCtrl.checkUserPermissions();
            Test.stopTest();

            // Verify
            System.assertEquals(true, userHasPermission, 'User should have permission');
        }
    }

    @IsTest
    private static void getDefaultPersonas() {
        System.runAs(getRunAsUser()) {
            // Exercise
            Test.startTest();
            List<Default_Persona__mdt> personas = PersonaManagementServiceCtrl.getDefaultPersonas();
            Test.stopTest();

            // Verify
            // We will not verify anything, as metadata from the package can be returned so we will never be sure how many records we should assert
            System.assertNotEquals(null, personas, 'List should be returned');
        }
    }

    @IsTest
    private static void createDefaultPersonaConfig() {
        System.runAs(getRunAsUser()) {
            // Exercise
            Test.startTest();
            PersonaDefinitionConfig result = PersonaManagementServiceCtrl.createDefaultPersonaConfig('DeveloperTest');
            Test.stopTest();

            // Verify
            System.assertNotEquals(null, result, 'Config JSON should be returned');
            System.assertEquals(1, result.permissionSetGroups.size(), 'A Permission Set Group for the persona should be created');
            System.assertNotEquals(null, result.publicGroupId, 'A Group for the persona should be created');
        }
    }

    @IsTest
    private static void createDefaultPersonaRecord() {
        System.runAs(getRunAsUser()) {
            // Setup
            String personaName = 'DeveloperTest';
            PersonaDefinitionConfig result = PersonaManagementServiceCtrl.createDefaultPersonaConfig(personaName);

            // Exercise
            Test.startTest();
            Persona.CreateRecordResult recordResult = PersonaManagementServiceCtrl.createDefaultPersonaRecord(
                personaName,
                '',
                JSON.serialize(result)
            );
            Test.stopTest();

            // Verify
            System.assertNotEquals(null, recordResult.persona, 'Persona record should be created');
        }
    }

    @IsTest
    private static void checkDefaultPersonaUpdates() {
        System.runAs(getRunAsUser()) {
            // Exercise
            Test.startTest();
            PersonaManagementServiceCtrl.checkDefaultPersonaUpdates();
            Test.stopTest();

            // Verify
            System.assert(true, 'This is doing nothing for now');
        }
    }

    @IsTest
    private static void applyDefaultPersonaUpdates() {
        System.runAs(getRunAsUser()) {
            // Setup
            String personaName = 'DeveloperTest';

            // Exercise
            Test.startTest();
            PersonaManagementServiceCtrl.applyDefaultPersonaUpdates(personaName);
            Test.stopTest();

            // Verify
            System.assert(true, 'This is doing nothing for now');
        }
    }

    @IsTest
    private static void getPersonas() {
        System.runAs(getRunAsUser()) {
            // Exercise
            Test.startTest();
            List<Persona_Definition__c> personas = PersonaManagementServiceCtrl.getPersonas();
            Test.stopTest();

            // Verify
            System.assertEquals(0, personas.size(), 'No personas should be returned');
        }
    }

    @IsTest
    private static void getPersonaDefinitions() {
        System.runAs(getRunAsUser()) {
            // Setup
            String personaName = 'DeveloperTest';
            PersonaDefinitionConfig result = PersonaManagementServiceCtrl.createDefaultPersonaConfig(personaName);
            PersonaManagementServiceCtrl.createDefaultPersonaRecord(personaName, '', JSON.serialize(result));

            // Exercise
            Test.startTest();
            List<PersonaManagementServiceCtrl.PersonaDefinition> personas = PersonaManagementServiceCtrl.getPersonaDefinitions();
            Test.stopTest();

            // Verify
            System.assertEquals(true, personas.size() > 0, 'Personas should be returned');
        }
    }

    @IsTest
    private static void createCopyPersonaConfig() {
        System.runAs(getRunAsUser()) {
            // Exercise
            Test.startTest();
            PersonaDefinitionConfig result = PersonaManagementServiceCtrl.createCopyPersonaConfig('DeveloperTest', 'DeveloperTest');
            Test.stopTest();

            // Verify
            System.assertNotEquals(null, result, 'Config JSON should be returned');
            System.assertEquals(1, result.permissionSetGroups.size(), 'A Permission Set Group for the persona should be created');
            System.assertNotEquals(null, result.publicGroupId, 'A Group for the persona should be created');
        }
    }

    @IsTest
    private static void createCopyPersonaRecord() {
        System.runAs(getRunAsUser()) {
            // Setup
            String personaName = 'DeveloperTest';
            PersonaDefinitionConfig result = PersonaManagementServiceCtrl.createCopyPersonaConfig(personaName, personaName);

            // Exercise
            Test.startTest();
            Persona.CreateRecordResult recordResult = PersonaManagementServiceCtrl.createCopyPersonaRecord(personaName, '', JSON.serialize(result));
            Test.stopTest();

            // Verify
            System.assertNotEquals(null, recordResult.persona, 'Persona record should be created');
        }
    }

    @IsTest
    private static void editPersonaDescription() {
        System.runAs(getRunAsUser()) {
            // Setup
            String personaName = 'DeveloperTest';
            PersonaDefinitionConfig result = PersonaManagementServiceCtrl.createCopyPersonaConfig(personaName, personaName);
            Persona.CreateRecordResult recordResult = PersonaManagementServiceCtrl.createCopyPersonaRecord(personaName, '', JSON.serialize(result));

            // Exercise
            Test.startTest();
            PersonaManagementServiceCtrl.editPersonaDescription(recordResult.persona.Id, 'My description');
            Test.stopTest();

            // Verify
            Persona_Definition__c persona = [SELECT Description__c FROM Persona_Definition__c WHERE Id = :recordResult.persona.Id LIMIT 1];
            System.assertEquals('My description', persona.Description__c, 'Persona record should be updated with description');
        }
    }

    @IsTest
    private static void deletePersona() {
        System.runAs(getRunAsUser()) {
            // Setup
            String personaName = 'DeveloperTest';
            PersonaDefinitionConfig result = PersonaManagementServiceCtrl.createCopyPersonaConfig(personaName, personaName);
            Persona.CreateRecordResult recordResult = PersonaManagementServiceCtrl.createCopyPersonaRecord(personaName, '', JSON.serialize(result));

            // Exercise
            Test.startTest();
            PersonaManagementServiceCtrl.deletePersona(recordResult.persona.Id);
            PersonaManagementServiceCtrl.deletePersona2(recordResult.persona.Id);
            PersonaManagementServiceCtrl.deletePersona3(recordResult.persona.Id);
            Test.stopTest();

            // Verify
            List<Persona_Definition__c> personas = [SELECT Id FROM Persona_Definition__c];
            System.assertEquals(0, personas.size(), 'The persona record should be deleted');
        }
    }

    private static User getRunAsUser() {
        return [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' ORDER BY CreatedDate DESC LIMIT 1];
    }
}