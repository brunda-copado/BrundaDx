@IsTest
private class CreateStandardRecordCtrlTest {

    @IsTest
    private static void getSupportedObjectsByName() {
        // Setup
        SupportedObjectsSelector.mockRecords = new List<SupportedObject__mdt> { new SupportedObject__mdt() };

        // Exercise
        Test.startTest();
        List<CreateStandardRecordCtrl.SupportedObject> result = CreateStandardRecordCtrl.getSupportedObjects();
        Test.stopTest();

        // Verify
        Assert.areEqual(1, result.size(), 'The result size matches.');
    }

    @IsTest
    private static void allSupportedObject() {

        // Exercise
        Test.startTest();
        List<SupportedObject__mdt> result = new SupportedObjectsSelector().allExposed();
        Test.stopTest();

        // Verify
        Assert.areEqual(3, result.size(), 'There are 3 records returned.');
    }

    @IsTest
    private static void getSupportedObjectsWithoutMock() {

        // Exercise
        Test.startTest();
        Map<String, String> result = new SupportedObjectsSelector().all();
        Test.stopTest();

        // Verify
        Assert.areEqual(4, result.size(), 'There are 4 records returned.');
    }

    @IsTest
    private static void getRecordBundle() {
        // Setup
        Exception expectedException = null;

        Function__c f = (Function__c) new Function().apiName('SampleFunction').script('echo "Ols"').persist();

        // Exercise
        Test.startTest();
        try {
            CreateStandardRecordCtrl.getRecordBundle(new List<Id> { f.Id });
        } catch(Exception ex) {
            expectedException = ex;
        }
        Test.stopTest();

        // Verify
        Assert.areEqual(null, expectedException, 'There is no exception');
    }

    @IsTest
    private static void getRecordBundleExceptionScenario() {
        // Setup
        Exception expectedException = null;

        // Exercise
        Test.startTest();
        try {
            CreateStandardRecordCtrl.getRecordBundle(new List<Id>());
        } catch(Exception ex) {
            expectedException = ex;
        }
        Test.stopTest();

        // Verify
        Assert.areNotEqual(null, expectedException, 'There should be exception');
    }

    @IsTest
    public static void getRecordBundleFunction() {
        // Setup
        Function__c f = (Function__c) new Function().name('Sample Function').apiName('SampleFunction').script('echo "Ols"').persist();

        JobTemplate__c job = (JobTemplate__c) new JobTemplate()
            .name('Job1')
            .add(new JobStep()
                        .name('S1')
                        .type('Function')
                        .configJson('{"functionName":"' + f.API_Name__c + '"}')
                )
            .persist();

        // Exercise
        List<CreateStandardRecordCtrl.NestedRecord> records = CreateStandardRecordCtrl.getNestedRecords(job.Id);

        // Verify

        Assert.areEqual(2, records.size(), 'should return 2 nested elements');

        Assert.areEqual('Job Step', records[0].type);
        Assert.areEqual('S1', records[0].name);

        Assert.areEqual('Function', records[1].type);
        Assert.areEqual('Sample Function', records[1].name);
    }

    @IsTest
    public static void getRecordBundleWithInvalidFunction() {
        Exception expectedException = null;

        // Setup
        Function__c f = (Function__c) new Function().name('Sample Function').apiName('SampleFunction').script('echo "Ols"').persist();

        JobTemplate__c job = (JobTemplate__c) new JobTemplate()
            .name('Job1')
            .add(new JobStep()
                        .name('S1')
                        .type('Function')
                        .configJson('{"functionName":"InvalidApiName"}')
                )
             .add(new JobStep()
                        .name('S2')
                        .type('Function')
                        .configJson('{"functionName":"' + f.API_Name__c + '"}')
                )
            .persist();

        // Exercise
        try {
            CreateStandardRecordCtrl.getNestedRecords(job.Id);
        } catch(Exception ex) {
            expectedException = ex;
        }

        // Verify
        Assert.isNotNull(expectedException, 'There is no exception');
        Assert.areEqual(Label.InvalidFunctionReference + 'InvalidApiName', expectedException.getMessage());
    }
}