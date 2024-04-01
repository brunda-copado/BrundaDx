@IsTest
private class JobStatusServiceTest {

    @TestSetup
    private static void makeData() {
        setupUser();
    }

    @IsTest
    private static void exception() {
        System.runAs( standardUser() ) {

            // Setup

            Exception expectedEx;
            CliProxy.CLIWrapper request = cliRequest( new CheckStatusAction.Request(null, null) );

            // Exercise

            try {
                new JobStatusService().run(request);
            } catch (Exception ex) {
                expectedEx = ex;
            }

            // Verify

            System.assertEquals(Label.Invalid_Job_Or_Result_Id, expectedEx.getMessage(), 'Exception should be thrown.');
        }
    }


    @IsTest
    private static void run() {
        System.runAs( standardUser() ) {

            // Setup

            JobExecution__c je = (JobExecution__c) new JobExecution()
                .status('Starting')
                .errorMsg('No errors yet')
                .persist();

            CliProxy.CLIWrapper request = cliRequest( new CheckStatusAction.Request(je.Id, null) );

            // Exercise

            String result = new JobStatusService().run(request);
            JobStatusService.Response proxyResponse = (JobStatusService.Response) JSON.deserialize(
                result,
                JobStatusService.Response.class
            );

            // Verify
            System.assertEquals('OK', proxyResponse.status, 'Status should be OK.');
            System.assertEquals('Job Status', proxyResponse.message, 'Message should be correct.');
            System.assertNotEquals(null, proxyResponse.body, 'Status should be returned.');

            CheckStatusAction.Response actionResponse = proxyResponse.body;

            System.assertEquals(je.Status__c, actionResponse.status, 'Incorrect Status');
            System.assertEquals(je.ErrorMessage__c, actionResponse.errorMessage, 'Incorrect Message.');
            System.assertEquals(null, actionResponse.progressStatus, 'Incorrect Message.');
            System.assertEquals(null, actionResponse.resultId, 'Incorrect Result Id.');
        }
    }

    // HELPER

    private static CliProxy.CLIWrapper cliRequest(CheckStatusAction.Request request) {
        CliProxy.CLIWrapper result = new CliProxy.CLIWrapper();

        result.mainService = 'job';
        result.subService = 'status';
        result.body = JSON.serialize(request);

        return result;
    }


    private static void setupUser() {
        TestUtilities.getAllMultilicense();

        User u = (User) new User_t()
            .assign( new PermissionSetAssignment_t().copadoUser() )
            .assign( new PermissionSetAssignment_t().jobEngine() )
            .persist();

        System.runAs(u) {
            new CopadoLicense().user(u).enableAll().persist();
        }
    }


    private static User standardUser() {
        return [
            SELECT Id
            FROM User
            WHERE Profile.Name = 'Standard User' AND UserName LIKE '%@test%.org'
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
    }
}