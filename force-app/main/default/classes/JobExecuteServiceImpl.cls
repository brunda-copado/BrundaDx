public inherited sharing class JobExecuteServiceImpl {
    private JobExecution__c job;

    // PUBLIC

    public static Jobs.ExecutionResult execute(Jobs.ExecutionRequest request) {
        return new JobExecuteServiceImpl().start(request);
    }

    public Jobs.ExecutionResult start(Jobs.ExecutionRequest request) {
        if (!Utilities.checkPermission('Copado_Job_Engine', new Set<Id>{ UserInfo.getUserId() }, false)) {
            String errorMessage = String.format(Label.PermissionSet_InsufficientAccess, new List<String>{ 'Copado Job Engine' });
            new JobEngine(request.jobExecutionId).finish('Error', errorMessage);

            return new Jobs.ExecutionResult(request.jobExecutionId);
        }
        job = new JobExecutionsSelector().byIdWithSteps(request.jobExecutionId);

        if (job == null) {
            throw new ApplicationException(Label.InvalidExecutionId);
        }

        if (job.JobSteps__r.isEmpty()) {
            throw new ApplicationException(String.format(Label.JobHasNoStep, new List<String>{ 'execute' }));
        }

        if (job.Status__c == 'In Progress') {
            throw new ApplicationException(Label.JobInProgress);
        }

        clearAllSteps();

        DML.safeUpdate(
            new JobExecution__c(
                Id = job.Id,
                ErrorMessage__c = null,
                Status__c = 'In Progress',
                VolumeOptions__c = volumeOptions(request.transactionId)
            ),
            'Could not update a Job Execution object on a Job execution process ( JobExecuteServiceImpl.execute class )'
        );
        JobEngine.start(new List<Id>{ job.Id });
        return new Jobs.ExecutionResult(job.Id);
    }

    // PRIVATE

    private String volumeOptions(String transactionId) {
        String result = job.VolumeOptions__c;

        if (String.isNotBlank(job.VolumeOptions__c)) {
            List<Parameter> parameters = (List<Parameter>) JSON.deserialize(job.VolumeOptions__c, List<Parameter>.class);

            for (Parameter parameter : parameters) {
                if (parameter.name == 'transactionId' && (String.isBlank(parameter.value) || String.isNotBlank(transactionId))) {
                    parameter.value = String.isNotBlank(transactionId) ? transactionId : job.Id + String.valueOf(DateTime.now().getTime());
                }
            }

            result = JSON.serializePretty(parameters, true);
        }

        return result;
    }

    private void clearAllSteps() {
        List<JobStep__c> stepsToUpdate = new List<JobStep__c>();
        Set<Id> stepIds = new Set<Id>();

        for (JobStep__c step : job.JobSteps__r) {
            stepsToUpdate.add(new JobStep__c(Id = step.Id, Result__c = null, ResultDataJson__c = null, IsSkipped__c = false));
            stepIds.add(step.Id);
        }
        fixLimboQueues(stepIds);
        DML.safeUpdate(stepsToUpdate, 'Could not update a Job Step object on a Job execution process ( JobExecuteServiceImpl.clearAllSteps class )');
    }

    private void fixLimboQueues(Set<Id> stepIds) {
        Boolean isBlockQueueEnabled = isBlockQueueEnabled();

        Set<Id> queuesToRemove = new Set<Id>();
        Set<Id> queuesToBlock = new Set<Id>();
        Set<Id> queuesToRelease = new Set<Id>();

        for (Queue__c queue : [SELECT Id, Status__c, ContextId__c FROM Queue__c WHERE ContextId__c IN :stepIds WITH USER_MODE]) {
            if (queue.Status__c == 'In Progress' && isBlockQueueEnabled) {
                queuesToBlock.add(queue.ContextId__c);
            } else if (queue.Status__c == 'In Progress' && !isBlockQueueEnabled) {
                queuesToRelease.add(queue.ContextId__c);
            } else if (queue.Status__c == 'Queued') {
                queuesToRemove.add(queue.ContextId__c);
            }
        }

        if (!queuesToBlock.isEmpty()) {
            Queue.block(queuesToBlock);
        }

        if (!queuesToRelease.isEmpty()) {
            Queue.releaseResource(queuesToRelease);
        }

        if (!queuesToRemove.isEmpty()) {
            Queue.remove(queuesToRemove);
        }
    }

    private Boolean isBlockQueueEnabled() {
        try {
            Map<String, Object> dataJson = (Map<String, Object>) Json.deserializeUntyped(job.DataJson__c);

            return dataJson.containsKey('blockQueueForTransaction') ? (Boolean) dataJson.get('blockQueueForTransaction') : false;
        } catch (Exception ex) {
            return false;
        }
    }
}