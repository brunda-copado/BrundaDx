@IsTest
private class CancelFunctionServiceImplTest {

    @TestSetup
    private static void setupData() {
        TestUtilities.getAllMultilicense();
        User user = (User) new User_t()
            .assign(new PermissionSetAssignment_t().copadoUser())
            .assign(new PermissionSetAssignment_t().jobEngine())
            .assign(new PermissionSetAssignment_t().functions())
            .persist();

        System.runAs(user) {
            new CopadoLicense().user(user).enableAll().persist();
            data();
        }
    }


    @IsTest
    private static void executeWithInvalidResultId() {
        System.runAs(getUser()) {

            // Setup

            Exception expectedException;
            CopadoFunctions.CancelResult expectedResult;

            // Exercise

            Test.startTest();
            try {
                expectedResult = CopadoFunctions.cancel(null);
            } catch(Exception ex) {
                expectedException = ex;
            }
            Test.stopTest();

            // Verify

            System.assertEquals(null, expectedResult, 'Response should be null');
            System.assertEquals('Missing required parameters : Result Id', expectedException.getMessage(), 'Exception message should match.');
        }
    }


    @IsTest
    private static void cancelFunction() {
        System.runAs(getUser()) {

            // Setup

            setHttpMock(201);
            Result__c record = [SELECT Id FROM Result__c WHERE Function__c != null AND Status__c = 'In Progress' LIMIT 1];

            // Exercise

            Test.startTest();
            CopadoFunctions.CancelResult expectedResponse = CopadoFunctions.cancel(record.Id);
            Test.stopTest();

            //Verify

            System.assertEquals('Cancelling', expectedResponse.result.Progress_Status__c, 'Progress Status matches.');
        }
    }


    @IsTest
    private static void cancelSuccessfulFunction() {
        System.runAs(getUser()) {

            // Setup

            setHttpMock(201);
            Result__c record = [SELECT Id FROM Result__c WHERE Function__c != null AND Status__c = 'Success' LIMIT 1];

            Exception resultException;

            // Exercise

            Test.startTest();
            try {
                CopadoFunctions.cancel(record.Id);
            } catch(Exception ex) {
                resultException = ex;
            }
            Test.stopTest();

            // Verify

            System.assertNotEquals(null, resultException, 'Exception should not be null');
            System.assertEquals(Label.Stop_Execution_Error_Completed, resultException.getMessage(), 'Error message matches.');
        }
    }


    @IsTest
    private static void stopExecutionWithErrorServerResponse() {
        System.runAs(getUser()) {
            // Setup

            setHttpMock(400);
            Result__c record = [SELECT Id FROM Result__c WHERE Function__c != null AND Status__c = 'In Progress' LIMIT 1];

            Exception resultException;

            // Exercise

            Test.startTest();
            try {
                CopadoFunctions.cancel(record.Id);
            } catch(Exception ex) {
                resultException = ex;
            }
            Test.stopTest();

            // Verify

            System.assertNotEquals(null, resultException, 'Exception should not be null');
            System.assertEquals(Label.Stop_Execution_Error_Connecting, resultException.getMessage(), 'Error message matches.');
        }
    }


    //HELPER

    private static User getUser() {
        return [SELECT Id, Email FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1];
    }


    private static void data() {
        new Function().apiName('Test1').add(
            new Result().status('In Progress')
        );

        new Function().apiName('Test2').add(
            new Result().status('Success')
        ).persist();
    }


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