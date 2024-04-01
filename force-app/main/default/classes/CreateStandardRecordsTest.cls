@IsTest
private class CreateStandardRecordsTest {
    @IsTest
    private static void executeNewRecords() {

        // Setup
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
        CreateStandardRecords.execute('CopadoStandardRecords');


        // Verify
        List<Function__c> results = [SELECT Id, API_Name__c, Script__c FROM Function__c];
        System.assertEquals(1, results.size(), 'There is 1 function record');
        System.assertEquals(f.API_Name__c, results[0].API_Name__c, 'The API name matches');
        System.assertEquals(f.Script__c, results[0].Script__c, 'The script matches');
    }


    @IsTest
    private static void executeExistingRecords() {

        // Setup
        Function__c f = (Function__c) new Function().apiName('SampleFunction').script('echo "Old"').persist();
        String json = CreateStandardRecords.serialize(new Set<Id> { f.Id });
        f.Script__c = 'echo "Updated"';
        update f;

        StaticResourcesSelector.mock = new List<StaticResource> {
            new StaticResource(Name = 'CopadoStandardRecords', Body = Blob.valueOf(json))
        };

        SupportedObjectsSelector.mock = new Map<String, String> {
            'copado__Function__c' => 'copado__API_Name__c'
         };


        // Exercise
        CreateStandardRecords.execute('CopadoStandardRecords');


        // Verify
        List<Function__c> results = [SELECT Id, API_Name__c, Script__c FROM Function__c];
        System.assertEquals(1, results.size(), 'There is 1 function record');
        System.assertEquals(f.API_Name__c, results[0].API_Name__c, 'The API name is same');
        System.assertEquals('echo "Old"', results[0].Script__c, 'The script matches');
    }
}