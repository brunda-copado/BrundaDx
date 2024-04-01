@SuppressWarnings('PMD.AvoidGlobalModifier')
global with sharing class CreateExecution {
    private List<Request> requests;

    // GLOBAL

	@InvocableMethod(label='Execute Job Template')
	global static List<JobExecution__c> execute(List<Request> requests) {
        return new CreateExecution(requests).execute();
	}


    // PRIVATE

    private CreateExecution(List<Request> requests) {
        this.requests = requests;
    }


    private List<JobExecution__c> execute() {
        if (requests.size() != 1) {
            throw new ApplicationException(Label.InvalidRequestError);
        }

        List<JobExecution__c> result = new List<JobExecution__c>();

        if (String.isBlank(requests[0].templateName)) {
            result.add(Jobs.Execution.create(getRequestWithoutTemplate(requests[0])).jobExecution);
        } else {
            result.add(Jobs.Execution.createFromTemplate(getRequestWithTemplate(requests[0])).jobExecution);
        }

        if (requests[0].runAfterInstantiation) {
            result[0] = Jobs.Execution.execute( new Jobs.ExecutionRequest (result[0].Id, requests[0].transactionId)).jobExecution;
        }

        return result;
    }


    private Jobs.ExecutionCreateFromTemplateRequest getRequestWithTemplate(Request request) {
        Jobs.ExecutionCreateFromTemplateRequest result = new Jobs.ExecutionCreateFromTemplateRequest();

        result.transactionId = request.transactionId;
        result.parentId = request.parentId;
        result.pipelineId = request.pipelineId;
        result.sourceId = request.sourceId;
        result.destinationId = request.destinationId;
        result.callback = request.callback;
        result.steps = asExecutionSteps(request);
        result.templateAPIName = request.templateName;
        result.dataJson = request.dataJson;
        result.parentStepId = request.jobStepId;

        return result;
    }


    private Jobs.ExecutionCreateRequest getRequestWithoutTemplate(Request request) {
        Jobs.ExecutionCreateRequest result = new Jobs.ExecutionCreateRequest();

        result.transactionId = request.transactionId;
        result.parentId = request.parentId;
        result.pipelineId = request.pipelineId;
        result.sourceId = request.sourceId;
        result.destinationId = request.destinationId;
        result.callback = request.callback;
        result.steps = asJobSteps(request);
        result.dataJson = request.dataJson;
        result.parentStepId = request.jobStepId;

        return result;
    }


    private List<Jobs.ExecutionStep> asExecutionSteps(Request request) {
        List<Jobs.ExecutionStep> result = new List<Jobs.ExecutionStep>();

        if(request.preSteps != null && !request.preSteps.isEmpty()) {
            result.add(new Jobs.ExecutionStep(request.preSteps, 'before'));
        }


        if(request.postSteps != null && !request.postSteps.isEmpty()) {
            result.add(new Jobs.ExecutionStep(request.postSteps));
        }


        if(request.additionalSteps != null && !request.additionalSteps.isEmpty()) {
            result.addAll(asExecutionSteps(request.additionalSteps));
        }

        return result;
    }


    private List<Jobs.ExecutionStep> asExecutionSteps(List<AdditionalStep> additionalSteps) {
        List<Jobs.ExecutionStep> result = new List<Jobs.ExecutionStep>();

        for(AdditionalStep additionalStep : additionalSteps) {
            if(additionalStep.preSteps != null && !additionalStep.preSteps.isEmpty()) {
                result.add( new Jobs.ExecutionStep(additionalStep.preSteps, 'before', additionalStep.state));
            }
            if(additionalStep.postSteps != null && !additionalStep.postSteps.isEmpty()) {
                result.add( new Jobs.ExecutionStep(additionalStep.postSteps, 'after', additionalStep.state));
            }
        }

        return result;
    }


    private List<JobStep__c> asJobSteps(Request request) {
        List<JobStep__c> result = new List<JobStep__c>();

        if(request.preSteps != null && !request.preSteps.isEmpty()) {
            result.addAll(request.preSteps);
        }

        if(request.additionalSteps != null && !request.additionalSteps.isEmpty()) {
            result.addAll(asJobSteps(request.additionalSteps));
        }

        if(request.postSteps != null && !request.postSteps.isEmpty()) {
            result.addAll(request.postSteps);
        }

        return result;
    }


    private List<JobStep__c> asJobSteps(List<AdditionalStep> additionalSteps) {
        List<JobStep__c> result = new List<JobStep__c>();

        for(AdditionalStep additionalStep : additionalSteps) {
            if(additionalStep.preSteps != null && !additionalStep.preSteps.isEmpty()) {
                result.addAll(additionalStep.preSteps);
            }
            if(additionalStep.postSteps != null && !additionalStep.postSteps.isEmpty()) {
                result.addAll(additionalStep.postSteps);
            }
        }

        return result;
    }


    // INNER

    global class Request {
        @InvocableVariable
        global String templateName;

        @InvocableVariable
        global String transactionId;

        @InvocableVariable
        global String parentId;

        @InvocableVariable
        global String pipelineId;

        @InvocableVariable
        global String sourceId;

        @InvocableVariable
        global String destinationId;

        @InvocableVariable
        global String callback;

        @InvocableVariable
        global String dataJson;

        @InvocableVariable
        global List<JobStep__c> preSteps;

        @InvocableVariable
        global List<JobStep__c> postSteps;

        @InvocableVariable
        global List<AdditionalStep> additionalSteps = new List<AdditionalStep>();

        @InvocableVariable
        global Boolean runAfterInstantiation = false;

        @InvocableVariable
        global String jobStepId;
    }
}