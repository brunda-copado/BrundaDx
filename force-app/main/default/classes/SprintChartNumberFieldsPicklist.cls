public with sharing class SprintChartNumberFieldsPicklist extends VisualEditor.DynamicPickList {
    private final static Set<DisplayType> ACCEPTED_FIELD_TYPES = new Set<DisplayType>{ DisplayType.Double, DisplayType.Integer, DisplayType.Long };

    public override VisualEditor.DataRow getDefaultValue() {
        return new VisualEditor.DataRow('', '');
    }

    public override VisualEditor.DynamicPickListRows getValues() {
        VisualEditor.DynamicPickListRows result = new VisualEditor.DynamicPickListRows();

        for (Schema.SObjectField field : Schema.SObjectType.Burndown_Item__c.fields.getMap().values()) {
            Schema.DescribeFieldResult dfr = field.getDescribe();

            if (ACCEPTED_FIELD_TYPES.contains(dfr.getType())) {
                result.addRow(new VisualEditor.DataRow(dfr.getLabel(), dfr.getName()));
            }
        }

        return result;
    }
}