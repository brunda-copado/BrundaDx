@SuppressWarnings('PMD.CognitiveComplexity, PMD.StdCyclomaticComplexity, PMD.CyclomaticComplexity')
public with sharing class PersonaServiceImpl {
    // PUBLIC

    public static Persona.CreateConfigResult createConfig(Persona.CreateConfigRequest request) {
        Persona.CreateConfigResult result = new Persona.CreateConfigResult();
        String copyFrom = String.isNotBlank(request.copyFrom) ? request.copyFrom : request.personaName;
        Default_Persona__mdt defaultPersona = getDefaultPersona(copyFrom);
        Group publicGroup = createPublicGroup(request.personaName, defaultPersona);
        PermissionSetGroup permissionSetGroup = createPermissionSetGroup(request.personaName);
        PermissionSet permissionSet = createPermissionSet(request.personaName);
        PersonaDefinitionConfig config = createPersonaConfig(
            defaultPersona,
            String.isNotBlank(request.copyFrom),
            publicGroup,
            permissionSetGroup,
            permissionSet
        );
        assignAppPermissions(permissionSet.Id, config);
        assignCustomPermissions(permissionSet.Id, config);
        assignPermissionSets(permissionSetGroup, config);
        result.personaConfig = config;
        return result;
    }

    public static Persona.CreateRecordResult createRecord(Persona.CreateRecordRequest request) {
        Persona.CreateRecordResult result = new Persona.CreateRecordResult();
        Persona_Definition__c persona = createPersona(request.personaName, request.description, request.personaConfig, request.isStandard);
        result.persona = persona;
        return result;
    }

    public static void deletePersona(Persona.DeletePersonaRequest request) {
        Id personaId = request.personaId;
        PersonaDefinitionConfig config = PersonaServiceHelper.getPersonaDefinition(personaId);
        List<Id> userIds = PersonaServiceHelper.findUsersForPersona(personaId);
        deletePublicGroup(config);
        deletePermissionSetGroup(config);
        deletePermissionSet(config);
        deletePackageLicenses(userIds, config);
    }

    public static void deletePersona2(Persona.DeletePersonaRequest request) {
        Id personaId = request.personaId;
        PersonaDefinitionConfig config = PersonaServiceHelper.getPersonaDefinition(personaId);
        List<Id> userIds = PersonaServiceHelper.findUsersForPersona(personaId);
        deleteCopadoLicenses(userIds, config);
        deletePersonaRecord(personaId);
    }

    public static void deletePersona3(Persona.DeletePersonaRequest request) {
        Id personaId = request.personaId;
        List<Id> userIds = PersonaServiceHelper.findUsersForPersona(personaId);
        updateUsers(userIds);
    }

    // PRIVATE

    private static Default_Persona__mdt getDefaultPersona(String personaName) {
        List<Default_Persona__mdt> defaultPersonas = [
            SELECT MasterLabel, DeveloperName, (SELECT Type__c, Value__c FROM Default_Persona_Permissions__r)
            FROM Default_Persona__mdt
            WHERE DeveloperName = :personaName.replaceAll('\\s+', '_')
            WITH USER_MODE
            LIMIT 1
        ];
        return !defaultPersonas.isEmpty()
            ? defaultPersonas[0]
            : new Default_Persona__mdt(DeveloperName = personaName.replaceAll('\\s+', '_'), MasterLabel = personaName);
    }

    private static Group createPublicGroup(String personaName, Default_Persona__mdt defaultPersona) {
        Group publicGroup = new Group(DeveloperName = getUniqueName(personaName), Name = personaName, DoesIncludeBosses = true, Type = 'Regular');
        DML.safeInsert(
            publicGroup,
            String.format(
                Label.ErrorWhileInserting,
                new List<String>{ Group.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).getLabel(), 'PersonaServiceImpl.createPublicGroup' }
            )
        );
        return publicGroup;
    }

    private static Group createPublicGroup(Default_Persona__mdt defaultPersona) {
        return createPublicGroup(defaultPersona.MasterLabel, defaultPersona);
    }

    private static PermissionSetGroup createPermissionSetGroup(String personaName) {
        String uniquePersonaName = getUniqueName(personaName);
        PermissionSetGroup permissionSetGroup = new PermissionSetGroup(DeveloperName = uniquePersonaName, MasterLabel = uniquePersonaName);
        DML.safeInsert(
            permissionSetGroup,
            String.format(Label.ErrorWhileInserting, new List<String>{ 'PermissionSetGroup', 'PersonaServiceImpl.createPermissionSetGroup' })
        );
        return permissionSetGroup;
    }

    private static PermissionSet createPermissionSet(String personaName) {
        // Because of the SF limitation we have to put _PS at the end of the label since it can be same name for permission set group too
        String uniquePersonaName = getUniqueName(personaName) + '_PS';
        PermissionSet permissionSet = new PermissionSet();
        permissionSet.Label = uniquePersonaName;
        permissionSet.Name = uniquePersonaName;
        permissionSet.PermissionsRunFlow = true;
        permissionSet.PermissionsRunReports = true;
        permissionSet.PermissionsApiEnabled = true;

        DML.safeInsert(
            permissionSet,
            String.format(Label.ErrorWhileInserting, new List<String>{ 'PermissionSet', 'PersonaServiceImpl.createPermissionSet' })
        );

        createObjectPermission(permissionSet.Id);

        return permissionSet;
    }

    private static void createObjectPermission(Id permissionSetId) {
        ObjectPermissions objectPermission = new ObjectPermissions();
        objectPermission.parentid = permissionSetId;
        objectPermission.permissionscreate = true;
        objectPermission.permissionsdelete = true;
        objectPermission.permissionsedit = true;
        objectPermission.permissionsread = true;
        objectPermission.sobjecttype = 'pushtopic';

        DML.safeInsert(
            objectPermission,
            String.format(Label.ErrorWhileInserting, new List<String>{ 'ObjectPermissions', 'PersonaServiceImpl.createObjectPermission' })
        );
    }

    @SuppressWarnings('PMD.ApexCRUDViolation')
    private static void assignAppPermissions(String permissionSetId, PersonaDefinitionConfig config) {
        Set<String> appNames = new Set<String>();
        for (PersonaDefinitionConfig.ConfigEntry entry : config.appPermissions) {
            appNames.add(entry.name);
        }

        List<SetupEntityAccess> appPermissions = new List<SetupEntityAccess>();
        // False positive since app menu item is setup object
        for (AppMenuItem appMenuItem : [SELECT Id, ApplicationId FROM AppMenuItem WHERE Type = 'TabSet' AND Name IN :appNames]) {
            // NOPMD
            appPermissions.add(new SetupEntityAccess(SetupEntityId = appMenuItem.ApplicationId, ParentId = permissionSetId));
        }

        DML.safeInsert(
            appPermissions,
            String.format(Label.ErrorWhileInserting, new List<String>{ 'SetupEntityAccess', 'PersonaServiceImpl.assignAppPermissions' })
        );
    }

    @SuppressWarnings('PMD.ApexCRUDViolation')
    private static void assignCustomPermissions(String permissionSetId, PersonaDefinitionConfig config) {
        Set<String> customPermissionNames = new Set<String>();
        for (PersonaDefinitionConfig.ConfigEntry entry : config.customPermissions) {
            customPermissionNames.add(entry.name);
        }

        List<SetupEntityAccess> customPermissions = new List<SetupEntityAccess>();
        // False positive sinceCustomPermission is setup object
        for (CustomPermission customPermission : [SELECT Id FROM CustomPermission WHERE DeveloperName IN :customPermissionNames]) {
            // NOPMD
            customPermissions.add(new SetupEntityAccess(SetupEntityId = customPermission.Id, ParentId = permissionSetId));
        }

        DML.safeInsert(
            customPermissions,
            String.format(Label.ErrorWhileInserting, new List<String>{ 'SetupEntityAccess', 'PersonaServiceImpl.assignCustomPermissions' })
        );
    }

    @SuppressWarnings('PMD.ExcessiveParameterList')
    private static PersonaDefinitionConfig createPersonaConfig(
        Default_Persona__mdt defaultPersona,
        Boolean isCustom,
        Group publicGroup,
        PermissionSetGroup permissionSetGroup,
        PermissionSet permissionSet
    ) {
        PersonaDefinitionConfig config = new PersonaDefinitionConfig();
        config.publicGroupId = publicGroup.Id;
        config.permissionSetGroups.add(new PersonaDefinitionConfig.ConfigEntry().name(permissionSetGroup.DeveloperName).isStandard());
        config.permissionSets.add(new PersonaDefinitionConfig.ConfigEntry().name(permissionSet.Name).isStandard());
        if (defaultPersona.Default_Persona_Permissions__r != null) {
            for (Default_Persona_Permission__mdt defaultPersonaPermission : defaultPersona.Default_Persona_Permissions__r) {
                PersonaDefinitionConfig.ConfigEntry entry = new PersonaDefinitionConfig.ConfigEntry().name(defaultPersonaPermission.Value__c);
                if (!isCustom) {
                    entry.isStandard();
                }
                if (defaultPersonaPermission.Type__c == PersonaDefinitionConfig.PermissionType.PermissionSet.name()) {
                    config.permissionSets.add(entry);
                } else if (defaultPersonaPermission.Type__c == PersonaDefinitionConfig.PermissionType.PermissionSetGroup.name()) {
                    config.permissionSetGroups.add(entry);
                } else if (defaultPersonaPermission.Type__c == PersonaDefinitionConfig.PermissionType.CopadoLicense.name()) {
                    config.licenses.add(entry);
                } else if (defaultPersonaPermission.Type__c == PersonaDefinitionConfig.PermissionType.PackageLicense.name()) {
                    config.packageLicenses.add(entry);
                } else if (defaultPersonaPermission.Type__c == PersonaDefinitionConfig.PermissionType.CredentialAccessLevel.name()) {
                    config.defaultCredentialAccessLevel = defaultPersonaPermission.Value__c;
                } else if (defaultPersonaPermission.Type__c == PersonaDefinitionConfig.PermissionType.AppPermission.name()) {
                    config.appPermissions.add(entry);
                } else if (defaultPersonaPermission.Type__c == PersonaDefinitionConfig.PermissionType.CustomPermission.name()) {
                    config.customPermissions.add(entry);
                }
            }
        }

        return config;
    }

    private static void assignPermissionSets(PermissionSetGroup permissionSetGroup, PersonaDefinitionConfig config) {
        Set<String> permissionSetNames = new Set<String>();
        for (PersonaDefinitionConfig.ConfigEntry entry : config.permissionSets) {
            permissionSetNames.add(entry.name);
        }
        List<PermissionSetGroupComponent> components = new List<PermissionSetGroupComponent>();
        for (PermissionSet permissionSet : [SELECT Id, Name FROM PermissionSet WHERE Name IN :permissionSetNames WITH USER_MODE]) {
            components.add(new PermissionSetGroupComponent(PermissionSetGroupId = permissionSetGroup.Id, PermissionSetId = permissionSet.Id));
        }
        DML.safeInsert(
            components,
            String.format(
                Label.ErrorWhileInserting,
                new List<String>{
                    PermissionSetGroupComponent.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).getLabel(),
                    'PersonaServiceImpl.assignPermissionSets'
                }
            )
        );
    }

    @SuppressWarnings('PMD.ExcessiveParameterList')
    private static Persona_Definition__c createPersona(String personaName, String description, PersonaDefinitionConfig config, Boolean isStandard) {
        Persona_Definition__c persona = new Persona_Definition__c(
            Name = personaName,
            Description__c = description,
            Config_JSON__c = JSON.serialize(config),
            Is_Standard__c = isStandard != null ? isStandard : false
        );
        DML.safeInsert(
            persona,
            String.format(
                Label.ErrorWhileInserting,
                new List<String>{
                    Persona_Definition__c.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).getLabel(),
                    'PersonaServiceImpl.createPersona'
                }
            )
        );
        return persona;
    }

    private static void deletePersonaRecord(Id personaId) {
        Persona_Definition__c personaToDelete = new Persona_Definition__c(Id = personaId);
        DML.safeDelete(
            personaToDelete,
            String.format(
                Label.ErrorWhileDeleting,
                new List<String>{
                    Persona_Definition__c.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).getLabel(),
                    'PersonaServiceImpl.deletePersonaRecord'
                }
            )
        );
    }

    private static void updateUsers(List<Id> userIds) {
        List<User> usersToUpdate = new List<User>();
        for (Id userId : userIds) {
            usersToUpdate.add(new User(Id = userId, Persona_Id__c = null));
        }
        DML.safeUpdate(
            usersToUpdate,
            String.format(
                Label.ErrorWhileUpdating,
                new List<String>{ User.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).getLabel(), 'PersonaServiceImpl.updateUsers' }
            )
        );
    }

    private static void deletePublicGroup(PersonaDefinitionConfig config) {
        Group groupToDelete = new Group(Id = config.publicGroupId);
        DML.safeDelete(
            groupToDelete,
            String.format(
                Label.ErrorWhileDeleting,
                new List<String>{ Group.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).getLabel(), 'PersonaServiceImpl.deletePublicGroup' }
            )
        );
    }

    private static void deletePermissionSet(PersonaDefinitionConfig config) {
        deletePermissionSetAssignments(config.getPersonaPermissionSet());

        List<PermissionSet> permissionSetToDelete = [
            SELECT Id
            FROM PermissionSet
            WHERE Name = :config.getPersonaPermissionSet()
            WITH USER_MODE
            LIMIT 1
        ];
        DML.safeDelete(
            permissionSetToDelete,
            String.format(
                Label.ErrorWhileDeleting,
                new List<String>{
                    PermissionSet.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).getLabel(),
                    'PersonaServiceImpl.deletePermissionSet'
                }
            )
        );
    }

    // PMD False positive, as WITH USER_MODE is not supported yet
    private static void deletePermissionSetAssignments(String permissionSet) {
        List<PermissionSetAssignment> permissionSetAssignments = [
            SELECT Id
            FROM PermissionSetAssignment
            WHERE PermissionSet.Name = :permissionSet
            WITH USER_MODE
        ];

        DML.safeDelete(
            permissionSetAssignments,
            String.format(
                Label.ErrorWhileDeleting,
                new List<String>{
                    PermissionSetAssignment.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).getLabel(),
                    'PersonaServiceImpl.deletePermissionSetAssignments'
                }
            )
        );
    }

    private static void deletePermissionSetGroup(PersonaDefinitionConfig config) {
        deletePermissionSetGroupAssignments(config.getPersonaPermissionSetGroup());

        List<PermissionSetGroup> permissionSetGroupToDelete = [
            SELECT Id
            FROM PermissionSetGroup
            WHERE DeveloperName = :config.getPersonaPermissionSetGroup()
            WITH USER_MODE
            LIMIT 1
        ];
        DML.safeDelete(
            permissionSetGroupToDelete,
            String.format(
                Label.ErrorWhileDeleting,
                new List<String>{
                    PermissionSetGroup.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).getLabel(),
                    'PersonaServiceImpl.deletePermissionSetGroup'
                }
            )
        );
    }

    // PMD False positive, as WITH USER_MODE is not supported yet
    private static void deletePermissionSetGroupAssignments(String permissionSetGroup) {
        List<PermissionSetAssignment> permissionSetAssignments = [
            SELECT Id
            FROM PermissionSetAssignment
            WHERE PermissionSetGroup.DeveloperName = :permissionSetGroup
            WITH USER_MODE
        ];

        DML.safeDelete(
            permissionSetAssignments,
            String.format(
                Label.ErrorWhileDeleting,
                new List<String>{
                    PermissionSetAssignment.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).getLabel(),
                    'PersonaServiceImpl.deletePermissionSetGroupAssignments'
                }
            )
        );
    }

    private static void deletePackageLicenses(List<Id> userIds, PersonaDefinitionConfig config) {
        if (config.packageLicenses.isEmpty()) {
            return;
        }

        List<String> licenses = new List<String>();
        for (PersonaDefinitionConfig.ConfigEntry entry : config.packageLicenses) {
            licenses.add(entry.name);
        }
        RemoveLicenseServiceImpl.removePackageLicenses(licenses, userIds);
    }

    private static void deleteCopadoLicenses(List<Id> userIds, PersonaDefinitionConfig config) {
        if (config.licenses.isEmpty()) {
            return;
        }

        List<String> licenses = new List<String>();
        for (PersonaDefinitionConfig.ConfigEntry entry : config.licenses) {
            licenses.add(entry.name);
        }

        RemoveLicenseServiceImpl.removeCopadoLicenses(licenses, userIds);
    }

    private static String getUniqueName(String personaName) {
        personaName = personaName.trim().replaceAll('[^a-zA-Z0-9]+', '_');
        return personaName + '_' +  System.now().format('yyyy_MM_dd_HH_mm_ss');
    }
}