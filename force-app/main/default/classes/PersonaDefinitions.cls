public with sharing class PersonaDefinitions extends fflib_SObjectDomain {
    // CONSTRUCTOR

    public PersonaDefinitions(List<Persona_Definition__c> records) {
        super(records);
    }

    // PUBLIC

    public override void onBeforeUpdate(Map<Id, SObject> old) {
        new PreventModificationStandardPersonas(records, (Map<Id, Persona_Definition__c>) old).execute();
    }

    // INNER

    public class Constructor implements fflib_SObjectDomain.IConstructable {
        public fflib_SObjectDomain construct(List<SObject> records) {
            return new PersonaDefinitions(records);
        }
    }
}