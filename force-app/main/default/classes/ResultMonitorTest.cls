@IsTest
private class ResultMonitorTest {

    private static final String STATUS_IN_PROGRESS = 'In Progress';
    private static final String STATUS_SUCCESS = 'Success';

    @TestSetup
    private static void setup() {
        new JobExecution().add(
            new JobStep().add(
                new Result().status(STATUS_IN_PROGRESS)
            )
        );

        new Function().apiName('Test1').add(
            new Result().status(STATUS_IN_PROGRESS)
        );

        new Function().apiName('Test2').add(
            new Result().status(STATUS_SUCCESS)
        ).persist();
    }

    @IsTest
    private static void getRecord() {
        // Setup
        Result__c record = [SELECT Status__c, Progress_Status__c FROM Result__c LIMIT 1];

        // Exercise
        Test.startTest();
        Result__c result = ResultMonitor.result(record.Id);
        Test.stopTest();

        // Verify
        System.assertEquals(record.Id, result.Id, 'Incorrect result retrieved.');
        System.assertEquals(record.Status__c, result.Status__c, 'Incorrect result status retrieved.');
        System.assertEquals(record.Progress_Status__c, result.Progress_Status__c, 'Incorrect result progress status retrieved.');
    }

    @IsTest
    private static void error() {
        // Setup
        Exception ex;

        // Exercise
        Test.startTest();
        try {
            ResultMonitor.result(null);
        } catch (Exception error) {
            ex = error;
        }
        Test.stopTest();

        // Verify
        System.assert(ex != null, 'No error was thrown for a null result id.');
    }

    @IsTest
    private static void getStopExecutionDataWithJobStep() {
        // Setup
        Result__c record = [SELECT JobStep__r.Name, JobStep__r.JobExecution__r.Name FROM Result__c WHERE JobStep__c != null LIMIT 1];

        String expectedTitle = String.format(Label.Stop_Execution_Title, new List<String> {SObjectType.JobStep__c.getLabel()});
        String expectedInfo = String.format(Label.Stop_Execution_Info, new List<String> {SObjectType.JobExecution__c.getLabel(), record.JobStep__r.JobExecution__r.Name});
        String expectedMessage = String.format(Label.Stop_Execution_Message_JobStep, new List<String> {record.JobStep__r.Name});
        String expectedError = String.format(Label.Stop_Execution_Error, new List<String> {SObjectType.JobStep__c.getLabel(), record.JobStep__r.Name});

        // Exercise
        Test.startTest();
        ResultMonitor.StopExecutionData result = ResultMonitor.getStopExecutionData(record.Id);
        Test.stopTest();

        // Verify
        System.assertEquals(expectedTitle, result.title, 'Incorrect title retrieved.');
        System.assertEquals(expectedInfo, result.info, 'Incorrect info retrieved.');
        System.assertEquals(expectedMessage, result.message, 'Incorrect message retrieved.');
        System.assertEquals(expectedError, result.error, 'Incorrect error retrieved.');
    }

    @IsTest
    private static void getStopExecutionDataWithFunction() {
        // Setup
        Result__c record = [SELECT Function__r.Name FROM Result__c WHERE Function__c != null LIMIT 1];

        String expectedTitle = String.format(Label.Stop_Execution_Title, new List<String> {SObjectType.Function__c.getLabel()});
        String expectedInfo = String.format(Label.Stop_Execution_Info, new List<String> {SObjectType.Function__c.getLabel(), record.Function__r.Name});
        String expectedMessage = Label.Stop_Execution_Message_Function;
        String expectedError = String.format(Label.Stop_Execution_Error, new List<String> {SObjectType.Function__c.getLabel(), record.Function__r.Name});

        // Exercise
        Test.startTest();
        ResultMonitor.StopExecutionData result = ResultMonitor.getStopExecutionData(record.Id);
        Test.stopTest();

        // Verify
        System.assertEquals(expectedTitle, result.title, 'Incorrect title retrieved.');
        System.assertEquals(expectedInfo, result.info, 'Incorrect info retrieved.');
        System.assertEquals(expectedMessage, result.message, 'Incorrect message retrieved.');
        System.assertEquals(expectedError, result.error, 'Incorrect error retrieved.');
    }

    @IsTest
    private static void stopExecution() {
        // Setup
        setHttpMock(201);
        Result__c record = [SELECT Id FROM Result__c WHERE Function__c != null AND Status__c = :STATUS_IN_PROGRESS LIMIT 1];

        // Exercise
        Test.startTest();
        ResultMonitor.stopExecution(record.Id);
        Test.stopTest();

        // Verify
        Result__c result = [SELECT Progress_Status__c FROM Result__c WHERE Id = :record.Id];
        System.assertEquals('Cancelling', result.Progress_Status__c, 'Incorrect Progress Status.');
    }

    @IsTest
    private static void stopExecutionCompleted() {
        // Setup
        setHttpMock(201);
        Result__c record = [SELECT Id FROM Result__c WHERE Function__c != null AND Status__c = :STATUS_SUCCESS LIMIT 1];
        
        Exception resultException;

        // Exercise
        Test.startTest();
        try {
            ResultMonitor.stopExecution(record.Id);
        } catch(Exception ex) {
            resultException = ex;
        }
        Test.stopTest();

        // Verify
        System.assertNotEquals(null, resultException, 'Exception should not be null');
        System.assertEquals(Label.Stop_Execution_Error_Completed, resultException.getMessage(), 'Incorrect error message.');
    }

    @IsTest
    private static void stopExecutionWithErrorServerResponse() {
        // Setup
        setHttpMock(400);
        Result__c record = [SELECT Id FROM Result__c WHERE Function__c != null AND Status__c = :STATUS_IN_PROGRESS LIMIT 1];
        
        Exception resultException;

        // Exercise
        Test.startTest();
        try {
            ResultMonitor.stopExecution(record.Id);
        } catch(Exception ex) {
            resultException = ex;
        }
        Test.stopTest();

        // Verify
        System.assertNotEquals(null, resultException, 'Exception should not be null');
        System.assertEquals(Label.Stop_Execution_Error_Connecting, resultException.getMessage(), 'Incorrect error message.');
    }

    @isTest
    private static void getHistoryTest() {
        Result__c record = [SELECT Status__c, Progress_Status__c FROM Result__c LIMIT 1];
        insert new Result__History(ParentId = record.Id,
                                   Field = Settings.ns + 'Progress_Status__c');
        
        // Call the method to test
        Test.startTest();
        List<ResultStatusDetail.HistoricalMessage> result = ResultMonitor.getHistoryData(record.Id);
        Test.stopTest();
        
        System.assertEquals(1, result.size(), 'Atleast one historical message must be fetched');
	}

    // Helper methods

    private static void setHttpMock(Integer status) {
        MockHttpResponseGenerator mockResponse = new MockHttpResponseGenerator(
            status,
            'Complete',
            '{}',
            null
        );

        Test.setMock(HttpCalloutMock.class, mockResponse);
    }

}