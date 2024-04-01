public inherited sharing class StatusServiceImpl {

    // PUBLIC 

    public static Actions.StatusResult status(Id jobExecutionId){
        JobExecution__c jobExecution = [
            SELECT Id,
                Status__c,
                (SELECT Id,
                    Name,
                    ApiName__c,
                    Order__c,
                    Status__c,
                    Type__c
                FROM JobSteps__r
                ORDER BY Order__c)
            FROM JobExecution__c
            WHERE Id = :jobExecutionId
            WITH SECURITY_ENFORCED
        ];
        
        Actions.StatusResult result = new Actions.StatusResult();
        result.jobStatus = jobExecution.Status__c;
        result.steps = jobExecution.JobSteps__r;
        
        return result;
    }
}