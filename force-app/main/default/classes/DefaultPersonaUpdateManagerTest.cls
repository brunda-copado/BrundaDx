@isTest
private class DefaultPersonaUpdateManagerTest {
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
    private static void checkDefaultPersonaUpdates() {
        System.runAs(getRunAsUser()) {
            // Setup
            Persona_Definition__c personaDefinition = new Persona_Definition__c(
                Name = 'TestPersona',
                Config_JSON__c = '{"assignedPermissionSetGroups":["TestGroup"],"licenses":["TestLicense"],"defaultCredentialAccessLevel":"TestAccessLevel"}'
            );
            insert personaDefinition;

            DefaultPersonaUpdateManager manager = new DefaultPersonaUpdateManager();
            manager.mock(mockPersonas());

            // Exercise
            Test.startTest();

            List<String> personasToUpdate = manager.checkForUpdates();
            Test.stopTest();

            // Verify
            System.assertEquals(false, personasToUpdate.isEmpty(), 'Updates were flagged as needed.');
        }
    }

    @IsTest
    private static void applyDefaultPersonaUpdates() {
        System.runAs(getRunAsUser()) {
            // Setup
            Persona_Definition__c personaDefinition = new Persona_Definition__c(
                Name = 'TestPersona',
                Config_JSON__c = '{"assignedPermissionSetGroups":["TestGroup"],"licenses":["TestLicense"],"defaultCredentialAccessLevel":"TestAccessLevel"}'
            );
            insert personaDefinition;

            DefaultPersonaUpdateManager manager = new DefaultPersonaUpdateManager();
            List<Default_Persona__mdt> mock = mockPersonas();
            manager.mock(mock);

            // Exercise
            Test.startTest();
            DefaultPersonaUpdateManager.ApplyUpdatesResult result = manager.applyUpdates(mock[0].MasterLabel);
            Test.stopTest();

            // Verify
            System.assertNotEquals(null, result.defaultPersonaToCreate, 'New Personas are added.');
        }
    }

    // PRIVATE

    private static User getRunAsUser() {
        return [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' ORDER BY CreatedDate DESC LIMIT 1];
    }

    private static List<Default_Persona__mdt> mockPersonas() {
        DateTime currentDateTime = System.now();
        return new List<Default_Persona__mdt>{
            new Default_Persona__mdt(
                MasterLabel = 'DefaultPersonaTest1 ' + currentDateTime,
                DeveloperName = 'DefaultPersonaTest1' + currentDateTime,
                Description__c = 'DefaultPersonaTest1 Description'
            ),
            new Default_Persona__mdt(
                MasterLabel = 'DefaultPersonaTest2 ' + currentDateTime,
                DeveloperName = 'DefaultPersonaTest2' + currentDateTime,
                Description__c = 'DefaultPersonaTest2 Description'
            )
        };
    }
}