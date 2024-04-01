public inherited sharing class QualityGateRuleConditionsSelector extends fflib_SObjectSelector {
    @TestVisible
    private static List<Quality_Gate_Rule_Condition__c> mock = new List<Quality_Gate_Rule_Condition__c>();

    // CTOR

    public QualityGateRuleConditionsSelector() {
        this(true);
    }

    public QualityGateRuleConditionsSelector(Boolean enforceFLS) {
        super(false, true, enforceFLS);
    }

    // PUBLIC

    public SObjectType getSObjectType() {
        return Quality_Gate_Rule_Condition__c.sObjectType;
    }

    public List<SObjectField> getSObjectFieldList() {
        return new List<SObjectField>{
            Quality_Gate_Rule_Condition__c.Id,
            Quality_Gate_Rule_Condition__c.Name,
            Quality_Gate_Rule_Condition__c.Quality_Gate_Rule__c,
            Quality_Gate_Rule_Condition__c.Environment__c,
            Quality_Gate_Rule_Condition__c.Stage__c,
            Quality_Gate_Rule_Condition__c.Filter_Criteria__c,
            Quality_Gate_Rule_Condition__c.Pipeline__c,
            Quality_Gate_Rule_Condition__c.Platform__c,
            Quality_Gate_Rule_Condition__c.Status__c,
            Quality_Gate_Rule_Condition__c.Extension_Configuration__c,
            Quality_Gate_Rule_Condition__c.AcceptanceCriteria__c,
            Quality_Gate_Rule_Condition__c.Tests_From__c
        };
    }

    public List<Quality_Gate_Rule_Condition__c> byQualityGateRule(Id qualityGateRuleId) {
        Map<Id, List<Quality_Gate_Rule_Condition__c>> conditionsByRuleId = byQualityGateRule(new Set<Id>{ qualityGateRuleId });
        return conditionsByRuleId.get(qualityGateRuleId);
    }

    public Map<Id, List<Quality_Gate_Rule_Condition__c>> byQualityGateRule(Set<Id> qualityGateRuleIds) {
        Map<Id, List<Quality_Gate_Rule_Condition__c>> result = new Map<Id, List<Quality_Gate_Rule_Condition__c>>();

        for (Id qualityGateRuleId : qualityGateRuleIds) {
            result.put(qualityGateRuleId, new List<Quality_Gate_Rule_Condition__c>());
        }

        for (
            Quality_Gate_Rule_Condition__c qualityGateRuleCondition : (List<Quality_Gate_Rule_Condition__c>) Database.query(
                newQueryFactory()
                    .selectFields(new List<String>{ 'Quality_Gate_Rule__r.Name', 'Quality_Gate_Rule__r.Tool__c' })
                    .setCondition(Quality_Gate_Rule_Condition__c.Quality_Gate_Rule__c + ' IN :qualityGateRuleIds')
                    .toSOQL()
            )
        ) {
            Id qualityGateRuleId = qualityGateRuleCondition.Quality_Gate_Rule__c;
            result.get(qualityGateRuleId).add(qualityGateRuleCondition);
        }
        return result;
    }

    public List<Quality_Gate_Rule_Condition__c> byActiveMeetingAnyFilter(List<String> filters) {
        String condition = Quality_Gate_Rule_Condition__c.Status__c + ' = \'Active\'';
        if (!filters.isEmpty()) {
            condition += ' AND ' + String.join(filters, ' AND ');
        }
        return Database.query(newQueryFactory().setCondition(condition).toSOQL());
    }

    public List<Quality_Gate_Rule_Condition__c> byIds(Set<Id> ids) {
        return (Test.isRunningTest() && mock.size() > 0)
            ? mock
            : (List<Quality_Gate_Rule_Condition__c>) Database.query(
                  newQueryFactory().setEnforceFLS(true).selectField('Extension_Configuration__c.ExtensionTool__c').setCondition('Id IN :ids').toSOQL()
              );
    }

    public static void setMock(List<Quality_Gate_Rule_Condition__c> providers) {
        mock = providers;
    }

    public static List<Quality_Gate_Rule_Condition__c> getMock() {
        return mock;
    }
}