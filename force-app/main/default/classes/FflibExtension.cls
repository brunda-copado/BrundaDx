@SuppressWarnings('PMD.ExcessiveParameterList')
public abstract with sharing class FflibExtension extends fflib_SObjectSelector {
    //CONSTRUCTOR

    public FflibExtension(
        Boolean includeFieldSetFields,
        Boolean enforceCRUD,
        Boolean enforceFLS,
        Boolean sortSelectFields
    ) {
        super(includeFieldSetFields, enforceCRUD, enforceFLS, sortSelectFields);
    }

    abstract Map<String, List<Schema.SObjectField>> getSObjectLookupFieldMap();

    //PUBLIC

    public void setLookupFields(fflib_QueryFactory queryFactory) {
        Map<String, List<Schema.SObjectField>> lookupFieldMap = getSObjectLookupFieldMap();

        for (String relationshipFieldPath : lookupFieldMap?.keySet()) {
            for (SObjectField field : lookupFieldMap.get(relationshipFieldPath)) {
                queryFactory.selectField(
                    relationshipFieldPath +
                    '.' +
                    field.getDescribe().getName()
                );
            }
        }
    }

    public void setLookupFields(fflib_QueryFactory queryFactory, String relationshipFieldPath) {
        Map<String, List<Schema.SObjectField>> lookupFieldMap = getSObjectLookupFieldMap();
        
        if (lookupFieldMap?.containsKey(relationshipFieldPath)) {
            for (SObjectField field : lookupFieldMap.get(relationshipFieldPath)) {
                queryFactory.selectField(
                    relationshipFieldPath +
                    '.' +
                    field.getDescribe().getName()
                );
            }
        }
    }
}