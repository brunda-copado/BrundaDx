@IsTest
private class CheckStatusActionTest {

    @TestSetup
    private static void makeData() {
        setupUser();
    }


    @IsTest
    private static void multipleRequests() {
        System.runAs(getRunAsUser()) {
            
            // Setup

            Exception expectedEx;
            List<CheckStatusAction.Request> requests = new List<CheckStatusAction.Request>{
                new CheckStatusAction.Request(null, null),
                new CheckStatusAction.Request(null, null)
            };

            // Exercise

            try {
                CheckStatusAction.fetch(requests);
            } catch (Exception ex) {
                expectedEx = ex;
            }

            // Verify

            System.assertEquals(
                Label.OnlyOneRequestAvailable,
                expectedEx.getMessage(),
                'Exception should be thrown.'
            );
        }
    }


    @IsTest
    private static void emptyRequest() {
        System.runAs(getRunAsUser()) {

            // Setup

            Exception expectedEx;
            CheckStatusAction.Request request = new CheckStatusAction.Request(null, null);

            // Exercise

            try {
                CheckStatusAction.fetch( asList(request) );
            } catch (Exception ex) {
                expectedEx = ex;
            }

            // Verify

            System.assertEquals(
                Label.Invalid_Job_Or_Result_Id,
                expectedEx.getMessage(),
                'Exception should be thrown.'
            );
        }
    }


    @IsTest
    private static void invalidJobId() {
        System.runAs(getRunAsUser()) {

            // Setup

            Exception expectedEx;
            JobTemplate__c jt = (JobTemplate__c) new JobTemplate().name('JT1').persist();
            CheckStatusAction.Request request = new CheckStatusAction.Request(jt.Id, null);

            // Exercise

            try {
                CheckStatusAction.fetch( asList(request) );
            } catch (Exception ex) {
                expectedEx = ex;
            }

            // Verify

            System.assertEquals(
                Label.InvalidExecutionId,
                expectedEx.getMessage(),
                'Exception should be thrown.'
            );
        }
    }


    @IsTest
    private static void invalidResultId() {
        System.runAs(getRunAsUser()) {

            // Setup

            Exception expectedEx;
            JobTemplate__c jt = (JobTemplate__c) new JobTemplate().name('JT1').persist();
            CheckStatusAction.Request request = new CheckStatusAction.Request(null, jt.Id);

            // Exercise

            try {
                CheckStatusAction.fetch( asList(request) );
            } catch (Exception ex) {
                expectedEx = ex;
            }

            // Verify

            System.assertEquals(
                Label.Result_not_Found,
                expectedEx.getMessage(),
                'Exception should be thrown.'
            );
        }
    }


    @IsTest
    private static void invalidRequest() {
        System.runAs(getRunAsUser()) {

            // Setup

            Exception expectedEx;
            JobExecution__c je = (JobExecution__c) new JobExecution().persist();
            Result__c r = (Result__c) new Result().persist();
            CheckStatusAction.Request request = new CheckStatusAction.Request(r.Id, je.Id);

            // Exercise

            try {
                CheckStatusAction.fetch( asList(request) );
            } catch (Exception ex) {
                expectedEx = ex;
            }

            // Verify

            System.assertEquals(
                Label.Invalid_Job_Or_Result_Id,
                expectedEx.getMessage(),
                'Exception should be thrown.'
            );
        }
    }


    @IsTest
    private static void jobWithNoSteps() {
        System.runAs(getRunAsUser()) {

            // Setup

            JobExecution__c je = (JobExecution__c) new JobExecution()
                                                        .status('Starting')
                                                        .errorMsg('No errors yet')
                                                        .persist();

            CheckStatusAction.Request request = new CheckStatusAction.Request(je.Id, null);

            // Exercise

            CheckStatusAction.Response response = CheckStatusAction.fetch( asList(request) ).get(0);

            // Verify

            System.assertEquals(je.Status__c, response.status, 'Incorrect Status');
            System.assertEquals(je.ErrorMessage__c, response.errorMessage, 'Incorrect Message.');
            System.assertEquals(null, response.progressStatus, 'Incorrect Message.');
            System.assertEquals(null, response.resultId, 'Incorrect Result Id.');
        }
    }


