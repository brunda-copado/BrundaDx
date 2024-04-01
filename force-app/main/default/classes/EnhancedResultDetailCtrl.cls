@SuppressWarnings('PMD.CyclomaticComplexity')
public with sharing class EnhancedResultDetailCtrl {
    // PUBLIC

    @AuraEnabled
    public static ResultDetails getDetails(Id recordId) {
        try {
            return new ResultDetails(recordId);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage() + ' ' + e.getStackTraceString());
        }
    }

    @AuraEnabled
    public static Id getSubJobResultId(Id resultId) {
        try {
            List<Result__c> consolidatedResult = [
                SELECT Id, Test__c, Test__r.LatestJobExecution__c, JobStep__r.Type__c, JobStep__r.Sub_Job_Execution__c, JobStep__r.JobExecution__c
                FROM Result__c
                WHERE Id = :resultId
                WITH USER_MODE
            ];

            if (consolidatedResult.isEmpty()) {
                return null;
            }

            Id qualityCheckJobId = getQualityCheckJobId(consolidatedResult[0]);
            if (qualityCheckJobId != null) {
                return resultId;
            }

            if (consolidatedResult[0].Test__c == null && consolidatedResult[0].JobStep__r?.Type__c != 'Test') {
                return null;
            }

            Id subJobExecutionId = getSubJobExecutionId(consolidatedResult[0]);

            if (subJobExecutionId == null) {
                throw new AuraHandledException(Label.RECORD_NOT_FOUND);
            }

            List<JobStep__c> latestStep = [
                SELECT Result__c
                FROM JobStep__c
                WHERE JobExecution__c = :subJobExecutionId AND Result__c != NULL
                WITH USER_MODE
                ORDER BY Order__c DESC
            ];

            return latestStep.isEmpty() ? null : latestStep[0].Result__c;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage() + ' ' + e.getStackTraceString());
        }
    }

    // PRIVATE

    private static Id getSubJobExecutionId(Result__c consolidatedResult) {
        return consolidatedResult.JobStep__c != null &&
            consolidatedResult.JobStep__r.Sub_Job_Execution__c != null
            ? consolidatedResult.JobStep__r.Sub_Job_Execution__c
            : getRelevantJobExecution(consolidatedResult);
    }

    private static Id getRelevantJobExecution(Result__c consolidatedResult) {
        try {
            for (JobExecution__c job : [
                SELECT Id, DataJson__c
                FROM JobExecution__c
                WHERE ParentRecord_Id__c = :consolidatedResult.Test__c OR Id = :consolidatedResult.Test__r.LatestJobExecution__c
                WITH USER_MODE
            ]) {
                if (String.isNotEmpty(job.DataJson__c)) {
                    JobData jobDataJson = (JobData) JSON.deserialize(job.DataJson__c, JobData.class);
                    if (!jobDataJson.resultIds.isEmpty() && jobDataJson.resultIds.contains(consolidatedResult.Id)) {
                        return job.Id;
                    }
                }
            }
            return null;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage() + ' ' + e.getStackTraceString());
        }
    }

    private static String getSobjectName(Id recordId) {
        if (recordId == null) {
            return '';
        }
        return recordId.getSobjectType().getDescribe().getLocalName();
    }

    private static Id getQualityCheckJobId(Result__c consolidatedResult) {
        Id result;
        try {
            for (JobExecution__c job : [
                SELECT Id, DataJson__c
                FROM JobExecution__c
                WHERE Id = :consolidatedResult.JobStep__r.JobExecution__c
                WITH USER_MODE
            ]) {
                if (String.isNotEmpty(job.DataJson__c)) {
                    JobData jobDataJson = (JobData) JSON.deserialize(job.DataJson__c, JobData.class);
                    if (jobDataJson.qualityCheck != null) {
                        result = job.Id;
                    }
                }
            }
            return result;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage() + ' ' + e.getStackTraceString());
        }
    }

    // INNER

    public with sharing class ResultDetails {
        @AuraEnabled
        public String namespace;
        @AuraEnabled
        public Result__c resultDetails;
        @AuraEnabled
        public List<JobStep__c> subJobExecutionSteps;

        public ResultDetails(Id resultId) {
            namespace = Settings.ns;
            resultDetails = new ResultsSelector().byId(resultId);

            // NOTE - Only if the result is of a sub job execution or is a test job execution result, fetch the steps
            if (
                resultDetails?.JobStep__r?.JobExecution__r?.Job_Step__c != null ||
                (getSobjectName(resultDetails?.JobStep__r?.JobExecution__r?.ParentId__c)) == 'Test__c'
            ) {
                subJobExecutionSteps = new JobStepsSelector().byJobWithResults(new Set<String>{ resultDetails.JobStep__r.JobExecution__c });
            }
        }
    }

    private class JobData {
        List<Id> resultIds;
        Id qualityCheck;
    }
}