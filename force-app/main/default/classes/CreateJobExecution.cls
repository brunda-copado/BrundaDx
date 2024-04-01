public inherited sharing class CreateJobExecution {
    private JobTemplate__c template;
    private Jobs.ExecutionCreateFromTemplateRequest request;
    private List<Jobs.ExecutionStep> executionSteps = new List<Jobs.ExecutionStep>();

    // CONSTRUCTOR

    public CreateJobExecution(Jobs.ExecutionCreateFromTemplateRequest request, JobTemplate__c template) {
        this.request = request;
        this.template = template;
    }

    public CreateJobExecution(Jobs.ExecutionCreateFromTemplateRequest request) {
        this.request = request;
    }

    public CreateJobExecution steps(List<Jobs.ExecutionStep> value) {
        this.executionSteps = value;
        return this;
    }

    // PUBLIC

    public Jobs.ExecutionCreateResult execute() {
        try {
            JobExecution__c job = createJob();

            if (executionSteps != null) {
                Jobs.Execution.addSteps(new Jobs.AddStepsRequest(job.Id, executionSteps));
            }

            return new Jobs.ExecutionCreateResult(job);
        } catch (Exception ex) {
            throw new ApplicationException(ex.getMessage());
        }
    }

    // PRIVATE

    private JobExecution__c createJob() {
        JobExecution__c result = new JobExecution__c();

        if (String.isNotBlank(request.parentId)) {
            setParentId(result, Id.valueOf(request.parentId));
        }

        result.Template__c = template?.Id;
        result.Status__c = 'Not Started';
        result.Callback__c = request.callback;
        result.DataJson__c = request.dataJson;
        result.Pipeline__c = request.pipelineId;
        result.Source__c = request.sourceId;
        result.Job_Step__c = request.parentStepId;
        result.Destination__c = request.destinationId;
        result.VolumeOptions__c = volumeOptions();

        DML.safeInsert(result, 'Could not create a Job Execution object on the Create Execution process ( CreateJobExecution.createJob class )');

        updateTransactionId(result);

        return result;
    }

    private void updateTransactionId(JobExecution__c job) {
        List<Parameter> parameters = (List<Parameter>) JSON.deserialize(job.VolumeOptions__c, List<Parameter>.class);
        Map<String, Parameter> parametersByName = groupByName(parameters);

        if(!parametersByName.containsKey('transactionId')) {
            parameters.add(transactionParameter(job.Id));
        }

        if(!parametersByName.containsKey('volumeId')) {
            String uniqueVolumeId = job.Id + String.valueOf(DateTime.now().getTime());
            parameters.add(new Parameter('volumeId', uniqueVolumeId));
        }

        job.VolumeOptions__c = JSON.serializePretty(parameters, true);

        DML.safeUpdate(
            job,
            'Could not update a Job Execution object on the Create Execution process ( CreateJobExecution.updateVolumeOptions class )'
        );
    }

    private Map<String, Parameter> groupByName(List<Parameter> parameters) {
        Map<String, Parameter> result = new Map<String, Parameter>();

        for(Parameter parameter : parameters) {
            result.put(parameter.name, parameter);
        }
        return result;
    }

    private String volumeOptions() {
        List<Parameter> result = new List<Parameter>();

        if (String.isNotBlank(template?.VolumeOptions__c)) {
            result = (List<Parameter>) JSON.deserialize(template.VolumeOptions__c, List<Parameter>.class);
        }

        return JSON.serialize(result);
    }

    private Parameter transactionParameter(Id jobId) {
        String transactionId = (String.isNotBlank(request.transactionId))
            ? request.transactionId
            : (jobId + String.valueOf(DateTime.now().getTime()));

        return new Parameter('transactionId', transactionId);
    }

    private void setParentId(JobExecution__c job, Id parentId) {
        String objectType = (String.isNotBlank(parentId)
            ? parentId.getSObjectType().getDescribe(SObjectDescribeOptions.DEFERRED).getLocalName()
            : '');
        String parentField = parentFieldByType().containsKey(objectType) ? parentFieldByType().get(objectType) : 'ParentRecord_Id__c';

        job.put(parentField, parentId);
    }

    private Map<String, String> parentFieldByType() {
        return new Map<String, String>{
            'Deployment__c' => 'Deployment__c',
            'Promotion__c' => 'Promotion__c',
            'User_Story_Commit__c' => 'UserStoryCommit__c',
            'Git_Backup__c' => 'Snapshot__c'
        };
    }
}