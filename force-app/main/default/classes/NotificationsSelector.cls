public inherited sharing class NotificationsSelector extends fflib_SObjectSelector {
    @TestVisible
    private static List<MC_Notification__mdt> mockNotifications;

    public SObjectType getSObjectType() {
        return MC_Notification__mdt.sObjectType;
    }

    public List<SObjectField> getSObjectFieldList() {
        return new List<SObjectField>{
            MC_Notification__mdt.MasterLabel,
            MC_Notification__mdt.DeveloperName,
            MC_Notification__mdt.Subject__c,
            MC_Notification__mdt.Template__c,
            MC_Notification__mdt.Active__c,
            MC_Notification__mdt.Description__c
        };
    }

    public List<MC_Notification__mdt> all() {
        return Test.isRunningTest() ? mockNotifications : Database.query(newQueryFactory().toSOQL());
    }

    public List<MC_Notification__mdt> byActive(Boolean isActive) {
        List<MC_Notification__mdt> result;

        if (Test.isRunningTest() && mockNotifications != null) {
            result = mockNotifications;
        } else {
            fflib_QueryFactory query = newQueryFactory().setCondition(MC_Notification__mdt.Active__c + ' = :isActive');
            result = Database.query(query.toSOQL());
        }

        return result;
    }

    public MC_Notification__mdt byName(String name) {
        List<MC_Notification__mdt> result;

        if (Test.isRunningTest() && mockNotifications != null) {
            result = mockNotifications;
        } else {
            fflib_QueryFactory query = newQueryFactory().setCondition(MC_Notification__mdt.Active__c + ' = true AND DeveloperName = :name');
            result = (List<MC_Notification__mdt>) Database.query(query.toSOQL());
        }

        return result.isEmpty() ? null : result[0];
    }
}