    @IsTest
    private static void jobWithNoExecutedSteps() {
        System.runAs(getRunAsUser()) {
            
            // Setup

            JobExecution__c je = (JobExecution__c) new JobExecution()
                                    .status('Completed')
                                    .add( new JobStep().executionSequence('before').order(1) )
                                    .add( new JobStep().executionSequence('after').order(2) )
                                    .persist();

            CheckStatusAction.Request request = new CheckStatusAction.Request(je.Id, null);

            // Exercise

            CheckStatusAction.Response response = CheckStatusAction.fetch( asList(request) ).get(0);

            // Verify

            System.assertEquals(je.Status__c, response.status, 'Incorrect Status');
            System.assertEquals(je.ErrorMessage__c, response.errorMessage, 'Incorrect Message.');
            System.assertEquals(null, response.progressStatus, 'Incorrect Progress Status.');
            System.assertEquals(null, response.resultId, 'Incorrect result Id.');
        }
    }


    @IsTest
    private static void jobStatusWithBeforeRun() {
        System.runAs(getRunAsUser()) {

            // Setup

            JobExecution__c je = (JobExecution__c) new JobExecution()
                .status('Error')
                .errorMsg('Failed')
                .add(
                    new JobStep()
                        .executionSequence('before')
                        .order(1)
                        .result(
                            new Result()
                                .status('Result Error')
                                .errMsg('Result Failed')
                                .progress('Zero')
                        )
                )
                .add( new JobStep().executionSequence('before').order(2) )
                .add( new JobStep().executionSequence('after').order(3) )
                .persist();

            CheckStatusAction.Request request = new CheckStatusAction.Request(je.Id, null);

            // Exercise

            CheckStatusAction.Response response = CheckStatusAction.fetch( asList(request) ).get(0);

            // Verify

            Result__c r = [
                SELECT Progress_Status__c
                FROM Result__c
                WHERE
                    ID IN (
                        SELECT Result__c
                        FROM JobStep__c
                        WHERE Order__c = 1 AND ExecutionSequence__c = 'before'
                    )
                LIMIT 1
            ];
            
            System.assertEquals(je.Status__c, response.status, 'Incorrect Status');
            System.assertEquals(je.ErrorMessage__c, response.errorMessage, 'Incorrect Message.');
            System.assertEquals(
                r.Progress_Status__c,
                response.progressStatus,
                'Incorrect Progress Status.'
            );
            System.assertEquals(r.Id, response.resultId, 'Incorrect result Id.');
        }
    }


    @IsTest
    private static void jobStatusWithAfterRun() {
        System.runAs(getRunAsUser()) {

            // Setup

            JobExecution__c je = (JobExecution__c) new JobExecution()
                .status('In Progress')
                .add( new JobStep().executionSequence('before').order(1).result( new Result() ) )
                .add( new JobStep().executionSequence('after').order(2).result( new Result() ) )
                .add(
                    new JobStep()
                        .executionSequence('after')
                        .order(3)
                        .result(
                            new Result()
                                .status('Working')
                                .errMsg('None')
                                .progress('Half')
                        )
                )
                .persist();

            CheckStatusAction.Request request = new CheckStatusAction.Request(je.Id, null);

            // Exercise

            CheckStatusAction.Response response = CheckStatusAction.fetch( asList(request) ).get(0);

            // Verify

            Result__c r = [
                SELECT Progress_Status__c
                FROM Result__c
                WHERE
                    ID IN (
                        SELECT Result__c
                        FROM JobStep__c
                        WHERE Order__c = 3 AND ExecutionSequence__c = 'after'
                    )
                LIMIT 1
            ];

            System.assertEquals(je.Status__c, response.status, 'Incorrect Status');
            System.assertEquals(je.ErrorMessage__c, response.errorMessage, 'Incorrect Message.');
            System.assertEquals(
                r.Progress_Status__c,
                response.progressStatus,
                'Incorrect Progress Status.'
            );
            System.assertEquals(r.Id, response.resultId, 'Incorrect result Id.');
        }
    }


