@IsTest
public class QualityGateRuleCondition extends DomainBuilder {
    public QualityGateRuleCondition() {
        super(Quality_Gate_Rule_Condition__c.SObjectType);
        platform('Other');
    }

    public QualityGateRuleCondition qualityGateRuleId(Id qualityGateRuleId) {
        set(Quality_Gate_Rule_Condition__c.Quality_Gate_Rule__c, qualityGateRuleId);
        return this;
    }

    public QualityGateRuleCondition platform(String platform) {
        return (QualityGateRuleCondition) set(Quality_Gate_Rule_Condition__c.Platform__c, platform);
    }

    public QualityGateRuleCondition pipeline(Pipeline pipeline) {
        setParent(Quality_Gate_Rule_Condition__c.Pipeline__c, pipeline);
        return this;
    }

    public QualityGateRuleCondition pipelineId(Id pipelineId) {
        set(Quality_Gate_Rule_Condition__c.Pipeline__c, pipelineId);
        return this;
    }

    public QualityGateRuleCondition environment(Environment environment) {
        setParent(Quality_Gate_Rule_Condition__c.Environment__c, environment);
        return this;
    }

    public QualityGateRuleCondition environmentId(Id environmentId) {
        set(Quality_Gate_Rule_Condition__c.Environment__c, environmentId);
        return this;
    }

    public QualityGateRuleCondition stage(Stage stage) {
        setParent(Quality_Gate_Rule_Condition__c.Stage__c, stage);
        return this;
    }

    public QualityGateRuleCondition stageId(Id stageId) {
        set(Quality_Gate_Rule_Condition__c.Stage__c, stageId);
        return this;
    }

    public QualityGateRuleCondition extensionConfiguration(Id entensionConfigurationId) {
        set(Quality_Gate_Rule_Condition__c.Extension_Configuration__c, entensionConfigurationId);
        return this;
    }

    public QualityGateRuleCondition extensionConfiguration(ExtensionConfiguration entensionConfiguration) {
        setParent(Quality_Gate_Rule_Condition__c.Extension_Configuration__c, entensionConfiguration);
        return this;
    }

    public QualityGateRuleCondition filterCriteria(String filterCriteria) {
        return (QualityGateRuleCondition) set(Quality_Gate_Rule_Condition__c.Filter_Criteria__c, filterCriteria);
    }

    public QualityGateRuleCondition testsFrom(String picklistSelection) {
        return (QualityGateRuleCondition) set(Quality_Gate_Rule_Condition__c.Tests_From__c, picklistSelection);
    }
}