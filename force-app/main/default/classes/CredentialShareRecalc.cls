@SuppressWarnings('PMD.AvoidGlobalModifier')
public with sharing class CredentialShareRecalc implements Database.Batchable<sObject> {
    // PUBLIC

    public Database.QueryLocator start(Database.BatchableContext context) {
        return Database.getQueryLocator([SELECT Config_Json__c FROM Persona_Definition__c]);
    }

    public void execute(Database.BatchableContext context, List<sObject> scope) {
        Map<Id, List<Persona_Definition__c>> personasByCredential = groupByCredential((List<Persona_Definition__c>) scope);

        List<Org__Share> oldOrgShare = [
            SELECT Id
            FROM Org__Share
            WHERE ParentId IN :personasByCredential.keySet() AND RowCause = :Schema.Org__Share.RowCause.Copado_Persona__c
        ];

        List<Org__Share> newOrgShare = new List<Org__Share>();
        for (Id credentialId : personasByCredential.keySet()) {
            for (Persona_Definition__c personaDefinition : personasByCredential.get(credentialId)) {
                Org__Share share = PersonaCredentialServiceImpl.shareWithReason(credentialId, personaDefinition);
                newOrgShare.add(share);
            }
        }

        delete oldOrgShare;

        insert newOrgShare;
    }

    @SuppressWarnings('PMD.EmptyStatementBlock')
    public void finish(Database.BatchableContext context) {
    }

    // PRIVATE

    private static Map<Id, List<Persona_Definition__c>> groupByCredential(List<Persona_Definition__c> personaDefinitions) {
        Map<Id, List<Persona_Definition__c>> result = new Map<Id, List<Persona_Definition__c>>();
        for (Persona_Definition__c personaDefinition : personaDefinitions) {
            PersonaDefinitionConfig config = (PersonaDefinitionConfig) JSON.deserialize(
                personaDefinition.Config_Json__c,
                PersonaDefinitionConfig.class
            );
            for (Id credentialId : config.credentialIds) {
                if (!result.containsKey(credentialId)) {
                    result.put(credentialId, new List<Persona_Definition__c>());
                }
                result.get(credentialId).add(personaDefinition);
            }
        }
        return result;
    }
}