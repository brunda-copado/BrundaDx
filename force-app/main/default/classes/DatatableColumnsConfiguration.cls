// Note: These describe calls are mostly describing fields and Field describe option is not resolving PMD issue, hence
@SuppressWarnings('PMD.EagerlyLoadedDescribeSObjectResult')
public virtual with sharing class DatatableColumnsConfiguration {
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
    @AuraEnabled
    public Boolean filterable { get; set; }

    // PROTECTED

    protected List<DatatableServiceColumnConfig> getColumnsConfig() {
        List<DatatableServiceColumnConfig> result = new List<DatatableServiceColumnConfig>();
        for (FieldSetMember member : DatatableServiceUtils.getMembers(objectApiName, fieldSetName)) {
            if (hasAccess(objectApiName, member)) {
                result.add(
                    new DatatableServiceColumnConfig(member, editable, searchable)
                        .hideDefaultActions(hideDefaultColumnsActions)
                        .sortable(sortable)
                        .filterable(filterable)
                );
            }
        }
        return result;
    }

    // PRIVATE

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

    @TestVisible
    private String field(String path) {
        String result = path.substringBefore('.');
        if (result.endsWith(DatatableConstants.REFERENCE_FIELD_PATH_END)) {
            // Not using replace, in case the field is namespaced and starts with 'r'
            result = result.removeEnd(DatatableConstants.REFERENCE_FIELD_PATH_END) + DatatableConstants.CUSTOM_FIELD_PATH_END;
        } else {
            result += DatatableConstants.ID;
        }
        return result;
    }
}