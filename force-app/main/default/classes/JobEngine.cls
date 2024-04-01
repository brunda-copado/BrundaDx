@SuppressWarnings('PMD.CyclomaticComplexity')
public with sharing class JobEngine implements CopadoQueueable {
    private static final String STEP_CALLBACK = 'StepCallback';
    private static final String TEST_STEP_CALLBACK = 'TestStepCallback';
    private static final String FUNCTION_STEP_CALLBACK = 'FunctionStepCallback';
    private static final String TRUE_VALUE = 'true';

    private JobExecution__c job;
    private List<JobStep__c> steps;

    // CONSTRUCTOR

    @SuppressWarnings('PMD.EmptyStatementBlock')
    public JobEngine() {
    }

    public JobEngine(Id jobId) {
        this.job = new JobExecutionsSelector().byId(jobId);
    }

    // PUBLIC

    @InvocableMethod(label='Start Job execution')
    public static List<Id> start(List<Id> jobIds) {
        List<Id> result = new List<Id>();

        for (Id jobId : jobIds) {
            Logger.debug(jobId, 'JobEngine.start', '', null);
            Id resultId = new JobEngine(jobId).executeNextStep();

            result.add(resultId);
        }

        return result;
    }

    // Copado Queueable

    public void execute(String jobId) {
        this.job = new JobExecutionsSelector().byId(jobId);
        DML.safeUpdate(new JobExecution__c(Id = jobId, Status__c = 'In Progress'), '');

        resume(nextStep());
    }

    public void cancel(String jobId) {
        Logger.warning(jobId, 'JobEngine.cancel', 'jobId: ', jobId);
        DML.safeUpdate(new JobExecution__c(Id = jobId, Status__c = 'Canceled'), '');
    }

    private Id resume(JobStep__c next) {
        Id resultId;

        try {
            resultId = invoke(next);
            DML.safeUpdate(
                new JobStep__c(Id = next.Id, Result__c = resultId),
                'Could not update a Job Step object on the Job Execution process ( JobExecution.executeNextStep class )'
            );
        } catch (CopadoFunctionException ex) {
            Logger.warning(next.Id, 'JobEngine.executeNextStep', '', null);
            resultId = ex.resultId;
            DML.safeUpdate(
                new JobStep__c(Id = next.Id, Result__c = resultId),
                'Could not update a Job Step object on the Job Execution process with exception ( JobExecution.executeNextStep class )'
            );

            finish('Error', ex.getMessage());
        } catch (Exception ex) {
            Logger.error(next.Id, 'JobEngine.executeNextStep', '', null, ex);
            finish('Error', ex.getMessage());
        }

        return resultId;
    }

    public Id executeNextStep() {
        JobStep__c next = nextStep();
        String sequentialResource = sequentialResource(next);

        // Note: if job is Canceled, chances are nextStep is invoked by an async process so this request will be ignored
        if (job.Status__c == 'Canceled' || (next == null && job.Status__c == 'Error')) {
            return null;
        } else if (String.isNotBlank(sequentialResource) && !isResourceAlreadyBlocked(next)) {
            DML.safeUpdate(new JobExecution__c(Id = job.Id, Status__c = 'Queued'), '');
            Queue.AddRequest request = new Queue.AddRequest();
            request.contextId = next.Id;
            request.contextName = job.Name + '-' + String.valueOf(DateTime.now().getTime());
            request.resource = sequentialResource;
            request.callback = JobEngine.class;
            request.payload = job.Id;
            request.transactionId = getTransactionId();

            Queue.add(request);
            return null;
        } else if (next == null) {
            finish('Successful');
            return null;
        }

        return resume(next);
    }

    private Boolean isResourceAlreadyBlocked(JobStep__c step) {
        List<Queue__c> existingQueue = [SELECT Id, Status__c FROM Queue__c WHERE ContextId__c = :step.Id WITH USER_MODE];

        if (!existingQueue.isEmpty() && existingQueue[0].Status__c == 'In Progress') {
            return true;
        }

        return false;
    }

    public void finish(String status, String errorMessage) {
        job.ErrorMessage__c = errorMessage;
        finish(status);
    }

    public void finish(String status) {
        Logger.info(job.Id, 'JobEngine.finish', status, null);
        job.Status__c = status;

        try {
            runCallback(job, status);
        } catch (Exception ex) {
            job.Status__c = 'Error';
            job.ErrorMessage__c = ex.getMessage();
            List<Queue__c> blockedQueues = [
                SELECT Id, Resource__c, ContextId__c
                                            FROM Queue__c
                WHERE Name LIKE :job.Name + '%' AND Status__c = 'Blocked'
                WITH USER_MODE
            ];

            // Note: This will release queue if the JE callback fails
            if(!blockedQueues.isEmpty()) {
                Set<Id> blockedContextIds = blockedContextIds(blockedQueues);
                Queue.releaseResource(blockedContextIds);
            }
        }

        DML.safeUpdate(
            new JobExecution__c(Id = job.Id, Status__c = job.Status__c, ErrorMessage__c = job.ErrorMessage__c),
            'Could not update a Job Execution object on the Job Execution process ( JobExecution.finish class )'
        );
    }

    // PRIVATE

    private Set<Id> blockedContextIds(List<Queue__c> blockedQueues) {
        Set<Id> result = new Set<Id>();

        for(Queue__c blockedQueue : blockedQueues) {
            result.add(blockedQueue.ContextId__c);
        }

        return result;
    }

    private String sequentialResource(JobStep__c step) {
        if (String.isBlank(step?.ConfigJson__c)) {
            return null;
        }

        Map<String, Object> configJson = (Map<String, Object>) JSON.deserializeUntyped(step.ConfigJson__c);

        return configJson.containsKey('sharedResource') ? (String) configJson.get('sharedResource') : null;
    }

    private List<CopadoFunctions.FunctionParameter> volumeOptions(JobStep__c step) {
        List<CopadoFunctions.FunctionParameter> result = new List<CopadoFunctions.FunctionParameter>();

        if (String.isNotBlank(job.VolumeOptions__c)) {
            result = (List<CopadoFunctions.FunctionParameter>) JSON.deserialize(job.VolumeOptions__c, List<CopadoFunctions.FunctionParameter>.class);
        }

        for(CopadoFunctions.FunctionParameter option : result) {
            if(option.name == 'transactionId') {
                String volumeId = volumeId(result);
                option.value = String.isNotBlank(volumeId) ? volumeId : option.value;
            }
        }

        if (
            isLastFunction(step) &&
            getValue(result, 'volumeEnabled') == TRUE_VALUE &&
            getValue(result, 'preserveVolumeAfterExecution') != TRUE_VALUE
        ) {
            result.add(new CopadoFunctions.FunctionParameter('killVolume', TRUE_VALUE));
        }

        return result;
    }

    private String volumeId(List<CopadoFunctions.FunctionParameter> options) {
        for(CopadoFunctions.FunctionParameter option : options) {
            if(option.name == 'volumeId') {
                return option.value;
            }
        }

        return null;
    }

    private String getValue(List<CopadoFunctions.FunctionParameter> parameters, String key) {
        String result = null;

        for (CopadoFunctions.FunctionParameter parameter : parameters) {
            if (parameter.name == key) {
                result = parameter.value;
                break;
            }
        }

        return result;
    }

    private Boolean isLastFunction(JobStep__c step) {
        Boolean result = false;

        for (Integer i = steps.size() - 1; i >= 0; i--) {
            if (steps[i].Type__c == 'Function') {
                result = (steps[i].Id == step.Id);
                break;
            }
        }

        return result;
    }

    private JobStep__c nextStep() {
        JobStep__c result;

        steps = new JobStepsSelector().byJobAndStatus(job.Id, 'Pending');

        List<JobStep__c> stepsToSkip = new List<JobStep__c>();
        Integer count = 0;

        try {
            for (JobStep__c step : steps) {
                if (isSkipped(step)) {
                    stepsToSkip.add(new JobStep__c(Id = step.Id, IsSkipped__c = true));
                } else {
                    result = step;
                    break;
                }
                count += 1;
            }
        } catch (Exception ex) {
            finish('Error', String.format(Label.Skip_Condition_Error, new List<String>{ steps[count].Name, ex.getMessage() }));
        } finally {
            if (!stepsToSkip.isEmpty()) {
                DML.safeUpdate(stepsToSkip, 'Could not update the Job Step object on the Job Execution process ( JobExecution.nextStep class )');
            }
        }

        return result;
    }

    private Boolean isSkipped(JobStep__c step) {
        if (String.isBlank(step.SkipCondition__c)) {
            return false;
        }

        Jobs.DynamicExpressionEvaluateResult response = evaluateSkipCondition(step);
        if (String.isNotBlank(response.errorMessage)) {
            throw new ApplicationException(response.errorMessage);
        }

        return String.isBlank(response.errorMessage) && isTruthy(response.value);
    }

    private Jobs.DynamicExpressionEvaluateResult evaluateSkipCondition(JobStep__c step) {
        Jobs.DynamicExpressionEvaluateRequest request = new Jobs.DynamicExpressionEvaluateRequest(step.Id, new List<String>{ step.SkipCondition__c });

        return Jobs.DynamicExpression.evaluate(request)[0];
    }

    private Boolean isTruthy(String expValue) {
        if (expValue == null || expValue.trim() == '' || expValue.equalsIgnoreCase('false') || expValue == '0' || expValue == '-0') {
            return false;
        }
        return true;
    }

    private void runCallback(JobExecution__c job, String status) {
        Logger.info(job.Id, 'JobEngine.runCallback', status, job.Callback__c);
        if (String.isNotBlank(job.Callback__c)) {
            Type callback = Type.forName(ns(job), localClass(job));

            if (callback == null) {
                throw new ApplicationException(Label.Invalid_Class + job.Callback__c);
            }

            ((JobExecutionCallback) callback.newInstance()).execute(job, status);

            Logger.trace(job.Id, 'JobEngine.runCallback complete', '', null);
        }
    }

    private Id invoke(JobStep__c step) {
        Id result;

        if (step.Type__c == 'Function') {
            result = invokeFunction(step);
        } else if (step.Type__c == 'Flow') {
            result = invokeFlow(step);
        } else if (step.Type__c == 'Manual') {
            result = invokeManual(step);
        } else if (step.Type__c == 'Test') {
            result = invokeTest(step);
        }

        return result;
    }

    private Id invokeFunction(JobStep__c step) {
        StepConfig config = config(step);

        Logger.debug(step.Id, 'JobEngine.invokeFunction', 'Parameters: ', config.parameters);

        CopadoFunctions.ExecuteRequest request = new CopadoFunctions.ExecuteRequest();
        request.contextId = step.Id;
        request.functionApiName = config.functionName;
        request.callback = FUNCTION_STEP_CALLBACK;
        request.parameters = config.parameters;
        request.options = volumeOptions(step);

        return CopadoFunctions.execute(request).result.Id;
    }

    private Id invokeTest(JobStep__c step) {
        Logger.debug(step.Id, 'JobEngine.invokeTest', 'Step: ', step);
        return new TestJobStep(step, TEST_STEP_CALLBACK, getTransactionId()).execute();
    }

    private Id invokeFlow(JobStep__c step) {
        StepConfig config = config(step);
        Logger.debug(step.Id, 'JobEngine.invokeFlow', 'Parameters: ', config.parameters);
        return new Flow(step.Id, config.flowName).parameters(getParameters(config.parameters)).resultCallback(STEP_CALLBACK).execute();
    }

    private Id invokeManual(JobStep__c step) {
        Logger.debug(step.Id, 'JobEngine.invokeManual', 'Step: ', step);
        return new ManualTaskJobStep(step, job).execute();
    }

    private List<Parameter> getParameters(List<CopadoFunctions.FunctionParameter> functionParameters) {
        List<Parameter> result = new List<Parameter>();

        if (functionParameters != null) {
            for (CopadoFunctions.FunctionParameter param : functionParameters) {
                result.add(new Parameter(param.name, param.value).sensitive(param.sensitive).required(param.required));
            }
        }

        return result;
    }

    private String ns(JobExecution__c job) {
        return job.Callback__c.contains('.') ? job.Callback__c.substringBefore('.') : '';
    }

    private String localClass(JobExecution__c job) {
        return job.Callback__c.contains('.') ? job.Callback__c.substringAfter('.') : job.Callback__c;
    }

    private StepConfig config(JobStep__c step) {
        return (StepConfig) JSON.deserialize(step.ConfigJson__c, StepConfig.class);
    }

    private String getTransactionId() {
        String result;

        if (String.isNotBlank(job.VolumeOptions__c)) {
            List<CopadoFunctions.FunctionParameter> parameters = (List<CopadoFunctions.FunctionParameter>) JSON.deserialize(
                job.VolumeOptions__c,
                List<CopadoFunctions.FunctionParameter>.class
            );
            result = getValue(parameters, 'transactionId');
        }

        return result;
    }

    // INNER

    public virtual class StepConfig {
        public String flowName;

        public String functionName;

        public List<CopadoFunctions.FunctionParameter> parameters;
    }
}