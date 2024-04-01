public with sharing class PersonaManagementPermissionServiceCtrl {
    @AuraEnabled
    public static List<PermissionSetGroup> getPermissionSetGroups() {
        Set<String> permissionSetGroupNames = new Set<String>();
        for (Persona_Definition__c persona : [SELECT Config_JSON__c FROM Persona_Definition__c WITH USER_MODE]) {
            PersonaDefinitionConfig config = (PersonaDefinitionConfig) JSON.deserialize(persona.Config_JSON__c, PersonaDefinitionConfig.class);
            permissionSetGroupNames.add(config.getPersonaPermissionSetGroup());
        }
        return [
            SELECT DeveloperName, Description, MasterLabel
            FROM PermissionSetGroup
            WHERE DeveloperName NOT IN :permissionSetGroupNames
            WITH USER_MODE
        ];
    }

    // Note: custom permissions missing, package information missing
    @AuraEnabled
    public static List<PersonaPermission> getPermissionsForPersona(String personaId) {
        List<PersonaPermission> result = new List<PersonaPermission>();
        PersonaDefinitionConfig config = PersonaServiceHelper.getPersonaDefinition(personaId);
        result.addAll(getPermissionSetGroups(config));
        result.addAll(getPermissionSets(config));
        result.addAll(getCustomPermissions(config));
        return result;
    }

    @AuraEnabled
    public static void addPermissionSetGroup(String personaId, List<String> permissionSetGroups) {
        Persona.AddPermissionRequest request = new Persona.AddPermissionRequest();
        request.personaId = personaId;
        request.permissionSetGroups = permissionSetGroups;
        Persona.PermissionService.add(request);
    }

    @AuraEnabled
    public static void addPermissionSetGroup2(String personaId, List<String> permissionSetGroups) {
        Persona.AddPermissionRequest request = new Persona.AddPermissionRequest();
        request.personaId = personaId;
        request.permissionSetGroups = permissionSetGroups;
        Persona.PermissionService.add2(request);
    }

    @AuraEnabled
    public static void removePermission(String personaId, String permissions) {
        Persona.RemovePermissionRequest request = new Persona.RemovePermissionRequest();
        request.personaId = personaId;
        request.permissions = convertPermissions(permissions);
        Persona.PermissionService.remove(request);
    }

    @AuraEnabled
    public static void removePermission2(String personaId, String permissions) {
        Persona.RemovePermissionRequest request = new Persona.RemovePermissionRequest();
        request.personaId = personaId;
        request.permissions = convertPermissions(permissions);
        Persona.PermissionService.remove2(request);
    }

    // PRIVATE

    private static List<Persona.Permission> convertPermissions(String permissions){
        List<Persona.Permission> result = new List<Persona.Permission>();
        List<PersonaPermission> permissionsList = (List<PersonaPermission>) JSON.deserialize(permissions, List<PersonaPermission>.class);
        for (PersonaPermission personaPermission : permissionsList) {
            Persona.Permission servicePermission = new Persona.Permission();
            servicePermission.name = personaPermission.developerName;
            servicePermission.type = personaPermission.type;
            result.add(servicePermission);
        }
        return result;
    }

    private static List<PersonaPermission> getPermissionSetGroups(PersonaDefinitionConfig config) {
        List<PersonaPermission> result = new List<PersonaPermission>();

        Map<String, Boolean> permissionSetGroupNames = new Map<String, Boolean>();
        for (PersonaDefinitionConfig.ConfigEntry entry : config.getAssignedPermissionSetGroups()) {
            permissionSetGroupNames.put(entry.name, entry.isStandard);
        }
        for (PermissionSetGroup permissionSetGroup : [
            SELECT DeveloperName, Description, MasterLabel, NamespacePrefix
            FROM PermissionSetGroup
            WHERE DeveloperName IN :permissionSetGroupNames.keyset()
            WITH USER_MODE
        ]) {
            PersonaPermission personaPermission = new PersonaPermission();
            personaPermission.id = permissionSetGroup.Id;
            personaPermission.developerName = permissionSetGroup.DeveloperName;
            personaPermission.label = permissionSetGroup.MasterLabel;
            personaPermission.description = permissionSetGroup.Description;
            personaPermission.type = 'Permission Set Group';
            personaPermission.packageName = permissionSetGroup.NamespacePrefix;
            personaPermission.isStandard = permissionSetGroupNames.get(permissionSetGroup.DeveloperName);
            result.add(personaPermission);
        }

        return result;
    }

    private static List<PersonaPermission> getPermissionSets(PersonaDefinitionConfig config) {
        List<PersonaPermission> result = new List<PersonaPermission>();

        Map<String, Boolean> permissionSetNames = new Map<String, Boolean>();
        for (PersonaDefinitionConfig.ConfigEntry entry : config.getAssignedPermissionSets()) {
            permissionSetNames.put(entry.name, entry.isStandard);
        }
        for (PermissionSet permissionSet : [
            SELECT Name, Description, Label, NamespacePrefix
            FROM PermissionSet
            WHERE Name IN :permissionSetNames.keyset()
            WITH USER_MODE
        ]) {
            PersonaPermission personaPermission = new PersonaPermission();
            personaPermission.id = permissionSet.Id;
            personaPermission.developerName = permissionSet.Name;
            personaPermission.label = permissionSet.Label;
            personaPermission.description = permissionSet.Description;
            personaPermission.type = 'Permission Set';
            personaPermission.packageName = permissionSet.NamespacePrefix;
            personaPermission.isStandard = permissionSetNames.get(permissionSet.Name);
            result.add(personaPermission);
        }

        return result;
    }

    private static List<PersonaPermission> getCustomPermissions(PersonaDefinitionConfig config) {
        List<PersonaPermission> result = new List<PersonaPermission>();

        Map<String, Boolean> customPermissionNames = new Map<String, Boolean>();
        for (PersonaDefinitionConfig.ConfigEntry entry : config.customPermissions) {
            customPermissionNames.put(entry.name, entry.isStandard);
        }
        for (CustomPermission customPermission : [
            SELECT Id, Description, DeveloperName, MasterLabel, NamespacePrefix
            FROM CustomPermission
            WHERE DeveloperName IN :customPermissionNames.keyset()
            WITH USER_MODE
        ]) {
            PersonaPermission personaPermission = new PersonaPermission();
            personaPermission.id = customPermission.Id;
            personaPermission.developerName = customPermission.DeveloperName;
            personaPermission.label = customPermission.MasterLabel;
            personaPermission.description = customPermission.Description;
            personaPermission.type = 'Custom Permission';
            personaPermission.packageName = customPermission.NamespacePrefix;
            personaPermission.isStandard = customPermissionNames.get(customPermission.DeveloperName);
            result.add(personaPermission);
        }
        return result;
    }

    public with sharing class PersonaPermission {
        @AuraEnabled
        public String id;
        @AuraEnabled
        public String developerName;
        @AuraEnabled
        public String label;
        @AuraEnabled
        public String description;
        @AuraEnabled
        public String type;
        @AuraEnabled
        public String packageName;
        @AuraEnabled
        public Boolean isStandard;
    }  
}