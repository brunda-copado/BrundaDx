public with sharing class JobExecutionFieldsPicklist extends VisualEditor.DynamicPickList {
    private final static Set<DisplayType> ACCEPTED_FIELD_TYPES = new Set<DisplayType>{ DisplayType.STRING, DisplayType.REFERENCE };
    private final static Set<String> SYSTEM_FIELDS = new Set<String>{ 'CreatedById', 'LastModifiedById', 'OwnerId' };

    public override VisualEditor.DataRow getDefaultValue() {
        return new VisualEditor.DataRow('', '');
    }

    public override VisualEditor.DynamicPickListRows getValues() {
        VisualEditor.DynamicPickListRows result = new VisualEditor.DynamicPickListRows();

        for (Schema.SObjectField field : Schema.SObjectType.JobExecution__c.fields.getMap().values()) {
            Schema.DescribeFieldResult fieldDescribe = field.getDescribe();

            if (ACCEPTED_FIELD_TYPES.contains(fieldDescribe.getType()) && !SYSTEM_FIELDS.contains(fieldDescribe.getName())) {
                result.addRow(new VisualEditor.DataRow(fieldDescribe.getLabel(), fieldDescribe.getName()));
            }
        }

        return result;
    }
}