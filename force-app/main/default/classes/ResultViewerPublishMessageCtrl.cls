public with sharing class ResultViewerPublishMessageCtrl {
    @AuraEnabled
    public static string getTool(Id resultId) {
        try {
            List<Result__c> results = [
                SELECT
                    Id,
                    JobStep__r.JobExecution__r.Job_Step__r.Quality_Gate_Rule_Condition__r.Extension_Configuration__r.ExtensionTool__c,
                    JobStep__r.JobExecution__c,
                    JobStep__r.JobExecution__r.DataJson__c
                FROM Result__c
                WHERE Id = :resultId
                WITH USER_MODE
            ];

            if (
                !results.isEmpty() &&
                String.isNotBlank(
                    results[0].JobStep__r?.JobExecution__r?.Job_Step__r?.Quality_Gate_Rule_Condition__r?.Extension_Configuration__r?.ExtensionTool__c
                )
            ) {
                return results[0]
                    .JobStep__r
                    ?.JobExecution__r
                    ?.Job_Step__r
                    ?.Quality_Gate_Rule_Condition__r
                    ?.Extension_Configuration__r
                    ?.ExtensionTool__c;
            } else if (!results.isEmpty() && results[0].JobStep__r?.JobExecution__c != null) {
                return testToolFor(results[0].JobStep__r?.JobExecution__c, results[0].JobStep__r?.JobExecution__r.DataJson__c);
            }
            return null;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    // PRIVATE

    private static String testToolFor(Id jobId, String jobPayload) {
        String result;
        if (String.isNotEmpty(jobPayload)) {
            JobData jobData = (JobData) JSON.deserialize(jobPayload, JobData.class);
            if (String.isNotEmpty(jobData.qualityCheck)) {
                result = testToolForQualityCheck(jobData.qualityCheck);
            }
        }

        if (String.isEmpty(result)) {
            result = testToolFor(jobId);
        }
        return result;
    }

    private static String testToolForQualityCheck(Id qualityCheckId) {
        List<Quality_Gate_Rule_Condition__c> conditions = [
            SELECT Extension_Configuration__r.ExtensionTool__c
            FROM Quality_Gate_Rule_Condition__c
            WHERE Id = :qualityCheckId
            WITH USER_MODE
        ];
        return conditions.isEmpty() ? null : conditions[0].Extension_Configuration__r?.ExtensionTool__c;
    }

    private static String testToolFor(Id jobId) {
        List<Test__c> tests = [SELECT ExtensionConfiguration__r.ExtensionTool__c FROM Test__c WHERE LatestJobExecution__c = :jobId WITH USER_MODE];
        return tests.isEmpty() ? null : tests[0].ExtensionConfiguration__r?.ExtensionTool__c;
    }

    private class JobData {
        String qualityCheck;
    }
}