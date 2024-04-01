// Note: These parameters are returned to a aura controller so they need to be public
@SuppressWarnings('PMD.ExcessivePublicCount')
public with sharing class SprintSnapshotRecordsCollector {
    private static final String SPRINT_SNAPSHOT_QUERY = 'SELECT {0} FROM {1} WHERE {2} ORDER BY CreatedDate ASC';

    @TestVisible
    private static String mockHistory = '';

    // Returns sprint snapshot response for an object
    public static List<SprintSnapshotResponse> getTrackedHistoryTrending(SprintSnapshotRequest request) {
        return prepareResponse(retrieveSprintSnapshots(getSelectFields(request.fields), request.objectName, request.filterClause), request.fields);
    }

    // Prepare response
    private static List<SprintSnapshotResponse> prepareResponse(List<sObject> records, Set<String> fields) {
        List<SprintSnapshotResponse> snapshots = new List<SprintSnapshotResponse>();
        SprintSnapshotResponse snapshot;
        for (sObject record : records) {
            snapshot = new SprintSnapshotResponse();
            snapshot.snapshotDate = (Date) record.get('Snapshot_Date__c');
            snapshot.snapshotFields = new List<SnapshotFieldResponse>();
            for (String field : fields) {
                SnapshotFieldResponse snapshotField = new SnapshotFieldResponse();
                snapshotField.fieldName = field;
                snapshotField.value = record.get(field) != null ? String.valueOf(record.get(field)) : null;
                snapshot.snapshotFields.add(snapshotField);
            }
            snapshots.add(snapshot);
        }
        return snapshots;
    }

    // Prepare fields to retrieve
    private static String getSelectFields(Set<String> fields) {
        return String.join(new List<String>(fields), ',');
    }

    // Retrieve snapshot records
    private static List<SObject> retrieveSprintSnapshots(String fields, String objectName, String whereClause) {
        List<SObject> snapshotRecords;
        try {
            String queryString = String.format(SPRINT_SNAPSHOT_QUERY, new List<String>{ fields, objectName, whereClause });
            snapshotRecords = Test.isRunningTest() && String.isNotEmpty(mockHistory) ? getMockData() : Database.query(queryString);
        } catch (System.QueryException ex) {
            throw ex;
        }
        return snapshotRecords;
    }

    private static SObject[] getMockData() {
        return (SObject[]) JSON.deserialize(mockHistory, List<SObject>.class);
    }

    // Sprint Snapshot Response Wrapper
    public with sharing class SprintSnapshotResponse {
        public Date snapshotDate { get; set; }
        public List<SnapshotFieldResponse> snapshotFields { get; set; }
    }

    // Sprint Snapshot Field Response Wrapper
    public with sharing class SnapshotFieldResponse {
        public String value { get; set; }
        public String fieldName { get; set; }
    }

    // Sprint Snapshot Request
    public with sharing class SprintSnapshotRequest {
        public String objectId { get; set; }
        public String objectName { get; set; }
        public Set<String> fields { get; set; }
        public String filterClause { get; set; }
    }
}