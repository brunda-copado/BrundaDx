@isTest
private class SprintSnapshotRecordsCollectorTest {
    private static final String MOCK_HISTORY = '[{"attributes" : {"type" : "OBJECT_NAME","url" : "/services/data/v54.0/sobjects/OBJECT_NAME/h007Q000004Fvb7QAC"},"Id" : "h007Q000004Fvb7QAC","Sprint__c" : "RECORD_ID","ACTUAL_VELOCITY_FIELD" : 130.00,"ACTUAL_VELOCITY_FIELD" : 150.00,"PLANNED_VELOCITY_FIELD" : 200.00,"PLANNED_VELOCITY_FIELD" : 200.00}, {"attributes" : {"type" : "OBJECT_NAME","url" : "/services/data/v54.0/sobjects/OBJECT_NAME/h007Q000004FvYDQA0"},"Id" : "h007Q000004FvYDQA0","Sprint__c" : "RECORD_ID","ACTUAL_VELOCITY_FIELD" : 130.00,"ACTUAL_VELOCITY_FIELD" : 130.00,"PLANNED_VELOCITY_FIELD" : 150.00,"PLANNED_VELOCITY_FIELD" : 200.00}, {"attributes" : {"type" : "OBJECT_NAME","url" : "/services/data/v54.0/sobjects/OBJECT_NAME/h007Q000004FfGWQA0"},"Id" : "h007Q000004FfGWQA0","Sprint__c" : "RECORD_ID","ACTUAL_VELOCITY_FIELD" : 107.00,"ACTUAL_VELOCITY_FIELD" : 130.00,"PLANNED_VELOCITY_FIELD" : 150.00,"PLANNED_VELOCITY_FIELD" : 150.00} ]';

    @TestSetup
    static void prepareData() {
        TestUtilities tu = new TestUtilities();

        tu.insertSObject(
            'Sprint__c',
            new Map<String, Object>{
                'Name' => 'Sprint1',
                'Start_Date__c' => Date.today().addDays(-8),
                'End_Date__c' => Date.today().addDays(8),
                'Planned_Velocity__c' => 150,
                'Actual_Velocity__c' => 100
            }
        );
    }

    @isTest
    static void testGetTrackedHistoryTrending() {
        Sprint__c s = [SELECT Id, Start_Date__c, End_Date__c FROM Sprint__c WHERE Name = 'Sprint1' LIMIT 1];

        SprintSnapshotRecordsCollector.SprintSnapshotRequest request = new SprintSnapshotRecordsCollector.SprintSnapshotRequest();
        request.objectId = s.Id;
        request.objectName = Schema.SObjectType.Burndown_Item__c.getName();
        request.fields = new Set<String>{
            Schema.SObjectType.Burndown_Item__c.fields.Actual_Velocity__c.getName(),
            Schema.SObjectType.Burndown_Item__c.fields.Planned_Velocity__c.getName()
        };
        request.filterClause = 'Sprint__c = \'' + s.Id + '\'';

        Test.startTest();
        SprintSnapshotRecordsCollector.mockHistory = MOCK_HISTORY
            .replaceAll('RECORD_ID', request.objectId)
            .replaceAll('OBJECT_NAME', Schema.SObjectType.Burndown_Item__c.getName())
            .replaceAll('ACTUAL_VELOCITY_FIELD', Schema.SObjectType.Burndown_Item__c.fields.Actual_Velocity__c.getName())
            .replaceAll('PLANNED_VELOCITY_FIELD', Schema.SObjectType.Burndown_Item__c.fields.Planned_Velocity__c.getName());
        SprintSnapshotRecordsCollector.SprintSnapshotResponse[] htResponse = SprintSnapshotRecordsCollector.getTrackedHistoryTrending(request);
        Test.stopTest();

        System.assert(!htResponse.isEmpty(), 'Returned History shouldn\'t be empty');
        System.assertEquals(3, htResponse.size(), 'Return history list should be 3');
    }
}