public with sharing class QualityChecksMonitorCtrl {
    @AuraEnabled
    public static QualityChecksData getAfterQualityGateJobs(String recordId, String jobExecutionId) {
        QualityChecksData result = new QualityChecksData();
        List<JobExecution__c> jobExecutions = getJobExecutions(recordId, jobExecutionId);
        Map<String, List<Result__History>> historyByResult = getResultHistory(jobExecutions);
        for (JobExecution__c jobExecution : jobExecutions) {
            List<HistoricalMessage> messages = new List<HistoricalMessage>();
            for (JobStep__c jobStep : jobExecution.JobSteps__r) {
                String resultId = jobStep.Result__c;
                if (historyByResult.containsKey(resultId)) {
                    for (Result__History resultHistory : historyByResult.get(resultId)) {
                        HistoricalMessage message = new HistoricalMessage();
                        message.id = resultHistory.Id;
                        message.createdDate = resultHistory.CreatedDate;
                        message.message = jobStep.Name + ' - ' + String.valueOf(resultHistory.NewValue);
                        messages.add(message);
                    }
                } else {
                    HistoricalMessage message = new HistoricalMessage();
                    message.id = jobStep.Id;
                    message.createdDate = jobStep.LastModifiedDate;
                    message.message = jobStep.Name + ' - ' + jobStep.Status__c;
                    messages.add(message);
                }
            }
            JobExecutionDetails details = new JobExecutionDetails();
            details.recordDetail = jobExecution;
            details.historicalMessages = messages;
            result.jobExecutions.add(details);
        }
        return result;
    }

    // PRIVATE

    private static List<JobExecution__c> getJobExecutions(String recordId, String jobExecutionId) {
        List<JobExecution__c> jobExecutions = [
            SELECT
                ErrorMessage__c,
                DataJson__c,
                CreatedDate,
                LastModifiedDate,
                Name,
                Status__c,
                Template__c,
                Template__r.Name,
                (SELECT Name, Status__c, Result__c, LastModifiedDate FROM JobSteps__r ORDER BY JobExecution__r.CreatedDate, Order__c ASC)
            FROM JobExecution__c
            WHERE UserStoryCommit__c = :recordId OR Promotion__c = :recordId OR Deployment__c = :recordId OR ParentId__c = :recordId
            WITH USER_MODE
        ];
        for (Integer i = (jobExecutions.size() - 1); i >= 0; i--) {
            JobExecution__c jobExecution = jobExecutions[i];
            if (String.isNotBlank(jobExecution.DataJson__c)) {
                JobExecutionData data = (JobExecutionData) JSON.deserialize(jobExecution.DataJson__c, JobExecutionData.class);
                if (data.parentJobExecutionId == jobExecutionId) {
                    continue;
                }
            }
            jobExecutions.remove(i);
        }
        return jobExecutions;
    }

    private static Map<String, List<Result__History>> getResultHistory(List<JobExecution__c> jobExecutions) {
        Set<Id> resultIds = new Set<Id>();
        for (JobExecution__c jobExecution : jobExecutions) {
            for (JobStep__c jobStep : jobExecution.JobSteps__r) {
                resultIds.add(jobStep.Result__c);
            }
        }
        Map<String, List<Result__History>> historyByResult = getResultHistoryTrackings(resultIds);
        return historyByResult;
    }

    private static Map<String, List<Result__History>> getResultHistoryTrackings(Set<Id> resultIds) {
        Map<String, List<Result__History>> historyByResult = new Map<String, List<Result__History>>();
        if (Test.isRunningTest()) {
            for (Id resultId : resultIds) {
                if (!historyByResult.containsKey(resultId)) {
                    historyByResult.put(resultId, new List<Result__History>());
                }
                historyByResult.get(resultId).add(new Result__History(ParentId = resultId, Field = Settings.ns + 'Progress_Status__c'));
            }
        } else {
            for (Result__History history : getResultHistory(resultIds)) {
                String resultId = history.ParentId;
                if (!historyByResult.containsKey(resultId)) {
                    historyByResult.put(resultId, new List<Result__History>());
                }
                historyByResult.get(resultId).add(history);
            }
        }
        return historyByResult;
    }

    private static List<Result__History> getResultHistory(Set<Id> resultIds) {
        List<Result__History> result = new List<Result__History>();
        for (Result__History history : [
            SELECT Id, ParentId, CreatedDate, NewValue
            FROM Result__History
            WHERE ParentId IN :resultIds
            WITH USER_MODE
            ORDER BY CreatedDate
        ]) {
            if (String.isNotBlank(String.valueOf(history.NewValue))) {
                result.add(history);
            }
        }
        return result;
    }

    @TestVisible
    private with sharing class JobExecutionData {
        public String parentJobExecutionId;
    }

    public with sharing class QualityChecksData {
        @AuraEnabled
        public List<JobExecutionDetails> jobExecutions = new List<JobExecutionDetails>();
    }

    public with sharing class JobExecutionDetails {
        @AuraEnabled
        public JobExecution__c recordDetail;
        @AuraEnabled
        public List<HistoricalMessage> historicalMessages;
    }

    public with sharing class HistoricalMessage {
        @AuraEnabled
        public String id;
        @AuraEnabled
        public Datetime createdDate;
        @AuraEnabled
        public String message;
    }
}