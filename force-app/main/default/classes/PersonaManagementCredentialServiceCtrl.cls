public with sharing class PersonaManagementCredentialServiceCtrl {
    @AuraEnabled
    public static List<Org__c> getCredentials() {
        return [SELECT Name, Environment__r.Name, Platform__c, Org_Type__c FROM Org__c WHERE Default_Credential__c = TRUE WITH USER_MODE];
    }

    @AuraEnabled
    public static List<PersonaCredential> getCredentialsForPersona(String personaId) {
        List<PersonaCredential> result = new List<PersonaCredential>();
        PersonaDefinitionConfig config = PersonaServiceHelper.getPersonaDefinition(personaId);
        Map<String, Org__Share> orgShareById = new Map<String, Org__Share>();
        for (Org__Share orgShare : [
            SELECT ParentId, AccessLevel
            FROM Org__Share
            WHERE RowCause = :Schema.Org__Share.RowCause.Copado_Persona__c AND UserOrGroupId = :config.publicGroupId
            WITH USER_MODE
        ]) {
            orgShareById.put(orgShare.ParentId, orgShare);
        }
        for (Org__c credential : [
            SELECT Name, Environment__r.Name, Platform__c, Org_Type__c
            FROM Org__c
            WHERE Id IN :orgShareById.keySet()
            WITH USER_MODE
        ]) {
            PersonaCredential personaCredential = new PersonaCredential();
            personaCredential.credential = credential;
            personaCredential.credentialShare = orgShareById.get(credential.Id);
            result.add(personaCredential);
        }
        return result;
    }

    @AuraEnabled
    public static void shareCredentials(String personaId, List<String> credentialIds) {
        Persona.ShareCredentialRequest request = new Persona.ShareCredentialRequest();
        request.credentialIds = credentialIds;
        request.personaId = personaId;
        Persona.CredentialService.share(request);
    }

    @AuraEnabled
    public static void removeCredential(String personaId, List<String> credentialIds) {
        Persona.RemoveCredentialRequest request = new Persona.RemoveCredentialRequest();
        request.credentialIds = credentialIds;
        request.personaId = personaId;
        Persona.CredentialService.remove(request);
    }

    @AuraEnabled
    public static void changeCredentialAccessLevel(String personaId, String credentialId, String accessLevel) {
        Persona.UpdateAccessLevelRequest request = new Persona.UpdateAccessLevelRequest();
        request.credentialIds = new List<String>{ credentialId };
        request.personaId = personaId;
        request.accessLevel = accessLevel;
        Persona.CredentialService.updateAccessLevel(request);
    }

    public with sharing class PersonaCredential {
        @AuraEnabled
        public Org__c credential;
        @AuraEnabled
        public Org__Share credentialShare;
    }
}