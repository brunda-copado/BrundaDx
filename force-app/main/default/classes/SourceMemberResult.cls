@SuppressWarnings('PMD.AvoidGlobalModifier,PMD.FormalParameterNamingConventions,PMD.FieldNamingConventions')
global with sharing class SourceMemberResult {
    @AuraEnabled
    global String CreatedDate;
    @AuraEnabled
    global LookupUserField CreatedBy;
    @AuraEnabled
    global String LastModifiedDate;
    @AuraEnabled
    global LookupUserField LastModifiedBy;
    @AuraEnabled
    global Boolean IsNameObsolete;
    @AuraEnabled
    global String MemberName;
    @AuraEnabled
    global String MemberType;

    global with sharing class LookupUserField {
        @AuraEnabled
        global String Name;
    }
}