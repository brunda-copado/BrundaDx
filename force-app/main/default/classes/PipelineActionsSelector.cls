public inherited sharing class PipelineActionsSelector extends fflib_SObjectSelector {
    // CTOR

    public PipelineActionsSelector() {
        this(true, true);
    }

    public PipelineActionsSelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(false, enforceCRUD, enforceFLS, false);
    }

    // PUBLIC

    public SObjectType getSObjectType() {
        return Pipeline_Action__c.sObjectType;
    }

    public List<SObjectField> getSObjectFieldList() {
        return new List<SObjectField>{
            Pipeline_Action__c.Id,
            Pipeline_Action__c.Name,
            Pipeline_Action__c.Action__c,
            Pipeline_Action__c.Default__c,
            Pipeline_Action__c.Environment__c,
            Pipeline_Action__c.Job_Template__c,
            Pipeline_Action__c.Overrides_Pipeline_Action__c,
            Pipeline_Action__c.Pipeline__c,
            Pipeline_Action__c.Platform__c
        };
    }

    @SuppressWarnings('PMD.ExcessiveParameterList')
    public List<Pipeline_Action__c> forDuplicates(Set<String> actions, Set<Id> pipelines, Set<Id> environments) {
        return Database.query(
            newQueryFactory()
                .setCondition('Action__c IN ' + getPicklistValues(actions) + ' OR Pipeline__c IN :pipelines OR Environment__c IN :environments')
                .toSOQL()
        );
    }

    public List<Pipeline_Action__c> forOverrides(Set<String> actions, Set<Id> pipelines) {
        return Database.query(
            newQueryFactory()
                .setCondition('Default__c = TRUE AND (Action__c IN ' + getPicklistValues(actions) + ' OR Pipeline__c IN :pipelines)')
                .toSOQL()
        );
    }

    public List<Pipeline_Action__c> forActionTemplate(String action, Id pipeline) {
        return Database.query(
            newQueryFactory()
                .selectField('Job_Template__r.ApiName__c')
                .setCondition('Action__c = :action AND Pipeline__c = :pipeline')
                .setOrdering('Default__c', fflib_QueryFactory.SortOrder.ASCENDING)
                .addOrdering('Environment__c', fflib_QueryFactory.SortOrder.ASCENDING, true)
                .toSOQL()
        );
    }

    // PRIVATE

    private String getPicklistValues(Set<String> actions) {
        List<String> actionValues = new List<String>();
        for (String action : actions) {
            if (action != null) {
                actionValues.add(String.escapeSingleQuotes(action));
            }
        }
        return '(\'' + String.join(actionValues, '\', \'') + '\')';
    }
}