public with sharing class DynamicDatatableQueryConfiguration {
    @AuraEnabled
    public String selectFieldSet { get; set; }
    @AuraEnabled
    public String fromObject { get; set; }
    @AuraEnabled
    public String relationshipField {
        get {
            if (relationshipField != null) {
                relationshipField = String.escapeSingleQuotes(relationshipField);
            }
            return relationshipField;
        }
        set;
    }
    @AuraEnabled
    public Id parentId {
        get {
            if (parentId != null) {
                parentId = String.escapeSingleQuotes(parentId);
            }
            return parentId;
        }
        set;
    }
    @AuraEnabled
    public String orderBy { get; set; }
    @AuraEnabled
    public Integer recordsLimit { get; set; }
    @AuraEnabled
    public Integer recordsOffset { get; set; }

    private final String QUERY_TEMPLATE = 'SELECT {0} FROM {1} WHERE {2} = \'\'{3}\'\' WITH SECURITY_ENFORCED ORDER BY {4} LIMIT {5} OFFSET {6}';

    // PUBLIC

    public String getFormattedQuery() {
        return String.format(QUERY_TEMPLATE, getParameters());
    }

    // PRIVATE

    private List<Object> getParameters() {
        relationshipField = (String.isBlank(relationshipField)) ? getDefaultRelationshipField() : relationshipField;
        return new List<Object>{ getSelectFields(), fromObject, relationshipField, parentId, orderBy, recordsLimit, recordsOffset };
    }

    private String getSelectFields() {
        Set<String> fields = new Set<String>();

        for (FieldSetMember field : getFieldSetFields()) {
            String fieldToAdd = field.getFieldPath();
            if (field.getType() == DisplayType.REFERENCE) {
                if (field.getFieldPath().endsWith('__c')) {
                    fieldToAdd = field.getFieldPath().replace('__c', '__r.Name');
                } else if (field.getFieldPath().endsWith('Id')) {
                    // Trick to no to replace other possible appearances of 'Id' in the field name
                    fieldToAdd = field.getFieldPath() + '__';
                    fieldToAdd = fieldToAdd.replace('Id__', '.Name');
                }
            }
            fields.add(fieldToAdd);
        }

        return String.join(new List<String>(fields), ',');
    }

    private List<FieldSetMember> getFieldSetFields() {
        return fflib_SObjectDescribe.getDescribe(fromObject).getFieldSets().get(selectFieldSet).getFields();
    }

    private String getDefaultRelationshipField() {
        List<SObjectField> sObjectFields = fflib_SObjectDescribe.getDescribe(fromObject).getFieldsMap().values();
        String parentObject = parentId.getSObjectType().getDescribe().getName();

        for (SObjectField field : sObjectFields) {
            DescribeFieldResult fieldDescribe = field.getDescribe();
            String fieldType = fieldDescribe.getType().name();
            if (fieldType == 'reference' && parentObject == fieldDescribe.getReferenceTo()[0].getDescribe().getName()) {
                return fieldDescribe.getName();
            }
        }

        throw new InvalidRelationshipException(Label.Invalid_Relationship_Error);
    }

    // INNER

    private class InvalidRelationshipException extends Exception {}
}