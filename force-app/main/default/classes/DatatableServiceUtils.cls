public with sharing class DatatableServiceUtils {
    public static List<FieldSetMember> getMembers(String type, String fieldSet) {
        return fflib_SObjectDescribe.getDescribe(type).getFieldSet(fieldSet).getFields();
    }

    public static String getRelationalFieldPath(String fieldPath) {
        if (fieldPath.endsWith(DatatableConstants.CUSTOM_FIELD_PATH_END)) {
            fieldPath = fieldPath.replace(DatatableConstants.CUSTOM_FIELD_PATH_END, DatatableConstants.CUSTOM_REFERENCE_FIELD_NAME);
        } else if (fieldPath.endsWith(DatatableConstants.ID)) {
            // Trick to no to replace other possible appearances of 'Id' in the field name
            fieldPath = fieldPath + DatatableConstants.DOUBLE_UNDERSCORE;
            fieldPath = fieldPath.replace(
                DatatableConstants.ID + DatatableConstants.DOUBLE_UNDERSCORE,
                DatatableConstants.STANDARD_REFERENCE_FIELD_NAME
            );
        }
        return fieldPath;
    }

    public static String getFieldName(FieldSetMember field) {
        return field.getSObjectField().getDescribe().getName();
    }

    public static String getFieldPath(FieldSetMember field) {
        return field.getFieldPath();
    }

    public static Boolean isUpdateable(FieldSetMember field) {
        return field.getSObjectField().getDescribe().isUpdateable();
    }
}