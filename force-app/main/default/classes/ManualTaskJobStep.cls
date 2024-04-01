public with sharing class ManualTaskJobStep {
    private JobStep__c step;
    private JobExecution__c job;

    private static final String STEP_CALLBACK = 'StepCallback';
    private static final String MANUAL_TASK_NOTIFICATION_NAME = 'ManualTask_Assigned';

    // CTOR

    public ManualTaskJobStep(JobStep__c step, JobExecution__c job) {
        this.job = job;
        this.step = step;
    }

    // PUBLIC

    public Id execute() {
        Id resultId;
        Logger.trace(step.Id, 'ManualTaskJobStep.execute', '', null);

        try {
            resultId = createResult();
            sendNotification();
            Map<String, String> flowParameter = new Map<String, String>{ 'resultId' => resultId };

            Flow.Interview.Job_Engine_Orchestrator flow = new Flow.Interview.Job_Engine_Orchestrator(flowParameter);
            flow.start();
        } catch (Exception ex) {
            Logger.error(step.Id, 'ManualTaskJobStep.execute', 'Result Id: ', resultId, ex);
            throw new ApplicationException(ex.getMessage());
        }

        return resultId;
    }

    // PRIVATE

    private Id createResult() {
        Result__c result = new Result__c();
        result.Status__c = 'In Progress';
        result.JobStep__c = step.Id;
        result.Job_Type__c = step.Type__c;
        result.ParentId__c = job.ParentId__c;
        result.Start_Time__c = Datetime.now();
        result.ApexCallback__c = STEP_CALLBACK;

        DML.safeInsert(result, 'Error creating Result for Manual Task Job Step (ManualTaskJobStep.createResult())');

        return result.Id;
    }

    private void sendNotification() {
        Logger.warning(step.Id, 'ManualTaskJobStep.sendNotification', 'Step ConfigJson: ', step.ConfigJson__c);

        Map<String, CopadoFunctions.FunctionParameter> parameters = stepParameters();
        Id assigneeId = parameters.get('assigneeId')?.value;

        if (assigneeId != null) {
            Map<String, String> mergeJson = new Map<String, String>{
                'ManualTaskName' => step.Name,
                'JobExecutionName' => job.Name,
                'ManualTaskLink' => getExternalLink(step.Id),
                'JobExecutionLink' => getExternalLink(job.Id),
                'UserName' => parameters.get('assigneeName')?.value
            };

            CopadoNotifications.SendRequest request = new CopadoNotifications.SendRequest(
                MANUAL_TASK_NOTIFICATION_NAME,
                new Set<Id>{ assigneeId },
                mergeJson
            );
            CopadoNotifications.send(request);
        }
    }

    private String getExternalLink(Id recordId) {
        return URL.getSalesforceBaseUrl().toExternalForm() + '/' + recordId;
    }

    private Map<String, CopadoFunctions.FunctionParameter> stepParameters() {
        Map<String, CopadoFunctions.FunctionParameter> result = new Map<String, CopadoFunctions.FunctionParameter>();

        if (String.isNotBlank(step.ConfigJson__c)) {
            JobEngine.StepConfig config = (JobEngine.StepConfig) JSON.deserialize(step.ConfigJson__c, JobEngine.StepConfig.class);

            for (CopadoFunctions.FunctionParameter param : config.parameters) {
                result.put(param.name, param);
            }
        }

        return result;
    }
}