global with sharing class RelatedListVisualPicklist extends VisualEditor.DynamicPickList {
    private VisualEditor.DynamicPickListRows rows;

    // CTOR

    @TestVisible
    private RelatedListVisualPicklist(String pageType, String objectType) {
        if (pageType == 'RecordPage') {
            Map<String, String> relatedLists = getRelatedList(objectType);

            rows = new VisualEditor.DynamicPickListRows();
            for (String related : relatedLists.keySet()) {
                rows.addRow(new VisualEditor.DataRow(relatedLists.get(related), related));
            }
        }
    }

    global RelatedListVisualPicklist(VisualEditor.DesignTimePageContext context) {
        this(context.pageType, context.entityName);
    }

    // PUBLIC

    global override VisualEditor.DataRow getDefaultValue() {
        return null;
    }

    global override VisualEditor.DynamicPickListRows getValues() {
        return rows;
    }

    // PRIVATE

    private Map<String, String> getRelatedList(String type) {
        Map<String, String> result = new Map<String, String>();

        for (ChildRelationship relation : childRelationships(type)) {
            DescribeSObjectResult child = relation.getChildSObject().getDescribe();

            // Note: Without localname doesnt work in namespaced orgs
            result.put(child.getLocalName(), child.getLabel());
        }

        return result;
    }

    private List<ChildRelationship> childRelationships(String parentType) {
        return fflib_SObjectDescribe.getDescribe(parentType).getDescribe().getChildRelationships();
    }
}