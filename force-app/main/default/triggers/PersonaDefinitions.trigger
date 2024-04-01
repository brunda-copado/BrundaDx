trigger PersonaDefinitions on Persona_Definition__c(before update) {
    fflib_SObjectDomain.triggerHandler(PersonaDefinitions.class);
}