public inherited sharing class FunctionsSelector extends fflib_SObjectSelector {
    public SObjectType getSObjectType() {
        return Function__c.sObjectType;
    }

    public List<SObjectField> getSObjectFieldList() {
        return new List<SObjectField>{
            Function__c.Id,
            Function__c.Name,
            Function__c.Script__c,
            Function__c.Image_Name__c,
            Function__c.Parameters__c,
            Function__c.Timeout__c,
            Function__c.API_Name__c,
            Function__c.Options__c,
            Function__c.Worker_Size__c,
            Function__c.Type__c,
            Function__c.Callback_Type__c,
            Function__c.ApexClass__c,
            Function__c.FlowHandler__c,
            Function__c.Version__c,
            Function__c.Result_Viewer_Component__c
        };
    }

    public Function__c byId(Id recordId) {
        List<Function__c> results = byIds(new Set<Id>{ recordId });
        return results.isEmpty() ? null : results[0];
    }

    public List<Function__c> byIds(Set<Id> ids) {
        return selectSObjectsById(ids);
    }

    public Function__c byApiName(String apiName) {
        List<Function__c> result = byApiNames(new Set<String>{ apiName });

        return (result.isEmpty() ? null : result[0]);
    }

    public List<Function__c> byApiNames(Set<String> apiNames) {
        return Database.query(newQueryFactory().setCondition(Function__c.API_Name__c + ' IN :apiNames').toSOQL());
    }

    // TODO move this out of selector
    @AuraEnabled
    public static List<Function__c> getFunctionsByApiName(String functionApiName) {
        return new List<Function__c>([SELECT Id, Name FROM Function__c WHERE Api_Name__c = :functionApiName WITH SECURITY_ENFORCED]);
    }
}