public inherited sharing class BundledStorySelector extends fflib_SObjectSelector {
    // CONSTRUCTOR

    public BundledStorySelector() {
        this(true, true);
    }

    public BundledStorySelector(Boolean enforceCRUD, Boolean enforceFLS) {
        super(false, enforceCRUD, enforceFLS);
    }

    // PUBLIC

    public SObjectType getSObjectType() {
        return Bundled_Story__c.sObjectType;
    }

    public List<SObjectField> getSObjectFieldList() {
        return new List<SObjectField>{ Bundled_Story__c.User_Story__c, Bundled_Story__c.Package_Version__c };
    }

    public List<Bundled_Story__c> byPackageVersion(Set<Id> versions) {
        return Database.query(
            newQueryFactory()
                .selectField('Package_Version__r.User_Story__c')
                .setCondition(Bundled_Story__c.Package_Version__c + ' IN :versions')
                .toSOQL()
        );
    }

    public List<Bundled_Story__c> byStoryIdsAndVersionStatus(Set<Id> stories, Set<String> status) {
        return Database.query(
            newQueryFactory()
                .selectField('User_Story__r.Name')
                .setCondition('User_Story__c IN :stories AND Package_Version__r.Status__c IN :status')
                .toSOQL()
        );
    }

    public List<Bundled_Story__c> byParentUSBIds(Set<Id> parentUSBIds) {
        return Database.query(
            newQueryFactory()
                .selectField('Package_Version__r.User_Story__c')
                .setCondition('Package_Version__r.User_Story__c IN :parentUSBIds')
                .toSOQL()
        );
    }
}