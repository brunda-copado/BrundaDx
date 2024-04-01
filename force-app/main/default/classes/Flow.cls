public inherited sharing class Flow implements Queueable, Database.AllowsCallouts {
    private Id stepId;
    private String flowName;
    private String callback;
    private List<Parameter> parameters;

    private Result__c result;

    @TestVisible
    private static Event__e mockResponse;

    // CONSTRUCTOR

    public Flow(Id stepId, String flowName) {
        this.stepId = stepId;
        this.flowName = flowName;
    }

    // PUBLIC

    public Id execute() {
        Logger.info(stepId, 'Flow.execute()', 'Flowname: ', flowName);
        createResult();

        if (Test.isRunningTest() && mockResponse != null) {
            mockResponse.Topic_Uri__c = OnJobStepComplete.STEP_ENDPOINT + result.Id;
            update new JobStep__c(Id = stepId, Result__c = result.Id);
            OnJobStepComplete.execute(new List<Event__e>{ mockResponse });
        } else {
            System.enqueueJob(this);
        }

        return result.Id;
    }

    public Flow resultCallback(String callback) {
        this.callback = callback;

        return this;
    }

    public Flow parameters(List<Parameter> parameters) {
        this.parameters = parameters;

        return this;
    }

    public void execute(QueueableContext ctx) {
        try {
            if (!parameters.isEmpty()) {
                parameters = new TemplatingEngine(stepId, parameters).parse();
            }
            Map<String, String> flowParameter = asMap(parameters);
            flowParameter.put('resultId', result.Id);

            Flow.Interview.createInterview(namespace(flowName), localName(flowName), flowParameter).start();
        } catch (Exception ex) {
            Logger.error(result.Id, 'Flow.execute(ctx)', 'Parameters: ', parameters, ex);
            handleException(ex, result);
        }
    }

    // PRIVATE

    private void handleException(Exception ex, Result__c result) {
        DML.safeUpdate(
            new Result__c(Id = result.Id, Status__c = 'Error', Error_Message__c = ex.getMessage()),
            'Could not update the result record ( Flow.handleException class )'
        );

        Event__e stepCompleted = new Event__e();
        stepCompleted.Payload__c = asPayload(false, ex.getMessage());
        stepCompleted.Topic_Uri__c = OnJobStepComplete.STEP_ENDPOINT + result.Id;
        EventBus.publish(stepCompleted);
    }

    private Map<String, String> asMap(List<Parameter> parameters) {
        Map<String, String> result = new Map<String, String>();

        for (Parameter parameter : parameters) {
            result.put(parameter.name, parameter.value);
        }

        return result;
    }

    private void createResult() {
        result = new Result__c();
        result.JobStep__c = stepId;
        result.Job_Type__c = flowName;
        result.ParentId__c = stepId;
        result.Status__c = 'In Progress';
        result.ApexCallback__c = callback;
        result.Start_Time__c = Datetime.now();
        DML.safeInsert(result, 'Could not create a Result object on the Flow process ( Flow.createResult class )');
    }

    private String asPayload(Boolean isSuccess, String message) {
        OnJobStepComplete.EventPayload result = new OnJobStepComplete.EventPayload(isSuccess, message);

        return JSON.serialize(result);
    }

    private String namespace(String name) {
        return name.contains('.') ? name.substringBefore('.') : '';
    }

    private String localName(String name) {
        return name.contains('.') ? name.substringAfter('.') : name;
    }
}