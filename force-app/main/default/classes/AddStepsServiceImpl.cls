public inherited sharing class AddStepsServiceImpl {
    private JobExecution__c job;
    private List<Jobs.ExecutionStep> steps;
    private static final String BEFORE = 'before';

    // CONSTRUCTOR

    public AddStepsServiceImpl(Jobs.AddStepsRequest request) {
        this.steps = request.steps;
        this.job = new JobExecutionsSelector().byIdWithSteps(request.jobExecutionId);
    }

    // PUBLIC STATIC

    public static Jobs.AddStepsResult execute(Jobs.AddStepsRequest request) {
        if (String.isBlank(request.jobExecutionId) || request.steps == null || request.steps.isEmpty()) {
            throw new ApplicationException(
                String.format(Label.MissingRequiredParameters, new List<Object>{ String.join(new List<String>{ 'Job Execution Id', 'Steps' }, ', ') })
            );
        }

        return new AddStepsServiceImpl(request).execute();
    }

    // PUBLIC

    public Jobs.AddStepsResult execute() {
        List<JobStep__c> jobSteps = addSteps();

        return new Jobs.AddStepsResult(updateOrder(jobSteps));
    }

    // PRIVATE

    private JobExecution__c updateOrder(List<JobStep__c> jobSteps) {
        List<JobStep__c> result = new List<JobStep__c>();

        for (Integer i = 0; i < jobSteps.size(); i++) {
            result.add(asJobStep(jobSteps[i], i + 1));
        }

        DML.safeUpsert(
            result,
            String.format(
                Label.ErrorWhileInserting,
                new List<String>{ JobStep__c.SObjectType.getDescribe().getLabel(), 'AddStepsServiceImpl.updateOrder' }
            )
        );

        return job;
    }

    private JobStep__c asJobStep(JobStep__c step, Integer order) {
        JobStep__c jobStep = new JobStep__c(
            Id = step.Id,
            Name = step.Name,
            Type__c = step.Type__c,
            Order__c = order,
            Result__c = step.Result__c,
            ApiName__c = step.ApiName__c,
            UserStory__c = step.UserStory__c,
            ConfigJson__c = step.ConfigJson__c,
            CustomType__c = step.CustomType__c,
            JobTemplate__c = step?.JobTemplate__c,
            JobExecution__c = step.JobExecution__c,
            ResultDataJson__c = step.ResultDataJson__c,
            ExecutionSequence__c = step.ExecutionSequence__c,
            Git_RepositoryId__c = step?.Git_RepositoryId__c,
            Resource_Observations__c = step?.Resource_Observations__c,
            Sub_Job_Execution__c = step?.Sub_Job_Execution__c,
            Result_Viewer_Component__c = step?.Result_Viewer_Component__c,
            SkipCondition__c = step?.SkipCondition__c,
            PipelineId__c = step.PipelineId__c
        );

        if (step.Type__c == 'Test') {
            jobStep.Quality_Gate_Rule__c = step.Quality_Gate_Rule__c;
            jobStep.Quality_Gate_Rule_Condition__c = step.Quality_Gate_Rule_Condition__c;
        }

        return jobStep;
    }

    private List<JobStep__c> addSteps() {
        List<JobStep__c> result = new List<JobStep__c>();
        Map<String, AdditionalStep> stepsByState = getStepsByState();

        if (stepsByState.containsKey(null)) {
            result.addAll(asClonedSteps(stepsByState.get(null).preSteps));
            result.addAll(job.JobSteps__r);
            result.addAll(asClonedSteps(stepsByState.get(null).postSteps));
        }

        for (JobStep__c step : result) {
            if (String.isNotBlank(step.Resource_Observations__c) && stepsByState.containsKey(step.Resource_Observations__c)) {
                AdditionalStep aStep = stepsByState.get(step.Resource_Observations__c);

                Integer index = result.indexOf(step);
                result = addBefore(result, aStep.preSteps, index);
                result = addAfter(result, aStep.postSteps, index);
            }
        }

        return result;
    }

    private List<JobStep__c> addBefore(List<JobStep__c> mainArray, List<JobStep__c> subArray, Integer index) {
        List<JobStep__c> result = new List<JobStep__c>();

        for (Integer i = 0; i < index; i++) {
            result.add(mainArray[i]);
        }
        result.addAll(asClonedSteps(subArray));
        for (Integer i = index; i < mainArray.size(); i++) {
            result.add(mainArray[i]);
        }

        return result;
    }

    private List<JobStep__c> addAfter(List<JobStep__c> mainArray, List<JobStep__c> subArray, Integer index) {
        List<JobStep__c> result = new List<JobStep__c>();

        for (Integer i = 0; i <= index; i++) {
            result.add(mainArray[i]);
        }
        result.addAll(asClonedSteps(subArray));
        for (Integer i = index + 1; i < mainArray.size(); i++) {
            result.add(mainArray[i]);
        }

        return result;
    }

    private List<JobStep__c> asClonedSteps(List<JobStep__c> stepsToClone) {
        List<JobStep__c> result = new List<JobStep__c>();

        for (JobStep__c stepToClone : stepsToClone) {
            JobStep__c step = stepToClone.clone(false, true, false, false);

            step.JobTemplate__c = null;
            step.UserStory__c = null;
            step.JobExecution__c = job.Id;
            step.PipelineId__c = job.Pipeline__c;
            step.Git_RepositoryId__c = job.Pipeline__r?.Git_Repository__c;

            result.add(step);
        }

        return result;
    }

    private Map<String, AdditionalStep> getStepsByState() {
        List<AdditionalStep> stepsToAdd = new List<AdditionalStep>();

        if (steps != null) {
            for (Jobs.ExecutionStep execStep : steps) {
                // Note: We will treat blank '' resource observation as null
                String state = String.isNotBlank(execStep.resourceObservation) ? execStep.resourceObservation : null;

                // Note: if sequence is not defined, it will be considered as 'After' and will be added as post step.
                List<JobStep__c> preSteps = execStep.sequence?.toLowerCase() == BEFORE ? execStep.steps : new List<JobStep__c>();
                List<JobStep__c> postSteps = execStep.sequence?.toLowerCase() != BEFORE ? execStep.steps : new List<JobStep__c>();
                AdditionalStep stepToAdd = new AdditionalStep(state, preSteps, postSteps);

                stepsToAdd.add(stepToAdd);
            }
        }

        return asMap(stepsToAdd);
    }

    private Map<String, AdditionalStep> asMap(List<AdditionalStep> stepsToAdd) {
        Map<String, AdditionalStep> result = new Map<String, AdditionalStep>();

        for (AdditionalStep stepToAdd : stepsToAdd) {
            AdditionalStep existingStep = result.containsKey(stepToAdd.state) ? result.get(stepToAdd.state) : new AdditionalStep(stepToAdd.state);

            if (stepToAdd.preSteps != null) {
                existingStep.preSteps.addAll(stepToAdd.preSteps);
            }

            if (stepToAdd.postSteps != null) {
                existingStep.postSteps.addAll(stepToAdd.postSteps);
            }

            result.put(stepToAdd.state, existingStep);
        }

        return result;
    }
}