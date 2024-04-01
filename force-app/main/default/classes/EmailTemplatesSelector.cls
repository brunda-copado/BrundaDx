public inherited sharing class EmailTemplatesSelector extends fflib_SObjectSelector {
    public SObjectType getSObjectType() {
        return EmailTemplate.sObjectType;
    }

    public List<SObjectField> getSObjectFieldList() {
        return new List<SObjectField>{ EmailTemplate.Id };
    }

    public List<EmailTemplate> byDevName(String devName) {
        return (List<EmailTemplate>) Database.query(newQueryFactory().setCondition(EmailTemplate.DeveloperName + ' = :devName').toSOQL());
    }
}