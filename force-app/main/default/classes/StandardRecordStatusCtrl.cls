public with sharing class StandardRecordStatusCtrl {

    @AuraEnabled
    public static List<StaticResource> getResources() {
        List<StaticResource> result;

        try {
            result = new StaticResourcesSelector().byName(new StandardResourcesSelector().all());
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }

        return result;
    }

    @AuraEnabled
    public static string getStandardRecordsBundle(Id resourceId) {
        String result;

        try {
            List<StaticResource> standardResource = new StaticResourcesSelector().byId(resourceId);
            result = standardResource[0].Body.toString();

            if(String.isBlank(Settings.ns)) {
                result = result.replaceAll('copado__', '');
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }

        return result;
    }

    @AuraEnabled
    public static InsertedBundle getInsertedBundle(String serializedBundle) {
        InsertedBundle result = new InsertedBundle();
        if(String.isBlank(Settings.ns)) {
            serializedBundle = serializedBundle.replaceAll('copado__', '');
        }

        SObjectDataLoader.RecordSetBundle bundle = (SObjectDataLoader.RecordSetBundle) JSON.deserialize(serializedBundle, SObjectDataLoader.RecordSetBundle.class);
        result.externalIdField = new SupportedObjectsSelector().byType(bundle.objectType);

        if(String.isBlank(result.externalIdField)) {
            throw new AuraHandledException(String.format(Label.UnSupportedStandardRecord, new List<String> {bundle.objectType}));
        }
        else if(String.isBlank(Settings.ns)) {
            result.externalIdField = result.externalIdField.replace('copado__', '');
        }

        Set<Id> recordIds = recordIds(bundle, result.externalIdField);

        if(!recordIds.isEmpty()) {
            String serializedBundleSet = CreateStandardRecords.serialize(recordIds);
            SObjectDataLoader.RecordsBundle bundles = (SObjectDataLoader.RecordsBundle) JSON.deserialize(serializedBundleSet, SObjectDataLoader.RecordsBundle.class);
            result.records = bundles.recordSetBundles[0].records;
        }

        return result;
    }

    @AuraEnabled
    public static void updateRecords(String resourceName) {
        try {
            CreateStandardRecords.execute(resourceName);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }


    // PRIVATE
    @SuppressWarnings('PMD.UnusedLocalVariable')
    private static Set<Id> recordIds(SObjectDataLoader.RecordSetBundle bundle, String externalIdField) {
        Set<String> recordNames = recordNames(bundle, externalIdField);
        String queryString = 'SELECT Id FROM ' + bundle.objectType + ' WHERE ' + externalIdField + ' IN : recordNames WITH SECURITY_ENFORCED';

        return new Map<Id, SObject>( Database.query( String.escapeSingleQuotes(queryString) ) ).keySet();
    }

    private static Set<String> recordNames(SObjectDataLoader.RecordSetBundle bundle, String externalIdField) {
        Set<String> result = new Set<String>();

        for(SObject record : bundle.records) {
            String recordName = (String) record.get(externalIdField);
            result.add(recordName);
        }

        return result;
    }

    // INNER

    public class InsertedBundle {
        @AuraEnabled
        public List<SObject> records;

        @AuraEnabled
        public String externalIdField;

        @SuppressWarnings('PMD.EmptyStatementBlock')
        public InsertedBundle() {}

        public InsertedBundle(List<SObject> records, String externalIdField) {
            this.records = records;
            this.externalIdField = externalIdField;
        }
    }
}