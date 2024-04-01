public with sharing class RemovePermissionServiceImpl {
    // PUBLIC

    public static void remove(Persona.RemovePermissionRequest request) {
        PersonaDefinitionConfig config = PersonaServiceHelper.getPersonaDefinition(request.personaId);
        validate(request, config);
        removePermissions(request, config);
    }

    // NOTE: this is only to separate transactions
    public static void remove2(Persona.RemovePermissionRequest request) {
        PersonaDefinitionConfig config = PersonaServiceHelper.getPersonaDefinition(request.personaId);
        updatePersonaDefinition(request, config);
    }

    // PRIVATE

    private static void removePermissions(Persona.RemovePermissionRequest request, PersonaDefinitionConfig config) {
        Map<String, List<String>> permissionsByType = groupPermissionsByType(request.permissions);
        List<Id> userIds = PersonaServiceHelper.findUsersInGroup(config.publicGroupId);
        PermissionSetGroup permissionSetGroup = [
            SELECT Id
            FROM PermissionSetGroup
            WHERE DeveloperName = :config.getPersonaPermissionSetGroup()
            WITH USER_MODE
            LIMIT 1
        ];
        PermissionSet permissionSet = [SELECT Id FROM PermissionSet WHERE Name = :config.getPersonaPermissionSet() WITH USER_MODE LIMIT 1];

        for (String permissionType : permissionsByType.keySet()) {
            if (permissionType == 'Permission Set') {
                removePermissionSets(permissionSetGroup, permissionsByType.get(permissionType));
            } else if (permissionType == 'Permission Set Group') {
                removePermissionSetGroups(permissionsByType.get(permissionType), userIds);
            } else if (permissionType == 'Custom Permission') {
                removeCustomPermission(permissionSet, permissionsByType.get(permissionType));
            }
        }
    }

    private static void validate(Persona.RemovePermissionRequest request, PersonaDefinitionConfig config) {
        for (Persona.Permission permissionToRemove : request.permissions) {
            String permissionType = permissionToRemove.type;
            String permissionName = permissionToRemove.name;
            if (
                permissionType == 'Permission Set' && permissionIsStandard(config.permissionSets, permissionName) ||
                permissionType == 'Permission Set Group' && permissionIsStandard(config.permissionSetGroups, permissionName) ||
                permissionType == 'Custom Permission' && permissionIsStandard(config.customPermissions, permissionName)
            ) {
                throw new ApplicationException(Label.Persona_Permission_Remove_Error);
            }
        }
    }

    private static Boolean permissionIsStandard(List<PersonaDefinitionConfig.ConfigEntry> configs, String value) {
        for (PersonaDefinitionConfig.ConfigEntry configEntry : configs) {
            if (configEntry.name == value) {
                return configEntry.isStandard;
            }
        }
        return false;
    }

    private static Map<String, List<String>> groupPermissionsByType(List<Persona.Permission> permissions) {
        Map<String, List<String>> result = new Map<String, List<String>>();
        for (Persona.Permission permission : permissions) {
            String type = permission.type;
            if (!result.containsKey(type)) {
                result.put(type, new List<String>());
            }
            result.get(type).add(permission.name);
        }
        return result;
    }

    private static void removePermissionSets(PermissionSetGroup permissionSetGroup, List<String> permissionSets) {
        List<PermissionSetGroupComponent> components = [
            SELECT Id
            FROM PermissionSetGroupComponent
            WHERE PermissionSetGroupId = :permissionSetGroup.Id AND PermissionSet.Name IN :permissionSets
            WITH USER_MODE
        ];
        DML.safeDelete(
            components,
            String.format(
                Label.ErrorWhileDeleting,
                new List<String>{
                    PermissionSetGroupComponent.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).getLabel(),
                    'RemovePermissionServiceImpl.removePermissionSets'
                }
            )
        );
    }

    private static void removeCustomPermission(PermissionSet permissionSet, List<String> customPermissions) {
        List<SetupEntityAccess> entities = [
            SELECT Id
            FROM SetupEntityAccess
            WHERE ParentId = :permissionSet.Id AND SetupEntityId IN (SELECT Id FROM CustomPermission WHERE DeveloperName IN :customPermissions)
            WITH USER_MODE
        ];
        DML.safeDelete(
            entities,
            String.format(
                Label.ErrorWhileDeleting,
                new List<String>{
                    SetupEntityAccess.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).getLabel(),
                    'RemovePermissionServiceImpl.removeCustomPermission'
                }
            )
        );
    }

    public static void removePermissionSetGroups(List<String> permissionSetGroups, List<Id> userIds) {
        List<PermissionSetAssignment> permissionSetAssignments = [
            SELECT Id
            FROM PermissionSetAssignment
            WHERE PermissionSetGroup.DeveloperName IN :permissionSetGroups AND AssigneeId IN :userIds
            WITH USER_MODE
        ];
        if (!permissionSetAssignments.isEmpty()) {
            DML.safeDelete(
                permissionSetAssignments,
                String.format(
                    Label.ErrorWhileDeleting,
                    new List<String>{
                        PermissionSetAssignment.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).getLabel(),
                        'RemovePermissionServiceImpl.removePermissionSetGroups'
                    }
                )
            );
        }
    }

    private static void updatePersonaDefinition(Persona.RemovePermissionRequest request, PersonaDefinitionConfig config) {
        Map<String, List<String>> permissionsByType = groupPermissionsByType(request.permissions);
        for (String permissionType : permissionsByType.keySet()) {
            if (permissionType == 'Permission Set') {
                removeFromList(config.permissionSets, permissionsByType.get(permissionType));
            } else if (permissionType == 'Permission Set Group') {
                removeFromList(config.permissionSetGroups, permissionsByType.get(permissionType));
            } else if (permissionType == 'Custom Permission') {
                removeFromList(config.customPermissions, permissionsByType.get(permissionType));
            }
        }
        PersonaServiceHelper.updatePersonaConfig(request.personaId, config);
    }

    private static void removeFromList(List<PersonaDefinitionConfig.ConfigEntry> entries, List<String> permissions) {
        for (Integer index = (entries.size() - 1); index >= 0; index--) {
            if (permissions.contains(entries[index].name)) {
                entries.remove(index);
            }
        }
    }
}