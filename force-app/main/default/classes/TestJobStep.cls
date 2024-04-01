public with sharing class TestJobStep implements Queueable, Database.AllowsCallouts {
    private JobStep__c step;
    private String callback;
    private String transactionId;

    private Result__c result;

    @TestVisible
    private static String mockResponseStatus;

    // CONSTRUCTOR

    public TestJobStep(JobStep__c step, String callback, String transactionId) {
        this.step = step;
        this.callback = callback;
        this.transactionId = transactionId;
    }

    // PUBLIC

    public Id execute() {
        result = result();
        DML.safeInsert(result, 'Could not create a Result object on the Test Job Step process ( TestJobStep.execute class )');

        if (Test.isRunningTest()) {
            mockCompletion(result);
        } else {
            System.enqueueJob(this);
        }

        return result.Id;
    }

    public void execute(QueueableContext ctx) {
        try {
            List<RunTestsAction.Request> requests = requests(result);
            List<RunTestsAction.Response> responses = RunTestsAction.execute(requests);
            if (!responses.isEmpty()) {
                DML.safeUpdate(
                    new JobStep__c(Id = result.JobStep__c, Sub_Job_Execution__c = responses[0].jobExecution.Id),
                    'Could not update a Job Step object on the Test Job Step process ( TestJobStep.execute class )'
                );
            }
        } catch (Exception ex) {
            handleException(ex, result);
        }
    }

    // PRIVATE

    private void mockCompletion(Result__c result) {
        completeStep(result, mockResponseStatus, null);
    }

    private void handleException(Exception ex, Result__c result) {
        completeStep(result, 'Error', ex.getMessage());
    }

    private void completeStep(Result__c result, String status, String errorMessage) {
        Result__c updatedResult = new Result__c(Id = result.Id, Status__c = status, Error_Message__c = errorMessage);
        DML.safeUpdate(updatedResult, 'Could not update the Result object on the TestJobStep ( TestJobStep.completeStep class )');
        new TestStepCallback().execute(result.Id, status);
    }

    private List<RunTestsAction.Request> requests(Result__c result) {
        RunTestsAction.Request request = new RunTestsAction.Request();
        ConfigJson config = (ConfigJson) JSON.deserialize(step.ConfigJson__c, ConfigJson.class);

        request.tool = config.type; // TODO: Change "type" attribute to "tool"
        request.resultId = result.Id;
        request.actionCallback = callback;
        request.contextIds = config.contextIds == null ? new List<Id>() : config.contextIds;
        request.environmentId = config.environmentId;
        request.propertiesOverride = config.propertiesOverride;
        request.transactionId = transactionId;
        setExtensionConfigAndAcceptanceCriteria(request, result.JobStep__c);

        return new List<RunTestsAction.Request>{ request };
    }

    private void setExtensionConfigAndAcceptanceCriteria(RunTestsAction.Request request, Id jobStepId) {
        for (JobStep__c jobStep : new JobStepsSelector().byIdWithExtensionConfiguration(jobStepId)) {
            request.extensionConfigurationId = jobStep.Quality_Gate_Rule_Condition__r.Extension_Configuration__c;
            request.acceptanceCriteria = jobStep.Quality_Gate_Rule_Condition__r.AcceptanceCriteria__c;
        }
    }

    private Result__c result() {
        Result__c result = new Result__c();
        result.JobStep__c = step.Id;
        result.Job_Type__c = 'Test';
        result.ParentId__c = step.Id;
        result.Status__c = 'In Progress';
        result.ApexCallback__c = callback;
        result.Start_Time__c = Datetime.now();

        return result;
    }

    // INNER

    public class ConfigJson {
        public String type;
        public Id environmentId;
        public List<Id> contextIds;

        // Note: this is additional test specific configuration(TBD)
        public String propertiesOverride;
    }
}