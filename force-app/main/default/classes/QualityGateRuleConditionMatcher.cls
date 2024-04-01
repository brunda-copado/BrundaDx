public inherited sharing class QualityGateRuleConditionMatcher {
    QualityGate.Request request;

    private PipelineDescriptor pipelineDescriptor;

    // CONSTRUCTOR

    public QualityGateRuleConditionMatcher(QualityGate.Request request) {
        this.request = request;
        this.pipelineDescriptor = new PipelineDescriptor(request.pipelineId);
    }

    // Note: temporary constructor for services
    public QualityGateRuleConditionMatcher(Quality.MatchingRulesRequest request) {
        this(getRequest(request));
    }

    // Note: temporary constructor for services
    public QualityGateRuleConditionMatcher(Quality.StepsRequest request) {
        this(getRequest(request));
    }

    // PUBLIC

    public Map<Id, Quality_Gate_Rule_Condition__c> execute() {
        List<Quality_Gate_Rule_Condition__c> conditions = new QualityGateRuleConditionsSelector().byActiveMeetingAnyFilter(filters());
        List<Quality_Gate_Rule_Condition__c> validConditions = validConditions(conditions);
        Map<Id, Quality_Gate_Rule_Condition__c> conditionByRuleId = maximumWeightConditions(validConditions);

        return conditionByRuleId;
    }

    // PRIVATE

    private List<String> filters() {
        List<String> result = new List<String>();

        if (String.isNotBlank(request.platform)) {
            result.add(asCondition('Platform__c', request.platform));
        }

        if (String.isNotBlank(request.action)) {
            result.add(asCondition('Quality_Gate_Rule__r.Actions__c', request.action));
        }

        return result;
    }

    private String asCondition(String field, String value) {
        String result = '';

        switch on fieldType(field) {
            when MultiPicklist {
                result = field + ' INCLUDES (\'' + String.escapeSingleQuotes(value) + '\')';
            }
            when else {
                result = field + ' = \'' + String.escapeSingleQuotes(value) + '\'';
            }
        }

        return result;
    }

    @SuppressWarnings('PMD.EagerlyLoadedDescribeSObjectResult')
    private Schema.DisplayType fieldType(String fieldName) {
        // Note: we assume we are working on Quality_Gate_Rule_Condition__c object by default
        String objectName = Schema.sObjectType.Quality_Gate_Rule_Condition__c.getName();
        if (fieldName.contains('.')) {
            String referenceField = fieldName.substringBefore('.');
            objectName = fflib_SObjectDescribe.getDescribe(objectName)
                    .getField(referenceField)
                    .getDescribe(FieldDescribeOptions.FULL_DESCRIBE)
                    .getReferenceTo()[0]
                .getDescribe(SObjectDescribeOptions.FULL)
                .getName();
            fieldName = fieldName.substringAfter('.');
        }
        return fflib_SObjectDescribe.getDescribe(objectName).getField(fieldName).getDescribe(FieldDescribeOptions.FULL_DESCRIBE).getType();
    }

    private List<Quality_Gate_Rule_Condition__c> validConditions(List<Quality_Gate_Rule_Condition__c> conditions) {
        List<Quality_Gate_Rule_Condition__c> result = new List<Quality_Gate_Rule_Condition__c>();

        for (Quality_Gate_Rule_Condition__c condition : conditions) {
            if (isValidCondition(condition)) {
                result.add(condition);
            }
        }

        return result;
    }

    private Boolean isValidCondition(Quality_Gate_Rule_Condition__c condition) {
        return matchScope(condition) && matchFilterCriteria(condition);
    }

    private Boolean matchScope(Quality_Gate_Rule_Condition__c condition) {
        Boolean pipelineAndEnvironmentAndStageEmpty = !environmentDefined(condition) && !pipelineDefined(condition) && !stageDefined(condition);

        Boolean sameEnvironment =
            !pipelineDefined(condition) &&
            !stageDefined(condition) &&
            environmentDefined(condition) &&
            matchingEnvironment(condition);
        Boolean samePipeline =
            !environmentDefined(condition) &&
            !stageDefined(condition) &&
            pipelineDefined(condition) &&
            matchingPipeline(condition);
        Boolean sameStage = !pipelineDefined(condition) && !environmentDefined(condition) && stageDefined(condition) && matchingStage(condition);

        Boolean samePipelineAndEnvironment =
            pipelineDefined(condition) &&
            environmentDefined(condition) &&
            !stageDefined(condition) &&
            matchingEnvironment(condition) &&
            matchingPipeline(condition);
        Boolean sameStageAndEnvironment =
            stageDefined(condition) &&
            environmentDefined(condition) &&
            !pipelineDefined(condition) &&
            matchingEnvironment(condition) &&
            matchingStage(condition);
        Boolean sameStageAndPipeline =
            stageDefined(condition) &&
            pipelineDefined(condition) &&
            !environmentDefined(condition) &&
            matchingPipeline(condition) &&
            matchingStage(condition);

        Boolean sameStageAndEnvironmentAndPipeline =
            stageDefined(condition) &&
            environmentDefined(condition) &&
            pipelineDefined(condition) &&
            matchingStage(condition) &&
            matchingEnvironment(condition) &&
            matchingPipeline(condition);

        return pipelineAndEnvironmentAndStageEmpty ||
            sameEnvironment ||
            samePipeline ||
            sameStage ||
            samePipelineAndEnvironment ||
            sameStageAndEnvironment ||
            sameStageAndPipeline ||
            sameStageAndEnvironmentAndPipeline;
    }

    private Boolean environmentDefined(Quality_Gate_Rule_Condition__c condition) {
        return condition.Environment__c != null;
    }

    private Boolean pipelineDefined(Quality_Gate_Rule_Condition__c condition) {
        return condition.Pipeline__c != null;
    }

    private Boolean stageDefined(Quality_Gate_Rule_Condition__c condition) {
        return condition.Stage__c != null;
    }

    private Boolean matchingEnvironment(Quality_Gate_Rule_Condition__c condition) {
        return condition.Environment__c == request.environmentId;
    }

    private Boolean matchingPipeline(Quality_Gate_Rule_Condition__c condition) {
        return condition.Pipeline__c == request.pipelineId;
    }

    private Boolean matchingStage(Quality_Gate_Rule_Condition__c condition) {
        return !String.isBlank(request.environmentId) && this.pipelineDescriptor.getStageId(request.environmentId) == condition.Stage__c;
    }

    private Boolean matchFilterCriteria(Quality_Gate_Rule_Condition__c condition) {
        String filterCriteria = condition.Filter_Criteria__c;
        return String.isBlank(filterCriteria) || new FilterCriteria(condition.Filter_Criteria__c).metadataChanges(request.metadataChanges).evaluate();
    }

    private Map<Id, Quality_Gate_Rule_Condition__c> maximumWeightConditions(List<Quality_Gate_Rule_Condition__c> conditions) {
        Map<Id, Quality_Gate_Rule_Condition__c> conditionByRuleId = new Map<Id, Quality_Gate_Rule_Condition__c>();
        Map<Id, Integer> maxWeightByRuleId = new Map<Id, Integer>();

        for (Quality_Gate_Rule_Condition__c condition : conditions) {
            Integer weight = new CalculateQGConditionWeight(condition).execute();
            Id qualityGateRuleId = condition.Quality_Gate_Rule__c;

            if (conditionByRuleId.get(qualityGateRuleId) == null) {
                conditionByRuleId.put(qualityGateRuleId, condition);
                maxWeightByRuleId.put(qualityGateRuleId, weight);
            } else if (weight > maxWeightByRuleId.get(qualityGateRuleId)) {
                conditionByRuleId.put(qualityGateRuleId, condition);
                maxWeightByRuleId.put(qualityGateRuleId, weight);
            }
        }

        return conditionByRuleId;
    }

    // Note: converting service request to existing request
    private static QualityGate.Request getRequest(Quality.MatchingRulesRequest request) {
        QualityGate.Request result = new QualityGate.Request();
        result.action = request.action;
        result.pipelineId = request.pipeline;
        result.platform = request.platform;
        result.templateName = request.templateName;
        result.environmentId = request.environment;
        result.contextIds = request.contextIds;
        result.metadataChanges = request.metadataChanges;
        return result;
    }

    // Note: converting service request to existing request
    private static QualityGate.Request getRequest(Quality.StepsRequest request) {
        QualityGate.Request result = new QualityGate.Request();
        result.action = request.action;
        result.pipelineId = request.pipeline;
        result.platform = request.platform;
        result.templateName = request.templateName;
        result.environmentId = request.environment;
        result.contextIds = request.contextIds;
        result.metadataChanges = request.metadataChanges;
        return result;
    }
}