public inherited sharing class CopadoNotificationsSelector extends fflib_SObjectSelector {
    public SObjectType getSObjectType() {
        return Copado_Notification__c.sObjectType;
    }

    public List<SObjectField> getSObjectFieldList() {
        return new List<SObjectField>{
            Copado_Notification__c.Id,
            Copado_Notification__c.Name,
            Copado_Notification__c.status__c,
            Copado_Notification__c.Type__c
        };
    }

    public CopadoNotificationsSelector() {
        this(true);
    }

    public CopadoNotificationsSelector(Boolean enforceFLS) {
        super(false, true, enforceFLS);
    }

    public List<Copado_Notification__c> byParentId(Set<Id> parentIds) {
        fflib_QueryFactory query = newQueryFactory().setCondition('ParentId__c IN :parentIds');
        return (List<Copado_Notification__c>) Database.query(query.toSOQL());
    }

    public List<Copado_Notification__c> byParentIdAndUnfinished(Set<Id> parentIds) {
        fflib_QueryFactory query = newQueryFactory().setCondition('ParentId__c IN :parentIds AND isFinished__c = FALSE');
        return (List<Copado_Notification__c>) Database.query(query.toSOQL());
    }

    public List<Copado_Notification__c> byTypeAndStatus(String type, String status) {
        fflib_QueryFactory query = newQueryFactory().setCondition('Type__c = :type AND Status__c = :status');

        return (List<Copado_Notification__c>) Database.query(query.toSOQL());
    }
}