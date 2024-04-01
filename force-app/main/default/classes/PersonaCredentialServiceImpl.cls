public with sharing class PersonaCredentialServiceImpl {
    // PUBLIC

    public static void share(Persona.ShareCredentialRequest request) {
        PersonaDefinitionConfig config = PersonaServiceHelper.getPersonaDefinition(request.personaId);
        shareCredentials(request.credentialIds, config);
        updatePersonaDefinition(request.credentialIds, request.personaId, config);
    }

    public static void remove(Persona.RemoveCredentialRequest request) {
        PersonaDefinitionConfig config = PersonaServiceHelper.getPersonaDefinition(request.personaId);
        removeCredentials(request.credentialIds, config.publicGroupId);
        Set<Id> credentialsToRetain = new Set<Id>(config.credentialIds);
        credentialsToRetain.removeAll(request.credentialIds);
        updatePersonaDefinition(new List<Id>(credentialsToRetain), request.personaId, config);
    }

    public static void updateAccessLevel(Persona.UpdateAccessLevelRequest request) {
        PersonaDefinitionConfig personaDefinition = PersonaServiceHelper.getPersonaDefinition(request.personaId);
        updateCredentialsAccessLevel(request.credentialIds, personaDefinition, request.accessLevel);
    }

    // NOTE: helper method for Apex Sharing Batch class
    public static Org__Share shareWithReason(Id credential, Persona_Definition__c personaDefinition) {
        PersonaDefinitionConfig config = (PersonaDefinitionConfig) JSON.deserialize(personaDefinition.Config_Json__c, PersonaDefinitionConfig.class);
        return shareWithReason(credential, config);
    }

    // PRIVATE

    private static Org__Share shareWithReason(Id credential, PersonaDefinitionConfig config) {
        String publicGroup = config.publicGroupId;
        String accessLevel = config.defaultCredentialAccessLevel;
        return new Org__Share(
            RowCause = Schema.Org__Share.RowCause.Copado_Persona__c,
            ParentId = credential,
            UserOrGroupId = publicGroup,
            AccessLevel = String.isNotBlank(accessLevel) ? accessLevel : 'Read'
        );
    }

    private static void shareCredentials(List<Id> credentials, PersonaDefinitionConfig config) {
        List<Org__Share> credentialShares = shareWithReason(credentials, config);
        DML.safeInsert(
            credentialShares,
            String.format(
                Label.ErrorWhileInserting,
                new List<String>{
                    Org__Share.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).getLabel(),
                    'PersonaCredentialServiceImpl.share'
                }
            )
        );
    }

    private static List<Org__Share> shareWithReason(List<Id> credentials, PersonaDefinitionConfig config) {
        List<Org__Share> credentialShares = new List<Org__Share>();
        for (String credential : credentials) {
            credentialShares.add(shareWithReason(credential, config));
        }
        return credentialShares;
    }

    private static void updatePersonaDefinition(List<Id> credentials, Id personaId, PersonaDefinitionConfig config) {
        config.credentialIds = credentials;
        PersonaServiceHelper.updatePersonaConfig(personaId, config);
    }

    private static void removeCredentials(List<Id> credentials, String publicGroup) {
        List<Org__Share> orgShares = [
            SELECT Id
            FROM Org__Share
            WHERE ParentId IN :credentials AND UserOrGroupId = :publicGroup AND RowCause = :Schema.Org__Share.RowCause.Copado_Persona__c
            WITH USER_MODE
        ];
        DML.safeDelete(
            orgShares,
            String.format(
                Label.ErrorWhileDeleting,
                new List<String>{
                    Org__Share.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).getLabel(),
                    'PersonaCredentialServiceImpl.removeCredentials'
                }
            )
        );
    }

    private static void updateCredentialsAccessLevel(List<Id> credentialIds, PersonaDefinitionConfig config, String accessLevel) {
        String publicGroup = config.publicGroupId;
        List<Org__Share> orgShareToUpdate = new List<Org__Share>();
        for (Org__Share orgShare : [
            SELECT Id, AccessLevel
            FROM Org__Share
            WHERE ParentId IN :credentialIds AND UserOrGroupId = :publicGroup AND RowCause = :Schema.Org__Share.RowCause.Copado_Persona__c
            WITH USER_MODE
        ]) {
            orgShare.AccessLevel = accessLevel;
            orgShareToUpdate.add(orgShare);
        }
        DML.safeUpdate(
            orgShareToUpdate,
            String.format(
                Label.ErrorWhileUpdating,
                new List<String>{
                    Org__Share.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).getLabel(),
                    'PersonaCredentialServiceImpl.updateAccessLevel'
                }
            )
        );
    }
}