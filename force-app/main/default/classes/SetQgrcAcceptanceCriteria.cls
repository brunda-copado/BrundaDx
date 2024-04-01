public with sharing class SetQgrcAcceptanceCriteria {
    private List<Quality_Gate_Rule_Condition__c> records;
    private Map<Id, SObject> oldRecords;

    // CTOR

    public SetQgrcAcceptanceCriteria(List<Quality_Gate_Rule_Condition__c> records, Map<Id, SObject> oldRecords) {
        this.records = records;
        this.oldRecords = oldRecords;
    }

    // PUBLIC

    public void execute() {
        Map<Id, List<Quality_Gate_Rule_Condition__c>> conditionsByExtensionConfigurationId = getConditionsByExtensionConfigurationId();

        for (ExtensionConfiguration__c record : new ExtensionConfigurationsSelector().byIds(conditionsByExtensionConfigurationId.keyset())) {
            for (Quality_Gate_Rule_Condition__c qualityGateRuleCondition : conditionsByExtensionConfigurationId.get(record.Id)) {
                qualityGateRuleCondition.AcceptanceCriteria__c = record.AcceptanceCriteria__c;
            }
        }
    }

    // PRIVATE

    private Map<Id, List<Quality_Gate_Rule_Condition__c>> getConditionsByExtensionConfigurationId() {
        Map<Id, List<Quality_Gate_Rule_Condition__c>> conditionsByExtensionConfigurationId = new Map<Id, List<Quality_Gate_Rule_Condition__c>>();
        
        for (Quality_Gate_Rule_Condition__c record : records) {
            if (!conditionsByExtensionConfigurationId.containsKey(record.Extension_Configuration__c)) {
                conditionsByExtensionConfigurationId.put(record.Extension_Configuration__c, new List<Quality_Gate_Rule_Condition__c>());
            }
            addCondition(conditionsByExtensionConfigurationId, record); 
        }

        return conditionsByExtensionConfigurationId;
    }

    private void addCondition(Map<Id, List<Quality_Gate_Rule_Condition__c>> conditionsByExtensionConfigurationId, 
                            Quality_Gate_Rule_Condition__c record){
        Quality_Gate_Rule_Condition__c oldRecord = oldRecords != null ? (Quality_Gate_Rule_Condition__c) oldRecords.get(record.Id) : null;

        if (oldRecord == null || record.Extension_Configuration__c != oldRecord.Extension_Configuration__c) {
            conditionsByExtensionConfigurationId.get(record.Extension_Configuration__c).add(record);
        }
    }
}