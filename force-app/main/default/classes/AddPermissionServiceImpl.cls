public with sharing class AddPermissionServiceImpl {
    // PUBLIC

    public static void add(Persona.AddPermissionRequest request) {
        PersonaDefinitionConfig personaDefinition = PersonaServiceHelper.getPersonaDefinition(request.personaId);
        List<Id> userIds = findActiveUsers(personaDefinition.publicGroupId);
        addPermissions(request.permissionSetGroups, userIds);
    }

    // NOTE: this is only to separate transactions
    public static void add2(Persona.AddPermissionRequest request) {
        PersonaDefinitionConfig personaDefinition = PersonaServiceHelper.getPersonaDefinition(request.personaId);
        updatePersonaDefinition(request, personaDefinition);
    }

    @SuppressWarnings('PMD.ApexCRUDViolation')
    public static void addPermissions(List<String> permissionSetGroupNames, List<Id> userIds) {
        List<PermissionSetAssignment> permissionSetAssignments = new List<PermissionSetAssignment>();

        List<PermissionSetGroup> permissionSetGroups = getPermissionSetGroups(permissionSetGroupNames);
        Map<String, Map<String, PermissionSetAssignment>> permissionSetAssignmentsByUser = getPermissionSetAssignments(permissionSetGroups, userIds);

        for (Id userId : userIds) {
            Map<String, PermissionSetAssignment> userPermissionSetAssignments = permissionSetAssignmentsByUser.get(userId);

            for (PermissionSetGroup permissionSetGroup : permissionSetGroups) {
                if (
                    userPermissionSetAssignments == null ||
                    (userPermissionSetAssignments != null && !userPermissionSetAssignments.containsKey(permissionSetGroup.DeveloperName))
                ) {
                    permissionSetAssignments.add(new PermissionSetAssignment(PermissionSetGroupId = permissionSetGroup.Id, AssigneeId = userId));
                }
            }
        }

        if (!permissionSetAssignments.isEmpty()) {
            insert permissionSetAssignments;
        }
    }

    // PRIVATE

    private static List<Id> findActiveUsers(String groupId) {
        List<Id> result = new List<Id>();
        // PMD False positive, as WITH USER_MODE is not supported yet
        for (User userRecord : [SELECT Id FROM User WHERE IsActive = TRUE AND Id IN :PersonaServiceHelper.findUsersInGroup(groupId) WITH USER_MODE]) {
            result.add(userRecord.Id);
        }
        return result;
    }

    // PMD False positive, as WITH USER_MODE is not supported yet
    private static List<PermissionSetGroup> getPermissionSetGroups(List<String> permissionSetGroupNames) {
        return [SELECT Id, DeveloperName FROM PermissionSetGroup WHERE DeveloperName IN :permissionSetGroupNames WITH USER_MODE];
    }

    private static Map<String, Map<String, PermissionSetAssignment>> getPermissionSetAssignments(
        List<PermissionSetGroup> permissionSetGroups,
        List<Id> userIds
    ) {
        Map<String, Map<String, PermissionSetAssignment>> permissionSetAssignmentsByUser = new Map<String, Map<String, PermissionSetAssignment>>();

        // PMD False positive, as WITH USER_MODE is not supported yet
        for (PermissionSetAssignment permissionSetAssignment : [
            SELECT Id, PermissionSetGroupId, PermissionSetGroup.DeveloperName, AssigneeId
            FROM PermissionSetAssignment
            WHERE PermissionSetGroupId IN :permissionSetGroups AND AssigneeId IN :userIds
            WITH USER_MODE
        ]) {
            if (!permissionSetAssignmentsByUser.containsKey(permissionSetAssignment.AssigneeId)) {
                permissionSetAssignmentsByUser.put(permissionSetAssignment.AssigneeId, new Map<String, PermissionSetAssignment>());
            }
            Map<String, PermissionSetAssignment> permissionSetAssignments = permissionSetAssignmentsByUser.get(permissionSetAssignment.AssigneeId);
            permissionSetAssignments.put(permissionSetAssignment.PermissionSetGroup.DeveloperName, permissionSetAssignment);
        }

        return permissionSetAssignmentsByUser;
    }

    private static void updatePersonaDefinition(Persona.AddPermissionRequest request, PersonaDefinitionConfig personaDefinition) {
        List<PersonaDefinitionConfig.ConfigEntry> configEntries = new List<PersonaDefinitionConfig.ConfigEntry>();
        for (String name : request.permissionSetGroups) {
            if (!alreadyExists(name, personaDefinition.permissionSetGroups)) {
                configEntries.add(new PersonaDefinitionConfig.ConfigEntry().name(name));
            }
        }

        if (!configEntries.isEmpty()) {
            personaDefinition.permissionSetGroups.addAll(configEntries);
            PersonaServiceHelper.updatePersonaConfig(request.personaId, personaDefinition);
        }
    }

    private static Boolean alreadyExists(String name, List<PersonaDefinitionConfig.ConfigEntry> configEntries) {
        for (PersonaDefinitionConfig.ConfigEntry entry : configEntries) {
            if (entry.name.equals(name)) {
                return true;
            }
        }
        return false;
    }
}