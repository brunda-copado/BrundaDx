public with sharing class SprintSnapshotConstants {
    public static final String SPRINT_TO_SNAPSHOT_FIELD_MAPPING = 'Sprint_Snapshot_Field_Mapping_JSON';
    public static final String SPRINT_PLANNED_VELOCITY = Schema.SObjectType.Sprint__c.fields.Planned_Velocity__c.getName();
    public static final String SPRINT_ACTUAL_VELOCITY = Schema.SObjectType.Sprint__c.fields.Actual_Velocity__c.getName();
    public static final String SNAPSHOT_PLANNED_VELOCITY = Schema.SObjectType.Burndown_Item__c.fields.Planned_Velocity__c.getName();
    public static final String SNAPSHOT_ACTUAL_VELOCITY =  Schema.SObjectType.Burndown_Item__c.fields.Actual_Velocity__c.getName();
}