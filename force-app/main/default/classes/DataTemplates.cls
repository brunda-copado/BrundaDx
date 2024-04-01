public with sharing class DataTemplates extends fflib_SObjectDomain {
    public DataTemplates(List<Data_Template__c> records) {
        super(records);
    }

    public override void onAfterUpdate(Map<Id, SObject> oldRecords) {
        new UpdateTemplateDetailAttachment((List<Data_Template__c>) records, (Map<Id, Data_Template__c>) oldRecords).execute();
    }

    // INNER
    public class Constructor implements fflib_SObjectDomain.IConstructable {
        public fflib_SObjectDomain construct(List<SObject> records) {
            return new DataTemplates(records);
        }
    }
}