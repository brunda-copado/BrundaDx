@SuppressWarnings('PMD.StdCyclomaticComplexity')
public with sharing class PersonaUserServiceImpl {
    // PUBLIC

    public static void add(Persona.AddUserRequest request) {
        validate(request);
        PersonaDefinitionConfig config = PersonaServiceHelper.getPersonaDefinition(request.personaId);
        addUsersToPublicGroup(request.userIds, config);
        assignPermissionSetGroupToUsers(request.userIds, config);
    }

    public static void add2(Persona.AddUserRequest request) {
        PersonaDefinitionConfig config = PersonaServiceHelper.getPersonaDefinition(request.personaId);
        addLicensesToUsers(request.personaId, config);
    }

    // NOTE: this is only to separate transactions
    public static void add3(Persona.AddUserRequest request) {
        PersonaDefinitionConfig config = PersonaServiceHelper.getPersonaDefinition(request.personaId);
        addPackageLicensesToUsers(request.personaId, config);
        updateUserWithPersonaId(request.userIds, request.personaId);
    }

    public static void remove(Persona.RemoveUserRequest request) {
        PersonaDefinitionConfig config = PersonaServiceHelper.getPersonaDefinition(request.personaId);
        removeLicensesFromUsers(request.userIds, config);
    }

    public static void remove2(Persona.RemoveUserRequest request) {
        PersonaDefinitionConfig config = PersonaServiceHelper.getPersonaDefinition(request.personaId);
        removePackageLicensesFromUsers(request.userIds, config);
    }

    // NOTE: this is only to separate transactions
    public static void remove3(Persona.RemoveUserRequest request) {
        PersonaDefinitionConfig config = PersonaServiceHelper.getPersonaDefinition(request.personaId);
        removePermissionSetGroupFromUsers(request.userIds, config);
        removeUsersFromPublicGroup(request.userIds, config);
        updateUserWithoutPersonaId(request.userIds);
    }

    // PRIVATE

    private static void validate(Persona.AddUserRequest request) {
        for (User user : [SELECT Id, IsActive, Persona_Id__c FROM User WHERE Id IN :request.userIds WITH USER_MODE]) {
            if (!user.IsActive || String.isNotBlank(user.Persona_Id__c)) {
                throw new ApplicationException(Label.Add_Users_to_Persona_Subtitle);
            }
        }
    }

    private static void addUsersToPublicGroup(List<Id> userIds, PersonaDefinitionConfig config) {
        List<GroupMember> groupMembers = new List<GroupMember>();
        for (Id userId : userIds) {
            groupMembers.add(new GroupMember(GroupId = config.publicGroupId, UserOrGroupId = userId));
        }
        DML.safeInsert(
            groupMembers,
            String.format(
                Label.ErrorWhileInserting,
                new List<String>{
                    GroupMember.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).getLabel(),
                    'PersonaUserServiceImpl.addUsersToPublicGroup'
                }
            )
        );
    }

    private static void addLicensesToUsers(Id personaId, PersonaDefinitionConfig config) {
        if (config.licenses.isEmpty()) {
            return;
        }

        List<String> licenses = new List<String>();
        for (PersonaDefinitionConfig.ConfigEntry entry : config.licenses) {
            licenses.add(entry.name);
        }

        Persona.AddLicenseRequest licenseRequest = new Persona.AddLicenseRequest();
        licenseRequest.personaId = personaId;
        licenseRequest.licenses = licenses;
        Persona.LicenseService.addCopadoLicense(licenseRequest);
    }

    private static void addPackageLicensesToUsers(Id personaId, PersonaDefinitionConfig config) {
        if (config.packageLicenses.isEmpty()) {
            return;
        }

        List<String> licenses = new List<String>();
        for (PersonaDefinitionConfig.ConfigEntry entry : config.packageLicenses) {
            licenses.add(entry.name);
        }

        Persona.AddLicenseRequest licenseRequest = new Persona.AddLicenseRequest();
        licenseRequest.personaId = personaId;
        licenseRequest.licenses = licenses;
        Persona.LicenseService.addPackageLicense(licenseRequest);
    }

    private static void assignPermissionSetGroupToUsers(List<Id> userIds, PersonaDefinitionConfig config) {
        List<String> permissionSetGroupNames = new List<String>();
        for (PersonaDefinitionConfig.ConfigEntry entry : config.permissionSetGroups) {
            permissionSetGroupNames.add(entry.name);
        }
        AddPermissionServiceImpl.addPermissions(permissionSetGroupNames, userIds);
    }

    private static void updateUserWithPersonaId(List<Id> userIds, Id personaId) {
        List<User> users = new List<User>();
        for (Id userId : userIds) {
            users.add(new User(Id = userId, Persona_Id__c = personaId));
        }
        DML.safeUpdate(
            users,
            String.format(
                Label.ErrorWhileUpdating,
                new List<String>{
                    User.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).getLabel(),
                    'PersonaUserServiceImpl.updateUserWithPersonaId'
                }
            )
        );
    }

    private static void removeUsersFromPublicGroup(List<Id> userIds, PersonaDefinitionConfig config) {
        List<GroupMember> groupMembers = [
            SELECT Id
            FROM GroupMember
            WHERE GroupId = :config.publicGroupId AND UserOrGroupId IN :userIds
            WITH USER_MODE
        ];
        DML.safeDelete(
            groupMembers,
            String.format(
                Label.ErrorWhileDeleting,
                new List<String>{
                    GroupMember.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).getLabel(),
                    'PersonaUserServiceImpl.removeUsersFromPublicGroup'
                }
            )
        );
    }

    private static void removePermissionSetGroupFromUsers(List<Id> userIds, PersonaDefinitionConfig config) {
        List<String> permissionSetGroupNames = new List<String>();
        for (PersonaDefinitionConfig.ConfigEntry entry : config.permissionSetGroups) {
            permissionSetGroupNames.add(entry.name);
        }
        RemovePermissionServiceImpl.removePermissionSetGroups(permissionSetGroupNames, userIds);
    }

    private static void removePackageLicensesFromUsers(List<Id> userIds, PersonaDefinitionConfig config) {
        if (config.packageLicenses.isEmpty()) {
            return;
        }

        List<String> licenses = new List<String>();
        for (PersonaDefinitionConfig.ConfigEntry entry : config.packageLicenses) {
            licenses.add(entry.name);
        }
        RemoveLicenseServiceImpl.removePackageLicenses(licenses, userIds);
    }

    private static void removeLicensesFromUsers(List<Id> userIds, PersonaDefinitionConfig config) {
        if (config.licenses.isEmpty()) {
            return;
        }

        List<String> licenses = new List<String>();
        for (PersonaDefinitionConfig.ConfigEntry entry : config.licenses) {
            licenses.add(entry.name);
        }

        RemoveLicenseServiceImpl.removeCopadoLicenses(licenses, userIds);
    }

    private static void updateUserWithoutPersonaId(List<Id> userIds) {
        List<User> users = new List<User>();
        for (Id userId : userIds) {
            users.add(new User(Id = userId, Persona_Id__c = null));
        }
        DML.safeUpdate(
            users,
            String.format(
                Label.ErrorWhileUpdating,
                new List<String>{
                    User.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).getLabel(),
                    'PersonaUserServiceImpl.updateUserWithoutPersonaId'
                }
            )
        );
    }
}