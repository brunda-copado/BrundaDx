public inherited sharing class DataTemplatesSelector extends fflib_SObjectSelector {
    public SObjectType getSObjectType() {
        return Data_Template__c.sObjectType;
    }

    public List<SObjectField> getSObjectFieldList() {
        return new List<SObjectField>{
            Data_Template__c.Id,
            Data_Template__c.Name,
            Data_Template__c.Main_Object__c,
            Data_Template__c.Template_Source_Org__c
        };
    }

    public DataTemplatesSelector() {
        this(true);
    }

    public DataTemplatesSelector(Boolean enforceFLS) {
        super(false, true, enforceFLS);
    }

    public List<Data_Template__c> byId(List<Id> recordIds) {
        return (List<Data_Template__c>) byId(new Set<Id>(recordIds));
    }

    public List<Data_Template__c> byId(Set<Id> recordIds) {
        return (List<Data_Template__c>) selectSObjectsById(recordIds);
    }

    @SuppressWarnings('PMD.UnusedLocalVariable')
    public List<Data_Template__c> byObjectRelatedToExistingTemplate(String objectName, Id recordId) {
        List<Data_Template__c> result = new List<Data_Template__c>();

        List<Data_Template__c> dataTemplates = byId(new Set<Id>{ recordId });
        if (!dataTemplates.isEmpty()) {
            Data_Template__c dataTemplate = dataTemplates.get(0);
            String orgCredential = dataTemplate.Template_Source_Org__c;
            fflib_QueryFactory query = newQueryFactory()
                .setCondition(
                    Data_Template__c.Main_Object__c +
                    ' = :objectName' +
                    ' AND ' +
                    Data_Template__c.Template_Source_Org__c +
                    ' = :orgCredential' +
                    ' AND ' +
                    Data_Template__c.Active__c +
                    ' = TRUE' +
                    ' AND ' +
                    Data_Template__c.Id +
                    ' != :recordId'
                );
            result = (List<Data_Template__c>) Database.query(query.toSOQL());
        }

        return result;
    }

    public List<Data_Template__c> byTemplateName(String templateName) {
        fflib_QueryFactory query = newQueryFactory().setCondition(Data_Template__c.Name + ' =: templateName');
        return (List<Data_Template__c>) Database.query(query.toSOQL());
    }

    public List<Data_Template__c> byIdWithAllFields(Set<Id> recordIds) {
        return (List<Data_Template__c>) Database.query(
            newQueryFactory()
            .selectFields(Schema.SObjectType.Data_Template__c.fields.getMap().keySet())
            .setCondition('id in :recordIds')
            .toSOQL()
            );        
    }
    
}