    @IsTest
    private static void jobStatusWithNoSequence() {
        System.runAs(getRunAsUser()) {

            // Setup

            JobExecution__c je = (JobExecution__c) new JobExecution()
                .status('Error')
                .errorMsg('Failed')
                .add( new JobStep().order(1).executionSequence('before') )
                .add(
                    new JobStep()
                        .order(2)
                        .result(
                            new Result()
                                .status('Result Error')
                                .errMsg('Result Failed')
                                .progress('Zero')
                        )
                )
                .add( new JobStep().executionSequence('after').order(3) )
                .persist();

            CheckStatusAction.Request request = new CheckStatusAction.Request(je.Id, null);

            // Exercise

            CheckStatusAction.Response response = CheckStatusAction.fetch( asList(request) ).get(0);

            // Verify

            Result__c r = [
                SELECT Progress_Status__c
                FROM Result__c
                WHERE
                    ID IN (
                        SELECT Result__c
                        FROM JobStep__c
                        WHERE Order__c = 2 AND ExecutionSequence__c = null
                    )
                LIMIT 1
            ];
            
            System.assertEquals(je.Status__c, response.status, 'Incorrect Status');
            System.assertEquals(je.ErrorMessage__c, response.errorMessage, 'Incorrect Message.');
            System.assertEquals(
                r.Progress_Status__c,
                response.progressStatus,
                'Incorrect Progress Status.'
            );
            System.assertEquals(r.Id, response.resultId, 'Incorrect result Id.');
        }
    }


    @IsTest
    private static void resultStatus() {
        System.runAs(getRunAsUser()) {

            // Setup

            Result__c r = (Result__c) new Result()
                                            .jobType('Test')
                                            .status('Error')
                                            .errMsg('Failed')
                                            .progress('None')
                                            .persist();

            CheckStatusAction.Request request = new CheckStatusAction.Request(null, r.Id);

            // Exercise

            CheckStatusAction.Response response = CheckStatusAction.fetch( asList(request) ).get(0);

            // Verify

            System.assertEquals(r.Status__c, response.status, 'Incorrect Status');
            System.assertEquals(r.Error_Message__c, response.errorMessage, 'Incorrect Message.');
            System.assertEquals(
                r.Progress_Status__c,
                response.progressStatus,
                'Incorrect Message.'
            );
            System.assertEquals(r.Id, response.resultId, 'Incorrect Message.');
        }
    }

    // HELPER

    private static void setupUser() {
        TestUtilities.getAllMultilicense();
        TestDataFactory.createUsers();

        User u = getRunAsUser();

        List<PermissionSetAssignment> assignments = new List<PermissionSetAssignment>();

        for (PermissionSet ps : [
            SELECT Id
            FROM PermissionSet
            WHERE Name IN ('Copado_User', 'Copado_Job_Engine', 'Copado_Functions')
        ]) {
            assignments.add(
                new PermissionSetAssignment(AssigneeId = u.Id, PermissionSetId = ps.Id)
            );
        }
        insert assignments;

        System.runAs(u) {
            TestUtilities.assignLicense(u.Username, true, true, true, true, true, true);
        }
    }


    private static User getRunAsUser() {
        return [
            SELECT Username
            FROM User
            WHERE Profile.Name = 'Standard User' AND Username LIKE '%pstdUser002@amamama.com%'
            LIMIT 1
        ];
    }


    private static List<CheckStatusAction.Request> asList(CheckStatusAction.Request request) {
        return new List<CheckStatusAction.Request>{ request };
    }
}