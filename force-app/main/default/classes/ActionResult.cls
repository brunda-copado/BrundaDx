public with sharing class ActionResult {
    private Id jobExecutionId;

    // CONSTRUCTOR

    public ActionResult(Id jobExecutionId) {
        this.jobExecutionId = jobExecutionId;
    }

    // PUBLIC

    // Note: this assumes that the last JobStep of the JobTemplate linked to the JobExecution contains the Result with the output. This may vary according to the JobTemplate used (and therefore according to the implementation of each extension). At the moment, the requirement is to put all ouput data in the Result of the last JobStep
    public Result__c getRecord() {
        Result__c result;

        JobStep__c lastJobTemplateStep = getLastJobTemplateStep(jobExecutionId);
        if (lastJobTemplateStep != null) {
            JobStep__c jobExecutionStep = getCorrespondingJobExecutionStep(jobExecutionId, lastJobTemplateStep);
            if (jobExecutionStep != null) {
                result = new ResultsSelector().byId(jobExecutionStep.Result__c);
            }
        }
        // Note: always fallback to last step result
        if (result == null) {
            result = new ResultsSelector().byJobExecutionId(jobExecutionId);
        }

        return result;
    }

    // PRIVATE

    private JobStep__c getLastJobTemplateStep(Id jobExecutionId) {
        JobStep__c result;

        JobExecution__c jobExecution = [SELECT Template__r.ApiName__c FROM JobExecution__c WHERE Id = :jobExecutionId WITH SECURITY_ENFORCED LIMIT 1];
        String jobTemplateApiName = jobExecution.Template__r.ApiName__c;
        if (String.isNotBlank(jobTemplateApiName)) {
            List<JobStep__c> jobTemplateSteps = new JobStepsSelector().byTemplateApiName(jobTemplateApiName);
            if (!jobTemplateSteps.isEmpty()) {
                result = jobTemplateSteps[jobTemplateSteps.size() - 1];
            }
        }

        return result;
    }

    private JobStep__c getCorrespondingJobExecutionStep(Id jobExecutionId, JobStep__c lastJobTemplateStep) {
        JobStep__c result;

        for (JobStep__c jobExecutionStep : new JobStepsSelector().byJob(jobExecutionId)) {
            if (
                jobExecutionStep.Result__c != null &&
                jobExecutionStep.Name == lastJobTemplateStep.Name &&
                jobExecutionStep.Type__c == lastJobTemplateStep.Type__c
            ) {
                result = jobExecutionStep;
                break;
            }
        }

        return result;
    }
}