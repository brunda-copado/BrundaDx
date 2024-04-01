@IsTest
private with sharing class PersonaManagementPermissionServiceTest {
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

    @IsTest
    private static void getPermissionSetGroups() {
        System.runAs(getRunAsUser()) {
            // Exercise
            Test.startTest();
            List<PermissionSetGroup> permissionSetGroups = PersonaManagementPermissionServiceCtrl.getPermissionSetGroups();
            Test.stopTest();

            // Verify
            Integer permissionSetGroupCount = [SELECT COUNT() FROM PermissionSetGroup];
            System.assertEquals(
                permissionSetGroupCount - 1,
                permissionSetGroups.size(),
                'The permission set group from the persona should be discarded.'
            );
        }
    }

    @IsTest
    private static void getPermissionsForPersona() {
        System.runAs(getRunAsUser()) {
            // Setup
            Id personaId = getPersonaDefinition();

            // Exercise
            Test.startTest();
            List<PersonaManagementPermissionServiceCtrl.PersonaPermission> permissions = PersonaManagementPermissionServiceCtrl.getPermissionsForPersona(
                personaId
            );
            Test.stopTest();

            // Verify
            System.assertEquals(1, permissions.size(), 'Only one permission set group should be returned, as the one from the persona is discarded.');
        }
    }

    @IsTest
    private static void addPermissionSetGroup() {
        System.runAs(getRunAsUser()) {
            // Exercise
            Test.startTest();
            PersonaManagementPermissionServiceCtrl.addPermissionSetGroup(getPersonaDefinition(), new List<String>{ 'TESTPSG1', 'TESTPSG2' });
            PersonaManagementPermissionServiceCtrl.addPermissionSetGroup2(getPersonaDefinition(), new List<String>{ 'TESTPSG1', 'TESTPSG2' });
            Test.stopTest();

            // Verify
            List<PermissionSetAssignment> permissionSetAssignments = [
                SELECT Id, PermissionSetGroupId, PermissionSetGroup.DeveloperName, AssigneeId
                FROM PermissionSetAssignment
                WHERE PermissionSetGroup.DeveloperName = 'TESTPSG2' AND AssigneeId = :UserInfo.getUserId()
            ];
            System.assertEquals(true, !permissionSetAssignments.isEmpty(), 'User should be assigned to permission set group.');
        }
    }

    @IsTest
    private static void removePermissionSetGroup() {
        System.runAs(getRunAsUser()) {
            // Exercise
            Test.startTest();
            List<PersonaManagementPermissionServiceCtrl.PersonaPermission> personaPermissions = new List<PersonaManagementPermissionServiceCtrl.PersonaPermission>();
            PersonaManagementPermissionServiceCtrl.PersonaPermission personaPermission = new PersonaManagementPermissionServiceCtrl.PersonaPermission();
            personaPermission.developerName = 'TESTPSG3';
            personaPermission.type = 'Permission Set Group';
            personaPermissions.add(personaPermission);
            PersonaManagementPermissionServiceCtrl.removePermission(getPersonaDefinition(), JSON.serialize(personaPermissions));
            PersonaManagementPermissionServiceCtrl.removePermission2(getPersonaDefinition(), JSON.serialize(personaPermissions));
            Test.stopTest();

            // Verify
            List<PermissionSetAssignment> permissionSetAssignments = [
                SELECT Id, PermissionSetGroupId, PermissionSetGroup.DeveloperName, AssigneeId
                FROM PermissionSetAssignment
                WHERE PermissionSetGroup.DeveloperName = 'TESTPSG3' AND AssigneeId = :UserInfo.getUserId()
            ];
            System.assertEquals(true, permissionSetAssignments.isEmpty(), 'User should be removed from permission set group.');
        }
    }

    private static void createData() {
        User user = getRunAsUser();
        PermissionSetGroup psg = createPermissionSetGroup('TESTPSG1', 'TEST PSG1');
        insert new PermissionSetAssignment(PermissionSetGroupId = psg.Id, AssigneeId = user.Id);

        createPermissionSetGroup('TESTPSG2', 'TEST PSG2');
        createPermissionSetGroup('TESTPSG3', 'TEST PSG3');

        Group testGroup = new Group(Name = 'Test Group', Type = 'Regular');
        insert testGroup;

        GroupMember testGroupMember = new GroupMember(GroupId = testGroup.Id, UserOrGroupId = user.Id);
        insert testGroupMember;

        PersonaDefinitionConfig config = new PersonaDefinitionConfig();
        config.publicGroupId = testGroup.Id;
        config.permissionSetGroups = new List<PersonaDefinitionConfig.ConfigEntry>();
        config.permissionSetGroups.add(new PersonaDefinitionConfig.ConfigEntry().name('TESTPSG1').isStandard());
        config.permissionSetGroups.add(new PersonaDefinitionConfig.ConfigEntry().name('TESTPSG3'));
        config.permissionSets.add(new PersonaDefinitionConfig.ConfigEntry().name('TESTPSG1PS').isStandard());

        Persona_Definition__c personaDef = new Persona_Definition__c(Config_JSON__c = JSON.serialize(config));
        insert personaDef;
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

    private static PermissionSetGroup getPermissionSetGroup(String name) {
        return [SELECT Id, Status FROM PermissionSetGroup WHERE DeveloperName = :name];
    }

    private static Id getPersonaDefinition() {
        return [SELECT Id FROM Persona_Definition__c LIMIT 1].Id;
    }

    private static User getRunAsUser() {
        return [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' ORDER BY CreatedDate DESC LIMIT 1];
    }
}