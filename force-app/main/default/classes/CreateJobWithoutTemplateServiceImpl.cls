public inherited sharing class CreateJobWithoutTemplateServiceImpl {
    // PUBLIC

    public static Jobs.ExecutionCreateResult execute(Jobs.ExecutionCreateRequest request) {
        Jobs.ExecutionCreateFromTemplateRequest createFromTemplateRequest = asRequest(request);
        return new CreateJobExecution(createFromTemplateRequest).steps(createFromTemplateRequest.steps).execute();
    }

    // PRIVATE

    private static Jobs.ExecutionCreateFromTemplateRequest asRequest(Jobs.ExecutionCreateRequest request) {
        Jobs.ExecutionCreateFromTemplateRequest result = new Jobs.ExecutionCreateFromTemplateRequest();
        result.callback = request.callback;
        result.dataJson = request.dataJson;
        result.destinationId = request.destinationId;
        result.parentId = request.parentId;
        result.pipelineId = request.pipelineId;
        result.sourceId = request.sourceId;
        result.transactionId = request.transactionId;
        result.parentStepId = request.parentStepId;

        // NOTE : JobSteps (without template) converted to Execution Step (with template) with sequence = after
        if (request.steps != null && !request.steps.isEmpty()) {
            result.steps = new List<Jobs.ExecutionStep>{ new Jobs.ExecutionStep(request.steps) };
        }

        return result;
    }
}