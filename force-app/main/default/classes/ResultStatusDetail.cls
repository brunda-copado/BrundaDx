@SuppressWarnings('PMD.ExcessivePublicCount,PMD.CognitiveComplexity,PMD.CyclomaticComplexity,PMD.StdCyclomaticComplexity')
public with sharing class ResultStatusDetail {
    private Id recordId;
    private Id queuedStepId;
    private String fieldApiName;
    private String objectApiName;
    private JobExecution__c jobExecution;
    private List<JobStep__c> jobSteps;

    private Set<Id> resultIds;
    private Map<Id, DateTime> resultCreatedDatesByResultIds;
    private Map<Id, String> resultDataJSONByStepIds;
    private Map<Id, List<HistoricalMessage>> historyDetailsByResultId = new Map<Id, List<HistoricalMessage>>();

    private static final String FLOW = 'Flow';
    private static final String MANUAL = 'Manual';
    private static final String QUEUED = 'Queued';
    private static final String PENDING = 'Pending';
    private static final String NOT_STARTED = 'Not Started';
    private static final String IN_PROGRESS = 'In Progress';
    private static final String SKIPPED = 'Skipped';

    @AuraEnabled
    public String mainTitle { get; set; }
    @AuraEnabled
    public String jobExecutionId { get; set; }
    @AuraEnabled
    public String jobTemplateId { get; set; }
    @AuraEnabled
    public String jobExecutionStatus { get; set; }
    @AuraEnabled
    public String jobExecutionErrorMessage { get; set; }
    @AuraEnabled
    public Datetime lastModifiedDate { get; set; }
    @AuraEnabled
    public List<ResultDetail> resultDetails { get; set; }
    @AuraEnabled
    public QueueStatus queueStatus { get; set; }

    public ResultStatusDetail(Id recordId, String objectApiName, String fieldApiName) {
        this.recordId = recordId;
        this.objectApiName = objectApiName;
        this.fieldApiName = fieldApiName;
    }

    public ResultStatusDetail getData() {
        Boolean allParamatersEmpty = recordId == null && String.isBlank(objectApiName) && String.isBlank(fieldApiName);

        if (!allParamatersEmpty) {
            objectApiName = getObjectApiName();
            fieldApiName = String.isNotBlank(fieldApiName) ? fieldApiName : 'Id';
            jobExecution = jobExecution();
            jobsteps = selectJobStepsByExecutionId(new Set<Id>{ jobExecution?.Id });

            setExecutionDetails();
        }

        return this;
    }

    // PRIVATE

    private JobExecution__c jobExecution() {
        JobExecution__c result = null;

        String securedRecordId = String.escapeSingleQuotes(recordId);

        if (fieldApiName == 'Id') {
            result = new JobExecutionsSelector().byId(securedRecordId);
        } else {
            String query = String.format('SELECT {0} FROM {1} WHERE Id = :securedRecordId', new List<String>{ fieldApiName, objectApiName });
            List<SObject> executions = Database.query(query);
            Id jobExecutionId = !executions.isEmpty() ? (Id) executions[0].get(fieldApiName) : null;

            if (jobExecutionId != null) {
                result = new JobExecutionsSelector().byId(jobExecutionId);
            }
        }

        return result;
    }

    private String getObjectApiName() {
        return recordId != null
            ? recordId.getSObjectType().getDescribe().getName()
            : String.isNotBlank(objectApiName) ? ((SObject) Type.forName(objectApiName).newInstance()).getSObjectType().getDescribe().getName() : '';
    }

    private void setExecutionDetails() {
        Set<Id> jobStepIds = new Map<Id, SOBject>(jobsteps).keySet();

        jobExecutionId = jobExecution?.Id;
        jobTemplateId = jobExecution?.Template__c;
        queueStatus = new QueueStatus().getData(jobStepIds);
        queuedStepId = queueStatus?.currentJob?.contextId;
        mainTitle = jobExecution != null ? String.isNotBlank(jobExecution?.Template__c) ? jobExecution?.Template__r?.Name : jobExecution.Name : null;

        jobExecutionStatus = jobExecution != null ? jobExecution.Status__c : NOT_STARTED;
        jobExecutionErrorMessage = jobExecution != null ? jobExecution.ErrorMessage__c : '';

        lastModifiedDate = jobExecution?.LastModifiedDate;
        resultDetails = populateResultDetails(jobsteps);
    }

    private List<ResultStatusDetail.ResultDetail> populateResultDetails(List<JobStep__c> steps) {
        resultDetails = new List<ResultStatusDetail.ResultDetail>();

        resultCreatedDatesByResultIds = new Map<Id, DateTime>();
        resultDataJSONByStepIds = new Map<Id, String>();
        resultIds = new Set<Id>();
        Set<Id> subJobIds = new Set<Id>();
        Boolean firstNotStartedStepFound = false;

        for (JobStep__c jobStep : steps) {
            ResultStatusDetail.ResultDetail detail = new ResultStatusDetail.ResultDetail();
            detail.jobStepId = jobStep.Id;
            detail.jobStepLabel = jobStep.Name;
            detail.jobStepType = jobStep.Type__c;
            detail.jobStepCustomType = jobStep.CustomType__c;
            detail.resultId = getRelevantResult(jobStep);
            detail.resultStatus = jobStep.Result__c != null ? jobStep.Result__r.Status__c : jobStep.Status__c == SKIPPED ? SKIPPED : NOT_STARTED;
            detail.resultValue = jobStep.Result__c != null ? jobStep.Result__r.Name : '';
            detail.resultLabel = Label.Result;
            detail.liveMessage = getLiveMessage(jobStep);
            detail.isQueued = jobStep.Id == queuedStepId;
            resultDetails.add(detail);

            if (detail.resultId != null && jobStep.Sub_Job_Execution__c == null) {
                resultIds.add(detail.resultId);
            }

            if (jobStep.Type__c == FLOW || jobStep.Type__c == MANUAL) {
                resultCreatedDatesByResultIds.put(jobStep.Result__c, jobStep.Result__r.CreatedDate);
                resultDataJSONByStepIds.put(jobStep.Id, jobStep.ResultDataJson__c);
            } else if (jobStep.Sub_Job_Execution__c != null) {
                subJobIds.add(jobStep.Sub_Job_Execution__c);
            }

            firstNotStartedStepFound = jobStep.Result__c == null;
        }

        if (!subJobIds.isEmpty()) {
            resultHistoriesForSubJobExecution(subJobIds);
        }
        resultHistories();
        populateHistoricalMessages();

        return resultDetails;
    }

    private Id getRelevantResult(JobStep__c jobStep) {
        if(jobStep.Sub_Job_Execution__c != null) {
            Id subJobResultId = getLastResultIdPerJob(new Set<Id>{ jobStep.Sub_Job_Execution__c }).get(jobStep.Sub_Job_Execution__c);

            return subJobResultId != null ? subJobResultId : jobStep.Result__c;
        }

        return jobStep.Result__c;
    }

    private Map<Id, Id> getLastResultIdPerJob(Set<Id> subJobIds) {
        Map<Id, Id> result = new Map<Id, Id>();

        List<JobStep__c> steps = [
            SELECT Id, Result__c, JobExecution__c
            FROM JobStep__c
            WHERE JobExecution__c != NULL AND JobExecution__c IN :subJobIds
            WITH USER_MODE
            ORDER BY Order__c DESC
        ];

        for (JobStep__c jobStep : steps) {
            if (jobStep.Result__c != null && !result.containsKey(jobStep.JobExecution__c)) {
                result.put(jobStep.JobExecution__c, jobStep.Result__c);
            }
        }

        return result;
    }

    private List<ResultStatusDetail.HistoricalMessage> returnHistoricalMessagesPerStepTypes(ResultStatusDetail.ResultDetail resultDetail) {
        if (resultDetail.jobStepType == FLOW || resultDetail.jobStepType == MANUAL) {
            ResultStatusDetail.HistoricalMessage newHistory = new ResultStatusDetail.HistoricalMessage();
            newHistory.createdDate = String.valueOf(resultCreatedDatesByResultIds.get(resultDetail.resultId));
            newHistory.message = resultDetail.jobStepType == MANUAL ? resultDataJSONByStepIds.get(resultDetail.jobStepId) : '';
            return new List<ResultStatusDetail.HistoricalMessage>{ newHistory };
        }

        return historyDetailsByResultId.get(resultDetail.resultId);
    }

    private void populateHistoricalMessages() {
        for (ResultStatusDetail.ResultDetail resultDetail : resultDetails) {
            resultDetail.historicalMessages = returnHistoricalMessagesPerStepTypes(resultDetail);
        }
    }

    private void resultHistories() {
        for (Result__History resultHistory : resultHistoryTrackings(resultIds)) {
            if (resultHistory.NewValue != null || Test.isRunningTest()) {
                ResultStatusDetail.HistoricalMessage newHistory = new ResultStatusDetail.HistoricalMessage();
                newHistory.createdDate = String.valueOf(resultHistory.CreatedDate);
                newHistory.message = String.valueOf(resultHistory.NewValue);
                if (historyDetailsByResultId.containsKey(resultHistory.ParentId)) {
                    historyDetailsByResultId.get(resultHistory.ParentId).add(newHistory);
                } else {
                    historyDetailsByResultId.put(resultHistory.ParentId, new List<ResultStatusDetail.HistoricalMessage>{ newHistory });
                }
            }
        }
    }

    private void resultHistoriesForSubJobExecution(Set<Id> subJobIds) {
        Map<Id, JobStep__c> jobStepByResultId = new Map<Id, JobStep__c>();

        for (JobStep__c jobStep : selectJobStepsByExecutionId(subJobIds)) {
            jobStepByResultId.put(jobStep.Result__c, jobStep);
        }

        Map<Id, Id> lastResultPerSubJob = getLastResultIdPerJob(subJobIds);

        for (Result__History resultHistory : resultHistoryTrackings(jobStepByResultId.keySet())) {
            ResultStatusDetail.HistoricalMessage newHistory = new ResultStatusDetail.HistoricalMessage();
            newHistory.createdDate = String.valueOf(resultHistory.CreatedDate);

            if (jobStepByResultId.get(resultHistory.ParentId).Type__c == FLOW || jobStepByResultId.get(resultHistory.ParentId).Type__c == MANUAL) {
                newHistory.message =
                    jobStepByResultId.get(resultHistory.ParentId).Name +
                    ' - ' +
                    jobStepByResultId.get(resultHistory.ParentId)?.Result__r?.Status__c;
            } else if (resultHistory.NewValue != null) {
                newHistory.message = jobStepByResultId.get(resultHistory.ParentId).Name + ' - ' + String.valueOf(resultHistory.NewValue);
            } else if (resultHistory.NewValue == null) {
                // NOTE : For records with null NewValue
                continue;
            }

            Id lastResultId = lastResultPerSubJob.get(jobStepByResultId.get(resultHistory.ParentId)?.JobExecution__c);
            if (historyDetailsByResultId.containsKey(lastResultId)) {
                historyDetailsByResultId.get(lastResultId).add(newHistory);
            } else {
                historyDetailsByResultId.put(lastResultId, new List<ResultStatusDetail.HistoricalMessage>{ newHistory });
            }
        }
    }

    private String getLiveMessage(JobStep__c step) {
        String result;

        if (step.Status__c == SKIPPED) {
            result = SKIPPED;
        } else if (step.Result__c == null && queuedStepId == step.Id) {
            result = QUEUED;
        } else if (step.Result__c == null) {
            result = NOT_STARTED;
        } else if (step.Type__c == FLOW) {
            result = step.Status__c;
        } else if (step.Type__c == MANUAL) {
            result = step.Status__c == IN_PROGRESS ? PENDING : step.Status__c;
        } else if (step.Status__c == IN_PROGRESS) {
            result = String.isNotBlank(step.Result__r.Progress_Status__c) ? step.Result__r.Progress_Status__c : IN_PROGRESS;
        } else {
            result = step.Status__c;
        }

        return result;
    }

    private List<JobStep__c> selectJobStepsByExecutionId(Set<Id> jobExecutionIds) {
        return [
            SELECT
                Id,
                Name,
                Type__c,
                Status__c,
                Result__c,
                CustomType__c,
                Result__r.Name,
                ResultDataJson__c,
                Result__r.CreatedDate,
                Result__r.Status__c,
                Result__r.Result_Data__c,
                Result__r.Progress_Status__c,
                JobExecution__r.Template__r.Name,
                JobExecution__c,
                Sub_Job_Execution__c,
                JobExecution__r.Job_Step__r.Result__c
            FROM JobStep__c
            WHERE JobExecution__c != NULL AND JobExecution__c IN :jobExecutionIds
            WITH SECURITY_ENFORCED
            ORDER BY JobExecution__r.CreatedDate, Order__c
        ];
    }

    private List<Result__History> resultHistoryTrackings(Set<Id> resultIds) {
        if (Test.isRunningTest()) {
            List<Result__History> histories = new List<Result__History>{}; //OldValue, NewValue not writeable
            for (Id resultId : resultIds) {
                histories.add(new Result__History(ParentId = resultId, Field = Settings.ns + 'Progress_Status__c'));
            }
            return histories;
        } else {
            return [
                SELECT Id, ParentId, CreatedDate, NewValue
                FROM Result__History
                WHERE ParentId IN :resultIds
                WITH SECURITY_ENFORCED
                ORDER BY CreatedDate
            ];
        }
    }

    // INNER

    public class ResultDetail {
        @AuraEnabled
        public Id jobStepId { get; set; }
        @AuraEnabled
        public String jobStepLabel { get; set; }
        @AuraEnabled
        public String jobStepType { get; set; }
        @AuraEnabled
        public String jobStepCustomType { get; set; }
        @AuraEnabled
        public Id resultId { get; set; }
        @AuraEnabled
        public String resultStatus { get; set; }
        @AuraEnabled
        public String resultValue { get; set; }
        @AuraEnabled
        public String resultLabel { get; set; }
        @AuraEnabled
        public List<HistoricalMessage> historicalMessages { get; set; }
        @AuraEnabled
        public String liveMessage { get; set; }
        @AuraEnabled
        public Boolean isQueued { get; set; }
    }

    public class HistoricalMessage {
        @AuraEnabled
        public String id { get; set; }
        @AuraEnabled
        public String createdDate { get; set; }
        @AuraEnabled
        public String message { get; set; }
    }

    public with sharing class QueueStatus {
        @AuraEnabled
        public QueuedJob currentJob;
        @AuraEnabled
        public List<QueuedJob> allQueuedJob;

        public QueueStatus getData(Id recordId) {
            return getData(new Set<Id>{ recordId });
        }

        public QueueStatus getData(Set<Id> recordIds) {
            if (recordIds == null) {
                return this;
            }

            List<Queue__c> currentQueue = [
                SELECT Id, Name, Status__c, Resource__c, ContextId__c, CreatedById, CreatedBy.Name
                FROM Queue__c
                WHERE ContextId__c IN :recordIds
                WITH USER_MODE
                LIMIT 1
            ];

            if (!currentQueue.isEmpty()) {
                List<Queue__c> allQueuedJobs = [
                    SELECT Id, Name, Status__c, Resource__c, ContextId__c, CreatedById, CreatedBy.Name
                    FROM Queue__c
                    WHERE Resource__c = :currentQueue[0].Resource__c
                    WITH USER_MODE
                    ORDER BY CreatedDate ASC
                ];
                Map<Id, JobStep__c> stepsById = new Map<Id, JobStep__c>(
                    [
                        SELECT Id, JobExecution__c, JobExecution__r.Name, JobExecution__r.Context__c
                        FROM JobStep__c
                        WHERE Id IN :getStepIds(allQueuedJobs)
                        WITH USER_MODE
                    ]
                );

                currentJob = asQueuedJob(currentQueue[0], stepsById);
                allQueuedJob = asQueuedJobs(allQueuedJobs, stepsById);
            }

            return this;
        }

        private Set<Id> getStepIds(List<Queue__c> queues) {
            Set<Id> result = new Set<Id>();

            for (Queue__c queue : queues) {
                result.add(queue.ContextId__c);
            }

            return result;
        }

        private List<QueuedJob> asQueuedJobs(List<Queue__c> queues, Map<Id, JobStep__c> stepsById) {
            List<QueuedJob> result = new List<QueuedJob>();

            for (Queue__c queue : queues) {
                result.add(asQueuedJob(queue, stepsById));
            }

            return result;
        }

        private QueuedJob asQueuedJob(Queue__c queue, Map<Id, JobStep__c> stepsById) {
            QueuedJob result = new QueuedJob();
            JobStep__c step = stepsById.get(queue.ContextId__c);

            result.id = queue.Id;
            result.status = queue.Status__c;
            result.resourceName = queue.Resource__c;
            result.contextId = queue.ContextId__c;

            result.contextLink = step?.JobExecution__r?.Context__c;

            result.processName = String.isBlank(step?.JobExecution__r?.Name) ? queue.Name : step?.JobExecution__r?.Name;
            result.processLink = '/' + (String.isBlank(step?.JobExecution__c) ? queue.ContextId__c : step?.JobExecution__c);

            result.ownerName = queue.CreatedBy.Name;
            result.ownerLink = '/' + queue.CreatedById;

            return result;
        }
    }

    public class QueuedJob {
        @AuraEnabled
        public Id id;
        @AuraEnabled
        public String status;
        @AuraEnabled
        public String resourceName;

        @AuraEnabled
        public String contextId;
        @AuraEnabled
        public String contextLink;

        @AuraEnabled
        public String processName;
        @AuraEnabled
        public String processLink;

        @AuraEnabled
        public String ownerName;
        @AuraEnabled
        public String ownerLink;
    }
}