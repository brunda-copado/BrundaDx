@SuppressWarnings('PMD.AvoidGlobalModifier')
global with sharing class RunJob implements Queueable, Database.AllowsCallouts {
    private JobExecution__c job;

    // CONSTRUCTOR

    public RunJob(Id jobId) {
        this(new JobExecutionsSelector().byId(jobId));
    }

    public RunJob(JobExecution__c job) {
        this.job = job;
    }

    // GLOBAL

    @InvocableMethod(label='Execute Job')
    global static void execute(List<Request> requests) {
        if (requests.size() != 1) {
            throw new ApplicationException(Label.InvalidRequestError);
        }

        Request request = requests[0];

        if(request.allSteps) {
            Jobs.Execution.execute( new Jobs.ExecutionRequest(request.jobId, request.transactionId2));
        } else {
            Jobs.Execution.resume(request.jobId);
        }
    }


    // PUBLIC

    @SuppressWarnings('PMD.EmptyStatementBlock')
    public void execute(QueueableContext ctx) {
        // Note: Nothing to do
    }

    // INNER

    global class Request {
        @InvocableVariable
        global Id jobId;

        @InvocableVariable
        global Id transactionId; // @deprecated

        @InvocableVariable
        global String transactionId2;

        @InvocableVariable
        global Boolean allSteps = true;

        private JobExecution__c job;

        @SuppressWarnings('PMD.EmptyStatementBlock')
        public Request() {
        }

        public Request(JobExecution__c job, String transactionId) {
            this.job = job;
            this.transactionId2 = transactionId;
        }
    }
}