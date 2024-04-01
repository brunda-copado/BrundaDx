public with sharing class QualityGateRules extends fflib_SObjectDomain {
    private static final String TOOL_FIELD = Settings.ns + 'Tool__c';
    private static final String TYPE_FIELD = Settings.ns + 'Type__c';
    private static final Set<String> FORBIDDEN_ACTIONS = new Set<String>{
        ActionConstants.CREATE_PACKAGE,
        ActionConstants.CREATE_PACKAGE_VERSION,
        ActionConstants.PUBLISH_PACKAGE_VERSION,
        ActionConstants.IMPORT_PACKAGE,
        ActionConstants.TAKE_SNAPSHOT,
        ActionConstants.SUBMIT_USER_STORIES
    };

    // CONSTRUCTOR

    public QualityGateRules(List<Quality_Gate_Rule__c> records) {
        super(records);
    }

    // PUBLIC

    public override void onBeforeInsert() {
        new SetTestToolType(new SetTestToolType.FieldConfig(TOOL_FIELD, TYPE_FIELD), records).execute();
    }

    public override void onBeforeUpdate(Map<Id, SObject> old) {
        new SetTestToolType(new SetTestToolType.FieldConfig(TOOL_FIELD, TYPE_FIELD), records, old).execute();
    }

    public override void onBeforeDelete() {
        new RestrictQualityGateUpdateOrDelete(records, null).execute();
    }

    public override void onValidate() {
        new RestrictQgrDuplicate(records).execute();
        // Note: temporary validation for packaging actions as they don't support Quality Gates yet. Will be removed in the future.
        validateActions(records);
    }

    public override void onValidate(Map<Id, SObject> old) {
        new RestrictQualityGateUpdateOrDelete(records, old).execute();
        new QualityAutomation(records, old).execute();
        onValidate();
    }

    // INNER

    public class Constructor implements fflib_SObjectDomain.IConstructable {
        public fflib_SObjectDomain construct(List<SObject> records) {
            return new QualityGateRules(records);
        }
    }

    // PRIVATE

    private void validateActions(List<Quality_Gate_Rule__c> records) {
        for (Quality_Gate_Rule__c record : records) {
            Set<String> forbiddenActions = new Set<String>();
            forbiddenActions.addAll(new Set<String>(record.Actions__c.split(';')));
            forbiddenActions.retainAll(FORBIDDEN_ACTIONS);
            List<String> actionLabels = getPicklistLabels(forbiddenActions);
            if (!forbiddenActions.isEmpty()) {
                record.addError(String.format(Label.Quality_Gate_Rule_Forbidden_Action, new List<String>{ String.join(actionLabels, ', ') }));
            }
        }
    }

    @SuppressWarnings('PMD.EagerlyLoadedDescribeSObjectResult')
    private List<String> getPicklistLabels(Set<String> picklistValues) {
        List<String> result = new List<String>();

        List<Schema.PicklistEntry> picklistEntries = Schema.Quality_Gate_Rule__c.Actions__c.getDescribe().getPicklistValues();
        for (String picklistValue : picklistValues) {
            for (Schema.PicklistEntry picklistEntry : picklistEntries) {
                if (picklistEntry.getValue() == picklistValue) {
                    result.add(picklistEntry.getLabel());
                    break;
                }
            }
        }

        return result;
    }
}