public with sharing class ResultMonitor {
    // PUBLIC

    @AuraEnabled(cacheable=false)
    public static Result__c result(Id id) {
        try {
            List<Result__c> results = [SELECT Name, Status__c, Progress_Status__c, Function__c FROM Result__c WHERE Id = :id WITH SECURITY_ENFORCED];

            if (results.isEmpty()) {
                throw new ApplicationException(Label.Result_not_Found);
            }

            return results[0];
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }
    }

    @AuraEnabled
    public static StopExecutionData getStopExecutionData(Id resultId) {
        try {
            StopExecutionData result = new StopExecutionData();
            Result__c aResult = [
                SELECT JobStep__c, JobStep__r.Name, JobStep__r.JobExecution__r.Name, Function__c, Function__r.Name
                FROM Result__c
                WHERE Id = :resultId
                WITH SECURITY_ENFORCED
            ];
            if (aResult.JobStep__c != null) {
                result.title = String.format(Label.Stop_Execution_Title, new List<String>{ SObjectType.JobStep__c.getLabel() });
                result.info = String.format(
                    Label.Stop_Execution_Info,
                    new List<String>{ SObjectType.JobExecution__c.getLabel(), aResult.JobStep__r.JobExecution__r.Name }
                );
                result.message = String.format(Label.Stop_Execution_Message_JobStep, new List<String>{ aResult.JobStep__r.Name });
                result.error = String.format(
                    Label.Stop_Execution_Error,
                    new List<String>{ SObjectType.JobStep__c.getLabel(), aResult.JobStep__r.Name }
                );
            } else {
                result.title = String.format(Label.Stop_Execution_Title, new List<String>{ SObjectType.Function__c.getLabel() });
                result.info = String.format(
                    Label.Stop_Execution_Info,
                    new List<String>{ SObjectType.Function__c.getLabel(), aResult.Function__r.Name }
                );
                result.message = Label.Stop_Execution_Message_Function;
                result.error = String.format(
                    Label.Stop_Execution_Error,
                    new List<String>{ SObjectType.Function__c.getLabel(), aResult.Function__r.Name }
                );
            }
            return result;
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }
    }

    @AuraEnabled
    public static void stopExecution(Id resultId) {
        try {
            Result__c aResult = [
                SELECT
                    Id,
                    Status__c,
                    Function__c,
                    Function__r.API_Name__c,
                    Function__r.Script__c,
                    Function__r.Image_Name__c,
                    Function__r.Worker_Size__c
                FROM Result__c
                WHERE Id = :resultId
                WITH SECURITY_ENFORCED
            ];

            if (aResult.Status__c != 'In Progress') {
                throw new ApplicationException(Label.Stop_Execution_Error_Completed);
            }

            CopadoFunctions.cancel(aResult.Id);
        } catch (Exception e) {
            throw new ApplicationException().auraHandled(e);
        }
    }

    @SuppressWarnings('PMD.ApexCRUDViolation')
    @AuraEnabled(cacheable=false)
    public static List<ResultStatusDetail.HistoricalMessage> getHistoryData(Id id) {
        List<ResultStatusDetail.HistoricalMessage> result = new List<ResultStatusDetail.HistoricalMessage>();

        List<Result__History> historyRecords = [
            SELECT Id, ParentId, CreatedDate, NewValue
            FROM Result__History
            WHERE ParentId = :id
            WITH USER_MODE
            ORDER BY CreatedDate
        ];

        for (Result__History record : historyRecords) {
            if (
                record.NewValue != null || Test.isRunningTest() //Since NewValue is not writeable in test classes
            ) {
                ResultStatusDetail.HistoricalMessage historicalRecord = new ResultStatusDetail.HistoricalMessage();
                historicalRecord.id = record.Id;
                historicalRecord.createdDate = String.valueOf(record.CreatedDate);
                historicalRecord.message = String.valueOf(record.NewValue);

                result.add(historicalRecord);
            }
        }

        return result;
    }

    public class StopExecutionData {
        @AuraEnabled
        public String title;
        @AuraEnabled
        public String info;
        @AuraEnabled
        public String message;
        @AuraEnabled
        public String error;
    }
}