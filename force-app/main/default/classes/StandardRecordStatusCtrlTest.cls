@IsTest
private class StandardRecordStatusCtrlTest {

    @IsTest
    private static void getInsertedBundle() {

        // Setup
        Function__c f = (Function__c) new Function().apiName('SampleFunction').script('echo "Hello"').persist();
        String bundleJson = CreateStandardRecords.serialize(new Set<Id> { f.Id });
        SObjectDataLoader.RecordsBundle bundle = (SObjectDataLoader.RecordsBundle) JSON.deserialize(bundleJson, SObjectDataLoader.RecordsBundle.class);

        String recordSetJson = JSON.serialize(bundle.RecordSetBundles[0]);

        StaticResourcesSelector.mock = new List<StaticResource> {
            new StaticResource(Name = 'CopadoStandardRecords', Body = Blob.valueOf(bundleJson))
        };

        SupportedObjectsSelector.mock = new Map<String, String> {
            'copado__Function__c' => 'copado__API_Name__c'
         };


        // Exercise
        StandardRecordStatusCtrl.InsertedBundle result = StandardRecordStatusCtrl.getInsertedBundle(recordSetJson);


        // Verify
        System.assertNotEquals(null, result, 'The result is not null');
    }


    @IsTest
    private static void updateRecords() {

        // Setup
        Exception expectedException = null;
        System.Savepoint savePoint = Database.setSavepoint();
        Function__c f = (Function__c) new Function().apiName('SampleFunction').script('echo "Hello"').persist();
        String json = CreateStandardRecords.serialize(new Set<Id> { f.Id });

        StaticResourcesSelector.mock = new List<StaticResource> {
            new StaticResource(Name = 'CopadoStandardRecords', Body = Blob.valueOf(json))
        };

        SupportedObjectsSelector.mock = new Map<String, String> {
            'copado__Function__c' => 'copado__API_Name__c'
         };

        Database.rollback(savePoint);


        // Exercise
        try {
            StandardRecordStatusCtrl.updateRecords(null);
        } catch (Exception ex) {
            expectedException = ex;
        }


        // Verify
        System.assertEquals(null, expectedException, 'There is no exception.');

        List<Function__c> results = [SELECT Id, API_Name__c, Script__c FROM Function__c];
        System.assertEquals(1, results.size(), 'There is 1 function record.');
        System.assertEquals(f.API_Name__c, results[0].API_Name__c, 'The API name matches.');
        System.assertEquals(f.Script__c, results[0].Script__c, 'The function script matches.');
    }


    @IsTest
    private static void getResources() {

        // Setup
        List<StaticResource> results = new List<StaticResource>();

        System.Savepoint savePoint = Database.setSavepoint();
        Function__c f = (Function__c) new Function().apiName('SampleFunction').script('echo "Hello"').persist();
        String json = CreateStandardRecords.serialize(new Set<Id> { f.Id });

        StaticResourcesSelector.mock = new List<StaticResource> {
            new StaticResource(Name = 'CopadoStandardRecords', Body = Blob.valueOf(json))
        };

        SupportedObjectsSelector.mock = new Map<String, String> {
            'copado__Function__c' => 'copado__API_Name__c'
        };

        Database.rollback(savePoint);


        // Exercise
        results = StandardRecordStatusCtrl.getResources();


        // Verify
        System.assertEquals(1, results.size(), 'There is 1 static resource');
        System.assertEquals('CopadoStandardRecords', results[0].Name, 'The Name matches.');
        System.assertEquals(Blob.valueOf(json), results[0].Body, 'The resource body matches.');
    }


    @IsTest
    private static void getStandardRecordsBundleException() {

        // Setup
        Exception expectedException = null;
        System.Savepoint savePoint = Database.setSavepoint();
        Function__c f = (Function__c) new Function().apiName('SampleFunction').script('echo "Hello"').persist();
        Database.rollback(savePoint);


        // Exercise
        try {
            StandardRecordStatusCtrl.getStandardRecordsBundle(f.Id);
        } catch (Exception ex) {
            expectedException = ex;
        }

        // Verify
        System.assertNotEquals(null, expectedException, 'There is an exception');
    }
}