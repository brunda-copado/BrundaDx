@IsTest
private with sharing class PersonaUserServiceImplTest {
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
        }
    }

    @IsTest
    private static void addUser() {
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

            Persona.AddUserRequest userRequest = new Persona.AddUserRequest();
            userRequest.personaId = recordResult.persona.Id;
            userRequest.userIds = new List<Id>{ UserInfo.getUserId() };

            PermissionSetGroup permissionSetGroup = [
                SELECT Id
                FROM PermissionSetGroup
                WHERE DeveloperName = :result.personaConfig.getPersonaPermissionSetGroup()
                LIMIT 1
            ];
            Test.calculatePermissionSetGroup(permissionSetGroup.Id);

            // Exercise
            Test.startTest();
            PersonaUserServiceImpl.add(userRequest);
            PersonaUserServiceImpl.add2(userRequest);
            PersonaUserServiceImpl.add3(userRequest);
            Test.stopTest();

            // Verify
            User updatedUser = [SELECT Id, Persona_Id__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            System.assertEquals(recordResult.persona.Id, updatedUser.Persona_Id__c, 'User record should be linked to persona record');
            Boolean userInGroup = [SELECT COUNT() FROM GroupMember WHERE Group.Name = :PERSONA_NAME AND UserOrGroupId = :UserInfo.getUserId()] > 0;
            System.assertEquals(true, userInGroup, 'User should be part of the public group of the persona');
            Boolean permissionSetGroupAssigned =
                [
                    SELECT COUNT()
                    FROM PermissionSetAssignment
                    WHERE
                        PermissionSetGroupId IN (SELECT Id FROM PermissionSetGroup WHERE DeveloperName = :result.personaConfig.getPersonaPermissionSetGroup())
                        AND AssigneeId = :UserInfo.getUserId()
                ] > 0;
            System.assertEquals(true, permissionSetGroupAssigned, 'Permission Set Group of the persona should be assigned to the user');
        }
    }

    @IsTest
    private static void removeUser() {
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

            // Exercise
            Test.startTest();
            Persona.RemoveUserRequest removeUserRequest = new Persona.RemoveUserRequest();
            removeUserRequest.personaId = recordResult.persona.Id;
            removeUserRequest.userIds = new List<Id>{ UserInfo.getUserId() };
            PersonaUserServiceImpl.remove(removeUserRequest);
            PersonaUserServiceImpl.remove2(removeUserRequest);
            PersonaUserServiceImpl.remove3(removeUserRequest);
            Test.stopTest();

            // Verify
            User updatedUser = [SELECT Id, Persona_Id__c FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
            System.assertEquals(null, updatedUser.Persona_Id__c, 'User record should not be linked to persona record');
            Boolean userInGroup = [SELECT COUNT() FROM GroupMember WHERE Group.Name = :PERSONA_NAME AND UserOrGroupId = :UserInfo.getUserId()] > 0;
            System.assertEquals(false, userInGroup, 'User should not be part of the public group of the persona');
            Boolean permissionSetGroupAssigned =
                [
                    SELECT COUNT()
                    FROM PermissionSetAssignment
                    WHERE
                        PermissionSetGroupId IN (SELECT Id FROM PermissionSetGroup WHERE DeveloperName = :PERSONA_NAME)
                        AND AssigneeId = :UserInfo.getUserId()
                ] > 0;
            System.assertEquals(false, permissionSetGroupAssigned, 'Permission Set Group of the persona should not be assigned to the user');
        }
    }

    private static User getRunAsUser() {
        return [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' ORDER BY CreatedDate DESC LIMIT 1];
    }

    private static Id getPersonaDefinition() {
        return [SELECT Id FROM Persona_Definition__c LIMIT 1].Id;
    }

    private static List<Org__c> getCredentials() {
        return [SELECT Id FROM Org__c];
    }
}