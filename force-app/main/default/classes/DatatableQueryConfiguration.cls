public with sharing class DatatableQueryConfiguration {
    @AuraEnabled
    public String selectFieldSet { get; set; }
    @AuraEnabled
    public String fromObject { get; set; }
    @AuraEnabled
    public String relationshipField {
        get {
            if (String.isBlank(relationshipField)) {
                relationshipField = getDefaultRelationshipField();
            }
            return String.escapeSingleQuotes(relationshipField);
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
    public List<Id> parentIds {
        get {
            if (parentIds == null) {
                parentIds = new List<Id>();
            }
            return parentIds;
        }
        set;
    }
    @AuraEnabled
    public String orderBy { get; set; }
    @AuraEnabled
    public Integer recordsLimit { get; set; }
    @AuraEnabled
    public Integer recordsOffset { get; set; }

    // PUBLIC

    public String getFormattedQuery() {
        return String.format(DatatableConstants.QUERY_TEMPLATE, getParameters());
    }

    // PRIVATE

    private List<Object> getParameters() {
        String whereCondition = '';
        if (!parentIds.isEmpty()) {
            List<String> conditions = new List<String>();

            for (Id recordId : parentIds) {
                conditions.add(relationshipField + ' = \'' + recordId + '\'');
            }
            whereCondition += String.join(conditions, ' OR ');
            return new List<Object>{ getSelectFields(), fromObject, whereCondition, orderBy, recordsLimit, recordsOffset };
        }

        whereCondition += relationshipField + ' = \'' + parentId + '\'';
        return new List<Object>{ getSelectFields(), fromObject, whereCondition, orderBy, recordsLimit, recordsOffset };
    }

    private String getSelectFields() {
        Set<String> fields = new Set<String>();

        for (FieldSetMember field : DatatableServiceUtils.getMembers(fromObject, selectFieldSet)) {
            String fieldPath = DatatableServiceUtils.getFieldPath(field);
            if (field.getType() == DisplayType.REFERENCE) {
                fieldPath = DatatableServiceUtils.getRelationalFieldPath(fieldPath);
            }
            fields.add(fieldPath);
        }
        return String.join(new List<String>(fields), DatatableConstants.COMMA);
    }

    private String getDefaultRelationshipField() {
        List<SObjectField> sObjectFields = fflib_SObjectDescribe.getDescribe(fromObject).getFieldsMap().values();
        String parentObject = !parentIds.isEmpty()
            ? parentIds[0].getSObjectType().getDescribe().getName()
            : parentId.getSObjectType().getDescribe().getName();

        for (SObjectField field : sObjectFields) {
            DescribeFieldResult fieldDescribe = field.getDescribe();
            String fieldType = fieldDescribe.getType().name();
            if (fieldType == DatatableConstants.FIELDTYPE_REFERENCE && parentObject == fieldDescribe.getReferenceTo()[0].getDescribe().getName()) {
                return fieldDescribe.getName();
            }
        }

        throw new InvalidRelationshipException(Label.Invalid_Relationship_Error);
    }

    // INNER

    private class InvalidRelationshipException extends Exception {
    }
}