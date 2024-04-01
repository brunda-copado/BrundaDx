@SuppressWarnings('PMD')
@IsTest
private class FunctionResultMonitorTest {
    @TestSetup
    private static void setup() {
        insertData();
    }


    @IsTest
    private static void getDefaultTimeout() {
        // Exercise
        Test.startTest();
        Decimal timeout = FunctionResultMonitor.timeout();
        Test.stopTest();

        // Verify
        String defaultTimeout = [SELECT Text_Field__c FROM Copado_Setting__mdt WHERE DeveloperName = 'Functions_backend_communication_timeout']
        ?.Text_Field__c;

        if (String.isNotBlank(defaultTimeout)) {
            System.assertEquals('5', String.valueOf(timeout), '');
        } else {
            System.assertEquals(defaultTimeout, String.valueOf(timeout), '');
        }
    }


    @IsTest
    private static void execute() {
        // Setup
        setHttpMock(201);

        // Exercise
        Test.startTest();
        Database.executeBatch(new FunctionResultMonitor(), 100);
        Test.stopTest();

        // Verify
        Result__c result = [SELECT Error_Message__c, Status__c, Progress_Status__c FROM Result__c LIMIT 1];
        String errorMessage = String.format(Label.Function_Execution_Timed_Out, new List<String>{ '1' }) + ' ' + Label.Function_Cancelled;

        System.assertEquals('Cancelled', result.Status__c, 'Status should be updated to "Cancelled".');
        System.assertEquals('Cancelled', result.Progress_Status__c, 'Progress Status should be updated to "Cancelled".');
        System.assertEquals(errorMessage, result.Error_Message__c, 'Error message must be updated to "function execution cancelled".');
    }


    @IsTest
    private static void schedule() {
        // Setup
        setHttpMock(201);

        // Exercise
        Test.startTest();
        FunctionResultMonitor.schedule();
        Test.stopTest();

        // Verify
        System.assertEquals(
            1,
            [SELECT COUNT() FROM CronTrigger WHERE CronJobDetail.Name = 'FunctionResultMonitor'],
            'Failed to schedule result monitor job.'
        );
    }

    // HELPER

    private static void insertData() {
        Function__c function = (Function__c) new Function()
            .name('muleDeploy')
            .apiName('muleDeploy')
            .script('echo hello world $par1')
            .type('Custom')
            .timeout(1)
            .paramaters('[{"name": "LogLevel", "defaultValue": "ERROR", "required": false}]')
            .workerSize('S')
            .persist();

        new Result()
            .jobType('muleDeploy')
            .startTime(Datetime.now().addMinutes(-10))
            .status('In Progress')
            .function(function.Id)
            .timeout(function.Timeout__c)
            .functionWorkerSize(function.Worker_Size__c)
            .persist();
    }

    private static void setHttpMock(Integer status) {
        MockHttpResponseGenerator mockResponse = new MockHttpResponseGenerator(
            status,
            'Complete',
            '{"id": "123123123", "status": "pending", "messages": ["function received and Queued", "executin will start shortly"]}',
            null
        );

        Test.setMock(HttpCalloutMock.class, mockResponse);
    }
}