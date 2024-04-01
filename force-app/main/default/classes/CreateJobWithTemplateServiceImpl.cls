public inherited sharing class CreateJobWithTemplateServiceImpl {
    // PUBLIC

    public static Jobs.ExecutionCreateFromTemplateResult execute(Jobs.ExecutionCreateFromTemplateRequest request) {
        if (String.isBlank(request.templateAPIName)) {
            throw new ApplicationException(String.format(Label.MissingRequiredParameters, new List<String>{ 'Template Name' }));
        }

        List<JobTemplate__c> templates = new JobTemplatesSelector().byApiNameWithSteps(request.templateAPIName);

        if (templates.isEmpty()) {
            throw new ApplicationException(String.format(Label.InvalidTemplateId, new List<String>{ request.templateAPIName }));
        }

        // NOTE : To accomodate template steps along with the request.steps (as request.steps may contain post steps too)
        Map<String, List<Jobs.ExecutionStep>> requestStepsBySequence = new Map<String, List<Jobs.ExecutionStep>>();
        if (request.steps != null && !request.steps.isEmpty()) {
            requestStepsBySequence = getRequestStepsBySequence(request.steps);
        }

        List<Jobs.ExecutionStep> steps = asExecutionSteps(requestStepsBySequence, templates[0]?.JobSteps__r);

        JobExecution__c job = new CreateJobExecution(request, templates[0]).steps(steps).execute().jobExecution;

        return new Jobs.ExecutionCreateFromTemplateResult(job);
    }

    // PRIVATE

    private static Map<String, List<Jobs.ExecutionStep>> getRequestStepsBySequence(List<Jobs.ExecutionStep> requestSteps) {
        Map<String, List<Jobs.ExecutionStep>> result = new Map<String, List<Jobs.ExecutionStep>>();

        for (Jobs.ExecutionStep step : requestSteps) {
            // NOTE : For ExecutionStep with no defined sequence, default sequence 'after' is assigned
            step.sequence = String.isBlank(step.sequence) ? 'after' : step.sequence;

            if (result.containsKey(step.sequence.toLowerCase())) {
                result.get(step.sequence.toLowerCase()).add(step);
            } else {
                result.put(step.sequence.toLowerCase(), new List<Jobs.ExecutionStep>{ step });
            }
        }

        return result;
    }

    private static List<Jobs.ExecutionStep> asExecutionSteps(
        Map<String, List<Jobs.ExecutionStep>> requestStepsBySequence,
        List<JobStep__c> templateSteps
    ) {
        List<Jobs.ExecutionStep> result = new List<Jobs.ExecutionStep>();

        if (requestStepsBySequence.containsKey('before')) {
            result.addAll(requestStepsBySequence.get('before'));
        }

        result.add(new Jobs.ExecutionStep(templateSteps));

        if (requestStepsBySequence.containsKey('after')) {
            result.addAll(requestStepsBySequence.get('after'));
        }

        return result;
    }
}