public with sharing class SetPropertyParents {
    private List<System_Property__c> records;
    private Map<Id, System_Property__c> old;

    // CONSTRUCTOR

    public SetPropertyParents(List<System_Property__c> records) {
        this(records, null);
    }

    public SetPropertyParents(List<System_Property__c> records, Map<Id, System_Property__c> old) {
        this.old = old;
        this.records = filter(records);
    }

    // PUBLIC

    public void execute() {
        for (System_Property__c property : records) {
            if (property.Is_Global__c && (old == null || !old?.get(property.Id)?.Is_Global__c)) {
                clearParentLookups(property);
            } else if (!property.Is_Global__c) {               
                property.ParentId__c = parentId(property);
                if (String.isBlank(property.ParentId__c)) {
                    property.addError(Label.ParentIdRequired);
                }
            }
        }
    }

    // PRIVATE

    private List<System_Property__c> filter(List<System_Property__c> properties) {
        List<System_Property__c> result = new List<System_Property__c>();

        for(System_Property__c property : properties) {
            System_Property__c oldRecord = old?.get(property.Id);
            if(old == null || (hasParentChanged(property, oldRecord) || hasGlobalChanged(property, oldRecord))) {
                result.add(property);
            }
        }

        return result;
    }

    private Boolean hasParentChanged(System_Property__c property, System_Property__c oldRecord) {
        return property.User__c != oldRecord.User__c ||
            property.Environment__c != oldRecord.Environment__c ||
            property.Pipeline__c != oldRecord.Pipeline__c ||
            property.ParentId__c != oldRecord.ParentId__c;
    }

    private Boolean hasGlobalChanged(System_Property__c property, System_Property__c oldRecord) {
        return property.Is_Global__c != oldRecord.Is_Global__c;
    }

    private Id parentId(System_Property__c property) {
        Id result;

        if (property.Environment__c != null) {
            result = property.Environment__c;
        } else if (property.Pipeline__c != null) {
            result = property.Pipeline__c;
        } else if (property.User__c != null) {
            result = property.User__c;
        } else if (String.isNotBlank(property.ParentId__c)) {
            result = property.ParentId__c;
        }

        return result;
    }

    private void clearParentLookups(System_Property__c property) {
        property.User__c = null;
        property.Environment__c = null;
        property.Pipeline__c = null;
        property.ParentId__c = null;
    }
}