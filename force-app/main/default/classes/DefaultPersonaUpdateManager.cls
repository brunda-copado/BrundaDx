@SuppressWarnings('PMD.CyclomaticComplexity, PMD.StdCyclomaticComplexity, PMD.CognitiveComplexity')
public with sharing class DefaultPersonaUpdateManager {
    private static List<Default_Persona__mdt> mock;
    // PUBLIC

    public List<String> checkForUpdates() {
        List<String> personasToUpdate = new List<String>();

        Map<String, Persona_Definition__c> personaByName = getPersonasByName();

        for (Default_Persona__mdt defaultPersona : getDefaultPersonas()) {
            Persona_Definition__c personaDefinition = personaByName.get(defaultPersona.MasterLabel);
            if (personaDefinition == null) {
                personasToUpdate.add(defaultPersona.MasterLabel);
            } else if (descriptionUpdated(personaDefinition, defaultPersona) || defaultPermissionsNotSet(personaDefinition, defaultPersona)) {
                personasToUpdate.add(defaultPersona.MasterLabel);
            }
        }
        return personasToUpdate;
    }

    public ApplyUpdatesResult applyUpdates(String personaName) {
        ApplyUpdatesResult result = new ApplyUpdatesResult();
        Default_Persona__mdt defaultPersona = getDefaultPersona(personaName);
        Map<String, Persona_Definition__c> personaByName = getPersonasByName();
        Persona_Definition__c personaDefinition = personaByName.get(defaultPersona.MasterLabel);
        if (personaDefinition == null) {
            result.defaultPersonaToCreate = defaultPersona;
        } else {
            result.updatedPersonaId = personaDefinition.Id;
            result.updatedPersonaDescription = defaultPersona.Description__c;
            PersonaDefinitionConfig updatedConfig = addNewPermissions(personaDefinition, defaultPersona);
            result.updatedPersonaConfigJson = JSON.serialize(updatedConfig);
        }
        return result;
    }

    public void mock(List<Default_Persona__mdt> defaultPersonas) {
        mock = defaultPersonas;
    }

    // PRIVATE

    private Map<String, Persona_Definition__c> getPersonasByName() {
        Map<String, Persona_Definition__c> result = new Map<String, Persona_Definition__c>();
        for (Persona_Definition__c personaDefinition : [SELECT Name, Description__c, Config_JSON__c FROM Persona_Definition__c WITH USER_MODE]) {
            result.put(personaDefinition.Name, personaDefinition);
        }
        return result;
    }

    private Boolean descriptionUpdated(Persona_Definition__c personaDefinition, Default_Persona__mdt defaultPersona) {
        return defaultPersona.Description__c != personaDefinition.Description__c;
    }

    private Boolean defaultPermissionsNotSet(Persona_Definition__c personaDefinition, Default_Persona__mdt defaultPersona) {
        PersonaDefinitionConfig config = getConfig(personaDefinition);

        for (Default_Persona_Permission__mdt defaultPersonaPermission : defaultPersona.Default_Persona_Permissions__r) {
            String type = defaultPersonaPermission.Type__c;
            String value = defaultPersonaPermission.Value__c;
            if (
                type == PersonaDefinitionConfig.PermissionType.PermissionSetGroup.name() &&
                !configContains(config.getAssignedPermissionSetGroups(), value)
            ) {
                return true;
            } else if (
                type == PersonaDefinitionConfig.PermissionType.PermissionSet.name() && !configContains(config.getAssignedPermissionSets(), value)
            ) {
                return true;
            } else if (type == PersonaDefinitionConfig.PermissionType.AppPermission.name() && !configContains(config.appPermissions, value)) {
                return true;
            } else if (type == PersonaDefinitionConfig.PermissionType.CustomPermission.name() && !configContains(config.customPermissions, value)) {
                return true;
            } else if (type == PersonaDefinitionConfig.PermissionType.CopadoLicense.name() && !configContains(config.licenses, value)) {
                return true;
            } else if (type == PersonaDefinitionConfig.PermissionType.PackageLicense.name() && !configContains(config.packageLicenses, value)) {
                return true;
            } else if (type == PersonaDefinitionConfig.PermissionType.CredentialAccessLevel.name() && config.defaultCredentialAccessLevel != value) {
                return true;
            }
        }
        return false;
    }

    private PersonaDefinitionConfig addNewPermissions(Persona_Definition__c personaDefinition, Default_Persona__mdt defaultPersona) {
        PersonaDefinitionConfig config = getConfig(personaDefinition);

        List<String> permissionSetGroupsToAdd = new List<String>();
        List<String> permissionSetsToAdd = new List<String>();
        List<String> appPermissionsToAdd = new List<String>();
        List<String> customPermissionsToAdd = new List<String>();
        List<String> licensesToAdd = new List<String>();
        List<String> packageLicensesToAdd = new List<String>();
        String newDefaultAccessLevel = config.defaultCredentialAccessLevel;
        for (Default_Persona_Permission__mdt defaultPersonaPermission : defaultPersona.Default_Persona_Permissions__r) {
            String type = defaultPersonaPermission.Type__c;
            String value = defaultPersonaPermission.Value__c;
            if (
                type == PersonaDefinitionConfig.PermissionType.PermissionSetGroup.name() &&
                !configContains(config.getAssignedPermissionSetGroups(), value)
            ) {
                permissionSetGroupsToAdd.add(value);
            } else if (
                type == PersonaDefinitionConfig.PermissionType.PermissionSet.name() && !configContains(config.getAssignedPermissionSets(), value)
            ) {
                permissionSetsToAdd.add(value);
            } else if (type == PersonaDefinitionConfig.PermissionType.AppPermission.name() && !configContains(config.appPermissions, value)) {
                appPermissionsToAdd.add(value);
            } else if (type == PersonaDefinitionConfig.PermissionType.CustomPermission.name() && !configContains(config.customPermissions, value)) {
                customPermissionsToAdd.add(value);
            } else if (type == PersonaDefinitionConfig.PermissionType.CopadoLicense.name() && !configContains(config.licenses, value)) {
                licensesToAdd.add(value);
            } else if (type == PersonaDefinitionConfig.PermissionType.PackageLicense.name() && !configContains(config.packageLicenses, value)) {
                packageLicensesToAdd.add(value);
            } else if (type == PersonaDefinitionConfig.PermissionType.CredentialAccessLevel.name() && config.defaultCredentialAccessLevel != value) {
                newDefaultAccessLevel = value;
            }
        }
        addMissingPermissionSetGroups(permissionSetGroupsToAdd, personaDefinition, config);
        addMissingCopadoLicenses(licensesToAdd, personaDefinition, config);
        addMissingPackageLicenses(packageLicensesToAdd, personaDefinition, config);
        addMissingPermissionSets(permissionSetsToAdd, config);
        addMissingApps(appPermissionsToAdd, config);
        addMissingCustomPermissions(customPermissionsToAdd, config);
        updateCredentialAccessLevel(newDefaultAccessLevel, config);
        return config;
    }

    private void addMissingPermissionSetGroups(
        List<String> permissionSetGroupsToAdd,
        Persona_Definition__c personaDefinition,
        PersonaDefinitionConfig config
    ) {
        if (permissionSetGroupsToAdd.isEmpty()) {
            return;
        }
        Persona.AddPermissionRequest addPermissionRequest = new Persona.AddPermissionRequest();
        addPermissionRequest.personaId = personaDefinition.Id;
        addPermissionRequest.permissionSetGroups = permissionSetGroupsToAdd;
        Persona.PermissionService.add(addPermissionRequest);
        for (String permissionSetGroup : permissionSetGroupsToAdd) {
            config.permissionSetGroups.add(new PersonaDefinitionConfig.ConfigEntry().name(permissionSetGroup).isStandard());
        }
    }

    private void addMissingCopadoLicenses(List<String> licensesToAdd, Persona_Definition__c personaDefinition, PersonaDefinitionConfig config) {
        if (licensesToAdd.isEmpty()) {
            return;
        }
        Persona.AddLicenseRequest addLicenseRequest = new Persona.AddLicenseRequest();
        addLicenseRequest.personaId = personaDefinition.Id;
        addLicenseRequest.licenses = licensesToAdd;
        Persona.LicenseService.addCopadoLicense(addLicenseRequest);
        for (String license : licensesToAdd) {
            config.licenses.add(new PersonaDefinitionConfig.ConfigEntry().name(license).isStandard());
        }
    }

    private void addMissingPackageLicenses(List<String> licensesToAdd, Persona_Definition__c personaDefinition, PersonaDefinitionConfig config) {
        if (licensesToAdd.isEmpty()) {
            return;
        }
        Persona.AddLicenseRequest addLicenseRequest = new Persona.AddLicenseRequest();
        addLicenseRequest.personaId = personaDefinition.Id;
        addLicenseRequest.licenses = licensesToAdd;
        Persona.LicenseService.addPackageLicense(addLicenseRequest);
        for (String license : licensesToAdd) {
            config.packageLicenses.add(new PersonaDefinitionConfig.ConfigEntry().name(license).isStandard());
        }
    }

    private void addMissingPermissionSets(List<String> permissionSetsToAdd, PersonaDefinitionConfig config) {
        if (permissionSetsToAdd.isEmpty()) {
            return;
        }
        PermissionSetGroup permissionSetGroup = [
            SELECT Id
            FROM PermissionSetGroup
            WHERE DeveloperName = :config.getPersonaPermissionSetGroup()
            WITH USER_MODE
            LIMIT 1
        ];
        List<PermissionSetGroupComponent> components = new List<PermissionSetGroupComponent>();
        for (PermissionSet permissionSet : [SELECT Id, Name FROM PermissionSet WHERE Name IN :permissionSetsToAdd WITH USER_MODE]) {
            components.add(new PermissionSetGroupComponent(PermissionSetGroupId = permissionSetGroup.Id, PermissionSetId = permissionSet.Id));
        }
        DML.safeInsert(
            components,
            String.format(
                Label.ErrorWhileInserting,
                new List<String>{
                    PermissionSetGroupComponent.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).getLabel(),
                    'DefaultPersonaUpdateManager.addMissingPermissionSets'
                }
            )
        );
        for (String permissionSet : permissionSetsToAdd) {
            config.permissionSets.add(new PersonaDefinitionConfig.ConfigEntry().name(permissionSet).isStandard());
        }
    }

    private void addMissingApps(List<String> appPermissionsToAdd, PersonaDefinitionConfig config) {
        if (appPermissionsToAdd.isEmpty()) {
            return;
        }
        PermissionSet permissionSet = [SELECT Id FROM PermissionSet WHERE Name = :config.getPersonaPermissionSet() WITH USER_MODE LIMIT 1];
        List<SetupEntityAccess> appPermissions = new List<SetupEntityAccess>();
        for (AppMenuItem appMenuItem : [
            SELECT Id, ApplicationId
            FROM AppMenuItem
            WHERE Type = 'TabSet' AND Name IN :appPermissionsToAdd
            WITH USER_MODE
        ]) {
            appPermissions.add(new SetupEntityAccess(SetupEntityId = appMenuItem.ApplicationId, ParentId = permissionSet.Id));
        }

        DML.safeInsert(
            appPermissions,
            String.format(Label.ErrorWhileInserting, new List<String>{ 'SetupEntityAccess', 'DefaultPersonaUpdateManager.addMissingApps' })
        );
        for (String appPermission : appPermissionsToAdd) {
            config.appPermissions.add(new PersonaDefinitionConfig.ConfigEntry().name(appPermission).isStandard());
        }
    }

    private void addMissingCustomPermissions(List<String> customPermissionsToAdd, PersonaDefinitionConfig config) {
        if (customPermissionsToAdd.isEmpty()) {
            return;
        }
        PermissionSet permissionSet = [SELECT Id FROM PermissionSet WHERE Name = :config.getPersonaPermissionSet() WITH USER_MODE LIMIT 1];
        List<SetupEntityAccess> customPermissions = new List<SetupEntityAccess>();
        for (CustomPermission customPermission : [SELECT Id FROM CustomPermission WHERE DeveloperName IN :customPermissionsToAdd WITH USER_MODE]) {
            customPermissions.add(new SetupEntityAccess(SetupEntityId = customPermission.Id, ParentId = permissionSet.Id));
        }

        DML.safeInsert(
            customPermissions,
            String.format(
                Label.ErrorWhileInserting,
                new List<String>{ 'SetupEntityAccess', 'DefaultPersonaUpdateManager.addMissingCustomPermissions' }
            )
        );

        for (String customPermission : customPermissionsToAdd) {
            config.customPermissions.add(new PersonaDefinitionConfig.ConfigEntry().name(customPermission).isStandard());
        }
    }

    private void updateCredentialAccessLevel(String newDefaultAccessLevel, PersonaDefinitionConfig config) {
        config.defaultCredentialAccessLevel = newDefaultAccessLevel;
    }

    private Boolean configContains(List<PersonaDefinitionConfig.ConfigEntry> configEntries, String value) {
        Set<PersonaDefinitionConfig.ConfigEntry> entriesSet = new Set<PersonaDefinitionConfig.ConfigEntry>(configEntries);
        return !entriesSet.isEmpty() && entriesSet.contains(new PersonaDefinitionConfig.ConfigEntry().name(value).isStandard());
    }

    private List<Default_Persona__mdt> getDefaultPersonas() {
        if (Test.isRunningTest() && mock != null) {
            return mock;
        } else {
            return [
                SELECT MasterLabel, DeveloperName, Description__c, (SELECT Type__c, Value__c FROM Default_Persona_Permissions__r)
                FROM Default_Persona__mdt
                WITH USER_MODE
            ];
        }
    }

    private static PersonaDefinitionConfig getConfig(Persona_Definition__c personaDefinition) {
        PersonaDefinitionConfig config = (PersonaDefinitionConfig) JSON.deserialize(personaDefinition.Config_JSON__c, PersonaDefinitionConfig.class);
        if (config.packageLicenses == null) {
            config.packageLicenses = new List<PersonaDefinitionConfig.ConfigEntry>();
        }

        return config;
    }

    private static Default_Persona__mdt getDefaultPersona(String personaName) {
        List<Default_Persona__mdt> defaultPersonas = [
            SELECT MasterLabel, DeveloperName, Description__c, (SELECT Type__c, Value__c FROM Default_Persona_Permissions__r)
            FROM Default_Persona__mdt
            WHERE DeveloperName = :personaName.replaceAll('\\s+', '_')
            WITH USER_MODE
            LIMIT 1
        ];
        return !defaultPersonas.isEmpty()
            ? defaultPersonas[0]
            : new Default_Persona__mdt(DeveloperName = personaName.replaceAll('\\s+', '_'), MasterLabel = personaName);
    }

    public with sharing class ApplyUpdatesResult {
        @AuraEnabled
        public Default_Persona__mdt defaultPersonaToCreate;
        @AuraEnabled
        public String updatedPersonaId;
        @AuraEnabled
        public String updatedPersonaConfigJson;
        @AuraEnabled
        public String updatedPersonaDescription;
    }
}