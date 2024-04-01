public with sharing class PersonaManagementUserServiceCtrl {
    private static List<String> discardUsers = new List<String>{ 'Integration User', 'Security User' };

    @AuraEnabled
    public static List<PersonaUser> getUsers() {
        List<PersonaUser> result = new List<PersonaUser>();
        Map<Id, Persona_Definition__c> personaDefinitionById = new Map<Id, Persona_Definition__c>(
            [SELECT Name FROM Persona_Definition__c WITH USER_MODE]
        );
        for (User user : [
            SELECT Name, Email, IsActive, Persona_Id__c
            FROM User
            WHERE UserType = 'Standard' AND Name NOT IN :discardUsers
            WITH USER_MODE
        ]) {
            PersonaUser personaUser = new PersonaUser();
            personaUser.user = user;
            personaUser.persona = personaDefinitionById.get(user.Persona_Id__c);
            result.add(personaUser);
        }
        return result;
    }

    @AuraEnabled
    public static List<User> getUsersForPersona(String personaId) {
        return [SELECT Name, Username, Email, IsActive FROM User WHERE Persona_Id__c = :personaId WITH USER_MODE];
    }

    @AuraEnabled
    public static void addUser(String personaId, List<String> userIds) {
        Persona.AddUserRequest request = new Persona.AddUserRequest();
        request.personaId = personaId;
        request.userIds = userIds;
        Persona.UserService.add(request);
    }

    @AuraEnabled
    public static void addUser2(String personaId, List<String> userIds) {
        Persona.AddUserRequest request = new Persona.AddUserRequest();
        request.personaId = personaId;
        request.userIds = userIds;
        Persona.UserService.add2(request);
    }

    @AuraEnabled
    public static void addUser3(String personaId, List<String> userIds) {
        Persona.AddUserRequest request = new Persona.AddUserRequest();
        request.personaId = personaId;
        request.userIds = userIds;
        Persona.UserService.add3(request);
    }

    @AuraEnabled
    public static void removeUser(String personaId, List<String> userIds) {
        Persona.RemoveUserRequest request = new Persona.RemoveUserRequest();
        request.personaId = personaId;
        request.userIds = userIds;
        Persona.UserService.remove(request);
    }

    @AuraEnabled
    public static void removeUser2(String personaId, List<String> userIds) {
        Persona.RemoveUserRequest request = new Persona.RemoveUserRequest();
        request.personaId = personaId;
        request.userIds = userIds;
        Persona.UserService.remove2(request);
    }

    @AuraEnabled
    public static void removeUser3(String personaId, List<String> userIds) {
        Persona.RemoveUserRequest request = new Persona.RemoveUserRequest();
        request.personaId = personaId;
        request.userIds = userIds;
        Persona.UserService.remove3(request);
    }

    @AuraEnabled
    public static void resetPassword(String userId) {
        System.resetPassword(userId, true);
    }

    public with sharing class PersonaUser {
        @AuraEnabled
        public User user;
        @AuraEnabled
        public Persona_Definition__c persona;
    }
}