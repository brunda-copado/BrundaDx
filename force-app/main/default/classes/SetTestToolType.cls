public with sharing class SetTestToolType {
    private FieldConfig fields;
    private List<SObject> records;

    // CONSTRUCTOR

    public SetTestToolType(FieldConfig fields, List<SObject> records) {
        this.fields = fields;
        this.records = records;
    }

    public SetTestToolType(FieldConfig fields, List<SObject> records, Map<Id, SObject> old) {
        this.fields = fields;
        this.records = updatedRecords(records, old);
    }

    // PUBLIC

    public void execute() {
        Map<String, String> testTypesByTool = testTypesByTool();

        for (SObject record : records) {
            String tool = String.valueOf(record.get(fields.toolField));

            if (String.isNotBlank(tool)) {
                String type = testTypesByTool.get(tool);

                if (String.isBlank(type)) {
                    record.addError(Label.Test_Tool_does_not_Exist);
                } else {
                    record.put(fields.typeField, testTypesByTool.get(tool));
                }
            }
        }
    }

    // PRIVATE

    private Map<String, String> testTypesByTool() {
        Map<String, String> result = new Map<String, String>();

        for (TestTool__mdt testTool : new TestToolsSelector().byNames(toolNames())) {
            result.put(testTool.MasterLabel, testTool.TestType__c);
        }

        return result;
    }

    private List<String> toolNames() {
        List<String> result = new List<String>();

        for (SObject record : records) {
            String tool = String.valueOf(record.get(fields.toolField));

            if (String.isNotBlank(tool)) {
                result.add(tool);
            }
        }

        return result;
    }

    private List<SObject> updatedRecords(List<SObject> records, Map<Id, SObject> old) {
        List<SObject> result = new List<SObject>();

        for (SObject record : records) {
            String newValue = String.valueOf(record.get(fields.toolField));
            String oldValue = String.valueOf(old.get(record.Id).get(fields.toolField));

            if (!newValue.equals(oldValue)) {
                result.add(record);
            }
        }

        return result;
    }

    // INNER

    public with sharing class FieldConfig {
        public String toolField;
        public String typeField;

        public FieldConfig(String toolField, String typeField) {
            this.toolField = toolField;
            this.typeField = typeField;
        }
    }
}