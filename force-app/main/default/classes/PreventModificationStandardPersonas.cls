public with sharing class PreventModificationStandardPersonas {
    private List<Persona_Definition__c> records;
    private Map<Id, Persona_Definition__c> old;

    // CONSTRUCTOR

    public PreventModificationStandardPersonas(List<Persona_Definition__c> records, Map<Id, Persona_Definition__c> old) {
        this.records = records;
        this.old = old;
    }

    // PUBLIC

    public void execute() {
        for (Persona_Definition__c personaDefinition : records) {
            Persona_Definition__c oldPersonaDefinition = old.get(personaDefinition.Id);
            PersonaDefinitionConfig personaConfig = (PersonaDefinitionConfig) JSON.deserialize(
                personaDefinition.Config_JSON__c,
                PersonaDefinitionConfig.class
            );
            PersonaDefinitionConfig oldPersonaConfig = (PersonaDefinitionConfig) JSON.deserialize(
                oldPersonaDefinition.Config_JSON__c,
                PersonaDefinitionConfig.class
            );

            try {
                checkConfigEntries(oldPersonaConfig.permissionSets, personaConfig.permissionSets);
                checkConfigEntries(oldPersonaConfig.permissionSetGroups, personaConfig.permissionSetGroups);
                checkConfigEntries(oldPersonaConfig.licenses, personaConfig.licenses);
                checkConfigEntries(oldPersonaConfig.packageLicenses, personaConfig.packageLicenses);
                checkConfigEntries(oldPersonaConfig.appPermissions, personaConfig.appPermissions);
            } catch (ApplicationException e) {
                personaDefinition.addError(Label.Modify_Standard_Persona_Error);
            }
        }
    }

    private void checkConfigEntries(List<PersonaDefinitionConfig.ConfigEntry> oldEntries, List<PersonaDefinitionConfig.ConfigEntry> newEntries) {
        for (PersonaDefinitionConfig.ConfigEntry configEntry : oldEntries) {
            if (configEntry.isStandard && !configContains(newEntries, configEntry.name)) {
                throw new ApplicationException();
            }
        }
    }

    private Boolean configContains(List<PersonaDefinitionConfig.ConfigEntry> configEntries, String value) {
        Set<PersonaDefinitionConfig.ConfigEntry> entriesSet = new Set<PersonaDefinitionConfig.ConfigEntry>(configEntries);
        return !entriesSet.isEmpty() && entriesSet.contains(new PersonaDefinitionConfig.ConfigEntry().name(value).isStandard());
    }
}