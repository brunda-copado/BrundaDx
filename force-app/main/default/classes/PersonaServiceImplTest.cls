@IsTest
private with sharing class PersonaServiceImplTest {
    private static final String PERSONA_NAME = 'CopadoTest - Custom Developer';

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
    private static void createConfig() {
        System.runAs(getRunAsUser()) {
            // Setup
            Persona.CreateConfigRequest request = new Persona.CreateConfigRequest();
            request.personaName = PERSONA_NAME;

            // Exercise
            Test.startTest();
            Persona.CreateConfigResult result = PersonaServiceImpl.createConfig(request);
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
            Persona.CreateConfigResult result = PersonaServiceImpl.createConfig(request);

            Persona.CreateRecordRequest recordRequest = new Persona.CreateRecordRequest();
            recordRequest.personaName = PERSONA_NAME;
            recordRequest.personaConfig = result.personaConfig;
            recordRequest.isStandard = false;

            // Exercise
            Test.startTest();
            Persona.CreateRecordResult recordResult = PersonaServiceImpl.createRecord(recordRequest);
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
            Persona.CreateConfigResult result = PersonaServiceImpl.createConfig(request);

            Persona.CreateRecordRequest recordRequest = new Persona.CreateRecordRequest();
            recordRequest.personaName = PERSONA_NAME;
            recordRequest.personaConfig = result.personaConfig;
            recordRequest.isStandard = false;
            Persona.CreateRecordResult recordResult = PersonaServiceImpl.createRecord(recordRequest);

            Persona.DeletePersonaRequest deleteRequest = new Persona.DeletePersonaRequest();
            deleteRequest.personaId = recordResult.persona.Id;

            // Exercise
            Test.startTest();
            PersonaServiceImpl.deletePersona(deleteRequest);
            PersonaServiceImpl.deletePersona2(deleteRequest);
            PersonaServiceImpl.deletePersona3(deleteRequest);
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