public inherited sharing class ExtensionConfigurationsSelector extends fflib_SObjectSelector {
    //CONSTRUCTOR

    public ExtensionConfigurationsSelector() {
        this(true);
    }

    public ExtensionConfigurationsSelector(Boolean enforceFLS) {
        super(false, true, enforceFLS, false);
    }

    //PUBLIC

    public SObjectType getSObjectType() {
        return ExtensionConfiguration__c.sObjectType;
    }

    public List<SObjectField> getSObjectFieldList() {
        return new List<SObjectField>{
            ExtensionConfiguration__c.Id,
            ExtensionConfiguration__c.Name,
            ExtensionConfiguration__c.Details__c,
            ExtensionConfiguration__c.ExtensionTool__c,
            ExtensionConfiguration__c.Active__c,
            ExtensionConfiguration__c.AcceptanceCriteria__c
        };
    }

    public List<ExtensionConfiguration__c> selectAll() {
        return (List<ExtensionConfiguration__c>) Database.query(newQueryFactory().toSOQL());
    }

    public List<ExtensionConfiguration__c> byIds(Set<Id> recordIds) {
        return (List<ExtensionConfiguration__c>) selectSObjectsById(recordIds);
    }

    public Map<Id, ExtensionConfiguration__c> getExtensionConfigsByIds(List<Test__c> newtests, Map<Id, Test__c> oldTests) {
        Set<Id> extensionConfigIds = new Set<Id>();

        for (Test__c test : newtests) {
            if (oldTests == null ? true : test.ExtensionConfiguration__c != oldTests.get(test.Id).ExtensionConfiguration__c) {
                extensionConfigIds.add(test.ExtensionConfiguration__c);
            }
        }

        return new Map<Id, ExtensionConfiguration__c>(byIds(extensionConfigIds));
    }
}