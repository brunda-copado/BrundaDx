@SuppressWarnings('PMD.AvoidGlobalModifier')
global with sharing class CheckStatusAction {

    private String jobId;
    private String resultId;

    // CONSTRUCTOR

    private CheckStatusAction(Request request) {
        this.jobId = request.jobId;
        this.resultId = request.resultId;
    }

    // GLOBAL

    @InvocableMethod(label='Check Status Action' category='Copado Action')
    global static List<Response> fetch(List<Request> requests) {
        try {
            if (requests.size() != 1) {
                throw new ApplicationException(Label.OnlyOneRequestAvailable);
            }
            Response response = new CheckStatusAction(requests[0]).fetch();

            return new List<Response>{ response };
        } catch (Exception ex) {
            throw new ApplicationException(ex.getMessage());
        }
    }

    // PRIVATE

    private Response fetch() {
        validateRequest();

        Response response;

        JobExecution__c job = String.isBlank(jobId) ? null : byIdsWithLastRunStep();

        Result__c result = String.isBlank(resultId) ? null : getResult();

        if (job != null) {
            response = new Response(job?.Status__c, job?.ErrorMessage__c);
            result = job.JobSteps__r.isEmpty() ? null : job.JobSteps__r[0].Result__r;
        }
        else {
            response = new Response(result?.Status__c, result?.Error_Message__c);
        }

        response.resultId = result?.Id;
        response.progressStatus = result?.Progress_Status__c;

        return response;
    }


    private JobExecution__c byIdsWithLastRunStep() {
        List<JobExecution__c> job = new JobExecutionsSelector()
                                        .byIdsWithLastRunStep(new Set<Id>{ jobId });

        if (job.isEmpty()) {
            throw new ApplicationException(Label.InvalidExecutionId);
        }

        return job[0];
    }


    private Result__c getResult() {
        List<Result__c> result = new ResultsSelector().byIds(new Set<Id>{ resultId });

        if (result.isEmpty()) {
            throw new ApplicationException(Label.Result_not_Found);
        }

        return result[0];
    }


    private void validateRequest() {
        if (
            (String.isBlank(jobId) && String.isBlank(resultId)) ||
            (String.isNotBlank(jobId) && String.isNotBlank(resultId))
        ) {
            throw new ApplicationException(Label.Invalid_Job_Or_Result_Id);
        }
    }

    // INNER

    global class Request {
        @InvocableVariable(label='Job Execution Id')
        global String jobId;

        @InvocableVariable(label='Result Id')
        global String resultId;

        // CTOR

        @SuppressWarnings('PMD.EmptyStatementBlock')
        global Request() {
            // Flows need a no-arg constructor
        }

        global Request(String jobId, String resultId) {
            this.jobId = jobId;
            this.resultId = resultId;
        }
    }


    global class Response {
        @InvocableVariable(label='Status of Job/Result')
        global String status;

        @InvocableVariable(label='Error message')
        global String errorMessage;

        @InvocableVariable(label='Result Id/Latest step result Id')
        global Id resultId;

        @InvocableVariable(label='Progress status of Job/Result')
        global String progressStatus;

        // CTOR

        private Response(String status, String errorMessage) {
            this.status = status;
            this.errorMessage = errorMessage;
        }
    }
}