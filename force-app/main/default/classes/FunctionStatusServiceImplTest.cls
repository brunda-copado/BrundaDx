@IsTest
private class FunctionStatusServiceImplTest {
    @TestSetup
    private static void setupData() {
        TestUtilities.getAllMultilicense();
        User user = (User) new User_t()
            .assign(new PermissionSetAssignment_t().copadoUser())
            .assign(new PermissionSetAssignment_t().functionsUser())
            .assign(new PermissionSetAssignment_t().jobEngine())
            .persist();

        System.runAs(user) {
            new CopadoLicense().user(user).enableAll().persist();
        }
    }

    @IsTest
    private static void exceptionWithNoResultId() {
        System.runAs(getUser()) {
            //Setup

            Exception expectedException;
            CopadoFunctions.StatusResponse expectedResult;

            // Exercise

            Test.startTest();
            try {
                expectedResult = CopadoFunctions.status(null);
            } catch (Exception ex) {
                expectedException = ex;
            }
            Test.stopTest();

            // Verify

            System.assertEquals(null, expectedResult, 'Response should be null');
            System.assertNotEquals(null, expectedException, 'An exception should be thrown');
            System.assertEquals('Missing required parameters : Result Id', expectedException.getMessage(), 'Exception message should match.');
        }
    }

    @IsTest
    private static void successfulResult() {
        System.runAs(getUser()) {
            // Setup

            Result__c result = (Result__c) new Result().status('Success').persist();

            result.ApexCallback__c = 'ApexCallbackClass';
            result.Function_Worker_Size__c = 'S';
            update result;

            // Exercise

            Test.startTest();
            CopadoFunctions.StatusResponse expectedResult = CopadoFunctions.status(result.Id);
            Test.stopTest();

            // Verify

            System.assertNotEquals(null, expectedResult, 'Result is not null');
            System.assertEquals('Success', expectedResult.result.Status__c, 'Result status is success.');
            System.assertEquals(null, expectedResult.result.Error_Message__c, 'Error Message is blank.');
            System.assertEquals('ApexCallbackClass', expectedResult.result.ApexCallback__c, 'The name of the callback matches');
            System.assertEquals('S', expectedResult.result.Function_Worker_Size__c, 'The worker size is S.');
        }
    }

    @IsTest
    private static void erroredResult() {
        System.runAs(getUser()) {
            // Setup

            Result__c result = (Result__c) new Result().status('Failed').progress('Completed').errMsg('Custom Error Message').persist();

            result.ApexCallback__c = 'ApexCallbackClass';
            result.Function_Worker_Size__c = 'M';
            update result;

            // Exercise

            Test.startTest();
            CopadoFunctions.StatusResponse expectedResult = CopadoFunctions.status(result.Id);
            Test.stopTest();

            // Verify

            System.assertNotEquals(null, expectedResult, 'Result is not null');
            System.assertEquals('Failed', expectedResult.result.Status__c, 'Result status is success.');
            System.assertEquals('Completed', expectedResult.result.Progress_Status__c, 'Progress status is completed.');
            System.assertEquals('Custom Error Message', expectedResult.result.Error_Message__c, 'Error Message matches.');
            System.assertEquals('ApexCallbackClass', expectedResult.result.ApexCallback__c, 'The name of the callback matches');
            System.assertEquals('M', expectedResult.result.Function_Worker_Size__c, 'The worker size is S.');
        }
    }

    // HELPER

    private static User getUser() {
        return [SELECT Id, Email FROM User WHERE Profile.Name = 'Standard User' ORDER BY CreatedDate DESC LIMIT 1];
    }
}