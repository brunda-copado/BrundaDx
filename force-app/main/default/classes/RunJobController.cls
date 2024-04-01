public with sharing class RunJobController {
    private static final Set<String> OUTSTANDING_STATUSES = new Set<String>{ 'Pending', 'Failed', 'Cancelled', 'Not Started' };

    @AuraEnabled(cacheable=false)
    public static void execute(Id jobId, Boolean allSteps) {
        try {
            if (allSteps) {
                Jobs.Execution.execute( new Jobs.ExecutionRequest (jobId));
            } else {
                Jobs.Execution.resume(jobId);
            }
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }
    }


    @AuraEnabled(cacheable=true)
    public static JobStep__c getNextStep(Id jobId, Boolean allSteps) {
        try {
            return nextStep(jobId, allSteps);
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }
    }

    // PRIVATE

    private static JobStep__c nextStep(Id jobId, Boolean allSteps) {
        JobStep__c result = null;

        for (JobStep__c step : new JobStepsSelector().byJob(jobId)) {
            if (allSteps || OUTSTANDING_STATUSES.contains(step.Status__c)) {
                result = step;
                break;
            }
        }

        return result;
    }
}