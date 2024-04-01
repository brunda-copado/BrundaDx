public with sharing class PersonaServiceHelper {
    // PMD False positive, as WITH USER_MODE is not supported yet
    public static PersonaDefinitionConfig getPersonaDefinition(Id personaId) {
        List<Persona_Definition__c> personaDefinitions = [SELECT Config_JSON__c FROM Persona_Definition__c WHERE Id = :personaId WITH USER_MODE];
        PersonaDefinitionConfig config = (PersonaDefinitionConfig) JSON.deserialize(
            personaDefinitions[0].Config_JSON__c,
            PersonaDefinitionConfig.class
        );
        if (config.packageLicenses == null) {
            config.packageLicenses = new List<PersonaDefinitionConfig.ConfigEntry>();
        }
        return config;
    }

    public static List<Id> findUsersInGroup(String groupId) {
        List<Id> result = new List<Id>();

        // False positive: group member controlled by parent
        for (GroupMember member : [SELECT UserOrGroupId FROM GroupMember WHERE GroupId = :groupId WITH USER_MODE]) {
            result.add(member.UserOrGroupId);
        }

        return result;
    }

    public static List<Id> findUsersForPersona(String personaId) {
        List<Id> result = new List<Id>();

        for (User user : [SELECT Id FROM User WHERE Persona_Id__c = :personaId WITH USER_MODE]) {
            result.add(user.Id);
        }

        return result;
    }

    public static void updatePersonaConfig(Id personaId, PersonaDefinitionConfig personaDefinition) {
        DML.safeUpdate(
            new Persona_Definition__c(Id = personaId, Config_Json__c = JSON.serialize(personaDefinition)),
            String.format(
                Label.ErrorWhileUpdating,
                new List<String>{
                    Persona_Definition__c.SObjectType.getDescribe(SObjectDescribeOptions.DEFERRED).getLabel(),
                    'PersonaServiceHelper.updatePersonaConfig'
                }
            )
        );
    }
}