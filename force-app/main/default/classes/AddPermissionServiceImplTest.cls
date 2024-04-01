@isTest
private class AddPermissionServiceImplTest {
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
    private static void addPermission() {
        System.runAs(getRunAsUser()) {
            // Setup
            Persona.AddPermissionRequest request = new Persona.AddPermissionRequest();
            request.personaId = getPersonaDefinition();
            request.permissionSetGroups = new List<String>{ 'TESTPSG1', 'TESTPSG2' };

            // Exercise
            Test.startTest();
            AddPermissionServiceImpl.add(request);
            AddPermissionServiceImpl.add2(request);
            Test.stopTest();

            // Verify
            List<PermissionSetAssignment> permissionSetAssignments = [
            SELECT Id, PermissionSetGroupId, PermissionSetGroup.DeveloperName, AssigneeId
            FROM PermissionSetAssignment
            WHERE PermissionSetGroup.DeveloperName = 'TESTPSG2' AND AssigneeId = :UserInfo.getUserId()];
            System.assertEquals(true, !permissionSetAssignments.isEmpty(), 'User should be assigned to permission set group.');
        }
    }

    // HELPERS

    private static void createData() {

        User user = getRunAsUser();
        PermissionSetGroup psg = createPermissionSetGroup('TESTPSG1', 'TEST PSG1');
        insert new PermissionSetAssignment(PermissionSetGroupId = psg.Id, AssigneeId = user.Id);
        
        createPermissionSetGroup('TESTPSG2', 'TEST PSG2');

        Group testGroup = new Group(Name = 'Test Group', Type = 'Regular');
        insert testGroup;

        GroupMember testGroupMember = new GroupMember(GroupId = testGroup.Id, UserOrGroupId = user.Id);
        insert testGroupMember;

        PersonaDefinitionConfig config = new PersonaDefinitionConfig();
        config.publicGroupId = testGroup.Id;
        config.permissionSetGroups = new List<PersonaDefinitionConfig.ConfigEntry>();
        config.permissionSetGroups.add(new PersonaDefinitionConfig.ConfigEntry().name('TESTPSG1'));

        Persona_Definition__c personaDef = new Persona_Definition__c(Config_JSON__c = JSON.serialize(config));
        insert personaDef;
    }

    private static PermissionSetGroup createPermissionSetGroup(String name, String label){
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

    private static PermissionSetGroup getPermissionSetGroup(String name){
        return [SELECT Id, Status from PermissionSetGroup where DeveloperName =: name];
    }

    private static Id getPersonaDefinition() {
        return [SELECT Id FROM Persona_Definition__c LIMIT 1].Id;
    }

    private static User getRunAsUser() {
        return [SELECT Id FROM User WHERE Profile.Name = 'System Administrator' ORDER BY CreatedDate DESC LIMIT 1];
    }
}