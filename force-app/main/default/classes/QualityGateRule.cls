@IsTest
public class QualityGateRule extends DomainBuilder {
    public QualityGateRule() {
        super(Quality_Gate_Rule__c.SObjectType);
    }

    public QualityGateRule add(QualityGateRuleCondition condition) {
        return (QualityGateRule) condition.setParent(Quality_Gate_Rule_Condition__c.Quality_Gate_Rule__c, this);
    }

    public QualityGateRule name(String name) {
        return (QualityGateRule) set(Quality_Gate_Rule__c.Name, name);
    }

    public QualityGateRule action(String action) {
        return (QualityGateRule) set(Quality_Gate_Rule__c.Actions__c, action);
    }

    public QualityGateRule actions(List<String> actions) {
        String actionList = String.join(actions, ';');
        return (QualityGateRule) set(Quality_Gate_Rule__c.Actions__c, actionList);
    }

    public QualityGateRule active(Boolean active) {
        return (QualityGateRule) set(Quality_Gate_Rule__c.Status__c, active ? 'Active' : 'Inactive');
    }

    public QualityGateRule tool(String type) {
        return (QualityGateRule) set(Quality_Gate_Rule__c.Tool__c, type);
    }

    public QualityGateRule sequence(String sequence) {
        return (QualityGateRule) set(Quality_Gate_Rule__c.Execution_sequence__c, sequence);
    }

    public QualityGateRule json(String json) {
        return (QualityGateRule) set(Quality_Gate_Rule__c.dataJson__c, json);
    }
}