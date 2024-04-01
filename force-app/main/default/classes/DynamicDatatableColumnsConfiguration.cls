public with sharing class DynamicDatatableColumnsConfiguration {
    @AuraEnabled
    public String objectApiName { get; set; }
    @AuraEnabled
    public String fieldSetName { get; set; }
    @AuraEnabled
    public Boolean hideDefaultColumnsActions { get; set; }
    @AuraEnabled
    public Boolean sortable { get; set; }
    @AuraEnabled
    public Boolean editable { get; set; }
    @AuraEnabled
    public Boolean searchable { get; set; }

    // PUBLIC

    public List<ColumnConfig> getColumnsConfig() {
        List<ColumnConfig> result = new List<ColumnConfig>();
        for (FieldSetMember member : getMembers(objectApiName, fieldSetName)) {
            if (hasAccess(objectApiName, member)) {
                result.add(new ColumnConfig(member, hideDefaultColumnsActions, sortable, editable, searchable));
            }
        }
        return result;
    }

    // PRIVATE

    private List<FieldSetMember> getMembers(String type, String fieldSet) {
        return fflib_SObjectDescribe.getDescribe(type).getFieldSet(fieldSet).getFields();
    }

    private Boolean hasAccess(String type, FieldSetMember member) {
        Boolean result;
        fflib_SObjectDescribe describe = fflib_SObjectDescribe.getDescribe(type);

        String path = member.getFieldPath();
        if (path.contains('.')) {
            SObjectType parentType = describe.getField(field(path)).getDescribe().getReferenceTo()[0];
            result =
                describe.getField(field(path)).getDescribe().isAccessible() &&
                fflib_SObjectDescribe.getDescribe(parentType).getField(path.substringAfter('.')).getDescribe().isAccessible();
        } else {
            result = describe.getField(path).getDescribe().isAccessible();
        }
        return result;
    }

    private String field(String path) {
        String result = path.substringBefore('.');
        if (result.endsWith('__r')) {
            // Not using replace, in case the field is namespaced and starts with 'r'
            result = result.removeEnd('__r') + '__c';
        } else {
            result += 'Id';
        }
        return result;
    }
}